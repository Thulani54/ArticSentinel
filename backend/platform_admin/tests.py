from datetime import timedelta
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from django.core.cache import cache
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from .models import PlatformAdministrator, AccessEvent
from .policy import mqtt_client_id,csv_cell
from .testapp.models import Company,Device,Report
class PlatformTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client=APIClient()
        self.admin=get_user_model().objects.create_user(username='operator',password='TemporaryPassword123!')
        self.role=PlatformAdministrator.objects.create(user=self.admin,must_change_password=False)
        self.member=get_user_model().objects.create_user(username='tenant',password='TenantPassword123!',is_staff=True,is_superuser=True)
        self.a=Company.objects.create(name='Alpha')
        self.b=Company.objects.create(name='Beta')
        Device.objects.create(company=self.a,name='Tank A',device_id='A',last_ping=timezone.now()-timedelta(minutes=5),offline_timeout=10)
        Device.objects.create(company=self.b,name='Tank B',device_id='B',last_ping=timezone.now()-timedelta(minutes=5),offline_timeout=2)
    def authorize(self,user=None):self.client.force_authenticate(user=user or self.admin)
    def test_no_tenant_or_staff_bypass(self):
        self.assertEqual(self.client.get('/records/devices/').status_code,401)
        self.authorize(self.member)
        for path in ['/access/','/overview/','/records/devices/','/records/reports/1/','/export/devices/']:
            self.assertEqual(self.client.get(path).status_code,403)
    def test_password_gate(self):
        self.role.must_change_password=True;self.role.save();self.authorize()
        self.assertTrue(self.client.get('/access/').data['must_change_password'])
        self.assertEqual(self.client.get('/records/devices/').status_code,403)
    def test_login_and_password_rotation(self):
        self.role.must_change_password=True;self.role.save()
        response=self.client.post('/login/',{'login':'operator','password':'TemporaryPassword123!'})
        self.assertEqual(response.status_code,200);old=response.data['token']
        self.client.credentials(HTTP_AUTHORIZATION='Token '+old)
        self.assertEqual(self.client.get('/records/companies/').status_code,403)
        self.assertEqual(self.client.post('/password/',{'current_password':'wrong','new_password':'NewSecurePassword123!'}).status_code,400)
        r=self.client.post('/password/',{'current_password':'TemporaryPassword123!','new_password':'NewSecurePassword123!'})
        self.assertEqual(r.status_code,200);self.assertNotEqual(old,r.data['token'])
        self.assertEqual(self.client.get('/records/companies/').status_code,401)
        self.client.credentials(HTTP_AUTHORIZATION='Token '+r.data['token'])
        self.assertEqual(self.client.get('/records/companies/').status_code,200)
    def test_tenant_login_rejected(self):
        r=self.client.post('/login/',{'login':'tenant','password':'TenantPassword123!'})
        self.assertEqual(r.status_code,401)
    def test_scoped_fleet_and_own_timeout(self):
        self.authorize()
        r=self.client.get('/records/devices/');self.assertEqual(r.status_code,200)
        self.assertEqual({x['device_id']:x['connection_status'] for x in r.data['results']},{'A':'online','B':'offline'})
        r=self.client.get('/records/devices/',{'company':self.b.pk})
        self.assertEqual(r.data['count'],1);self.assertEqual(r.data['results'][0]['device_id'],'B')
        self.assertNotIn('password',str(r.data));self.assertTrue(AccessEvent.objects.filter(action='view').exists())
    def test_inactive_and_never_reported(self):
        Device.objects.create(company=self.a,name='New',device_id='NEW')
        Device.objects.create(company=self.a,name='Inactive',device_id='OFF',is_active=False,last_ping=timezone.now())
        self.authorize();r=self.client.get('/records/devices/')
        statuses={x['device_id']:x['connection_status'] for x in r.data['results']}
        self.assertEqual(statuses['NEW'],'never_reported');self.assertEqual(statuses['OFF'],'inactive')
    def test_filters_and_pagination_validation(self):
        self.authorize()
        for params in [{'page':0},{'page_size':101},{'company':'bad'}]:
            self.assertEqual(self.client.get('/records/devices/',params).status_code,400)
        self.assertEqual(self.client.get('/records/devices/',{'q':'Tank A'}).data['count'],1)
        self.assertEqual(self.client.get('/records/reports/',{'from':'not-a-date'}).status_code,400)
        self.assertEqual(self.client.get('/records/reports/',{'from':'2026-11-15','to':'2026-11-01'}).status_code,400)
    def test_report_detail_and_export_is_authenticated(self):
        report=Report.objects.create(business_id=self.b.pk,report_id='R1',report_name='=HYPERLINK("bad")',report_data={'consumption_kg':3})
        self.authorize()
        r=self.client.get(f'/records/reports/{report.pk}/')
        self.assertEqual(r.data['company_name'],'Beta');self.assertEqual(r.data['report_data'],{'consumption_kg':3})
        r=self.client.get('/export/reports/',{'company':self.b.pk})
        self.assertEqual(r.status_code,200);self.assertIn("'=HYPERLINK",r.content.decode())
        self.assertTrue(AccessEvent.objects.filter(action='export').exists())
    def test_disable_revokes_existing_session(self):
        self.authorize();self.role.enabled=False;self.role.save()
        self.assertEqual(self.client.get('/records/companies/').status_code,403)
    def test_assigned_ids_stable_and_distinct(self):
        self.assertEqual(mqtt_client_id(3),mqtt_client_id(3))
        self.assertNotEqual(mqtt_client_id(3),mqtt_client_id(4))
        self.assertLessEqual(len(mqtt_client_id(3)),23)
        self.assertEqual(csv_cell('  =SUM(A1)'),"'  =SUM(A1)")

    def test_fleet_aggregation_clears_record_ordering(self):
        from django.db.models import Count
        from .views import filtered, connection_counts
        Device.objects.create(company=self.a,name='Tank C',device_id='C',last_ping=timezone.now())
        qs=filtered('devices',{})
        counts=connection_counts(qs)
        self.assertEqual(counts,{'online':2,'offline':1})
        self.assertEqual(sum(counts.values()),qs.count())

class InsightsTests(TestCase):
    setUp = PlatformTests.setUp
    authorize = PlatformTests.authorize
    def test_insights_are_scoped_and_events_use_south_african_dates(self):
        from .testapp.models import Alert,Maintenance,MaintenanceType
        from datetime import datetime
        from zoneinfo import ZoneInfo
        from unittest.mock import patch
        now=datetime(2026,11,15,10,tzinfo=ZoneInfo('UTC'))
        a=Device.objects.get(device_id='A');b=Device.objects.get(device_id='B')
        Alert.objects.create(company=self.a,device=a,triggered_at=datetime(2026,11,14,22,30,tzinfo=ZoneInfo('UTC')))
        Alert.objects.create(company=self.b,device=b,triggered_at=now,title='Other company')
        Alert.objects.create(company=self.a,device=a,triggered_at=now-timedelta(days=20),status='resolved',resolved_at=now)
        kind=MaintenanceType.objects.create(name='Inspection')
        Maintenance.objects.create(device=a,maintenance_type=kind,scheduled_date=now-timedelta(days=1))
        Maintenance.objects.create(device=b,maintenance_type=kind,scheduled_date=now-timedelta(days=1))
        Maintenance.objects.create(device=a,maintenance_type=kind,scheduled_date=now+timedelta(days=2))
        self.authorize()
        with patch('platform_admin.insights.timezone.now',return_value=now):
            r=self.client.get('/insights/',{'days':7,'company':self.a.pk})
        self.assertEqual(r.status_code,200)
        self.assertEqual(len(r.data['activity']),7)
        self.assertEqual(r.data['activity'][-1]['alerts'],1)
        self.assertEqual(r.data['activity'][-1]['resolved'],1)
        self.assertEqual(r.data['backlog']['overdue_maintenance'],1)
        self.assertEqual(r.data['backlog']['due_next_7_days'],1)
        self.assertEqual([x['id'] for x in r.data['companies']],[self.a.pk])
        self.assertTrue(all(x['company_id']==self.a.pk for x in r.data['attention']))
    def test_inactive_fleet_has_no_fake_coverage(self):
        Device.objects.filter(company=self.a).update(is_active=False)
        self.authorize()
        r=self.client.get('/insights/',{'company':self.a.pk})
        self.assertEqual(r.status_code,200)
        self.assertIsNone(r.data['companies'][0]['coverage_pct'])
        self.assertEqual(r.data['backlog']['devices_not_reporting'],0)
        self.assertEqual(r.data['totals']['alerts'],0)
    def test_insights_access_and_bad_range(self):
        self.assertEqual(self.client.get('/insights/').status_code,401)
        self.authorize(self.member)
        self.assertEqual(self.client.get('/insights/').status_code,403)
        self.authorize()
        self.assertEqual(self.client.get('/insights/',{'days':999}).status_code,400)
    def test_attention_filters_type_and_sort(self):
        self.authorize()
        r=self.client.get('/records/devices/',{'attention':'needs_attention','type':'gas_cylinder','sort':'oldest_reading'})
        self.assertEqual([x['device_id'] for x in r.data['results']],['B'])
        self.assertEqual(self.client.get('/records/devices/',{'sort':'password'}).status_code,400)
        self.assertEqual(self.client.get('/records/reports/',{'attention':'overdue'}).status_code,400)

    def test_critical_drilldown_excludes_closed_and_other_severities(self):
        from .testapp.models import Alert
        device=Device.objects.get(device_id='A')
        for severity,status in [('critical','active'),('critical','resolved'),('high','active')]:
            Alert.objects.create(company=self.a,device=device,severity=severity,status=status,triggered_at=timezone.now())
        self.authorize()
        response=self.client.get('/records/alerts/',{'attention':'unresolved','severity':'critical'})
        self.assertEqual(response.status_code,200)
        self.assertEqual(response.data['count'],1)
        self.assertEqual(response.data['results'][0]['severity'],'critical')
        self.role.must_change_password=True;self.role.save()
        self.assertEqual(self.client.get('/insights/').status_code,403)
