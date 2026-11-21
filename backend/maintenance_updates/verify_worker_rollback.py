"""Verify the installed reminder task on one disposable PostgreSQL record.

Run only after reviewing this file and the installed worker guards:
  ARTIC_QA_USER_EMAIL=<authorized account> python manage.py shell \
    -c "exec(open('maintenance_updates/verify_worker_rollback.py').read())"

The actual Celery task body runs synchronously with mail fully mocked. No polling
task, queue, external delivery or existing-record mutation is permitted. The
single temporary UUID row is always rolled back and its absence is checked.
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
from django.utils import timezone
from device.models import Device
from maintenance.models import DeviceMaintenance, MaintenanceType
from maintenance import tasks
from user.models import User as Profile


class RollbackVerification(Exception):
    pass


def blocked(*args, **kwargs):
    raise AssertionError('Unexpected external side effect was blocked')


email = os.environ.get('ARTIC_QA_USER_EMAIL')
assert email, 'Set ARTIC_QA_USER_EMAIL to the authorized existing account.'
profile = Profile.objects.select_related('user', 'business').get(user__email__iexact=email)
assert profile.business is not None and profile.is_active and profile.user.is_active
assert connection.vendor == 'postgresql', 'This verification expects PostgreSQL.'
assert router.db_for_write(DeviceMaintenance) == 'default', 'Unexpected database routing'
for signal in (signals.pre_save, signals.post_save, signals.pre_delete, signals.post_delete):
    assert not signal.has_listeners(DeviceMaintenance), 'Unexpected model signal; review before running'
with connection.cursor() as cursor:
    cursor.execute('SELECT tgname FROM pg_trigger WHERE tgrelid = to_regclass(%s) AND NOT tgisinternal', [DeviceMaintenance._meta.db_table])
    assert not cursor.fetchall(), 'Unexpected database trigger; review before running'
device = Device.objects.filter(company=profile.business).order_by('pk').first()
kind = MaintenanceType.objects.filter(is_active=True).order_by('pk').first()
assert device is not None and kind is not None, 'Existing equipment and maintenance type are required.'
assert tasks.send_maintenance_reminder_email.name == 'maintenance.tasks.send_maintenance_reminder_email'

record_id = uuid.uuid4()
checks = []
locks = []


def observe_lock(execute, sql, params, many, context):
    if 'FOR UPDATE' in sql.upper() and DeviceMaintenance._meta.db_table in sql:
        # Keep only a count, never SQL/account data in the resulting evidence.
        locks.append(True)
    return execute(sql, params, many, context)


with ExitStack() as blockers:
    # The database connection is already open before socket creation is blocked.
    blockers.enter_context(patch.object(EmailMessage, 'send', blocked))
    blockers.enter_context(patch.object(Storage, 'save', blocked))
    blockers.enter_context(patch.object(socket.socket, 'connect', blocked))
    blockers.enter_context(patch.object(socket.socket, 'connect_ex', blocked))
    blockers.enter_context(patch.object(socket, 'create_connection', blocked))
    blockers.enter_context(patch('smtplib.SMTP', blocked))
    blockers.enter_context(patch('smtplib.SMTP_SSL', blocked))
    blockers.enter_context(patch('celery.app.task.Task.apply_async', blocked))
    blockers.enter_context(patch('celery.app.base.Celery.send_task', blocked))
    blockers.enter_context(patch.object(tasks.send_maintenance_reminder_email, 'retry', blocked))
    blockers.enter_context(patch.object(tasks, '_get_maintenance_recipients', return_value=['rollback-only@example.invalid']))
    blockers.enter_context(patch.object(tasks, 'render_to_string', return_value='Rollback-only reminder verification'))
    smtp = blockers.enter_context(patch.object(tasks, '_send_email_direct', return_value=True))
    blockers.enter_context(connection.execute_wrapper(observe_lock))
    try:
        with transaction.atomic():
            with connection.cursor() as cursor:
                cursor.execute("SET LOCAL lock_timeout = '5s'")
                cursor.execute("SET LOCAL statement_timeout = '20s'")
            now = timezone.now()
            record = DeviceMaintenance.objects.create(
                id=record_id, device=device, maintenance_type=kind,
                scheduled_date=now + timedelta(hours=1), status='scheduled',
                work_description='Rollback-only reminder worker verification',
                created_by=profile, assigned_to=None,
            )
            assert tasks.send_maintenance_reminder_email.run(str(record_id), 'upcoming') is True
            record.refresh_from_db()
            assert record.reminder_sent and record.reminder_sent_at is not None
            assert smtp.call_count == 1 and len(locks) == 1
            checks.append('eligible delivery records success under row lock')

            assert tasks.send_maintenance_reminder_email.run(str(record_id), 'upcoming') is False
            assert smtp.call_count == 1
            checks.append('duplicate job skips transport')

            for state in ('in_progress', 'completed', 'cancelled'):
                # Modify only the still-uncommitted synthetic record.
                DeviceMaintenance.objects.filter(pk=record_id).update(
                    status=state, reminder_sent=False, reminder_sent_at=None)
                assert tasks.send_maintenance_reminder_email.run(str(record_id), 'upcoming') is False
                assert smtp.call_count == 1
                record.refresh_from_db()
                assert record.status == state and not record.reminder_sent
                checks.append(state + ' skips transport and preserves status')

            DeviceMaintenance.objects.filter(pk=record_id).update(status='scheduled')
            smtp.return_value = False
            assert tasks.send_maintenance_reminder_email.run(str(record_id), 'upcoming') is False
            record.refresh_from_db()
            assert not record.reminder_sent and record.reminder_sent_at is None
            assert smtp.call_count == 2
            checks.append('failed transport leaves success flag unset')

            # Only the temporary row was used; every valid invocation locked it.
            assert len(locks) == 6
            raise RollbackVerification()
    except RollbackVerification:
        pass
    finally:
        assert not DeviceMaintenance.objects.filter(pk=record_id).exists(), 'Temporary record unexpectedly persisted'

print(json.dumps({
    'result': 'passed', 'checks': checks, 'row_lock_queries': len(locks),
    'rollback_verified': True, 'messages_sent': 0, 'tasks_queued': 0,
    'notes': 'Actual installed Celery task.run and PostgreSQL with SMTP mocked; this verifies row-lock execution, not concurrent-process contention or physical email delivery.',
}, indent=2))
