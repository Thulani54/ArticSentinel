from datetime import timedelta
from uuid import uuid4
from unittest.mock import patch
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from company.models import Company, Profile
from device.models import Device
from alerts.models import Alert
from .models import CylinderRefill, AlertTeamState, AlertTeamEvent

class JournalTests(TestCase):
    def setUp(self):
        self.company = Company.objects.create(name='One')
        self.other = Company.objects.create(name='Two')
        self.user = get_user_model().objects.create_user(username='owner')
        self.member = get_user_model().objects.create_user(username='member')
        self.stranger = get_user_model().objects.create_user(username='stranger')
        Profile.objects.create(user=self.user, business=self.company)
        Profile.objects.create(user=self.member, business=self.other).secondary_businesses.add(self.company)
        Profile.objects.create(user=self.stranger, business=self.other)
        self.device = Device.objects.create(company=self.company, device_id='GAS-1', device_type='gas_cylinder')
        self.bottle = Device.objects.create(company=self.company, device_id='BOT-1', device_type='device7')
        self.alert = Alert.objects.create(company=self.company, device=self.device)
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.refill_url = f'/devices/{self.device.pk}/refills/'
        self.team_url = f'/alerts/{self.alert.pk}/team/'
        self.scan_url = f'/devices/{self.bottle.pk}/scans/'
        self.body = {'request_id': str(uuid4()), 'purchased_on': timezone.localdate().isoformat(), 'gas_kg': '9.00', 'cost': '300.00', 'supplier': 'Local gas', 'notes': 'Receipt 42'}

    def test_refill_roundtrip_totals_and_duplicate_retry(self):
        self.assertEqual(self.client.post(self.refill_url, self.body, format='json').status_code, 201)
        self.assertEqual(self.client.post(self.refill_url, self.body, format='json').status_code, 200)
        self.assertEqual(CylinderRefill.objects.count(), 1)
        response = self.client.get(self.refill_url).data
        self.assertEqual(response['count'], 1)
        self.assertEqual(response['refills'][0]['supplier'], 'Local gas')
        self.assertEqual(float(response['total_cost']), 300)
        self.assertEqual(CylinderRefill.objects.get().created_by, self.user)

    def test_cylinder_change_can_record_no_purchase_and_configuration_snapshot(self):
        body = {**self.body, 'kind': 'cylinder_change', 'gas_kg': '0', 'cost': '0', 'capacity_kg': '19', 'tare_kg': '17.20'}
        response = self.client.post(self.refill_url, body, format='json')
        self.assertEqual(response.status_code, 201)
        row = response.data['refill']
        self.assertEqual(row['kind'], 'cylinder_change')
        self.assertEqual(float(row['capacity_kg']), 19)
        self.assertEqual(float(row['tare_kg']), 17.2)
        self.assertEqual(float(row['gas_kg']), 0)

    def test_invalid_cylinder_snapshot_and_zero_refill_purchase_rejected(self):
        for data in [{'kind': 'other'}, {'capacity_kg': '-2'}, {'tare_kg': 'NaN'}, {'gas_kg': '0'}]:
            self.assertEqual(self.client.post(self.refill_url, {**self.body, **data}, format='json').status_code, 400)

    def test_refill_month_rejects_invalid_and_future_values(self):
        for month in ['invalid', '9999-12', '1999-01']:
            self.assertEqual(self.client.get(self.refill_url, {'month': month}).status_code, 400)

    def test_duplicate_request_with_different_contents_conflicts(self):
        self.client.post(self.refill_url, self.body, format='json')
        changed = {**self.body, 'cost': '999.00'}
        self.assertEqual(self.client.post(self.refill_url, changed, format='json').status_code, 409)

    def test_refill_rejects_invalid_dates_and_amounts(self):
        for field, value in [('gas_kg', 'NaN'), ('cost', '-1'), ('gas_kg', '201'), ('gas_kg', '.001'), ('gas_kg', True), ('purchased_on', (timezone.localdate() + timedelta(days=1)).isoformat()), ('supplier', 'x' * 161)]:
            with self.subTest(field=field, value=value):
                self.assertEqual(self.client.post(self.refill_url, {**self.body, field: value}, format='json').status_code, 400)
        self.assertEqual(CylinderRefill.objects.count(), 0)

    def test_history_business_and_type_guard(self):
        self.client.force_authenticate(self.stranger)
        for url in [self.refill_url, self.team_url, self.scan_url]:
            self.assertEqual(self.client.get(url).status_code, 403)
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.get(f'/devices/{self.bottle.pk}/refills/').status_code, 400)
        self.assertEqual(self.client.get(f'/devices/{self.device.pk}/scans/').status_code, 400)

    def test_authentication_required_for_every_endpoint(self):
        self.client = APIClient()
        for url in [self.refill_url, self.team_url, self.scan_url]:
            self.assertIn(self.client.get(url).status_code, (401, 403))

    def test_secondary_member_access(self):
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.get(self.refill_url).status_code, 200)
        self.assertEqual(self.client.get(self.team_url).status_code, 200)

    def test_team_assign_note_resolve_history(self):
        response = self.client.patch(self.team_url, {'revision': 0, 'action': 'assign', 'assigned_to': self.member.pk}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['assigned_to'], self.member.pk)
        self.client.force_authenticate(self.member)
        response = self.client.patch(self.team_url, {'revision': 1, 'action': 'note', 'note': 'Checking the cylinder now'}, format='json')
        self.assertEqual(response.status_code, 200)
        response = self.client.patch(self.team_url, {'revision': 2, 'action': 'resolve', 'note': 'Replaced cylinder and checked the scale'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.alert.refresh_from_db()
        self.assertEqual(self.alert.status, 'resolved')
        self.assertIsNotNone(self.alert.resolved_at)
        self.assertEqual(response.data['events'][0]['actor'], 'member')
        self.assertEqual(len(response.data['events']), 3)

    def test_team_revision_conflict_does_not_overwrite(self):
        self.client.patch(self.team_url, {'revision': 0, 'action': 'assign', 'assigned_to': self.member.pk}, format='json')
        response = self.client.patch(self.team_url, {'revision': 0, 'action': 'assign', 'assigned_to': None}, format='json')
        self.assertEqual(response.status_code, 409)
        self.assertEqual(AlertTeamState.objects.get().assigned_to, self.member)
        self.assertEqual(AlertTeamEvent.objects.count(), 1)

    def test_team_rejects_cross_business_and_inactive_assignee(self):
        for who in [self.stranger, self.member]:
            if who == self.member:
                who.is_active = False; who.save()
            self.assertEqual(self.client.patch(self.team_url, {'revision': 0, 'action': 'assign', 'assigned_to': who.pk}, format='json').status_code, 400)

    def test_inactive_business_profile_cannot_be_assigned_or_access_journal(self):
        profile = self.member.profile
        profile.is_active = False; profile.save()
        data = self.client.get(self.team_url).data
        self.assertNotIn(self.member.pk, [member['id'] for member in data['members']])
        self.assertEqual(self.client.patch(self.team_url, {'revision': 0, 'action': 'assign', 'assigned_to': self.member.pk}, format='json').status_code, 400)
        self.member.refresh_from_db()
        self.client.force_authenticate(self.member)
        self.assertEqual(self.client.get(self.refill_url).status_code, 403)
        self.assertEqual(self.client.get(self.team_url).status_code, 403)

    def test_resolution_requires_note(self):
        self.assertEqual(self.client.patch(self.team_url, {'revision': 0, 'action': 'resolve', 'note': ''}, format='json').status_code, 400)
        self.alert.refresh_from_db()
        self.assertEqual(self.alert.status, 'active')

    def test_alert_company_mismatch_denied(self):
        self.alert.company = self.other; self.alert.save()
        self.assertEqual(self.client.get(self.team_url).status_code, 403)

    @patch('device_journal.views.scan_rows')
    def test_scan_filters_pagination_and_no_credentials(self, source):
        source.return_value = [{'code': 'Bottle 1', 'verified': False}] * 51
        response = self.client.get(self.scan_url, {'result': 'failed', 'q': 'Bottle 1', 'offset': '50'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['scans']), 50)
        self.assertEqual(response.data['next_offset'], 100)
        self.assertEqual(source.call_args.args[3:], ('Bottle 1', 'failed', 50))

    @patch('device_journal.views.scan_rows')
    def test_invalid_scan_filters_never_query_timeseries(self, source):
        for params in [{'result': 'unknown'}, {'from': '2000-01-01'}, {'offset': '-1'}, {'q': 'x' * 513}]:
            self.assertEqual(self.client.get(self.scan_url, params).status_code, 400)
        source.assert_not_called()

    @patch('device_journal.views.scan_rows', side_effect=RuntimeError('private database details'))
    def test_scan_connection_failure_is_clear_and_safe(self, source):
        response = self.client.get(self.scan_url)
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('private', str(response.data))


class ScanQueryTests(TestCase):
    @patch('device_journal.telemetry.connections')
    def test_search_is_bound_and_credentials_never_selected(self, connections):
        from types import SimpleNamespace
        from device_journal.telemetry import scan_rows
        cursor = connections.__getitem__.return_value.cursor.return_value.__enter__.return_value
        cursor.fetchall.return_value = [(timezone.now(), 'BOTTLE-42', True, 'in', 'Supplier', 5, 1, 2, 3, 4)]
        needle = "%' OR 1=1 --"
        rows = scan_rows(SimpleNamespace(device_id='D7-1'), timezone.now(), timezone.now(), needle, 'verified', 0)
        query, params = cursor.execute.call_args.args
        self.assertNotIn(needle, query)
        self.assertIn(needle, params)
        self.assertNotIn('auth_key', query)
        self.assertEqual(rows[0]['tray_kg'], [1, 2, 3, 4])
        self.assertNotIn('auth_key', rows[0])
