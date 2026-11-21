from django.conf import settings
from django.db import models

class CylinderRefill(models.Model):
    device = models.ForeignKey('device.Device', on_delete=models.CASCADE)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    request_id = models.UUIDField()
    fingerprint = models.CharField(max_length=64)
    purchased_on = models.DateField()
    kind = models.CharField(max_length=24, choices=[('refill', 'Refill purchase'), ('cylinder_change', 'Cylinder change')], default='refill')
    capacity_kg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    tare_kg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    gas_kg = models.DecimalField(max_digits=7, decimal_places=2)
    cost = models.DecimalField(max_digits=10, decimal_places=2)
    supplier = models.CharField(max_length=160, blank=True)
    notes = models.CharField(max_length=1000, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-purchased_on', '-id']
        constraints = [models.UniqueConstraint(fields=['device', 'request_id'], name='journal_refill_request_unique')]

class AlertTeamState(models.Model):
    alert = models.OneToOneField('alerts.Alert', on_delete=models.CASCADE)
    assigned_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    revision = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

class AlertTeamEvent(models.Model):
    state = models.ForeignKey(AlertTeamState, on_delete=models.CASCADE, related_name='events')
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='+')
    actor_name = models.CharField(max_length=160)
    assignee_name = models.CharField(max_length=160, blank=True)
    action = models.CharField(max_length=16)
    note = models.CharField(max_length=2000, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at', '-id']
