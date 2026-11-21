"""Run through manage.py shell after migrations. No messages sent."""
from communication.models import CommunicationTemplate
from django_celery_beat.models import IntervalSchedule, PeriodicTask
from device.models import Device
from device.status import latest_reading_time
from scale_connections.tasks import observe

CommunicationTemplate.objects.get_or_create(
 template_type='device_online',communication_type='email',is_default=True,
 defaults={'name':'Scale back online','is_active':True,'priority':10,
 'subject':'ArticSentinel: {device_name} is back online',
 'message':'<h2>Your gas scale is back online</h2><p><strong>{device_name}</strong> ({device_id}) is reporting again.</p><p>Location: {device_location}<br>Business: {company_name}<br>Detected: {timestamp}</p><p>You can view the latest readings in ArticSentinel.</p>',
 'available_variables':['device_name','device_id','device_location','company_name','timestamp']})
# Establish a silent current baseline before enabling polling.
count=0
for device in Device.objects.filter(device_type='gas_cylinder',is_active=True).exclude(device_id__startswith='MONITOR-'):
 observe(device,latest_reading_time(device));count+=1
schedule,_=IntervalSchedule.objects.get_or_create(every=1,period=IntervalSchedule.MINUTES)
PeriodicTask.objects.update_or_create(name='scale-connection-email-alerts',defaults={
 'task':'scale_connections.tasks.check_scales','interval':schedule,'enabled':True})
print('Recovery email template and one-minute scale checks configured; baselines:',count)
