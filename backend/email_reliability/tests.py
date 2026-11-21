from datetime import timedelta
from unittest.mock import patch
import smtplib,ssl
from django.contrib.auth import get_user_model
from django.test import TestCase,SimpleTestCase,override_settings
from django.utils import timezone
from company.models import Company
from device.models import Device
from user.models import User
from communication.models import CommunicationLog,Template
from scale_connections.models import ConnectionState,ConnectionDelivery
from scale_connections.tasks import observe,deliver_pending
from exvr.email_backend import VerifiedSMTP,send_html_email,VerifiedEmailBackend

class ConnectionTests(TestCase):
 def setUp(self):
  self.now=timezone.now();self.company=Company.objects.create(name='One');self.other=Company.objects.create(name='Two')
  self.device=Device.objects.create(company=self.company,name='Scale',device_id='scale-1')
  self.login=get_user_model().objects.create(username='owner',email='owner@example.invalid')
  self.profile=User.objects.create(user=self.login,business=self.company)
 def offline(self):
  observe(self.device,self.now-timedelta(minutes=11),self.now)
 def online(self):
  observe(self.device,self.now,self.now+timedelta(seconds=1))
 def test_baseline_does_not_send_or_queue(self):
  self.offline();self.assertEqual(ConnectionDelivery.objects.count(),0)
 def test_recovery_survives_mqtt_online_flag(self):
  self.offline();self.device.is_online=True;self.device.save();self.online()
  d=ConnectionDelivery.objects.get();self.assertTrue(d.online);self.assertEqual(d.recipient,self.login.email)
 def test_repeated_online_observations_are_idempotent(self):
  self.offline();self.online();self.online();self.assertEqual(ConnectionDelivery.objects.count(),1)
 def test_offline_uses_configured_timeout(self):
  observe(self.device,self.now,self.now)
  observe(self.device,self.now,self.now+timedelta(minutes=9));self.assertEqual(ConnectionDelivery.objects.count(),0)
  observe(self.device,self.now,self.now+timedelta(minutes=11));self.assertFalse(ConnectionDelivery.objects.get().online)
 def test_initial_online_is_silent(self):
  self.online();self.assertFalse(ConnectionDelivery.objects.exists())
 def test_secondary_business_receives_but_unrelated_does_not(self):
  secondary=get_user_model().objects.create(username='secondary',email='secondary@example.invalid')
  p=User.objects.create(user=secondary,business=self.other);p.secondary_businesses.add(self.company)
  outsider=get_user_model().objects.create(username='outsider',email='outsider@example.invalid')
  User.objects.create(user=outsider,business=self.other)
  self.offline();self.online();self.assertEqual(set(ConnectionDelivery.objects.values_list('recipient',flat=True)),{self.login.email,secondary.email})
 def test_opted_out_inactive_and_duplicate_email(self):
  for name,enabled,active in [('off',False,True),('inactive',True,False),('duplicate',True,True)]:
   u=get_user_model().objects.create(username=name,email=self.login.email if name=='duplicate' else name+'@example.invalid',is_active=active)
   User.objects.create(user=u,business=self.company,email_notifications=enabled)
  self.offline();self.online();self.assertEqual(ConnectionDelivery.objects.count(),1)
 def test_older_concurrent_observation_cannot_regress(self):
  self.offline();self.online();observe(self.device,self.now-timedelta(minutes=12),self.now+timedelta(seconds=2))
  self.assertTrue(ConnectionState.objects.get().online);self.assertEqual(ConnectionDelivery.objects.count(),1)
 def queue(self):
  self.offline();self.online();d=ConnectionDelivery.objects.get();d.next_attempt_at=timezone.now()-timedelta(seconds=1);d.save();return d
 @patch('alerts.tasks.send_communication_with_template',return_value=True)
 def test_acceptance_recorded_once(self,send):
  d=self.queue()
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now):deliver_pending();deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'sent');self.assertEqual(send.call_count,1);self.assertEqual(send.call_args.kwargs['template_type'],'device_online')
 @patch('alerts.tasks.send_communication_with_template',return_value=False)
 def test_failed_send_retries_with_backoff(self,send):
  d=self.queue()
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now):deliver_pending();deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'pending');self.assertEqual(d.attempts,1);self.assertEqual(send.call_count,1)
 @patch('alerts.tasks.send_communication_with_template',return_value=False)
 def test_five_failures_stop_retrying(self,send):
  d=self.queue();d.attempts=4;d.save()
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now):deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'failed')
 @patch('alerts.tasks.send_communication_with_template')
 def test_revoked_membership_does_not_receive(self,send):
  d=self.queue();self.profile.business=self.other;self.profile.save();deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'superseded');send.assert_not_called()
 @patch('alerts.tasks.send_communication_with_template')
 def test_stale_telemetry_cancels_recovery_email(self,send):
  d=self.queue()
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now-timedelta(minutes=30)):deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'superseded');send.assert_not_called()
 @patch('alerts.tasks.send_communication_with_template',return_value=True)
 def test_failed_communication_log_does_not_apply_cooldown(self,send):
  self.queue();t=Template.objects.create(template_type='device_online')
  CommunicationLog.objects.create(device=self.device,recipient=self.login.email,template_used=t,status='failed',sent_at=timezone.now())
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now):deliver_pending()
  send.assert_called_once()
 @patch('alerts.tasks.send_communication_with_template')
 def test_successful_log_applies_cooldown(self,send):
  d=self.queue();t=Template.objects.create(template_type='device_online')
  CommunicationLog.objects.create(device=self.device,recipient=self.login.email,template_used=t,status='sent',sent_at=timezone.now())
  with patch('scale_connections.tasks.latest_reading_time',return_value=self.now):deliver_pending()
  d.refresh_from_db();self.assertEqual(d.status,'cooldown');send.assert_not_called()

class TransportTests(SimpleTestCase):
 @override_settings(EMAIL_TLS_SERVER_NAME='provider.example.invalid')
 def test_tls_checks_hosting_identity_and_restores_endpoint(self):
  smtp=VerifiedSMTP();smtp._host='mail.example.invalid'
  seen={}
  def start(obj,*,context=None):
   seen.update(host=obj._host,verify=context.verify_mode,hostname=context.check_hostname)
   return (220,b'ready')
  with patch.object(smtplib.SMTP,'starttls',start):smtp.starttls()
  self.assertEqual(seen,{'host':'provider.example.invalid','verify':ssl.CERT_REQUIRED,'hostname':True})
  self.assertEqual(smtp._host,'mail.example.invalid')
 @override_settings(EMAIL_TLS_SERVER_NAME='provider.example.invalid')
 def test_invalid_certificate_is_not_bypassed(self):
  smtp=VerifiedSMTP();smtp._host='mail.example.invalid'
  with patch.object(smtplib.SMTP,'starttls',side_effect=ssl.SSLCertVerificationError('invalid')):
   with self.assertRaises(ssl.SSLCertVerificationError):smtp.starttls()
  self.assertEqual(smtp._host,'mail.example.invalid')
 def test_html_message_uses_configured_backend(self):
  from django.core import mail
  self.assertTrue(send_html_email('test@example.invalid','Subject','<p>Body</p>'))
  self.assertEqual(len(mail.outbox),1);self.assertEqual(mail.outbox[0].body,'Body')

class ReportTransportTests(SimpleTestCase):
 def test_report_keeps_pdf_and_uses_configured_backend(self):
  from alerts.tasks import send_enhanced_analytics_pdf_email
  from django.core import mail
  with patch('smtplib.SMTP',side_effect=AssertionError('No direct SMTP fallback')):
   self.assertTrue(send_enhanced_analytics_pdf_email(b'%PDF-test',['report@example.invalid']))
  message=mail.outbox[-1]
  self.assertEqual(message.to,['report@example.invalid'])
  self.assertEqual(message.attachments[0][1],b'%PDF-test')
  self.assertEqual(message.attachments[0][2],'application/pdf')
 def test_maintenance_keeps_headers_and_uses_configured_backend(self):
  from maintenance_mail import _send_email_direct
  from django.core import mail
  with patch('smtplib.SMTP',side_effect=AssertionError('No direct SMTP fallback')):
   self.assertTrue(_send_email_direct('Reminder','Plain','<p>HTML</p>',['member@example.invalid'],maintenance_id='123',device_id=7,reminder_type='upcoming'))
  message=mail.outbox[-1]
  self.assertEqual(message.extra_headers['X-Device-ID'],'7')
  self.assertEqual(message.extra_headers['X-Maintenance-ID'],'123')
