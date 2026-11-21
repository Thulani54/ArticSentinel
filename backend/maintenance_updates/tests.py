"""Exercise patched host handlers and real maintenance models in isolation."""
import json
import uuid
from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.http import JsonResponse
from django.test import TestCase, RequestFactory
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework.authtoken.models import Token
from company.models import Company
from device.models import Device
from user.models import User as Profile
from .models import DeviceMaintenance, MaintenanceType, MaintenanceChecklist, MaintenanceSchedule, MaintenanceObservation
from . import views
from .access import maintenance_access


class MaintenanceBoundaryTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.company = Company.objects.create(name='Primary test site')
        cls.other = Company.objects.create(name='Other test site')
        cls.device = Device.objects.create(company=cls.company, name='Test scale', device_id='T-1')
        cls.other_device = Device.objects.create(company=cls.other, name='Private scale', device_id='T-2')
        cls.kind = MaintenanceType.objects.create(name='Inspection', category='inspection')
        cls.actor = get_user_model().objects.create_user(username='actor', password='local-test')
        cls.teammate = get_user_model().objects.create_user(username='teammate')
        cls.outsider = get_user_model().objects.create_user(username='outsider')
        cls.profile = Profile.objects.create(user=cls.actor, business=cls.company)
        cls.teammate_profile = Profile.objects.create(user=cls.teammate, business=cls.company)
        cls.outside_profile = Profile.objects.create(user=cls.outsider, business=cls.other)
        cls.token = Token.objects.create(user=cls.actor).key

    def setUp(self):
        self.factory = RequestFactory()
        self.future = (timezone.now() + timedelta(days=2)).isoformat()

    def call(self, name, data=None, method='POST', token=True, **kwargs):
        headers = {'HTTP_AUTHORIZATION': 'Token ' + self.token} if token else {}
        data = data or {}
        request = (self.factory.get('/maintenance/test', data=data, **headers) if method == 'GET' else
                   self.factory.generic(method, '/maintenance/test', json.dumps(data), content_type='application/json', **headers))
        return getattr(views, name)(request, **kwargs)

    def draft(self, **extra):
        return {'business_id': self.company.pk, 'device_id': self.device.pk,
                'maintenance_type_id': str(self.kind.pk), 'scheduled_date': self.future,
                'work_description': 'Check scale calibration', **extra}

    def create(self, **extra):
        response = self.call('create_maintenance_record', self.draft(**extra))
        self.assertEqual(response.status_code, 201, response.content)
        return DeviceMaintenance.objects.get(pk=json.loads(response.content)['maintenance']['id'])

    def test_anonymous_and_invalid_token_cannot_read_or_write(self):
        for name in ('list_maintenance_records', 'create_maintenance_record', 'get_maintenance_dashboard', 'get_maintenance_schedules'):
            self.assertEqual(self.call(name, self.draft(), token=False).status_code, 403)
        self.token = 'not-a-token'
        self.assertEqual(self.call('list_maintenance_records', self.draft()).status_code, 401)
        self.assertEqual(DeviceMaintenance.objects.count(), 0)

    def test_company_scope_covers_lists_records_children_and_schedules(self):
        foreign = DeviceMaintenance.objects.create(device=self.other_device, maintenance_type=self.kind, scheduled_date=parse_datetime(self.future), work_description='Other work')
        checklist = MaintenanceChecklist.objects.create(maintenance=foreign, item_description='Foreign checklist')
        observation = MaintenanceObservation.objects.create(maintenance=foreign, text='Private note')
        schedule = MaintenanceSchedule.objects.create(device=self.other_device, maintenance_type=self.kind, frequency='daily', start_date=timezone.now().date(), next_due=timezone.now().date())
        cases = [
            ('list_maintenance_records', {'business_id': self.other.pk}, 'POST', {}),
            ('get_maintenance_record', {}, 'GET', {'maintenance_id': foreign.pk}),
            ('update_checklist_item', {'is_completed': True}, 'POST', {'item_id': checklist.pk}),
            ('delete_maintenance_observation', {}, 'DELETE', {'observation_id': observation.pk}),
            ('update_maintenance_schedule', {'is_active': False}, 'POST', {'schedule_id': schedule.pk}),
        ]
        for name, data, method, kwargs in cases:
            with self.subTest(name=name):
                self.assertEqual(self.call(name, data, method, **kwargs).status_code, 403)
        self.assertEqual(self.call('create_maintenance_record', self.draft(device_id=self.other_device.pk)).status_code, 403)

    def test_secondary_company_member_can_read_and_be_assigned(self):
        self.profile.secondary_businesses.add(self.other)
        self.assertEqual(self.call('list_maintenance_records', {'business_id': self.other.pk}).status_code, 200)
        record = self.call('create_maintenance_record', self.draft(business_id=self.other.pk, device_id=self.other_device.pk, assigned_to_id=self.profile.pk))
        self.assertEqual(record.status_code, 201, record.content)

    def test_foreign_and_inactive_assignees_are_rejected(self):
        self.assertEqual(self.call('create_maintenance_record', self.draft(assigned_to_id=self.outside_profile.pk)).status_code, 403)
        self.teammate_profile.is_active = False
        self.teammate_profile.save()
        self.assertEqual(self.call('create_maintenance_record', self.draft(assigned_to_id=self.teammate_profile.pk)).status_code, 403)

    def test_complete_requires_start_and_every_critical_checklist_item(self):
        record = self.create(checklist_items=[{'description': 'Verify calibration', 'is_critical': True}])
        self.assertEqual(self.call('update_maintenance_status', {'action': 'complete'}, maintenance_id=record.pk).status_code, 409)
        start = self.call('update_maintenance_status', {'action': 'start', 'user_id': self.outside_profile.pk}, maintenance_id=record.pk)
        self.assertEqual(start.status_code, 200, start.content)
        record.refresh_from_db()
        self.assertEqual(record.performed_by_id, self.profile.pk)
        self.assertEqual(self.call('update_maintenance_status', {'action': 'complete'}, maintenance_id=record.pk).status_code, 409)
        item = record.checklist_items.get()
        check = self.call('update_checklist_item', {'mark_completed': True, 'user_id': self.outside_profile.pk}, item_id=item.pk)
        self.assertEqual(check.status_code, 200, check.content)
        item.refresh_from_db()
        self.assertEqual(item.completed_by_id, self.profile.pk)
        self.assertEqual(self.call('update_maintenance_status', {'action': 'complete', 'outcome': 'successful'}, maintenance_id=record.pk).status_code, 200)
        record.refresh_from_db()
        self.assertEqual(record.status, 'completed')
        for action in ('start', 'cancel', 'complete', 'reschedule'):
            self.assertEqual(self.call('update_maintenance_status', {'action': action, 'new_date': self.future}, maintenance_id=record.pk).status_code, 409)

    def test_completion_cannot_bypass_workflow_through_create_update_or_actual_dates(self):
        self.assertEqual(self.call('create_maintenance_record', self.draft(status='completed')).status_code, 400)
        record = self.create()
        for payload in ({'status': 'completed'}, {'actual_end_date': self.future}, {'actual_start_date': self.future}, {'performed_by_id': self.teammate_profile.pk}):
            self.assertEqual(self.call('update_maintenance_record', payload, maintenance_id=record.pk).status_code, 400)
        record.refresh_from_db()
        self.assertEqual(record.status, 'scheduled')

    def test_creator_and_observation_actor_are_server_attributed(self):
        record = self.create(user_id=self.outside_profile.pk, created_by_id=self.outside_profile.pk)
        self.assertEqual(record.created_by_id, self.profile.pk)
        response = self.call('maintenance_observations', {'text': 'Measured correctly', 'user_id': self.outside_profile.pk}, maintenance_id=record.pk)
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(record.observations.get().created_by_id, self.profile.pk)

    def test_superuser_without_profile_can_create_with_null_attribution(self):
        admin = get_user_model().objects.create_superuser(username='admin', password='test')
        self.token = Token.objects.create(user=admin).key
        self.assertIsNone(self.create().created_by_id)

    def test_invalid_inputs_return_400_without_partial_records(self):
        cases = [dict(estimated_cost=-1), dict(actual_cost='NaN'), dict(estimated_duration_hours=True),
                 dict(scheduled_date='bad-date'), dict(scheduled_date=''), dict(work_description=[]),
                 dict(checklist_items=[{}]), dict(checklist_items='wrong'), dict(checklist_items=[{'description': 'x', 'is_critical': 'false'}])]
        for values in cases:
            with self.subTest(values=values):
                self.assertEqual(self.call('create_maintenance_record', self.draft(**values)).status_code, 400)
        self.assertEqual(DeviceMaintenance.objects.count(), 0)

    def test_inner_caught_500_rolls_back_created_record(self):
        with patch.object(views, 'serialize_maintenance_record', side_effect=RuntimeError('test serialization failure')):
            self.assertEqual(self.call('create_maintenance_record', self.draft()).status_code, 500)
        self.assertEqual(DeviceMaintenance.objects.count(), 0)

    def test_filters_dates_and_pagination_validate_before_querying(self):
        for data in ({'filters': []}, {'order_by': 4}, {'per_page': 1000}, {'page': 0}, {'filters': {'date_from': 'garbage'}}):
            self.assertEqual(self.call('list_maintenance_records', {'business_id': self.company.pk, **data}).status_code, 400)

    def test_schedules_validate_create_and_merged_updates(self):
        draft = dict(business_id=self.company.pk, device_id=self.device.pk, maintenance_type_id=str(self.kind.pk), start_date='2026-10-03', frequency='custom', custom_frequency_days=7)
        for invalid in ({'custom_frequency_days': 0}, {'custom_frequency_days': True}, {'end_date': '2026-01-01'}, {'auto_assign_to_id': self.outside_profile.pk}):
            self.assertIn(self.call('create_maintenance_schedule', {**draft, **invalid}).status_code, (400, 403))
        response = self.call('create_maintenance_schedule', draft)
        self.assertEqual(response.status_code, 201, response.content)
        schedule = MaintenanceSchedule.objects.get()
        self.assertEqual(self.call('update_maintenance_schedule', {'custom_frequency_days': 0}, schedule_id=schedule.pk).status_code, 400)
        self.assertEqual(self.call('update_maintenance_schedule', {'is_active': False}, schedule_id=schedule.pk).status_code, 200)

    def test_generate_repeated_request_creates_one_due_record(self):
        MaintenanceSchedule.objects.create(device=self.device, maintenance_type=self.kind, frequency='daily', start_date=timezone.now().date(), next_due=timezone.now().date())
        for _ in range(2):
            response = self.call('generate_scheduled_maintenance', {'business_id': self.company.pk})
            self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(DeviceMaintenance.objects.count(), 1)

    def test_expired_schedule_never_generates_past_end_date(self):
        today = timezone.now().date()
        MaintenanceSchedule.objects.create(device=self.device, maintenance_type=self.kind, frequency='daily', start_date=today - timedelta(days=5), end_date=today - timedelta(days=1), next_due=today)
        response = self.call('generate_scheduled_maintenance', {'business_id': self.company.pk})
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(DeviceMaintenance.objects.count(), 0)

    def test_record_request_uuid_replays_without_duplicate_and_rejects_changed_payload(self):
        draft = self.draft(client_request_id=str(uuid.uuid4()), estimated_cost=1, estimated_duration_hours=1,
                           checklist_items=[{'description': 'Check calibration', 'is_critical': True}])
        first = self.call('create_maintenance_record', draft)
        replay = self.call('create_maintenance_record', draft)
        self.assertEqual(first.status_code, 201, first.content)
        self.assertEqual(replay.status_code, 201, replay.content)
        self.assertEqual(DeviceMaintenance.objects.count(), 1)
        self.assertEqual(MaintenanceChecklist.objects.count(), 1)
        self.assertEqual(json.loads(first.content)['maintenance']['id'], json.loads(replay.content)['maintenance']['id'])
        self.assertEqual(self.call('create_maintenance_record', {**draft, 'work_description': 'Different'}).status_code, 409)
        self.assertEqual(self.call('create_maintenance_record', {**draft, 'checklist_items': []}).status_code, 409)

    def test_schedule_request_uuid_replays_without_duplicate(self):
        draft = dict(business_id=self.company.pk, device_id=self.device.pk, maintenance_type_id=str(self.kind.pk),
                     start_date='2026-10-03', frequency='weekly', client_request_id=str(uuid.uuid4()))
        self.assertEqual(self.call('create_maintenance_schedule', draft).status_code, 201)
        replay = self.call('create_maintenance_schedule', draft)
        self.assertEqual(replay.status_code, 201, replay.content)
        self.assertEqual(MaintenanceSchedule.objects.count(), 1)

    def test_duplicate_schedule_and_unknown_type_have_clear_client_errors(self):
        draft = dict(business_id=self.company.pk, device_id=self.device.pk, maintenance_type_id=str(self.kind.pk), start_date='2026-10-03', frequency='weekly')
        self.assertEqual(self.call('create_maintenance_schedule', draft).status_code, 201)
        self.assertEqual(self.call('create_maintenance_schedule', draft).status_code, 409)
        self.assertEqual(self.call('create_maintenance_record', self.draft(maintenance_type_id=str(uuid.uuid4()))).status_code, 404)

    def test_inactive_profile_and_inactive_login_cannot_access_maintenance(self):
        self.profile.is_active = False
        self.profile.save()
        self.assertEqual(self.call('list_maintenance_records', {'business_id': self.company.pk}).status_code, 403)
        self.profile.is_active = True
        self.profile.save()
        self.actor.is_active = False
        self.actor.save()
        self.assertEqual(self.call('list_maintenance_records', {'business_id': self.company.pk}).status_code, 401)

    def test_idempotency_compares_dates_as_instants_not_timezone_text(self):
        draft = self.draft(client_request_id=str(uuid.uuid4()), scheduled_date='2030-01-01T10:00:00+02:00')
        self.assertEqual(self.call('create_maintenance_record', draft).status_code, 201)
        self.assertEqual(self.call('create_maintenance_record', draft).status_code, 201)
        self.assertEqual(DeviceMaintenance.objects.count(), 1)

    def test_report_get_requires_account_and_explicit_accessible_business(self):
        @maintenance_access
        def report(request):
            return JsonResponse({'report': 'authorized'})
        for query, auth, status in [({'business_id': self.company.pk}, False, 403), ({'business_id': self.other.pk}, True, 403), ({}, True, 400), ({'business_id': self.company.pk}, True, 200)]:
            request = self.factory.get('/api/maintenance/report/', query, **({'HTTP_AUTHORIZATION': 'Token ' + self.token} if auth else {}))
            self.assertEqual(report(request).status_code, status)

    def test_actual_analytics_api_class_is_guarded_before_sql(self):
        from services.mqtt_data_service import MaintenanceReportView
        endpoint = MaintenanceReportView.as_view()
        for query, auth, status in [({'business_id': self.company.pk}, False, 403), ({'business_id': self.other.pk}, True, 403),
                                    ({'business_id': self.company.pk, 'start_date': 'bad'}, True, 400),
                                    ({'business_id': self.company.pk, 'start_date': '2026-10-10', 'end_date': '2026-10-01'}, True, 400)]:
            with patch.object(MaintenanceReportView, 'get') as get:
                request = self.factory.get('/api/maintenance/report/', query, **({'HTTP_AUTHORIZATION': 'Token ' + self.token} if auth else {}))
                self.assertEqual(endpoint(request).status_code, status)
                get.assert_not_called()
        original = MaintenanceReportView.get
        executions = []
        def read_report(view, request):
            with patch('django.db.connection.cursor') as connection:
                cursor = connection.return_value.__enter__.return_value
                cursor.description = [('total',)]
                cursor.fetchone.return_value = (0,)
                cursor.fetchall.return_value = []
                response = original(view, request)
                executions.extend(cursor.execute.call_args_list)
                return response
        with patch.object(MaintenanceReportView, 'get', read_report):
            request = self.factory.get('/api/maintenance/report/', {'business_id': self.company.pk}, HTTP_AUTHORIZATION='Token ' + self.token)
            response = endpoint(request)
            self.assertEqual(response.status_code, 200)
        self.assertEqual(len(executions), 10)
        self.assertTrue(all(str(call.args[1][0]) == str(self.company.pk) for call in executions))
