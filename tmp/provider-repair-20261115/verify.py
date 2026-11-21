import json
import os
from email.utils import parseaddr

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'exvr.settings')
import django
django.setup()

import requests
from django.conf import settings
from google.auth.transport.requests import Request
from mobile_push.models import PushInstallation
from mobile_push.sender import credentials
from monitoring.checks import push_provider, deepseek
from monitoring.models import CheckState

print('provider_checks', json.dumps({**push_provider(), **deepseek()}))
print('email_display_name', parseaddr(settings.DEFAULT_FROM_EMAIL)[0])
installation = PushInstallation.objects.filter(
    enabled=True, platform='android', user__email__iexact='thulanik544@gmail.com'
).order_by('-updated_at').first()
if installation is None:
    print('fcm_validate_only_target', 'validation topic; no enabled Android installation for requested account')
else:
    print('fcm_validate_only_target', 'registered Android installation')
if True:
    creds = credentials()
    if not creds.valid:
        creds.refresh(Request())
    response = requests.post(
        f'https://fcm.googleapis.com/v1/projects/{creds.project_id}/messages:send',
        headers={'Authorization': f'Bearer {creds.token}'},
        json={
            'validate_only': True,
            'message': {
                **({'token': installation.token} if installation else {'topic': 'artic-provider-validation'}),
                'notification': {'title': 'Artic Sentinel validation', 'body': 'Provider dry run; no delivery.'},
                'data': {'kind': 'gas_level', 'device_id': '0', 'threshold': '30', 'event_id': '0'},
                'android': {'priority': 'HIGH', 'ttl': '900s', 'notification': {'channel_id': 'gas_alerts', 'icon': 'ic_stat_gas', 'tag': 'provider-validation'}},
            },
        }, timeout=25,
    )
    print('fcm_validate_only_http', response.status_code)
    if not response.ok:
        error = response.json().get('error', {})
        print('fcm_error_status', error.get('status'))
        print('fcm_error_codes', [detail.get('errorCode') for detail in error.get('details', [])])
for state in CheckState.objects.filter(name__in=['push-provider', 'ai-provider']):
    print('scheduled_monitor', json.dumps({
        'name': state.name, 'ok': state.ok, 'since': str(state.since),
        'checked_at': str(state.checked_at), 'consecutive_failures': state.consecutive_failures,
        'detail': state.detail,
    }))
