"""Installation-scoped push diagnostics; never allows targeting other users."""
import uuid
from datetime import timedelta
from django.db import transaction
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from device.gas_views import _user_can_access
from .models import PushInstallation, PushDelivery, DeviceThresholdDelivery
from .sender import configured, _send


def _installation(request):
    token = request.data.get('token')
    if not isinstance(token, str) or not 20 <= len(token) <= 512:
        return None
    return PushInstallation.objects.filter(user=request.user, token=token, enabled=True).select_related('company').first()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def status(request):
    installation = _installation(request)
    if installation is None or not _user_can_access(request.user, installation.company):
        return Response({'error': 'This phone is not registered for your account. Enable notifications and retry.'}, status=404)
    last_sent = []
    pending = 0
    for model in (PushDelivery, DeviceThresholdDelivery):
        query = model.objects.filter(installation=installation)
        pending += query.filter(sent_at__isnull=True).count()
        sent_at = query.filter(sent_at__isnull=False).order_by('-sent_at').values_list('sent_at', flat=True).first()
        if sent_at:
            last_sent.append(sent_at)
    return Response({'registered': True, 'platform': installation.platform,
        'delivery_configured': configured(), 'pending_alerts': pending,
        'last_alert_accepted_at': max(last_sent).isoformat() if last_sent else None,
        'last_test_requested_at': installation.last_test_requested_at.isoformat() if installation.last_test_requested_at else None})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_test(request):
    installation = _installation(request)
    if installation is None or not _user_can_access(request.user, installation.company):
        return Response({'error': 'Enable notifications on this phone before sending a test.'}, status=404)
    if not configured():
        return Response({'error': 'Notification delivery is not configured on the server.'}, status=503)
    now = timezone.now()
    with transaction.atomic():
        installation = PushInstallation.objects.select_for_update().get(pk=installation.pk)
        if installation.user_id != request.user.pk or not installation.enabled:
            return Response({'error': 'This phone registration changed. Enable notifications again.'}, status=409)
        if installation.last_test_requested_at and installation.last_test_requested_at > now - timedelta(seconds=60):
            return Response({'error': 'Wait one minute before sending another test.'}, status=429)
        installation.last_test_requested_at = now
        installation.save(update_fields=['last_test_requested_at'])
    try:
        outcome = _send(installation.token, 0, 0, uuid.uuid4().hex,
            'ArticSentinel test notification',
            'Phone alerts are connected. Tap to return to notification settings.',
            kind='notification_test', tag='artic-notification-test')
    except Exception:
        return Response({'error': 'The notification provider could not accept this test. Try again shortly.'}, status=502)
    if outcome == 'unregistered':
        PushInstallation.objects.filter(pk=installation.pk, token=installation.token, user=request.user).update(enabled=False)
        return Response({'error': 'This phone registration expired. Enable notifications again.'}, status=410)
    return Response({'accepted': True, 'message': 'The notification provider accepted the test. Confirm it appears on this phone.'})
