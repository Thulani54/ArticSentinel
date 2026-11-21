"""Durable scale connection transitions, independent of MQTT's online flag."""
from datetime import timedelta
import logging
from celery import shared_task
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from django.utils.html import escape
from device.models import Device
from device.status import latest_reading_time, is_online_at
from user.models import User
from .models import ConnectionState, ConnectionDelivery

logger = logging.getLogger(__name__)


def recipients(device):
    return User.objects.filter(
        Q(business_id=device.company_id) | Q(secondary_businesses__id=device.company_id),
        is_active=True, user__is_active=True, email_notifications=True,
    ).select_related('user').distinct()


def observe(device, latest, now=None):
    now = now or timezone.now()
    online = latest is not None and now - latest <= timedelta(minutes=device.offline_timeout or 10)
    with transaction.atomic():
        state, created = ConnectionState.objects.get_or_create(
            device=device, defaults={'online':online, 'last_reading_at':latest, 'changed_at':now})
        state = ConnectionState.objects.select_for_update().get(pk=state.pk)
        if (now < state.changed_at or
            (state.last_reading_at and latest and latest < state.last_reading_at)):
            return state.online
        # First observation establishes a baseline and must not email the whole fleet.
        if not created and state.online != online:
            state.online = online
            state.sequence += 1
            state.changed_at = now
            for profile in recipients(device):
                email = (profile.user.email or '').strip().lower()
                if email:
                    ConnectionDelivery.objects.get_or_create(
                        state=state, sequence=state.sequence, recipient=email,
                        defaults={'online':online, 'profile':profile, 'created_at':now, 'next_attempt_at':now})
        state.last_reading_at = latest
        state.save()
    return online


@shared_task(ignore_result=True)
def check_scales():
    devices = Device.objects.filter(device_type='gas_cylinder',is_active=True).exclude(device_id__startswith='MONITOR-')
    for device in devices:
        try:
            observe(device, latest_reading_time(device))
        except Exception:
            logger.exception('Scale connection check failed for device %s', device.pk)
    deliver_pending.delay()


@shared_task(ignore_result=True)
def deliver_pending():
    from alerts.tasks import send_communication_with_template
    from communication.models import CommunicationLog
    for _ in range(100):
        with transaction.atomic():
            # Lock only the delivery row; avoid nullable-join FOR UPDATE issues.
            delivery = ConnectionDelivery.objects.select_for_update(skip_locked=True).filter(
                status='pending',next_attempt_at__lte=timezone.now()).order_by('pk').first()
            if delivery is None:
                return
            state = ConnectionState.objects.select_related('device__company').get(pk=delivery.state_id)
            device = state.device
            profile = recipients(device).filter(pk=delivery.profile_id).first()
            now = timezone.now()
            if (not device.is_active or not profile or
                profile.user.email.strip().lower() != delivery.recipient or
                state.sequence != delivery.sequence or
                now - delivery.created_at > timedelta(hours=1)):
                delivery.status = 'superseded'
                delivery.save(update_fields=['status'])
                continue
            # Check telemetry again before sending a delayed connection message.
            if is_online_at(latest_reading_time(device),device) != delivery.online:
                delivery.status='superseded'
                delivery.save(update_fields=['status'])
                continue
            kind = 'device_online' if delivery.online else 'device_offline'
            recent = CommunicationLog.objects.filter(
                device_id=device.pk,recipient__iexact=delivery.recipient,
                template_used__template_type=kind,status__in=['sent','delivered'],
                sent_at__gte=now-timedelta(minutes=30)).exists()
            if recent:
                delivery.status='cooldown'
                delivery.save(update_fields=['status'])
                continue
            delivery.attempts += 1
            variables = {
                'device_name':escape(device.name),'device_id':escape(device.device_id),
                'device_location':escape(device.location or 'Not specified'),
                'company_name':escape(device.company.name),
                'status':'Online' if delivery.online else 'Offline',
                'timestamp':timezone.localtime(state.changed_at).strftime('%Y-%m-%d %H:%M %Z'),
                'status_emoji':'🟢' if delivery.online else '🔴',
                'offline_minutes':device.offline_timeout or 10,
            }
            # Existing communication log is the delivery audit trail. Same verified
            # transport as other notifications; no email during state observation.
            try:
                accepted = send_communication_with_template(
                    communication_type='email',template_type=kind,recipient=delivery.recipient,
                    template_vars=variables,user_id=profile.pk,device_id=device.pk,
                    priority='normal' if delivery.online else 'high')
            except Exception as exc:
                accepted = False
                delivery.last_error = type(exc).__name__
            if accepted:
                delivery.status='sent';delivery.sent_at=now;delivery.last_error=''
            elif delivery.attempts >= 5:
                delivery.status='failed';delivery.last_error='See communication log'
            else:
                delivery.next_attempt_at=now+timedelta(minutes=2**(delivery.attempts-1))
                delivery.last_error='See communication log'
            delivery.save()


@shared_task

def send_diagnostic_email(recipient, request_id):
    """Explicit administrator-requested test; no web endpoint exposes this task."""
    from communication.models import CommunicationLog
    from exvr.email_backend import send_html_email
    existing = CommunicationLog.objects.filter(metadata__diagnostic_request_id=request_id).first()
    if existing:
        return {'id':existing.pk,'status':existing.status,'duplicate_request':True}
    subject = 'ArticSentinel email delivery test - 8 November 2026'
    body = ('<h2>ArticSentinel email delivery test</h2>'
            '<p>This test was requested to verify email delivery after repairs.</p>'
            '<p>This message is not a real gas-level or connection alert.</p>'
            '<p>Please confirm that you received it. Scale offline and back-online '
            'notifications now use the same authenticated email service.</p>')
    log = CommunicationLog.objects.create(
        communication_type='email',recipient=recipient,subject=subject,message=body,
        status='pending',metadata={'diagnostic_request_id':request_id})
    try:
        if send_html_email(recipient,subject,body):
            log.mark_sent(provider_response={'transport':'authenticated_starttls','certificate_verified':True})
        else:
            log.mark_failed('SMTP did not accept the message')
    except Exception as exc:
        log.mark_failed(type(exc).__name__+': '+str(getattr(exc,'smtp_code','')))
    return {'id':log.pk,'status':log.status}
