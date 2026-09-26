from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from company.models import Company
from device.gas_views import _user_can_access
from .models import PushInstallation
from .sender import configured

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register(request):
    try:
        business_id = int(request.data.get('business_id'))
    except (ValueError, TypeError):
        return Response({'error':'A valid business ID is required'},status=400)
    company = get_object_or_404(Company, id=business_id)
    if not _user_can_access(request.user, company):
        return Response({'error':'Access denied to this business'},status=403)
    token = request.data.get('token')
    platform = request.data.get('platform')
    if not isinstance(token,str) or not 20 <= len(token) <= 512 or platform not in ('android','ios'):
        return Response({'error':'A valid push token and mobile platform are required'},status=400)
    PushInstallation.objects.update_or_create(token=token, defaults={'user':request.user,'company':company,'platform':platform,'enabled':True})
    return Response({'success':True,'delivery_configured':configured(),'thresholds':[50,30,10]})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def unregister(request):
    PushInstallation.objects.filter(user=request.user,token=request.data.get('token')).update(enabled=False)
    return Response({'success':True})

from django.db import transaction
from device.models import Device
from .models import DeviceAlertSettings, DeviceAlertRule
from .metrics import catalog, device_kind
from .rule_policy import normalize_rules

def settings_payload(device, settings):
    groups={}
    if settings is not None:
        for rule in settings.rules.order_by('metric','comparison','-threshold'):
            groups.setdefault((rule.metric,rule.comparison),[]).append(rule.threshold)
    elif device_kind(device)=='gas_cylinder':
        groups[('gas_level','lte')]=[50,30,10]
    return {'device_id':device.pk,'revision':settings.revision if settings else 0,
        'personalized':settings is not None,
        'metrics':[dict(id=key,**value) for key,value in catalog(device).items()],
        'rules':[{'metric':key[0],'comparison':key[1],'thresholds':values} for key,values in groups.items()]}

@api_view(['GET','PUT'])
@permission_classes([IsAuthenticated])
def device_rules(request,device_id):
    device=get_object_or_404(Device,pk=device_id)
    if not _user_can_access(request.user,device.company):
        return Response({'error':'Access denied to this device'},status=403)
    if request.method=='GET':
        settings=DeviceAlertSettings.objects.filter(user=request.user,device=device).first()
        return Response(settings_payload(device,settings))
    try:
        rules=normalize_rules(request.data.get('rules'),catalog(device))
        revision=request.data.get('revision')
        if isinstance(revision,bool) or not isinstance(revision,int) or revision<0:raise ValueError('Reload the device alert rules before saving.')
    except ValueError as error:
        return Response({'error':str(error)},status=400)
    with transaction.atomic():
        settings,_=DeviceAlertSettings.objects.get_or_create(user=request.user,device=device)
        settings=DeviceAlertSettings.objects.select_for_update().get(pk=settings.pk)
        if settings.revision!=revision:
            transaction.set_rollback(True)
            return Response({'error':'These rules changed on another phone. Reload them before saving.'},status=409)
        keep=[]
        for metric,comparison,threshold in rules:
            rule,_=DeviceAlertRule.objects.get_or_create(settings=settings,metric=metric,comparison=comparison,threshold=threshold)
            keep.append(rule.pk)
        settings.rules.exclude(pk__in=keep).delete()
        settings.revision+=1;settings.save(update_fields=['revision'])
        return Response(settings_payload(device,settings))
