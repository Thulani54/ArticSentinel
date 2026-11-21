"""Exercise installed transition + template + log code; rollback all rows.
Every SMTP send is mocked. Do not use this as evidence of physical delivery.
"""
from datetime import timedelta
from unittest.mock import patch
from django.db import transaction
from django.utils import timezone
from device.models import Device
from scale_connections.models import ConnectionState, ConnectionDelivery
from scale_connections.tasks import observe,deliver_pending
from communication.models import CommunicationLog

with transaction.atomic():
 device=Device.objects.filter(device_type='gas_cylinder',is_active=True,company_id=1).exclude(device_id__startswith='MONITOR-').first()
 assert device is not None
 now=timezone.now()
 state,_=ConnectionState.objects.get_or_create(device=device,defaults={'online':True})
 state=ConnectionState.objects.select_for_update().get(pk=state.pk)
 state.online=True;state.sequence=10000;state.changed_at=now-timedelta(minutes=30);state.last_reading_at=now-timedelta(minutes=30);state.save()
 with patch('exvr.email_backend.send_html_email',return_value=True) as sender:
  observe(device,now-timedelta(minutes=20),now)
  offline=list(ConnectionDelivery.objects.filter(state=state,sequence=10001).values_list('pk',flat=True))
  assert offline
  with patch('scale_connections.tasks.latest_reading_time',return_value=now-timedelta(minutes=20)):
   deliver_pending()
  assert ConnectionDelivery.objects.filter(pk__in=offline,status='sent').count()==len(offline)
  device.is_online=True # What the MQTT bridge writes; must not hide recovery.
  observe(device,now,now+timedelta(seconds=1))
  online=list(ConnectionDelivery.objects.filter(state=state,sequence=10002).values_list('pk',flat=True))
  assert online
  ConnectionDelivery.objects.filter(pk__in=online).update(next_attempt_at=now)
  with patch('scale_connections.tasks.latest_reading_time',return_value=now):
   deliver_pending()
  assert ConnectionDelivery.objects.filter(pk__in=online,status='sent').count()==len(online)
  before=sender.call_count
  observe(device,now,now+timedelta(seconds=2))
  with patch('scale_connections.tasks.latest_reading_time',return_value=now):deliver_pending()
  assert sender.call_count==before
  print('POSTGRES_ROLLBACK_OK offline=',len(offline),'online=',len(online),'SMTP calls mocked=',before)
 transaction.set_rollback(True)
