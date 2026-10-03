import uuid
from datetime import timedelta
from unittest.mock import patch

from django.core import mail
from django.db import DatabaseError
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIRequestFactory

from .models import EnquiryDelivery, ProductEnquiry
from .service import source_hash
from .tasks import deliver_pending
from .views import create_enquiry


class ProductEnquiryTests(TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.data = {'request_id': str(uuid.uuid4()), 'name': 'Example Customer',
                     'email': 'customer@example.com', 'phone': '', 'company': '',
                     'product_type': 'gas_cylinder',
                     'message': 'Please tell me more about this gas scale.',
                     'contact_consent': True}

    def submit(self, **changes):
        data = dict(self.data, **changes)
        request = self.factory.post('/enquiries/', data, format='json', REMOTE_ADDR='192.0.2.1')
        return create_enquiry(request)

    def test_public_form_persists_before_mail_delivery(self):
        result = self.submit()
        self.assertEqual(result.status_code, 201)
        self.assertEqual(result.data['reference'], self.data['request_id'])
        self.assertEqual(ProductEnquiry.objects.count(), 1)
        self.assertEqual(EnquiryDelivery.objects.count(), 2)
        self.assertEqual(len(getattr(mail, 'outbox', [])), 0)

    def test_retry_is_idempotent(self):
        self.submit()
        self.assertEqual(self.submit().status_code, 200)
        self.assertEqual(ProductEnquiry.objects.count(), 1)
        self.assertEqual(EnquiryDelivery.objects.count(), 2)

    def test_reusing_reference_for_changed_request_is_rejected(self):
        self.submit()
        self.assertEqual(self.submit(message='This is a different message.').status_code, 409)
        self.assertEqual(ProductEnquiry.objects.count(), 1)

    def test_all_catalogue_products_can_be_requested(self):
        from .catalog import PRODUCTS
        for number, product in enumerate(PRODUCTS):
            result = self.submit(request_id=str(uuid.uuid4()), product_type=product,
                                 email=f'customer{number}@example.com')
            self.assertEqual(result.status_code, 201, product)

    def test_product_is_allowlisted(self):
        self.assertEqual(self.submit(product_type='arbitrary-product').status_code, 400)
        self.assertEqual(ProductEnquiry.objects.count(), 0)

    def test_explicit_consent_is_required(self):
        self.assertEqual(self.submit(contact_consent=False).status_code, 400)
        self.assertEqual(ProductEnquiry.objects.count(), 0)

    def test_contact_and_message_validation(self):
        for field, value in [('email', 'bad-email'), ('message', 'short'),
                             ('name', 'X' * 121), ('message', 'X' * 2001),
                             ('phone', 'X' * 41), ('request_id', 'not-a-uuid'),
                             ('name', 'Name\r\nBcc: victim@example.com')]:
            with self.subTest(field=field, value=value[:30]):
                self.assertEqual(self.submit(**{field: value}).status_code, 400)
        self.assertEqual(ProductEnquiry.objects.count(), 0)

    def test_client_cannot_choose_recipients(self):
        self.submit(recipients=['attacker@example.com'], to='attacker@example.com')
        self.assertSetEqual(set(EnquiryDelivery.objects.values_list('recipient', flat=True)),
                            {'admin-one@example.com', 'admin-two@example.com'})

    @override_settings(PRODUCT_ENQUIRY_RECIPIENTS=())
    def test_missing_email_configuration_does_not_claim_success(self):
        self.assertEqual(self.submit().status_code, 503)
        self.assertEqual(ProductEnquiry.objects.count(), 0)

    @patch('product_enquiries.views.save_enquiry', side_effect=DatabaseError)
    def test_database_failure_has_recoverable_error(self, save):
        self.assertEqual(self.submit().status_code, 503)

    def test_email_rate_limit_and_safe_retry(self):
        for _ in range(3):
            self.assertEqual(self.submit(request_id=str(uuid.uuid4())).status_code, 201)
        result = self.submit()
        self.assertEqual(result.status_code, 429)
        self.assertEqual(result['Retry-After'], '3600')
        self.assertEqual(ProductEnquiry.objects.count(), 3)

    def test_existing_reference_bypasses_rate_limit_without_duplicate(self):
        self.submit()
        for _ in range(2):
            self.submit(request_id=str(uuid.uuid4()))
        self.assertEqual(self.submit().status_code, 200)
        self.assertEqual(ProductEnquiry.objects.count(), 3)

    def test_source_rate_limit_across_different_emails(self):
        self.submit()
        existing = ProductEnquiry.objects.get()
        ProductEnquiry.objects.bulk_create([
            ProductEnquiry(id=uuid.uuid4(), name='Example', email=f'{i}@example.com',
                           product_type='device7', message='Example request',
                           contact_consent=True, payload_hash='x' * 64,
                           source_hash=existing.source_hash)
            for i in range(19)
        ])
        self.assertEqual(self.submit(request_id=str(uuid.uuid4()), email='other@example.com').status_code, 429)

    def test_forwarded_ip_is_ignored_without_trusted_proxy_config(self):
        first = self.factory.post('/', {}, REMOTE_ADDR='192.0.2.1', HTTP_X_REAL_IP='192.0.2.2')
        second = self.factory.post('/', {}, REMOTE_ADDR='192.0.2.1', HTTP_X_REAL_IP='192.0.2.3')
        self.assertEqual(source_hash(first), source_hash(second))

    @override_settings(PRODUCT_ENQUIRY_TRUST_REAL_IP=True)
    def test_verified_proxy_ip_is_used_when_configured(self):
        first = self.factory.post('/', {}, REMOTE_ADDR='172.1.0.1', HTTP_X_REAL_IP='192.0.2.2')
        second = self.factory.post('/', {}, REMOTE_ADDR='172.1.0.1', HTTP_X_REAL_IP='192.0.2.3')
        self.assertNotEqual(source_hash(first), source_hash(second))

    def test_mail_reaches_both_configured_admins_with_reply_to(self):
        self.submit()
        result = deliver_pending()
        self.assertEqual(result['sent'], 2)
        self.assertEqual(len(mail.outbox), 2)
        self.assertSetEqual({item.to[0] for item in mail.outbox},
                            {'admin-one@example.com', 'admin-two@example.com'})
        self.assertEqual(mail.outbox[0].reply_to, ['customer@example.com'])
        self.assertIn(self.data['request_id'], mail.outbox[0].body)
        self.assertIn('Gas cylinder scale', mail.outbox[0].subject)
        self.assertEqual(EnquiryDelivery.objects.filter(sent_at__isnull=False).count(), 2)

    def test_successfully_sent_messages_are_not_sent_again(self):
        self.submit()
        deliver_pending()
        self.assertEqual(deliver_pending()['sent'], 0)
        self.assertEqual(len(mail.outbox), 2)

    @patch('product_enquiries.tasks.send_delivery')
    def test_partial_failure_only_retries_unsent_admin(self, send):
        self.submit()
        send.side_effect = [None, TimeoutError('private smtp details')]
        self.assertEqual(deliver_pending()['sent'], 1)
        pending = EnquiryDelivery.objects.get(sent_at__isnull=True)
        self.assertEqual(pending.last_error, 'TimeoutError')
        self.assertGreater(pending.next_attempt_at, timezone.now())
        self.assertEqual(pending.attempts, 1)
        self.assertEqual(deliver_pending()['checked'], 0)
        EnquiryDelivery.objects.filter(pk=pending.pk).update(
            next_attempt_at=timezone.now() - timedelta(seconds=1))
        send.side_effect = None
        self.assertEqual(deliver_pending()['sent'], 1)
        self.assertEqual(send.call_count, 3)

    @patch('product_enquiries.tasks.EmailMessage.send', return_value=0)
    def test_zero_messages_sent_is_a_retryable_failure(self, send):
        self.submit()
        self.assertEqual(deliver_pending()['sent'], 0)
        self.assertEqual(EnquiryDelivery.objects.filter(sent_at__isnull=True, attempts=1).count(), 2)
