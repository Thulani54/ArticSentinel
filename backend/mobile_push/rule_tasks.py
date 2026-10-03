"""Personal device rules run from the existing once-a-minute alert schedule."""
import logging
from datetime import timedelta
from django.db import transaction
from django.utils import timezone
from celery import shared_task
from device.gas_views import _user_can_access
from device.models import Device
from .models import DeviceAlertSettings, DeviceAlertRule, DeviceThresholdEvent, DeviceThresholdDelivery, PushInstallation
from .metrics import catalog, read_latest
from .rule_policy import evaluate_rule,most_urgent_rules
from .sender import configured, send_threshold_notification
logger=logging.getLogger(__name__)

def check_device_thresholds():
    if not configured():return
    devices=Device.objects.filter(
        pk__in=DeviceAlertSettings.objects.filter(rules__isnull=False,user__is_active=True).values('device_id'),is_active=True)
    for device in devices:
        try:
            at,values=read_latest(device)
            if at is None:continue
            for settings_id in DeviceAlertSettings.objects.filter(device=device,user__is_active=True).values_list('pk',flat=True):
                with transaction.atomic():
                    settings=DeviceAlertSettings.objects.select_for_update().select_related('user').get(pk=settings_id)
                    if not _user_can_access(settings.user,device.company):continue
                    crossed=[]
                    for rule in settings.rules.select_for_update():
                        if rule.metric not in values or (rule.last_reading_at and at<=rule.last_reading_at):continue
                        spec=catalog(device).get(rule.metric)
                        if spec is None:continue
                        fire,triggered=evaluate_rule(values[rule.metric],rule.threshold,rule.comparison,rule.triggered,spec)
                        rule.triggered=triggered;rule.last_reading_at=at;rule.save(update_fields=['triggered','last_reading_at'])
                        if fire:crossed.append(rule)
                    for rule in most_urgent_rules(crossed):
                        event,_=DeviceThresholdEvent.objects.get_or_create(rule=rule,reading_at=at,defaults={'value':values[rule.metric]})
                        for installation in PushInstallation.objects.filter(user=settings.user,company=device.company,enabled=True):
                            DeviceThresholdDelivery.objects.get_or_create(event=event,installation=installation)
        except Exception as error:
            logger.warning('Device threshold check failed for device %s: %s',device.pk,type(error).__name__)
    deliver_device_thresholds.delay()

@shared_task
def deliver_device_thresholds():
    if not configured():return
    for _ in range(100):
        with transaction.atomic():
            delivery=DeviceThresholdDelivery.objects.select_for_update(of=('self',),skip_locked=True).filter(
                sent_at__isnull=True,attempts__lt=5,next_attempt_at__lte=timezone.now(),
                event__reading_at__gte=timezone.now()-timedelta(minutes=15),
                installation__enabled=True).select_related('event__rule__settings__device__company','event__rule__settings__user','installation').order_by('next_attempt_at').first()
            if delivery is None:break
            settings=delivery.event.rule.settings;device=settings.device
            delivery.attempts+=1
            if not settings.user.is_active or not device.is_active or delivery.installation.user_id!=settings.user_id or delivery.installation.company_id!=device.company_id or not _user_can_access(settings.user,device.company):
                delivery.attempts=5;delivery.last_error='access changed'
            else:
                try:
                    result=send_threshold_notification(delivery.installation.token,delivery.event)
                    if result=='sent':delivery.sent_at=timezone.now();delivery.last_error=''
                    elif result=='unregistered':
                        delivery.installation.enabled=False;delivery.installation.save(update_fields=['enabled']);delivery.last_error='unregistered'
                except Exception as error:delivery.last_error=type(error).__name__
            delivery.next_attempt_at=timezone.now()+timedelta(seconds=min(300,15*2**delivery.attempts));delivery.save()
