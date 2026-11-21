import importlib.util
from unittest.mock import MagicMock, patch
from rest_framework.test import APIRequestFactory, force_authenticate
from django.contrib.auth.models import User

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
alerts=load('alerts.operations_check','/tmp/operations-alerts.py')
roles=load('roles_and_rights.operations_check','/tmp/operations-roles.py')
factory=APIRequestFactory(); user=User.objects.filter(is_active=True).first()
for name in ['acknowledge_alert','mark_false_positive']:
    target=MagicMock()
    request=factory.post('/api/alerts/action/',{'business_id':1,'alert_id':1},format='json');force_authenticate(request,user=user)
    with patch.object(alerts,'validate_business_access',return_value=object()),patch.object(alerts,'get_object_or_404',return_value=target):
        response=getattr(alerts,name)(request)
    assert response.status_code==200,(name,response.data)
    if name=='acknowledge_alert': target.acknowledge.assert_called_once_with(user=user);target.save.assert_not_called()
    else: assert target.status=='false_positive';target.save.assert_called_once();target.acknowledge.assert_not_called()
    response=getattr(alerts,name)(factory.post('/api/alerts/action/',{},format='json'))
    assert response.status_code in (401,403)
    print(name+': mocked action and authentication passed')
request=factory.post('/api/create_role/',{},format='json');force_authenticate(request,user=user)
response=roles.create_role(request);assert response.status_code==400,response.content
print('create_role: authenticated validation passed')
