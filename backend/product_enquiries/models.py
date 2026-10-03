import uuid

from django.db import models
from django.utils import timezone


class ProductEnquiry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=120)
    email = models.EmailField(max_length=254, db_index=True)
    phone = models.CharField(max_length=40, blank=True)
    company = models.CharField(max_length=160, blank=True)
    product_type = models.CharField(max_length=32)
    message = models.TextField()
    contact_consent = models.BooleanField()
    payload_hash = models.CharField(max_length=64)
    source_hash = models.CharField(max_length=64, db_index=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        ordering = ('-created_at',)

    def __str__(self):
        return f'{self.product_type} · {self.id}'


class EnquiryDelivery(models.Model):
    enquiry = models.ForeignKey(ProductEnquiry, on_delete=models.CASCADE,
                                related_name='deliveries')
    recipient = models.EmailField(max_length=254)
    attempts = models.PositiveIntegerField(default=0)
    next_attempt_at = models.DateTimeField(default=timezone.now, db_index=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    last_error = models.CharField(max_length=120, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(
            fields=('enquiry', 'recipient'), name='unique_enquiry_recipient')]


class SubmissionGate(models.Model):
    """One short transaction lock makes rate limits work across web workers."""
    id = models.PositiveSmallIntegerField(primary_key=True, default=1)
