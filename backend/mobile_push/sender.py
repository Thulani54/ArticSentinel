import time
import os
from functools import lru_cache
from pathlib import Path
import requests

KEY_PATH = os.environ.get('ARTIC_FCM_SERVICE_ACCOUNT', '/app/.secrets/fcm-service-account.json')

def configured():
    return Path(KEY_PATH).is_file()

@lru_cache(maxsize=1)
def credentials():
    from google.oauth2 import service_account
    return service_account.Credentials.from_service_account_file(KEY_PATH, scopes=['https://www.googleapis.com/auth/firebase.messaging'])

def send_notification(token, event):
    from google.auth.transport.requests import Request
    creds = credentials()
    if not creds.valid:
        creds.refresh(Request())
    urgent = event.threshold == 10
    title = 'Gas cylinder nearly empty' if urgent else f'Gas level reached {event.threshold}%'
    body = f'{event.device.name}: {event.level:.0f}% remaining. ' + ('Arrange a refill soon.' if urgent else 'Plan your next refill.')
    response = requests.post(
        f'https://fcm.googleapis.com/v1/projects/{creds.project_id}/messages:send',
        headers={'Authorization': f'Bearer {creds.token}'},
        json={'message': {'token': token, 'notification': {'title': title, 'body': body},
            'data': {'kind': 'gas_level', 'device_id': str(event.device_id), 'threshold': str(event.threshold), 'event_id': str(event.id)},
            'android': {'priority': 'HIGH', 'ttl': '900s', 'notification': {'channel_id': 'gas_alerts','icon':'ic_stat_gas','tag':f'gas-{event.device_id}-{event.threshold}'}},
            'apns': {'headers': {'apns-priority':'10','apns-expiration':str(int(time.time())+900),'apns-collapse-id':f'gas-{event.device_id}-{event.threshold}'}, 'payload': {'aps': {'sound':'default'}}}}}, timeout=20)
    if response.ok:
        return 'sent'
    try:
        codes = [detail.get('errorCode') for detail in response.json().get('error',{}).get('details',[])]
    except (ValueError, AttributeError):
        codes = []
    if 'UNREGISTERED' in codes:
        return 'unregistered'
    # Do not log payloads, registration tokens, or private key contents.
    raise RuntimeError(f'FCM HTTP {response.status_code}')
