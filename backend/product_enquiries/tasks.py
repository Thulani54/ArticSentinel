import logging
from datetime import timedelta

from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMessage, get_connection
from django.db import transaction
from django.utils import timezone

from .catalog import PRODUCTS
from .models import EnquiryDelivery
from .service import recipients

logger = logging.getLogger(__name__)


def send_delivery(delivery):
    enquiry = delivery.enquiry
    product = PRODUCTS[enquiry.product_type]
    body = '\n'.join([
        'A customer requested more information from the ArticSentinel app.', '',
        f'Product: {product}', f'Reference: {enquiry.pk}',
        f'Received: {enquiry.created_at.isoformat()}', '',
        f'Name: {enquiry.name}', f'Email: {enquiry.email}',
        f'Phone: {enquiry.phone or "Not provided"}',
        f'Company: {enquiry.company or "Not provided"}', '',
        'Message:', enquiry.message, '',
        'The customer agreed to be contacted about this request.',
        'These are customer-provided contact details. Reply to follow up.',
    ])
    connection = get_connection(timeout=20, fail_silently=False)
    email = EmailMessage(
        subject=f'ArticSentinel product enquiry: {product}', body=body,
        from_email=settings.DEFAULT_FROM_EMAIL, to=[delivery.recipient],
        reply_to=[enquiry.email], connection=connection,
        headers={'Message-ID': f'<enquiry-{enquiry.pk}-{delivery.pk}@articsentinel.com>'},
    )
    if email.send(fail_silently=False) != 1:
        raise RuntimeError('Mail backend did not accept the message')


@shared_task(name='product_enquiries.tasks.deliver_pending')
def deliver_pending():
    allowed = set(recipients())
    due = list(EnquiryDelivery.objects.filter(sent_at__isnull=True,
               next_attempt_at__lte=timezone.now()).order_by('next_attempt_at')
               .values_list('pk', flat=True)[:20])
    sent = 0
    for pk in due:
        with transaction.atomic():
            delivery = EnquiryDelivery.objects.select_for_update(skip_locked=True).filter(
                pk=pk, sent_at__isnull=True,
                next_attempt_at__lte=timezone.now()).first()
            if delivery is None:
                continue
            delivery.attempts += 1
            try:
                if delivery.recipient not in allowed:
                    raise RuntimeError('Recipient is no longer configured')
                send_delivery(delivery)
            except Exception as error:
                # Do not log the SMTP exception text, addresses or enquiry body.
                delivery.last_error = type(error).__name__
                delivery.next_attempt_at = timezone.now() + timedelta(
                    minutes=min(360, 2 ** min(delivery.attempts, 9)))
                logger.warning('Product enquiry delivery %s deferred (%s)',
                               delivery.pk, delivery.last_error)
            else:
                delivery.sent_at = timezone.now()
                delivery.last_error = ''
                sent += 1
            delivery.save(update_fields=['attempts', 'next_attempt_at', 'sent_at', 'last_error'])
    return {'sent': sent, 'checked': len(due)}
