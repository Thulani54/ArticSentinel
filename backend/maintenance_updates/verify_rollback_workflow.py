"""Manual host verification against deployed routes/PostgreSQL, always rolled back.

Run only after reviewing the installed maintenance handlers and this script:
  ARTIC_QA_USER_EMAIL=<existing signed-in account> python manage.py shell \
    -c "exec(open('maintenance_updates/verify_rollback_workflow.py').read())"

No live HTTP request, token creation, mail, Celery task or existing-row mutation.
Temporary rows never commit. A checklist sequence number can advance on rollback.
The database connection must already be established before network calls are blocked.
"""
import json
import os
import socket
import uuid
from contextlib import ExitStack
from datetime import timedelta
from unittest.mock import patch

from django.core.files.storage import Storage
from django.core.mail import EmailMessage
from django.db import connection, router, transaction
from django.db.models import signals
from django.test import RequestFactory
from django.urls import resolve
from django.utils import timezone
from rest_framework.authtoken.models import Token
from company.models import Company
from device.models import Device
from maintenance.models import DeviceMaintenance, MaintenanceChecklist, MaintenanceSchedule, MaintenanceType
from user.models import User as Profile


class RollbackVerification(Exception):
    pass


def blocked(*args, **kwargs):
    raise AssertionError('Unexpected external side effect was blocked')


email = os.environ.get('ARTIC_QA_USER_EMAIL')
assert email, 'Set ARTIC_QA_USER_EMAIL to the authorized existing account.'
token = Token.objects.select_related('user').get(user__email__iexact=email)
profile = Profile.objects.select_related('business').get(user=token.user)
company = profile.business
assert company is not None and token.user.is_active and profile.is_active
assert connection.vendor == 'postgresql', 'This verification expects PostgreSQL.'
models = (DeviceMaintenance, MaintenanceChecklist, MaintenanceSchedule)
for model in models:
    assert router.db_for_write(model) == 'default', 'Unexpected database routing'
    for signal in (signals.pre_save, signals.post_save, signals.pre_delete, signals.post_delete):
        assert not signal.has_listeners(model), 'Unexpected model signal; review before running'
    with connection.cursor() as cursor:
        cursor.execute('SELECT tgname FROM pg_trigger WHERE tgrelid = to_regclass(%s) AND NOT tgisinternal', [model._meta.db_table])
        assert not cursor.fetchall(), 'Unexpected database trigger; review before running'

# Use an existing equipment/type pair with two unused recurring frequencies.
chosen = None
for device in Device.objects.filter(company=company).order_by('pk'):
    for kind in MaintenanceType.objects.filter(is_active=True):
        used = set(MaintenanceSchedule.objects.filter(device=device, maintenance_type=kind).values_list('frequency', flat=True))
        available = [f for f, _ in MaintenanceSchedule.FREQUENCY_CHOICES if f not in used and f != 'custom']
        if len(available) >= 2:
            chosen = device, kind, available[:2]
            break
    if chosen:
        break
assert chosen is not None, 'No existing equipment/type pair with two unused schedule frequencies.'
device, kind, frequencies = chosen
record_id, schedule_id = uuid.uuid4(), uuid.uuid4()
factory = RequestFactory()
steps = []


def call(method, path, data=None, expected=200):
    headers = {'HTTP_AUTHORIZATION': 'Token ' + token.key}
    request = (factory.get(path, data or {}, **headers) if method == 'GET' else
               factory.post(path, json.dumps(data or {}), content_type='application/json', **headers))
    match = resolve(path)
    response = match.func(request, *match.args, **match.kwargs)
    if hasattr(response, 'render'):
        response.render()
    payload = json.loads(response.content) if 'json' in response.get('Content-Type', '') else response.content
    assert response.status_code == expected, f'{method} {path} returned {response.status_code}: {payload}'
    steps.append({'route': path.replace(str(record_id), '<temporary-record>').replace(str(schedule_id), '<temporary-schedule>'), 'status': response.status_code})
    return payload


now = timezone.now()
scheduled = now + timedelta(minutes=5)
report_start, report_end = (now - timedelta(days=1)).date().isoformat(), (now + timedelta(days=2)).date().isoformat()
report_query = {'business_id': company.pk, 'start_date': report_start, 'end_date': report_end}
checklist_id = None
with ExitStack() as blockers:
    # Authenticate through the real token authenticator; never log the key.
    blockers.enter_context(patch.object(EmailMessage, 'send', blocked))
    blockers.enter_context(patch.object(Storage, 'save', blocked))
    blockers.enter_context(patch.object(socket.socket, 'connect', blocked))
    blockers.enter_context(patch.object(socket, 'create_connection', blocked))
    blockers.enter_context(patch('celery.app.task.Task.apply_async', blocked))
    blockers.enter_context(patch('celery.app.base.Celery.send_task', blocked))
    try:
        with transaction.atomic():
            # Avoid waiting indefinitely on a production request or accidental long query.
            with connection.cursor() as cursor:
                cursor.execute("SET LOCAL lock_timeout = '5s'")
                cursor.execute("SET LOCAL statement_timeout = '20s'")
            before_report = call('GET', '/api/maintenance/report/', report_query)
            data = {
                'client_request_id': str(record_id), 'device_id': device.pk,
                'maintenance_type_id': str(kind.pk), 'scheduled_date': scheduled.isoformat(),
                'work_description': 'Rollback-only workflow verification', 'priority': 'normal',
                'assigned_to_id': profile.pk, 'estimated_cost': '12.50',
                'checklist_items': [{'description': 'Rollback-only critical verification', 'is_critical': True}],
            }
            created = call('POST', '/api/maintenance/create/', data, 201)
            assert created['maintenance']['id'] == str(record_id)
            replay = call('POST', '/api/maintenance/create/', data, 201)
            assert replay.get('replayed') is True and DeviceMaintenance.objects.filter(pk=record_id).count() == 1
            item = MaintenanceChecklist.objects.get(maintenance_id=record_id)
            checklist_id = item.pk
            call('POST', f'/api/maintenance/{record_id}/update/', {
                'work_description': 'Rollback-only edited description', 'priority': 'high', 'estimated_cost': '15.00'})
            record = DeviceMaintenance.objects.get(pk=record_id)
            assert record.work_description == 'Rollback-only edited description' and record.priority == 'high'
            call('POST', f'/api/maintenance/{record_id}/status/', {'action': 'start', 'user_id': 1})
            record.refresh_from_db()
            assert record.status == 'in_progress' and record.performed_by_id == profile.pk
            call('POST', f'/api/maintenance/{record_id}/status/', {'action': 'complete'}, 409)
            record.refresh_from_db()
            assert record.status == 'in_progress' and record.actual_end_date is None
            call('POST', f'/api/maintenance/checklist/{item.pk}/update/', {'mark_completed': True, 'user_id': 1, 'notes': 'Verified in rollback-only QA'})
            item.refresh_from_db()
            assert item.is_completed and item.completed_by_id == profile.pk
            call('POST', f'/api/maintenance/{record_id}/status/', {'action': 'complete', 'outcome': 'successful'})
            detail = call('GET', f'/api/maintenance/{record_id}/')['maintenance']
            assert detail['status'] == 'completed' and detail['checklist_items'][0]['is_completed']
            report = call('GET', '/api/maintenance/report/', report_query)
            assert report['overall_statistics']['completed_count'] == before_report['overall_statistics']['completed_count'] + 1
            assert any(str(row['id']) == str(record_id) for row in report['recent_completed'])
            monthly = call('GET', f'/api/maintenance/reports/{scheduled.year}/{scheduled.month}/records/', {'business_id': company.pk})
            assert any(row['id'] == str(record_id) for row in monthly['maintenance_records'])
            pdf = call('GET', f'/api/maintenance/reports/{record_id}/pdf/', {'business_id': company.pk})
            assert pdf.startswith(b'%PDF-') and len(pdf) > 1000
            schedule_data = {'client_request_id': str(schedule_id), 'device_id': device.pk, 'maintenance_type_id': str(kind.pk),
                'frequency': frequencies[0], 'start_date': scheduled.date().isoformat(), 'auto_assign_to_id': profile.pk, 'is_active': False}
            result = call('POST', '/api/maintenance/schedule/create/', schedule_data, 201)
            assert result['schedule']['id'] == str(schedule_id)
            assert call('POST', '/api/maintenance/schedule/create/', schedule_data, 201).get('replayed') is True
            call('POST', f'/api/maintenance/schedule/{schedule_id}/update/', {'frequency': frequencies[1], 'is_active': False})
            schedule = MaintenanceSchedule.objects.get(pk=schedule_id)
            assert schedule.frequency == frequencies[1] and not schedule.is_active
            assert schedule.next_due == schedule.calculate_next_due_date(schedule.start_date)
            # This exception exits the only outer transaction without ever committing.
            raise RollbackVerification()
    except RollbackVerification:
        pass
    finally:
        assert not DeviceMaintenance.objects.filter(pk=record_id).exists(), 'Temporary record unexpectedly persisted'
        assert not MaintenanceSchedule.objects.filter(pk=schedule_id).exists(), 'Temporary schedule unexpectedly persisted'
        if checklist_id is not None:
            assert not MaintenanceChecklist.objects.filter(pk=checklist_id).exists(), 'Temporary checklist unexpectedly persisted'

print(json.dumps({'result': 'passed', 'steps': steps, 'rollback_verified': True, 'messages_sent': 0,
    'notes': 'Actual deployed route handlers and PostgreSQL, in-process requests; not a device-to-network end-to-end run. Checklist sequence may advance.'}, indent=2))
