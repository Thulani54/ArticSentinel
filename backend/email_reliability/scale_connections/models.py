from django.db import models
from django.utils import timezone

class ConnectionState(models.Model):
    device = models.OneToOneField('device.Device', on_delete=models.CASCADE)
    online = models.BooleanField()
    sequence = models.PositiveIntegerField(default=0)
    changed_at = models.DateTimeField(default=timezone.now)
    last_reading_at = models.DateTimeField(null=True)

class ConnectionDelivery(models.Model):
    state = models.ForeignKey(ConnectionState, on_delete=models.CASCADE)
    sequence = models.PositiveIntegerField()
    online = models.BooleanField()
    profile = models.ForeignKey('user.User', on_delete=models.CASCADE)
    recipient = models.EmailField()
    created_at = models.DateTimeField(default=timezone.now)
    attempts = models.PositiveSmallIntegerField(default=0)
    next_attempt_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=16, default='pending')
    sent_at = models.DateTimeField(null=True)
    last_error = models.CharField(max_length=200, blank=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['state','sequence','recipient'], name='unique_scale_connection_recipient')]
