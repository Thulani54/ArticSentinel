import hashlib
import ipaddress
import json
from datetime import timedelta

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured, ValidationError
from django.core.validators import validate_email
from django.db import transaction
from django.utils import timezone
from django.utils.crypto import constant_time_compare, salted_hmac

from .models import EnquiryDelivery, ProductEnquiry, SubmissionGate


class RequestConflict(Exception):
    pass


class SubmissionLimited(Exception):
    pass


def recipients():
    configured = getattr(settings, 'PRODUCT_ENQUIRY_RECIPIENTS', ())
    if not isinstance(configured, (list, tuple)) or len(configured) != 2:
        raise ImproperlyConfigured('Two product enquiry recipients must be configured.')
    result = []
    for item in configured:
        try:
            validate_email(item)
        except (ValidationError, TypeError):
            raise ImproperlyConfigured('Invalid product enquiry recipient.') from None
        if '\n' in item or '\r' in item:
            raise ImproperlyConfigured('Invalid product enquiry recipient.')
        result.append(item.lower())
    if len(set(result)) != 2:
        raise ImproperlyConfigured('Two different product enquiry recipients are required.')
    return result


def source_hash(request):
    # Enable this only behind a proxy that overwrites X-Real-IP (not XFF).
    source = request.META.get('REMOTE_ADDR', '')
    if getattr(settings, 'PRODUCT_ENQUIRY_TRUST_REAL_IP', False):
        source = request.META.get('HTTP_X_REAL_IP', source)
    try:
        source = str(ipaddress.ip_address(source))
    except ValueError:
        source = 'unknown'
    return salted_hmac('product-enquiry-source', source, algorithm='sha256').hexdigest()


def save_enquiry(data, source):
    data = dict(data)
    request_id = data.pop('request_id')
    fingerprint = hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()
    destinations = recipients()
    now = timezone.now()
    with transaction.atomic():
        SubmissionGate.objects.get_or_create(pk=1)
        SubmissionGate.objects.select_for_update().get(pk=1)
        existing = ProductEnquiry.objects.filter(pk=request_id).first()
        if existing:
            if not constant_time_compare(existing.payload_hash, fingerprint):
                raise RequestConflict
            return existing, False
        recent = ProductEnquiry.objects.filter(created_at__gte=now - timedelta(hours=1))
        if (recent.filter(email=data['email']).count() >= 3
                or recent.filter(source_hash=source).count() >= 20
                or recent.count() >= 100):
            raise SubmissionLimited
        enquiry = ProductEnquiry.objects.create(
            id=request_id, payload_hash=fingerprint, source_hash=source, **data)
        EnquiryDelivery.objects.bulk_create([
            EnquiryDelivery(enquiry=enquiry, recipient=recipient)
            for recipient in destinations
        ])
    # Celery beat drains the durable table. Accepting does not depend on Redis.
    return enquiry, True
