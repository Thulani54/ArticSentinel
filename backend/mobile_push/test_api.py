"""Run with Django initialized; all writes and outbound requests are mocked."""
import unittest
from types import SimpleNamespace
from unittest.mock import patch
from rest_framework.test import APIRequestFactory, force_authenticate
from . import views

class RegistrationTests(unittest.TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.user = SimpleNamespace(is_authenticated=True, is_active=True, pk=71)
        self.company = SimpleNamespace(pk=9)

    def request(self, data, authenticate=True):
        request = self.factory.post('/api/push/register/', data, format='json')
        if authenticate:
            force_authenticate(request, user=self.user)
        return request

    def test_invalid_business_is_bad_request(self):
        self.assertEqual(views.register(self.request({'business_id':'invalid'})).status_code,400)

    def test_anonymous_cannot_register(self):
        response = views.register(self.request({}, authenticate=False))
        self.assertIn(response.status_code, (401, 403))

    @patch.object(views.PushInstallation.objects, 'update_or_create')
    @patch.object(views, '_user_can_access', return_value=False)
    @patch.object(views, 'get_object_or_404')
    def test_other_business_rejected_without_write(self, lookup, access, write):
        lookup.return_value = self.company
        response = views.register(self.request({'business_id':9,'token':'x'*40,'platform':'android'}))
        self.assertEqual(response.status_code,403)
        write.assert_not_called()

    @patch.object(views, 'configured', return_value=True)
    @patch.object(views.PushInstallation.objects, 'update_or_create')
    @patch.object(views, '_user_can_access', return_value=True)
    @patch.object(views, 'get_object_or_404')
    def test_registration_binds_authenticated_user(self, lookup, access, write, configured):
        lookup.return_value = self.company
        response = views.register(self.request({'business_id':9,'token':'x'*40,'platform':'android','user_id':999}))
        self.assertEqual(response.status_code,200)
        self.assertEqual(write.call_args.kwargs['defaults']['user'],self.user)
        self.assertEqual(response.data['thresholds'],[50,30,10])

    @patch.object(views.PushInstallation.objects, 'filter')
    def test_unregister_only_changes_callers_token(self, query):
        response = views.unregister(self.request({'token':'x'*40}))
        self.assertEqual(response.status_code,200)
        query.assert_called_once_with(user=self.user,token='x'*40)

class PersonalRuleAccessTests(unittest.TestCase):
    def setUp(self):
        self.factory=APIRequestFactory()
        self.user=SimpleNamespace(is_authenticated=True,is_active=True,pk=71)
        self.device=SimpleNamespace(pk=8,device_type='gas_cylinder',company=SimpleNamespace(pk=9))
    def request(self,method='get',data=None):
        request=getattr(self.factory,method)('/api/push/devices/8/rules/',data or {},format='json')
        force_authenticate(request,user=self.user)
        return request
    @patch.object(views.DeviceAlertSettings.objects,'filter')
    @patch.object(views,'_user_can_access',return_value=True)
    @patch.object(views,'get_object_or_404')
    def test_get_only_reads_current_users_preferences(self,lookup,access,query):
        lookup.return_value=self.device;query.return_value.first.return_value=None
        result=views.device_rules(self.request(),8)
        query.assert_called_once_with(user=self.user,device=self.device)
        self.assertEqual(result.data['rules'][0]['thresholds'],[50,30,10])
    @patch.object(views.DeviceAlertSettings.objects,'filter')
    @patch.object(views,'_user_can_access',return_value=False)
    @patch.object(views,'get_object_or_404')
    def test_cross_business_rules_are_not_read(self,lookup,access,query):
        lookup.return_value=self.device
        self.assertEqual(views.device_rules(self.request(),8).status_code,403)
        query.assert_not_called()
    @patch.object(views.DeviceAlertSettings.objects,'get_or_create')
    @patch.object(views,'_user_can_access',return_value=True)
    @patch.object(views,'get_object_or_404')
    def test_invalid_write_does_not_replace_current_rules(self,lookup,access,write):
        lookup.return_value=self.device
        result=views.device_rules(self.request('put',{'revision':0,'rules':[{'metric':'gas_level','comparison':'lte','thresholds':[110]}]}),8)
        self.assertEqual(result.status_code,400);write.assert_not_called()
