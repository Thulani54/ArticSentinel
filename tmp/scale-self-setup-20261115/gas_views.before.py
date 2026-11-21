"""Gas cylinder scale API: per-device setup (tare, capacity, price, thresholds)
and weight readings ingested by mqtt/transfere_to_pg_gas.py."""

from django.db import connections
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from company.models import Company
from .models import Device, DeviceMqttLogin, GasCylinderConfig

CONFIG_FIELDS = ('gas_capacity_kg', 'tare_kg', 'price_per_kg', 'low_threshold_pct', 'warning_threshold_pct')


def _user_can_access(user, company):
    if user.is_superuser:
        return True
    profile = getattr(user, 'profile', None)
    if profile is None:
        return False
    return profile.business_id == company.id or profile.secondary_businesses.filter(id=company.id).exists()


def _resolve_device(request):
    """(device, error_response) for the business_id/device_id in the request body.

    device_id may be the numeric primary key or the string device identifier."""
    business_id = request.data.get('business_id')
    device_ref = request.data.get('device_id')
    if not business_id or device_ref in (None, ''):
        return None, Response({'error': 'business_id and device_id are required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        company = Company.objects.get(id=business_id)
    except (Company.DoesNotExist, ValueError, TypeError):
        return None, Response({'error': 'Business not found'}, status=status.HTTP_404_NOT_FOUND)
    if not _user_can_access(request.user, company):
        return None, Response({'error': 'Access denied to this business'}, status=status.HTTP_403_FORBIDDEN)

    devices = Device.objects.filter(company=company, device_type='gas_cylinder')
    ref = str(device_ref)
    device = (devices.filter(id=int(ref)).first() if ref.isdigit() else None) or devices.filter(device_id=ref).first()
    if device is None:
        return None, Response({'error': 'Gas cylinder device not found'}, status=status.HTTP_404_NOT_FOUND)
    return device, None


def _config_payload(config, is_default):
    return {
        **{f: getattr(config, f) for f in CONFIG_FIELDS},
        'full_weight_kg': config.full_weight_kg,
        'is_default': is_default,
        'updated_at': config.updated_at.isoformat() if config.updated_at else None,
    }


def _config_for(device):
    config = GasCylinderConfig.objects.filter(device=device).first()
    if config is None:
        return GasCylinderConfig(device=device), True  # unsaved model defaults
    return config, False


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gas_config(request):
    device, error = _resolve_device(request)
    if error:
        return error
    config, is_default = _config_for(device)
    return Response({'success': True, 'config': _config_payload(config, is_default)})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gas_config_update(request):
    device, error = _resolve_device(request)
    if error:
        return error

    values = {}
    for field in CONFIG_FIELDS:
        if field in request.data:
            try:
                values[field] = float(request.data[field])
            except (TypeError, ValueError):
                return Response({'error': {field: ['Must be a number.']}}, status=status.HTTP_400_BAD_REQUEST)

    config, _ = _config_for(device)
    merged = {f: values.get(f, getattr(config, f)) for f in CONFIG_FIELDS}
    problems = {}
    if not 0 < merged['gas_capacity_kg'] <= 200:
        problems['gas_capacity_kg'] = ['Must be between 0 and 200 kg.']
    if not 0 < merged['tare_kg'] <= 200:
        problems['tare_kg'] = ['Must be between 0 and 200 kg.']
    if merged['price_per_kg'] < 0:
        problems['price_per_kg'] = ['Cannot be negative.']
    if not 0 < merged['low_threshold_pct'] < merged['warning_threshold_pct'] < 100:
        problems['low_threshold_pct'] = ['Low must be above 0 and below the warning level, which must be below 100.']
    if problems:
        return Response({'error': problems}, status=status.HTTP_400_BAD_REQUEST)

    for field, value in merged.items():
        setattr(config, field, value)
    config.updated_by = request.user
    config.save()
    return Response({'success': True, 'config': _config_payload(config, False)})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gas_readings(request):
    """Readings for the last `days` days (default 30, max 400), oldest first,
    bucketed so long ranges stay small: 5 min up to 2 days, 30 min up to 14
    days, hourly beyond. Each bucket carries its last reading."""
    device, error = _resolve_device(request)
    if error:
        return error
    try:
        days = max(1, min(400, int(request.data.get('days', 30))))
    except (TypeError, ValueError):
        days = 30
    bucket = '5 minutes' if days <= 2 else '30 minutes' if days <= 14 else '1 hour'

    config, is_default = _config_for(device)
    with connections['timeseries'].cursor() as cursor:
        cursor.execute(
            """
            SELECT time_bucket(%s::interval, time) AS t,
                   last(gross_kg, time), last(tare_kg, time),
                   last(battery_pct, time), last(rssi, time)
            FROM gas_cylinder_data
            WHERE device_id = %s AND time >= NOW() - (%s * INTERVAL '1 day')
            GROUP BY t
            ORDER BY t
            """,
            [bucket, device.device_id, days],
        )
        rows = cursor.fetchall()
        cursor.execute(
            """
            SELECT time, gross_kg, tare_kg, battery_pct, rssi, temp, fw_version
            FROM gas_cylinder_data WHERE device_id = %s ORDER BY time DESC LIMIT 1
            """,
            [device.device_id],
        )
        latest_row = cursor.fetchone()

    def shape(t, gross, tare):
        # Readings stored before the device was set up carry no tare; use the current one.
        tare = tare if tare is not None else config.tare_kg
        net = max(0.0, gross - tare)
        level = max(0.0, min(100.0, net / config.gas_capacity_kg * 100.0)) if config.gas_capacity_kg else None
        return {'time': t.isoformat(), 'gross_kg': gross, 'tare_kg': tare, 'net_kg': round(net, 3),
                'level_pct': round(level, 2) if level is not None else None}

    readings = [{**shape(t, g, tr), 'battery_pct': b, 'rssi': r} for t, g, tr, b, r in rows]
    latest = None
    if latest_row:
        t, g, tr, b, r, temp, fw = latest_row
        latest = {**shape(t, g, tr), 'battery_pct': b, 'rssi': r, 'temp': temp, 'fw_version': fw}

    return Response({
        'success': True,
        'device': {'id': device.id, 'device_id': device.device_id, 'name': device.name,
                   'is_online': device.is_online,
                   'last_ping': device.last_ping.isoformat() if device.last_ping else None},
        'config': _config_payload(config, is_default),
        'days': days,
        'bucket': bucket,
        'count': len(readings),
        'readings': readings,
        'latest': latest,
    })


# --- Scale broker credentials ------------------------------------------------
# The web container can't write the broker's password file, so it drops a
# hashed request into the spool; the host's exvr-mqtt-credsync unit applies it
# and reloads the broker. The plaintext password never touches disk.

import base64
import hashlib
import json
import os
import re
import secrets
import time

from django.utils import timezone

from .models import GasScaleCredential

CREDENTIAL_SPOOL = os.environ.get('MQTT_CREDENTIAL_SPOOL', '/app/mosquitto/pending')
SCALE_MQTT_HOST = os.environ.get('MQTT_SCALE_PUBLIC_HOST', 'api.articsentinel.com')
SCALE_MQTT_PORT = 8883
SCALE_USERNAME_RE = re.compile(r'^[A-Za-z0-9._-]{1,50}$')


def _mosquitto_hash(password):
    salt = os.urandom(12)
    digest = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, 101)
    return f"$7$101${base64.b64encode(salt).decode()}${base64.b64encode(digest).decode()}"


def _spool_request(payload, timeout=8.0):
    """Queue a credsync request and wait until the host has applied it."""
    name = f"{payload['username']}-{secrets.token_hex(4)}"
    tmp = os.path.join(CREDENTIAL_SPOOL, name + '.tmp')
    final = os.path.join(CREDENTIAL_SPOOL, name + '.json')
    with open(tmp, 'w') as f:
        json.dump(payload, f)
    os.rename(tmp, final)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if not os.path.exists(final):
            return True
        time.sleep(0.25)
    return False


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gas_credentials_issue(request):
    """Issue (or rotate) the scale's broker login and return it once.

    Any member of the device's business may issue, the same people who can add
    the device; who did it is recorded."""
    device, error = _resolve_device(request)
    if error:
        return error
    username = device.device_id
    if not SCALE_USERNAME_RE.match(username or '') or username == 'gas-bridge':
        return Response({'error': "This device ID can't be used as a broker login. "
                                  "Use letters, digits, dots, dashes or underscores (max 50)."},
                        status=status.HTTP_400_BAD_REQUEST)

    password = secrets.token_urlsafe(18)
    try:
        applied = _spool_request({'username': username, 'hash': _mosquitto_hash(password)})
    except OSError:
        return Response({'error': 'The broker login service is unavailable. Try again later.'},
                        status=status.HTTP_503_SERVICE_UNAVAILABLE)
    if not applied:
        return Response({'error': "The broker didn't confirm the new login in time. Try again."},
                        status=status.HTTP_503_SERVICE_UNAVAILABLE)

    GasScaleCredential.objects.update_or_create(
        device=device, defaults={'issued_by': request.user, 'issued_at': timezone.now()})
    # Gas logins are ordinary device logins too (device/mqtt_login.py).
    DeviceMqttLogin.objects.update_or_create(
        device=device, defaults={'issued_by': request.user, 'issued_at': timezone.now()})
    return Response({
        'success': True,
        'credentials': {
            'device_id': username,
            'mqtt_host': SCALE_MQTT_HOST,
            'mqtt_port': SCALE_MQTT_PORT,
            'mqtt_user': username,
            'mqtt_pass': password,
            'topic': f'gas_cylinder/{username}/data',
        },
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gas_credentials_status(request):
    """When the scale's login was last issued, without the password."""
    device, error = _resolve_device(request)
    if error:
        return error
    cred = GasScaleCredential.objects.filter(device=device).select_related('issued_by').first()
    return Response({'success': True, 'issued': cred is not None,
                     'issued_at': cred.issued_at.isoformat() if cred else None,
                     'issued_by': (cred.issued_by.email if cred and cred.issued_by else None)})
