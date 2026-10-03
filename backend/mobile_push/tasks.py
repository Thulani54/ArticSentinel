from datetime import timedelta
import math
from celery import shared_task
from django.db import connections, transaction
from django.utils import timezone
from device.models import Device, GasCylinderConfig
from device.gas_views import _user_can_access
from .models import PushInstallation, GasPushState, GasPushEvent, PushDelivery, DeviceAlertSettings
from .thresholds import evaluate_level
from .sender import configured, send_notification

@shared_task
def check_gas_levels():
    if not configured():
        return {'delivery_configured':False}
    configs = GasCylinderConfig.objects.select_related('device','device__company').filter(device__device_type='gas_cylinder',device__is_active=True)
    count = 0
    for config in configs:
        with connections['timeseries'].cursor() as cursor:
            cursor.execute("SELECT time, gross_kg FROM gas_cylinder_data WHERE device_id=%s AND time >= NOW() - INTERVAL '15 minutes' ORDER BY time DESC LIMIT 1",[config.device.device_id])
            reading = cursor.fetchone()
        if not reading or not config.gas_capacity_kg or not math.isfinite(reading[1]):
            continue
        at,gross = reading
        # A weight lower than the empty cylinder indicates a removed cylinder or calibration issue.
        if gross < config.tare_kg - 0.2:
            continue
        level = min(100.0,max(0.0,(gross-config.tare_kg)/config.gas_capacity_kg*100))
        with transaction.atomic():
            state,_ = GasPushState.objects.get_or_create(device=config.device)
            state = GasPushState.objects.select_for_update().get(pk=state.pk)
            if state.last_reading_at and at <= state.last_reading_at:
                continue
            threshold,notified = evaluate_level(level,state.notified_thresholds)
            state.last_reading_at = at
            state.notified_thresholds = notified
            state.save()
            if threshold is not None:
                event,_ = GasPushEvent.objects.get_or_create(device=config.device,threshold=threshold,reading_at=at,defaults={'level':level})
                installations = PushInstallation.objects.filter(company=config.device.company,enabled=True,user__is_active=True).select_related('user')
                for installation in installations:
                    if DeviceAlertSettings.objects.filter(user=installation.user,device=config.device).exists():
                        continue
                    if _user_can_access(installation.user,config.device.company):
                        PushDelivery.objects.get_or_create(event=event,installation=installation)
                count += 1
    from .rule_tasks import check_device_thresholds
    check_device_thresholds()
    deliver_gas_notifications.delay()
    return {'events':count}

@shared_task
def deliver_gas_notifications():
    if not configured():
        return
    # Database locking coordinates concurrent workers. A failed request is retried
    # with backoff, while old alerts are never delivered after a long outage.
    for _ in range(100):
        with transaction.atomic():
            delivery = PushDelivery.objects.select_for_update(skip_locked=True).filter(
                sent_at__isnull=True, attempts__lt=5,next_attempt_at__lte=timezone.now(),
                event__created_at__gte=timezone.now()-timedelta(minutes=15),
                installation__enabled=True).select_related('event__device__company','installation__user').order_by('next_attempt_at').first()
            if delivery is None:
                break
            installation = delivery.installation
            delivery.attempts += 1
            if DeviceAlertSettings.objects.filter(user=installation.user,device=delivery.event.device).exists():
                delivery.attempts=5;delivery.last_error='replaced by personal rules'
            elif not installation.user.is_active or not _user_can_access(installation.user,delivery.event.device.company):
                installation.enabled=False;installation.save(update_fields=['enabled'])
                delivery.last_error='access revoked'
            else:
                try:
                    result=send_notification(installation.token,delivery.event)
                    if result=='sent':
                        delivery.sent_at=timezone.now();delivery.last_error=''
                    elif result=='unregistered':
                        installation.enabled=False;installation.save(update_fields=['enabled'])
                        delivery.last_error='unregistered'
                except Exception as error:
                    delivery.last_error=type(error).__name__
            delivery.next_attempt_at=timezone.now()+timedelta(seconds=min(300,15*2**delivery.attempts))
            delivery.save()

# Import so Celery autodiscovery registers the personal-rule delivery task.
from .rule_tasks import deliver_device_thresholds
