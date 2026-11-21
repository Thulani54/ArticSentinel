import hashlib
import json
from datetime import date, datetime, time, timedelta
from decimal import Decimal, InvalidOperation
from uuid import UUID
from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from device.models import Device
from alerts.models import Alert
from .models import CylinderRefill, AlertTeamState, AlertTeamEvent
from .telemetry import scan_rows


def can_access(user, company_id):
    if not user.is_active:
        return False
    if user.is_superuser:
        return True
    profile = getattr(user, 'profile', None)
    return profile is not None and getattr(profile, 'is_active', True) and (profile.business_id == company_id or profile.secondary_businesses.filter(pk=company_id).exists())


def resolve_device(request, device_id, kind):
    device = get_object_or_404(Device, pk=device_id)
    if not can_access(request.user, device.company_id):
        return None, Response({'error': 'You do not have access to this device.'}, status=403)
    if device.device_type.lower() != kind:
        return None, Response({'error': 'This history is not available for this device type.'}, status=400)
    return device, None


def clean_text(value, field, limit):
    if not isinstance(value, str) or len(value.strip()) > limit:
        raise ValueError(f'{field} must be text of at most {limit} characters.')
    return value.strip()


def decimal_field(value, label, minimum, maximum):
    if isinstance(value, bool):
        raise ValueError(f'Enter a valid {label}.')
    try:
        number = Decimal(str(value))
        if not number.is_finite() or not minimum <= number <= maximum or number != number.quantize(Decimal('.01')):
            raise ValueError()
        return number
    except (InvalidOperation, ValueError):
        raise ValueError(f'{label} must be between {minimum} and {maximum}, with at most 2 decimal places.')


def refill_payload(row):
    return {'id': row.pk, 'purchased_on': row.purchased_on.isoformat(), 'gas_kg': str(row.gas_kg),
        'cost': str(row.cost), 'currency': 'ZAR', 'supplier': row.supplier, 'notes': row.notes,
        'kind': row.kind, 'capacity_kg': str(row.capacity_kg) if row.capacity_kg is not None else None,
        'tare_kg': str(row.tare_kg) if row.tare_kg is not None else None,
        'created_at': row.created_at.isoformat()}


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def refills(request, device_id):
    device, error = resolve_device(request, device_id, 'gas_cylinder')
    if error is not None:
        return error
    if request.method == 'POST':
        try:
            request_id = UUID(str(request.data.get('request_id')))
            day = date.fromisoformat(str(request.data.get('purchased_on')))
            if day > timezone.localdate() or day.year < 2000:
                raise ValueError('Choose a purchase date between 2000 and today.')
            kind = request.data.get('kind', 'refill')
            if kind not in ('refill', 'cylinder_change'):
                raise ValueError('Choose refill purchase or cylinder change.')
            values = {'purchased_on': day, 'kind': kind,
                'capacity_kg': decimal_field(request.data['capacity_kg'], 'Cylinder capacity', Decimal('.01'), Decimal('200')) if request.data.get('capacity_kg') not in (None, '') else None,
                'tare_kg': decimal_field(request.data['tare_kg'], 'Empty cylinder weight', Decimal('.01'), Decimal('200')) if request.data.get('tare_kg') not in (None, '') else None,
                'gas_kg': decimal_field(request.data.get('gas_kg'), 'Gas kilograms', Decimal('0') if kind == 'cylinder_change' else Decimal('.01'), Decimal('200')),
                'cost': decimal_field(request.data.get('cost'), 'Cost', Decimal('0'), Decimal('99999999.99')),
                'supplier': clean_text(request.data.get('supplier', ''), 'Supplier', 160),
                'notes': clean_text(request.data.get('notes', ''), 'Notes', 1000)}
        except (ValueError, TypeError) as exc:
            return Response({'error': str(exc) or 'Check the refill details and retry.'}, status=400)
        fingerprint = hashlib.sha256(json.dumps(values, default=str, sort_keys=True).encode()).hexdigest()
        with transaction.atomic():
            # Serialise retries per device so a lost HTTP response cannot create a duplicate.
            Device.objects.select_for_update().get(pk=device.pk)
            row, created = CylinderRefill.objects.get_or_create(device=device, request_id=request_id,
                defaults={**values, 'created_by': request.user, 'fingerprint': fingerprint})
            if row.fingerprint != fingerprint:
                return Response({'error': 'This request was already used for different refill details.'}, status=409)
        return Response({'refill': refill_payload(row)}, status=201 if created else 200)
    try:
        month = date.fromisoformat(request.query_params.get('month', timezone.localdate().strftime('%Y-%m')) + '-01')
        if not date(2000, 1, 1) <= month <= timezone.localdate().replace(day=1):
            raise ValueError()
        offset = int(request.query_params.get('offset', '0'))
        if not 0 <= offset <= 100000:
            raise ValueError()
    except ValueError:
        return Response({'error': 'Choose a valid month and history page.'}, status=400)
    next_month = (month.replace(day=28) + timedelta(days=4)).replace(day=1)
    rows = CylinderRefill.objects.filter(device=device, purchased_on__gte=month, purchased_on__lt=next_month)
    totals = rows.aggregate(cost=Sum('cost'), gas_kg=Sum('gas_kg'))
    page = list(rows[offset:offset + 51])
    return Response({'month': month.strftime('%Y-%m'), 'currency': 'ZAR', 'total_cost': str(totals['cost'] or 0),
        'purchased_kg': str(totals['gas_kg'] or 0), 'count': rows.count(), 'refills': [refill_payload(r) for r in page[:50]],
        'next_offset': offset + 50 if len(page) > 50 else None})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def scans(request, device_id):
    device, error = resolve_device(request, device_id, 'device7')
    if error is not None:
        return error
    try:
        today = timezone.localdate()
        start = date.fromisoformat(request.query_params.get('from', (today - timedelta(days=6)).isoformat()))
        end = date.fromisoformat(request.query_params.get('to', today.isoformat()))
        if not 0 <= (end - start).days <= 89 or end > today:
            raise ValueError('Choose a period of up to 90 days, ending today or earlier.')
        result = request.query_params.get('result', 'all')
        if result not in ('all', 'verified', 'failed'):
            raise ValueError('Choose All, Verified or Failed scans.')
        search = clean_text(request.query_params.get('q', ''), 'Search', 512)
        offset = int(request.query_params.get('offset', '0'))
        if not 0 <= offset <= 100000:
            raise ValueError('History page is invalid.')
        since = timezone.make_aware(datetime.combine(start, time.min))
        until = timezone.make_aware(datetime.combine(end + timedelta(days=1), time.min))
    except (ValueError, TypeError) as exc:
        return Response({'error': str(exc) or 'Check the history filters.'}, status=400)
    try:
        rows = scan_rows(device, since, until, search, result, offset)
    except Exception:
        return Response({'error': 'Scan history is temporarily unavailable. Please retry.'}, status=503)
    return Response({'scans': rows[:50], 'next_offset': offset + 50 if len(rows) > 50 else None,
        'from': start.isoformat(), 'to': end.isoformat(), 'retention_days': 90})


def member_name(user):
    return (user.get_full_name() or user.email or user.username)[:160]


def team_members(company_id):
    return get_user_model().objects.filter(is_active=True, profile__is_active=True).filter(
        Q(profile__business_id=company_id) | Q(profile__secondary_businesses__id=company_id)).distinct().order_by('first_name', 'username')


def team_payload(alert, state):
    events = state.events.all()[:30] if state else []
    return {'alert_id': alert.pk, 'status': alert.status, 'revision': state.revision if state else 0,
        'assigned_to': state.assigned_to_id if state else None,
        'assigned_name': member_name(state.assigned_to) if state and state.assigned_to else None,
        'members': [{'id': u.pk, 'name': member_name(u)} for u in team_members(alert.company_id)],
        'events': [{'id': e.pk, 'action': e.action, 'actor': e.actor_name, 'assignee': e.assignee_name,
            'note': e.note, 'created_at': e.created_at.isoformat()} for e in events]}


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def alert_team(request, alert_id):
    alert = get_object_or_404(Alert.objects.select_related('device'), pk=alert_id)
    if alert.company_id != alert.device.company_id or not can_access(request.user, alert.company_id):
        return Response({'error': 'You do not have access to this alert.'}, status=403)
    if request.method == 'GET':
        return Response(team_payload(alert, AlertTeamState.objects.filter(alert=alert).first()))
    try:
        revision = request.data.get('revision')
        if isinstance(revision, bool) or not isinstance(revision, int) or revision < 0:
            raise ValueError('Reload the alert before saving.')
        action = request.data.get('action')
        if action not in ('assign', 'resolve', 'note'):
            raise ValueError('Choose an alert action.')
        note = clean_text(request.data.get('note', ''), 'Note', 2000)
        if action in ('resolve', 'note') and len(note) < 5:
            raise ValueError('Add a note of at least 5 characters explaining what was done.')
        assignee = None
        if action == 'assign' and request.data.get('assigned_to') is not None:
            value = request.data['assigned_to']
            if isinstance(value, bool) or not isinstance(value, int):
                raise ValueError('Choose a team member.')
            assignee = team_members(alert.company_id).filter(pk=value).first()
            if assignee is None:
                raise ValueError('Choose an active member of this business.')
    except ValueError as exc:
        return Response({'error': str(exc)}, status=400)
    with transaction.atomic():
        alert = Alert.objects.select_for_update().get(pk=alert.pk)
        state, _ = AlertTeamState.objects.get_or_create(alert=alert)
        if state.revision != revision:
            return Response({'error': 'This alert changed on another device. Reload before saving.'}, status=409)
        if action == 'resolve' and alert.status == 'resolved':
            return Response({'error': 'This alert is already resolved. Reload to see the latest update.'}, status=409)
        if action == 'assign':
            state.assigned_to = assignee
        if action == 'resolve':
            alert.status = 'resolved'
            alert.resolved_at = timezone.now()
            alert.save(update_fields=['status', 'resolved_at'])
        state.revision += 1
        state.save()
        AlertTeamEvent.objects.create(state=state, actor=request.user, actor_name=member_name(request.user),
            assignee_name=member_name(assignee) if assignee else '', action=action, note=note)
    return Response(team_payload(alert, state))
