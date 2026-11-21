"""Authenticated, company-scoped boundary for the existing maintenance handlers."""
import json
import math
import uuid
from decimal import Decimal
from functools import wraps

from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Q
from django.http import Http404, JsonResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime
from rest_framework.exceptions import APIException
from rest_framework.request import Request
from rest_framework.settings import api_settings

from company.models import Company
from device.models import Device
from device.gas_views import _user_can_access
from user.models import User as Profile
from .models import DeviceMaintenance, MaintenanceSchedule, MaintenanceChecklist, MaintenanceObservation, MaintenanceType

CATALOGUE = {'get_maintenance_types', 'get_observation_categories'}
WRITE_METHODS = {'POST', 'PUT', 'PATCH', 'DELETE'}
ALLOWED_ACTIONS = {
    'start': {'scheduled', 'overdue'}, 'complete': {'in_progress'},
    'cancel': {'scheduled', 'overdue', 'in_progress'},
    'reschedule': {'scheduled', 'overdue'},
}


def authenticate(request):
    # SessionAuthentication needs the original Django request via ._request;
    # wrapping also preserves token authentication and rejects invalid tokens.
    drf_request = request if isinstance(request, Request) else Request(
        request, authenticators=[klass() for klass in api_settings.DEFAULT_AUTHENTICATION_CLASSES])
    user = drf_request.user
    if not getattr(user, 'is_authenticated', False):
        raise PermissionError('Sign in to manage maintenance.')
    if not getattr(user, 'is_active', True) or not getattr(getattr(user, 'profile', None), 'is_active', True):
        raise PermissionError('This account is inactive.')
    request.user, request.auth = user, drf_request.auth


def profile_members(company):
    return Profile.objects.filter(is_active=True, user__is_active=True).filter(
        Q(business=company) | Q(secondary_businesses=company)).distinct()


def resolve_company(kwargs, data, request):
    if 'maintenance_id' in kwargs:
        obj = get_object_or_404(DeviceMaintenance.objects.select_related('device__company'), pk=kwargs['maintenance_id'])
        return obj.device.company, obj
    if 'schedule_id' in kwargs:
        obj = get_object_or_404(MaintenanceSchedule.objects.select_related('device__company'), pk=kwargs['schedule_id'])
        return obj.device.company, obj
    if 'item_id' in kwargs:
        obj = get_object_or_404(MaintenanceChecklist.objects.select_related('maintenance__device__company'), pk=kwargs['item_id'])
        return obj.maintenance.device.company, obj
    if 'observation_id' in kwargs:
        obj = get_object_or_404(MaintenanceObservation.objects.select_related('maintenance__device__company'), pk=kwargs['observation_id'])
        return obj.maintenance.device.company, obj
    business_id = data.get('business_id') or request.GET.get('business_id') or request.GET.get('company_id')
    if business_id:
        return get_object_or_404(Company, pk=business_id), None
    if data.get('device_id'):
        return get_object_or_404(Device.objects.select_related('company'), pk=data['device_id']).company, None
    raise ValueError('Choose a business before managing maintenance.')


def _text(data, key, maximum=10000, nonempty=False):
    if key not in data:
        return
    value = data[key]
    if not isinstance(value, str) or len(value) > maximum or (nonempty and not value.strip()):
        raise ValueError('Enter valid text for ' + key + '.')


def _date(value, key, datetime_value=False):
    if not isinstance(value, str):
        raise ValueError('Enter a valid date for ' + key + '.')
    parsed = parse_datetime(value) if datetime_value else parse_date(value)
    if parsed is None and not datetime_value:
        dt = parse_datetime(value)
        parsed = dt.date() if dt is not None else None
    if parsed is None:
        raise ValueError('Enter a valid date for ' + key + '.')
    if datetime_value and timezone.is_naive(parsed):
        parsed = timezone.make_aware(parsed)
    return parsed


def validate_payload(data, company, obj=None):
    if data.get('maintenance_type_id'):
        get_object_or_404(MaintenanceType, pk=data['maintenance_type_id'], is_active=True)
    if 'client_request_id' in data:
        try:
            data['client_request_id'] = str(uuid.UUID(str(data['client_request_id'])))
        except (ValueError, AttributeError):
            raise ValueError('Use a valid request identifier.')
    if data.get('business_id') and str(data['business_id']) != str(company.pk):
        raise PermissionError('This record belongs to a different business.')
    for key in ('business_id', 'company_id', 'device_id', 'assigned_to_id', 'performed_by_id', 'supervised_by_id', 'auto_assign_to_id'):
        if key in data and data[key] not in (None, '') and (isinstance(data[key], bool) or not str(data[key]).isdigit() or int(data[key]) < 1):
            raise ValueError('Use a valid identifier for ' + key + '.')
    if data.get('device_id') and not Device.objects.filter(pk=data['device_id'], company=company).exists():
        raise PermissionError('Choose equipment from this business.')
    for key in ('assigned_to_id', 'performed_by_id', 'supervised_by_id', 'auto_assign_to_id'):
        if data.get(key) == '':
            data[key] = None
        if data.get(key) and not profile_members(company).filter(pk=data[key]).exists():
            raise PermissionError('Choose an active teammate from this business.')
    for key, choices in [('status', DeviceMaintenance.STATUS_CHOICES), ('priority', DeviceMaintenance.PRIORITY_CHOICES),
                         ('frequency', MaintenanceSchedule.FREQUENCY_CHOICES), ('outcome', DeviceMaintenance.OUTCOME_CHOICES)]:
        if key in data and data[key] not in dict(choices):
            raise ValueError('Choose a valid ' + key + '.')
    frequency = data.get('frequency', getattr(obj, 'frequency', None))
    if frequency == 'custom' or 'custom_frequency_days' in data and data['custom_frequency_days'] is not None:
        days = data.get('custom_frequency_days', getattr(obj, 'custom_frequency_days', None))
        if isinstance(days, bool) or not isinstance(days, int) or not 1 <= days <= 3650:
            raise ValueError('Custom frequency must be between 1 and 3650 days.')
    for field in ('estimated_cost', 'actual_cost', 'estimated_duration_hours', 'actual_duration_hours'):
        if data.get(field) is not None:
            value = data[field]
            try:
                number = float(value)
            except (ValueError, TypeError):
                raise ValueError('Enter a valid non-negative number for ' + field + '.')
            maximum = 99999999.99 if field.endswith('_cost') else 9999999
            if isinstance(value, bool) or not math.isfinite(number) or not 0 <= number <= maximum:
                raise ValueError('Enter a valid non-negative number for ' + field + '.')
    for key in ('scheduled_date', 'actual_start_date', 'actual_end_date', 'new_date'):
        if key in data:
            # An explicit empty scheduled date otherwise becomes an inner 500.
            if data[key] is None and key.startswith('actual_'):
                continue
            data[key] = _date(data[key], key, True).isoformat()
    for key in ('start_date', 'end_date', 'date_from', 'date_to', 'next_maintenance_date'):
        if key in data and data[key] not in (None, ''):
            data[key] = _date(data[key], key).isoformat()
    start = data.get('start_date') or getattr(obj, 'start_date', None)
    end = data.get('end_date', getattr(obj, 'end_date', None))
    if start and end and _date(str(end), 'end_date') < _date(str(start), 'start_date'):
        raise ValueError('End date must follow the start date.')
    for key in ('is_critical', 'is_completed', 'mark_completed', 'is_active'):
        if key in data and not isinstance(data[key], bool):
            raise ValueError(key + ' must be true or false.')
    for key in ('work_description', 'description', 'text', 'observation'):
        _text(data, key, maximum=200 if key == 'description' else 10000, nonempty=True)
    for key in ('notes', 'work_performed', 'issues_found', 'resolution_notes', 'recommendations', 'reason',
                'external_contractor', 'contractor_contact', 'safety_precautions', 'compliance_notes'):
        _text(data, key)
    if 'checklist_items' in data:
        items = data['checklist_items']
        if not isinstance(items, list) or len(items) > 100:
            raise ValueError('Provide no more than 100 checklist items.')
        for item in items:
            if not isinstance(item, dict) or 'description' not in item:
                raise ValueError('Every checklist item needs a description.')
            _text(item, 'description', maximum=200, nonempty=True)
            if 'is_critical' in item and not isinstance(item['is_critical'], bool):
                raise ValueError('is_critical must be true or false.')
    for key in ('parts_used', 'materials_used'):
        if key in data and (not isinstance(data[key], list) or len(data[key]) > 200):
            raise ValueError('Provide a list of ' + key + '.')
    if 'page' in data and (isinstance(data['page'], bool) or not isinstance(data['page'], int) or data['page'] < 1):
        raise ValueError('Page must be a positive integer.')
    if 'per_page' in data and (isinstance(data['per_page'], bool) or not isinstance(data['per_page'], int) or not 1 <= data['per_page'] <= 100):
        raise ValueError('Page size must be between 1 and 100.')
    if 'order_by' in data and (not isinstance(data['order_by'], str) or data['order_by'].lstrip('-') not in {'scheduled_date', 'created_at', 'updated_at', 'priority', 'status'}):
        raise ValueError('Choose a supported sort order.')
    if 'filters' in data:
        if not isinstance(data['filters'], dict):
            raise ValueError('Filters must be an object.')
        filters = data['filters']
        if set(filters) - {'device_id', 'status', 'priority', 'maintenance_type', 'assigned_to', 'date_from', 'date_to', 'overdue_only'}:
            raise ValueError('Unsupported maintenance filter.')
        validate_payload({key: value for key, value in filters.items() if value not in ('', None)}, company)


def _same_value(left, right):
    if left == right:
        return True
    if isinstance(left, Decimal):
        try:
            return left == Decimal(str(right))
        except Exception:
            return False
    if hasattr(left, 'isoformat'):
        if isinstance(right, str) and hasattr(left, 'hour'):
            parsed = parse_datetime(right)
            if parsed is not None:
                return left == parsed
        left = left.isoformat()
    return str(left) == str(right) or left in (None, '') and right in (None, '')


def creation_replay(name, data, company, profile):
    """The client-generated UUID is the row ID, making lost-response retries safe.

    Locking the company serializes same-business creates before checking that ID.
    No schema change or process-local idempotency cache is required.
    """
    request_id = data.get('client_request_id')
    if not request_id or name not in {'create_maintenance_record', 'create_maintenance_schedule'}:
        return None
    Company.objects.select_for_update().get(pk=company.pk)
    model = DeviceMaintenance if name == 'create_maintenance_record' else MaintenanceSchedule
    existing = model.objects.filter(pk=request_id).select_related('device', 'maintenance_type').first()
    if existing is None:
        return None
    if existing.device.company_id != company.pk or str(existing.device_id) != str(data.get('device_id')):
        raise PermissionError('This request identifier is already in use.')
    fields = ('maintenance_type_id', 'work_description', 'scheduled_date', 'estimated_cost',
              'estimated_duration_hours', 'assigned_to_id', 'priority', 'parts_used', 'materials_used',
              'external_contractor', 'safety_precautions') if model is DeviceMaintenance else (
              'maintenance_type_id', 'frequency', 'custom_frequency_days', 'start_date', 'end_date', 'auto_assign_to_id', 'is_active')
    defaults = {'priority': 'normal', 'parts_used': [], 'materials_used': [], 'external_contractor': '', 'safety_precautions': '', 'is_active': True}
    same_actor = model is MaintenanceSchedule or existing.created_by_id == (profile.pk if profile else None)
    if not same_actor or any(not _same_value(getattr(existing, field), data.get(field, defaults.get(field))) for field in fields):
        return JsonResponse({'error': 'This request identifier belongs to different or already edited maintenance. Refresh before retrying.'}, status=409)
    if model is DeviceMaintenance:
        expected_items = [(item['description'], item.get('is_critical', False)) for item in data.get('checklist_items', [])]
        actual_items = list(existing.checklist_items.values_list('item_description', 'is_critical'))
        if expected_items != actual_items:
            return JsonResponse({'error': 'This request identifier has a different checklist. Refresh before retrying.'}, status=409)
        from .views import serialize_maintenance_record
        return JsonResponse({'success': True, 'maintenance': serialize_maintenance_record(existing), 'replayed': True}, status=201)
    return JsonResponse({'success': True, 'schedule': {'id': str(existing.pk), 'device': existing.device.name,
        'maintenance_type': existing.maintenance_type.name, 'frequency': existing.frequency,
        'frequency_display': existing.get_frequency_display(), 'start_date': existing.start_date.isoformat(),
        'next_due': existing.next_due.isoformat(), 'is_active': existing.is_active}, 'replayed': True}, status=201)


def maintenance_access(view):
    @wraps(view)
    def checked(request, *args, **kwargs):
        try:
            authenticate(request)
            is_json = 'application/json' in (request.content_type or '')
            data = (request.GET.dict() if request.method == 'GET' else
                    json.loads(request.body or b'{}') if is_json else request.POST.dict())
            if not isinstance(data, dict):
                raise ValueError('Send a JSON object.')
            if view.__name__ in CATALOGUE:
                return view(request, *args, **kwargs)
            company, obj = resolve_company(kwargs, data, request)
            if not _user_can_access(request.user, company):
                raise PermissionError('You do not have access to this business.')
            validate_payload(data, company, obj)
            if request.method == 'GET':
                request.GET = request.GET.copy()
                for key in ('start_date', 'end_date', 'date_from', 'date_to'):
                    if key in data:
                        request.GET[key] = data[key]
            if view.__name__ == 'get_assignable_users':
                users = [{'id': p.pk, 'username': p.user.username,
                    'full_name': p.user.get_full_name() or p.user.username,
                    'email': p.user.email, 'user_type': p.user_type} for p in profile_members(company).select_related('user')]
                return JsonResponse({'success': True, 'users': users})
            profile = getattr(request.user, 'profile', None)
            data['user_id'] = profile.pk if profile is not None else None
            if view.__name__ == 'create_maintenance_record' and data.get('status', 'scheduled') != 'scheduled':
                raise ValueError('New maintenance must start as scheduled.')
            if view.__name__ == 'update_maintenance_record':
                if any(key in data for key in ('actual_start_date', 'actual_end_date', 'performed_by_id', 'actual_duration_hours')):
                    raise ValueError('Use status actions to record the performer and actual work times.')
            if is_json:
                request._body = json.dumps(data).encode()
            if request.method in WRITE_METHODS:
                with transaction.atomic():
                    replay = creation_replay(view.__name__, data, company, profile)
                    if replay is not None:
                        return replay
                    if view.__name__ == 'create_maintenance_schedule':
                        Company.objects.select_for_update().get(pk=company.pk)
                        if MaintenanceSchedule.objects.filter(device_id=data.get('device_id'), maintenance_type_id=data.get('maintenance_type_id'), frequency=data.get('frequency')).exists():
                            return JsonResponse({'error': 'This equipment already has this maintenance schedule. Edit the existing schedule instead.'}, status=409)
                    if view.__name__ == 'update_maintenance_schedule':
                        Company.objects.select_for_update().get(pk=company.pk)
                        if MaintenanceSchedule.objects.filter(device=obj.device, maintenance_type=obj.maintenance_type, frequency=data.get('frequency', obj.frequency)).exclude(pk=obj.pk).exists():
                            return JsonResponse({'error': 'A schedule with this frequency already exists for this equipment.'}, status=409)
                    record = None
                    if isinstance(obj, DeviceMaintenance):
                        record = DeviceMaintenance.objects.select_for_update().get(pk=obj.pk)
                    elif isinstance(obj, (MaintenanceChecklist, MaintenanceObservation)):
                        # Same lock as completion: a checklist edit cannot race
                        # with checking the required items and completing work.
                        record = DeviceMaintenance.objects.select_for_update().get(pk=obj.maintenance_id)
                    elif isinstance(obj, MaintenanceSchedule):
                        MaintenanceSchedule.objects.select_for_update().get(pk=obj.pk)
                    if record is not None:
                        action = data.get('action') if view.__name__ == 'update_maintenance_status' else None
                        if action is not None:
                            if action not in ALLOWED_ACTIONS:
                                raise ValueError('Choose a valid maintenance action.')
                            if record.status not in ALLOWED_ACTIONS[action]:
                                return JsonResponse({'error': 'The maintenance status has changed. Refresh before continuing.'}, status=409)
                            if action == 'reschedule' and not data.get('new_date'):
                                raise ValueError('Choose the new scheduled date.')
                            if action == 'complete' and record.checklist_items.filter(is_critical=True, is_completed=False).exists():
                                return JsonResponse({'error': 'Complete every critical checklist item first.'}, status=409)
                        if view.__name__ == 'update_maintenance_record' and 'status' in data and data['status'] != record.status:
                            raise ValueError('Use the maintenance status action to change status.')
                    response = view(request, *args, **kwargs)
                    # Legacy handlers catch exceptions themselves; a failed
                    # response must roll back their partially completed writes.
                    if response.status_code >= 400:
                        transaction.set_rollback(True)
                    return response
            return view(request, *args, **kwargs)
        except PermissionError as error:
            return JsonResponse({'error': str(error)}, status=403)
        except Http404:
            return JsonResponse({'error': 'Maintenance record or business not found.'}, status=404)
        except (ValueError, TypeError, ValidationError) as error:
            return JsonResponse({'error': str(error) if not isinstance(error, json.JSONDecodeError) else 'Invalid JSON data.'}, status=400)
        except APIException:
            return JsonResponse({'error': 'Sign in again to manage maintenance.'}, status=401)
    return checked
