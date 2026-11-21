import importlib.util,json
from unittest.mock import patch
from django.contrib.auth import get_user_model
from rest_framework.test import APIRequestFactory,force_authenticate
from device.models import Device
from platform_admin.policy import mqtt_client_id

spec=importlib.util.spec_from_file_location('device.gas_setup_candidate','/tmp/artic-gas-setup-candidate.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
User=get_user_model()
user=User.objects.get(email='surprisemathlaba@gmail.com')
device=Device.objects.filter(company_id=user.profile.business_id,device_type='gas_cylinder').first()
assert device is not None
factory=APIRequestFactory()
body={'business_id':device.company_id,'device_id':device.pk}
def request(view,payload=body,actor=user):
    req=factory.post('/api/gas/credentials/issue/',payload,format='json',HTTP_HOST='api.articsentinel.com')
    if actor is not None:force_authenticate(req,user=actor)
    return view(req)
with patch.object(module,'_spool_request',return_value=True) as spool,patch.object(module.GasScaleCredential.objects,'update_or_create') as old_meta,patch.object(module.DeviceMqttLogin.objects,'update_or_create') as meta:
    r=request(module.gas_credentials_issue)
    assert r.status_code==200
    credentials=r.data['credentials']
    assert credentials['mqtt_client_id']==mqtt_client_id(device.pk)
    assert credentials['mqtt_tls'] is True and credentials['mqtt_port']==8883
    assert credentials['mqtt_user']==device.device_id
    assert credentials['topic']==f'gas_cylinder/{device.device_id}/data'
    assert len(credentials['mqtt_pass'])>=20
    assert 'no-store' in r.get('Cache-Control','')
    assert 'mqtt_pass' not in spool.call_args.args[0]
    assert spool.call_count==meta.call_count==old_meta.call_count==1
    outsider=User(username='unpersisted-probe',is_active=True)
    denied=request(module.gas_credentials_issue,actor=outsider)
    assert denied.status_code==403
    assert spool.call_count==1
    unauth=request(module.gas_credentials_issue,actor=None)
    assert unauth.status_code in (401,403)
    assert spool.call_count==1
    non_gas=Device.objects.filter(company_id=user.profile.business_id).exclude(device_type='gas_cylinder').first()
    if non_gas:
        assert request(module.gas_credentials_issue,{**body,'device_id':non_gas.pk}).status_code==404
        assert spool.call_count==1
    other=Device.objects.exclude(company_id=user.profile.business_id).filter(device_type='gas_cylinder').first()
    if other:
        assert request(module.gas_credentials_issue,{'business_id':other.company_id,'device_id':other.pk}).status_code==403
        assert spool.call_count==1
r=request(module.gas_credentials_status)
assert r.status_code==200 and r.data['mqtt_client_id']==mqtt_client_id(device.pk)
assert 'mqtt_pass' not in r.data
assert 'no-store' in r.get('Cache-Control','')
print(json.dumps({'ok':True,'identity_in_credentials_and_status':True,'per_device_login':True,'cross_company_and_unauthenticated_blocked':True,'password_hidden_in_status':True,'no_cache':True,'live_credentials_rotated':False}))
