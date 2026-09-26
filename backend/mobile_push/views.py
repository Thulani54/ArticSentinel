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
