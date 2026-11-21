"""Run actual patched Celery task functions with isolated DB and fake delivery."""
import uuid
from datetime import timedelta
from unittest.mock import Mock, patch

from django.db import connection
from django.test import TestCase, override_settings
from django.utils import timezone
from company.models import Company
from device.models import Device
from .models import DeviceMaintenance, MaintenanceType
from . import tasks
from .worker_guards import mark_overdue_if_due, REMINDER_FLAGS


class MaintenanceReminderTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.company = Company.objects.create(name='Isolated worker test')
        cls.device = Device.objects.create(company=cls.company, name='Scale', device_id='TEST-ONLY')
        cls.kind = MaintenanceType.objects.create(name='Inspection', category='inspection')

    def setUp(self):
        self.now = timezone.now()
        for name, return_value in (('_build_maintenance_email_context', {}),
                                   ('_get_maintenance_recipients', ['qa@example.invalid']),
                                   ('render_to_string', 'test reminder')):
            mock = patch.object(tasks, name, return_value=return_value)
            mock.start()
            self.addCleanup(mock.stop)

    def record(self, status='scheduled', past=False, **values):
        return DeviceMaintenance.objects.create(device=self.device, maintenance_type=self.kind,
            scheduled_date=self.now + timedelta(hours=-1 if past else 1),
            work_description='Isolated task verification', status=status, **values)

    def send(self, record, kind='upcoming'):
        return tasks.send_maintenance_reminder_email.run(str(record.pk), reminder_type=kind)

    def test_celery_registration_keeps_public_task_name(self):
        self.assertEqual(tasks.send_maintenance_reminder_email.name, 'maintenance.tasks.send_maintenance_reminder_email')

    def test_terminal_or_started_work_never_sends_queued_reminder(self):
        with patch.object(tasks, '_send_email_direct') as deliver:
            for status in ('completed', 'cancelled', 'in_progress'):
                for past, kind in ((False, 'upcoming'), (True, 'overdue')):
                    self.assertFalse(self.send(self.record(status, past=past), kind))
            deliver.assert_not_called()

    def test_unknown_type_invalid_or_missing_record_is_ignored(self):
        with patch.object(tasks, '_send_email_direct') as deliver:
            for identifier in (None, 'bad-id', str(uuid.uuid4())):
                self.assertFalse(tasks.send_maintenance_reminder_email.run(identifier))
            self.assertFalse(self.send(self.record(), 'unknown-type'))
            deliver.assert_not_called()

    def test_sent_flag_skips_every_reminder_type(self):
        with patch.object(tasks, '_send_email_direct') as deliver:
            for kind, flag in REMINDER_FLAGS.items():
                record = self.record(past=kind.startswith('overdue'), **{flag: True})
                self.assertFalse(self.send(record, kind))
            deliver.assert_not_called()

    def test_send_and_duplicate_execute_actual_handler_once(self):
        record = self.record()
        with patch.object(tasks, '_send_email_direct', return_value=True) as deliver:
            self.assertTrue(self.send(record))
            self.assertFalse(self.send(record))
            self.assertEqual(deliver.call_count, 1)
        record.refresh_from_db()
        self.assertTrue(record.reminder_sent)
        self.assertIsNotNone(record.reminder_sent_at)

    def test_each_reminder_type_records_its_own_success_flag(self):
        with patch.object(tasks, '_send_email_direct', return_value=True):
            for kind, flag in REMINDER_FLAGS.items():
                record = self.record(past=kind.startswith('overdue'))
                self.assertTrue(self.send(record, kind))
                record.refresh_from_db()
                self.assertTrue(getattr(record, flag))
                self.assertIsNotNone(getattr(record, flag + '_at'))

    def test_failed_delivery_stays_retryable(self):
        record = self.record()
        with patch.object(tasks, '_send_email_direct', return_value=False):
            self.assertFalse(self.send(record))
        record.refresh_from_db()
        self.assertFalse(record.reminder_sent)
        self.assertIsNone(record.reminder_sent_at)
        with patch.object(tasks, '_send_email_direct', return_value=True):
            self.assertTrue(self.send(record))

    def test_date_category_is_rechecked_after_queueing(self):
        with patch.object(tasks, '_send_email_direct') as deliver:
            self.assertFalse(self.send(self.record(past=True), 'upcoming'))
            self.assertFalse(self.send(self.record(past=False), 'overdue'))
            deliver.assert_not_called()

    def test_lock_is_on_bare_parent_row_during_actual_delivery(self):
        record = self.record()
        actual_select = DeviceMaintenance.objects.select_for_update
        queries = []
        def capture(*args, **kwargs):
            query = actual_select(*args, **kwargs)
            queries.append(query.query)
            return query
        def deliver(*args, **kwargs):
            self.assertTrue(connection.in_atomic_block)
            return True
        with patch.object(DeviceMaintenance.objects, 'select_for_update', side_effect=capture), patch.object(tasks, '_send_email_direct', side_effect=deliver):
            self.assertTrue(self.send(record))
        self.assertEqual(len(queries), 1)
        self.assertTrue(queries[0].select_for_update)
        self.assertFalse(queries[0].select_related)

    def test_stale_overdue_row_cannot_regress_live_workflow_status(self):
        for status in ('in_progress', 'completed', 'cancelled'):
            stale = self.record(past=True)
            # Simulate the API transition after the checker read its queryset.
            DeviceMaintenance.objects.filter(pk=stale.pk).update(status=status)
            self.assertFalse(mark_overdue_if_due(stale, self.now))
            stale.refresh_from_db()
            self.assertEqual(stale.status, status)

    def test_rescheduled_or_deleted_row_is_not_queued(self):
        stale = self.record(past=True)
        DeviceMaintenance.objects.filter(pk=stale.pk).update(status='scheduled', scheduled_date=self.now + timedelta(days=7))
        self.assertFalse(mark_overdue_if_due(stale, self.now))
        self.assertEqual(stale.status, 'scheduled')
        DeviceMaintenance.objects.filter(pk=stale.pk).delete()
        self.assertFalse(mark_overdue_if_due(stale, self.now))

    def test_due_scheduled_record_becomes_overdue(self):
        record = self.record()
        DeviceMaintenance.objects.filter(pk=record.pk).update(scheduled_date=self.now - timedelta(hours=1))
        self.assertTrue(mark_overdue_if_due(record, self.now))
        self.assertEqual(record.status, 'overdue')

    def test_actual_overdue_worker_uses_fresh_status_before_dispatch(self):
        record = self.record(past=True)
        def complete_before_recheck(stale, now):
            DeviceMaintenance.objects.filter(pk=stale.pk).update(status='completed')
            return mark_overdue_if_due(stale, now)
        with patch.object(tasks, 'mark_overdue_if_due', side_effect=complete_before_recheck), patch.object(tasks.send_maintenance_reminder_email, 'delay') as queue:
            result = tasks.check_overdue_maintenance_reminders.run()
            self.assertEqual(result['queued'], 0)
            queue.assert_not_called()
        record.refresh_from_db()
        self.assertEqual(record.status, 'completed')

    def test_actual_legacy_repair_never_selects_in_progress(self):
        record = self.record('in_progress', past=True)
        with patch.object(tasks.send_maintenance_reminder_email, 'delay') as queue:
            result = tasks.send_past_missed_reminders.run()
            self.assertEqual(result['sent'], 0)
            queue.assert_not_called()
        record.refresh_from_db()
        self.assertEqual(record.status, 'in_progress')

    def test_actual_overdue_worker_queues_eligible_record(self):
        record = self.record(past=True)
        with patch.object(tasks.send_maintenance_reminder_email, 'delay') as queue:
            result = tasks.check_overdue_maintenance_reminders.run()
            self.assertEqual(result['queued'], 1)
            queue.assert_called_once_with(str(record.pk), reminder_type='overdue')

    @override_settings(DEFAULT_FROM_EMAIL='sender@example.invalid', EMAIL_HOST='smtp.invalid', EMAIL_HOST_USER='', EMAIL_HOST_PASSWORD='')
    def test_accepted_smtp_with_quit_and_close_errors_does_not_fallback(self):
        smtp = Mock()
        smtp.sendmail.return_value = {}
        smtp.quit.side_effect = OSError('connection closed after acceptance')
        smtp.close.side_effect = OSError('already closed')
        with patch.object(tasks.smtplib, 'SMTP', return_value=smtp) as connect:
            self.assertTrue(tasks._send_email_direct('Test', 'text', '<p>text</p>', ['qa@example.invalid']))
            connect.assert_called_once_with('smtp.invalid', 25, timeout=30)
            smtp.sendmail.assert_called_once()

    @override_settings(DEFAULT_FROM_EMAIL='sender@example.invalid', EMAIL_HOST='smtp.invalid', EMAIL_HOST_USER='', EMAIL_HOST_PASSWORD='')
    def test_failed_connect_falls_back_but_accepted_fallback_quit_error_succeeds(self):
        smtp = Mock()
        smtp.sendmail.return_value = {}
        smtp.quit.side_effect = OSError('closed after acceptance')
        with patch.object(tasks.smtplib, 'SMTP', side_effect=[OSError('connection refused'), smtp]) as connect:
            self.assertTrue(tasks._send_email_direct('Test', 'text', '<p>text</p>', ['qa@example.invalid']))
            self.assertEqual(connect.call_count, 2)
            smtp.sendmail.assert_called_once()
