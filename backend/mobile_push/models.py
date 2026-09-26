from django.conf import settings
from django.db import models
from django.utils import timezone

class PushInstallation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    company = models.ForeignKey('company.Company', on_delete=models.CASCADE)
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=10)
    enabled = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

class GasPushState(models.Model):
    device = models.OneToOneField('device.Device', on_delete=models.CASCADE)
    last_reading_at = models.DateTimeField(null=True)
    notified_thresholds = models.JSONField(default=list)

class GasPushEvent(models.Model):
    device = models.ForeignKey('device.Device', on_delete=models.CASCADE)
    threshold = models.PositiveSmallIntegerField()
    level = models.FloatField()
    reading_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['device','threshold','reading_at'],name='unique_gas_push_event')]

class PushDelivery(models.Model):
    event = models.ForeignKey(GasPushEvent, on_delete=models.CASCADE)
    installation = models.ForeignKey(PushInstallation, on_delete=models.CASCADE)
    attempts = models.PositiveSmallIntegerField(default=0)
    next_attempt_at = models.DateTimeField(default=timezone.now)
    sent_at = models.DateTimeField(null=True)
    last_error = models.CharField(max_length=100, blank=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['event','installation'],name='unique_gas_push_delivery')]

class DeviceAlertSettings(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    device = models.ForeignKey('device.Device', on_delete=models.CASCADE)
    revision = models.PositiveIntegerField(default=0)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['user','device'],name='personal_device_alert_settings')]

class DeviceAlertRule(models.Model):
    settings = models.ForeignKey(DeviceAlertSettings, on_delete=models.CASCADE, related_name='rules')
    metric = models.CharField(max_length=40)
    comparison = models.CharField(max_length=3)
    threshold = models.FloatField()
    triggered = models.BooleanField(default=False)
    last_reading_at = models.DateTimeField(null=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['settings','metric','comparison','threshold'],name='personal_device_alert_rule')]

class DeviceThresholdEvent(models.Model):
    rule = models.ForeignKey(DeviceAlertRule, on_delete=models.CASCADE)
    value = models.FloatField()
    reading_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['rule','reading_at'],name='unique_device_threshold_event')]

class DeviceThresholdDelivery(models.Model):
    event = models.ForeignKey(DeviceThresholdEvent, on_delete=models.CASCADE)
    installation = models.ForeignKey(PushInstallation, on_delete=models.CASCADE)
    attempts = models.PositiveSmallIntegerField(default=0)
    next_attempt_at = models.DateTimeField(default=timezone.now)
    sent_at = models.DateTimeField(null=True)
    last_error = models.CharField(max_length=100,blank=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['event','installation'],name='unique_device_threshold_delivery')]
