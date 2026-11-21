from unittest.mock import patch
from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from company.models import Company, Profile
from .models import PushInstallation

class DiagnosticsTests(TestCase):
    def setUp(self):
        self.company = Company.objects.create(name='Test company')
        self.other_company = Company.objects.create(name='Other company')
        self.user = get_user_model().objects.create_user('test-user')
        self.other = get_user_model().objects.create_user('other-user')
        Profile.objects.create(user=self.user, business=self.company)
        Profile.objects.create(user=self.other, business=self.other_company)
        self.installation = PushInstallation.objects.create(user=self.user, company=self.company, token='a'*40, platform='android')
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_unauthenticated_is_rejected(self):
        self.client = APIClient()
        self.assertIn(self.client.post('/test/', {'token':'a'*40}).status_code, [401,403])

    @patch('mobile_push.diagnostics._send')
    def test_other_users_installation_cannot_be_targeted(self, send):
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.post('/test/', {'token':'a'*40}).status_code,404)
        send.assert_not_called()

    @patch('mobile_push.diagnostics._send')
    def test_revoked_company_membership_cannot_send(self, send):
        Profile.objects.filter(user=self.user).update(business=self.other_company)
        self.client.force_authenticate(get_user_model().objects.get(pk=self.user.pk))
        self.assertEqual(self.client.post('/test/', {'token':'a'*40}).status_code,404)
        send.assert_not_called()

    @patch('mobile_push.diagnostics.configured', return_value=True)
    @patch('mobile_push.diagnostics._send', return_value='sent')
    def test_one_current_phone_test_and_rate_limit(self, send, configured):
        response = self.client.post('/test/', {'token':'a'*40})
        self.assertEqual(response.status_code,200)
        self.assertTrue(response.json()['accepted'])
        self.assertEqual(send.call_args.args[0],self.installation.token)
        self.assertEqual(send.call_args.kwargs['kind'],'notification_test')
        self.assertEqual(self.client.post('/test/', {'token':'a'*40}).status_code,429)
        self.assertEqual(send.call_count,1)

    @patch('mobile_push.diagnostics.configured', return_value=True)
    @patch('mobile_push.diagnostics._send', return_value='unregistered')
    def test_expired_token_is_disabled(self, send, configured):
        self.assertEqual(self.client.post('/test/', {'token':'a'*40}).status_code,410)
        self.installation.refresh_from_db()
        self.assertFalse(self.installation.enabled)

    @patch('mobile_push.diagnostics.configured', return_value=True)
    @patch('mobile_push.diagnostics._send', side_effect=RuntimeError('private provider response'))
    def test_failure_does_not_claim_delivery_or_expose_provider_detail(self, send, configured):
        response = self.client.post('/test/', {'token':'a'*40})
        self.assertEqual(response.status_code,502)
        self.assertNotIn('private',str(response.content))
        self.assertNotIn('accepted',response.json())

    @patch('mobile_push.diagnostics.configured', return_value=True)
    def test_diagnostics_does_not_return_registration_token(self, configured):
        response = self.client.post('/status/', {'token':'a'*40})
        self.assertEqual(response.status_code,200)
        self.assertTrue(response.json()['registered'])
        self.assertNotIn('a'*40,str(response.content))
        self.assertEqual(response.json()['pending_alerts'],0)
