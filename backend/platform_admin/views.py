"""Explicit platform oversight endpoints; tenant APIs and roles remain unchanged."""
import csv
import hashlib
import io
from datetime import timedelta

from django.apps import apps
from django.conf import settings
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.db.models import Case, When, Value, F, Q, Count, CharField, DateTimeField, DurationField, ExpressionWrapper, IntegerField
from django.db.models.functions import Cast
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import BasePermission, AllowAny
from rest_framework.response import Response
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.views import APIView
from .models import PlatformAdministrator, AccessEvent
from .policy import mqtt_client_id, csv_cell

MODELS = {
    'companies': 'company.Company', 'devices': 'device.Device',
    'alerts': 'alerts.Alert', 'maintenance': 'maintenance.DeviceMaintenance',
    'reports': 'reports.GeneratedReport', 'users': 'user.User',
    'enquiries': 'product_enquiries.ProductEnquiry', 'health': 'monitoring.CheckState',
    'activity': 'platform_admin.AccessEvent',
}
# All response fields are explicit. Never expose device credentials or account secrets.
FIELDS = {
    'companies': ('id','name','is_active','contact_person','email','phone','city','created_at'),
    'devices': ('id','company_id','company__name','name','device_id','device_type','location','connection_status','is_active','last_ping','offline_timeout'),
    'alerts': ('id','company_id','company__name','device__name','title','message','severity','status','triggered_at','resolved_at'),
    'maintenance': ('id','device__company_id','device__company__name','device__name','maintenance_type__name','status','priority','scheduled_date','actual_end_date','work_description'),
    'reports': ('id','report_id','business_id','report_name','report_type','status','generated_at','start_date','end_date','generated_by','download_count'),
    'users': ('id','business_id','business__name','user__first_name','user__last_name','user__email','user_type','is_active','user__last_login'),
    'enquiries': ('id','name','email','phone','company','product_type','message','created_at'),
    'health': ('name','ok','detail','checked_at','since','consecutive_failures'),
    'activity': ('id','user__username','action','resource','filters','created_at'),
}
SEARCH = {
    'companies': ('name','email','city'), 'devices': ('name','device_id','location','company__name'),
    'alerts': ('title','device__name','company__name'), 'maintenance': ('device__name','maintenance_type__name'),
    'reports': ('report_name','report_id'), 'users': ('user__email','user__first_name','user__last_name'),
    'enquiries': ('name','email','company','product_type'), 'health': ('name',),
    'activity': ('user__username','action','resource'),
}
COMPANY = {'companies':'id','devices':'company_id','alerts':'company_id','maintenance':'device__company_id','reports':'business_id','users':'business_id'}
DATE = {'alerts':'triggered_at','maintenance':'scheduled_date','reports':'generated_at','enquiries':'created_at','activity':'created_at'}
ORDER = {'companies':'name','devices':'-created_at','alerts':'-triggered_at','maintenance':'scheduled_date','reports':'-generated_at','users':'user__email','enquiries':'-created_at','health':'name','activity':'-created_at'}


def model(resource):
    if resource not in MODELS:
        raise ValidationError('Unknown collection.')
    return apps.get_model(getattr(settings, 'PLATFORM_ADMIN_MODELS', {}).get(resource, MODELS[resource]))


def member(user):
    if not user or not user.is_authenticated or not user.is_active:
        return None
    return PlatformAdministrator.objects.filter(user=user, enabled=True).first()


class IsPlatformAdmin(BasePermission):
    def has_permission(self, request, view):
        request.platform_member = member(request.user)
        return request.platform_member is not None


class AdminView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsPlatformAdmin]
    password_change_allowed = False

    def check_permissions(self, request):
        super().check_permissions(request)
        if request.platform_member.must_change_password and not self.password_change_allowed:
            raise PermissionDenied('Change your temporary password before accessing platform data.')

    def finalize_response(self, request, response, *args, **kwargs):
        response = super().finalize_response(request, response, *args, **kwargs)
        response['Cache-Control'] = 'no-store'
        return response


class LoginThrottle(SimpleRateThrottle):
    rate = '10/min'
    scope = 'platform_login'
    def get_cache_key(self, request, view):
        identifier = str(request.data.get('login', '')).strip().casefold()
        return self.cache_format % {'scope': self.scope, 'ident': hashlib.sha256(identifier.encode()).hexdigest()}


class Login(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [LoginThrottle]
    def post(self, request):
        identifier = str(request.data.get('login', '')).strip()[:254]
        password = request.data.get('password', '')
        if not isinstance(password, str) or len(password) > 1024:
            raise ValidationError('Invalid sign-in details.')
        User = get_user_model()
        account = User.objects.filter(Q(username__iexact=identifier) | Q(email__iexact=identifier)).first()
        user = authenticate(request, username=account.username if account else identifier, password=password)
        admin = member(user)
        if not admin:
            return Response({'detail':'Invalid admin login or password.'},status=401,headers={'Cache-Control':'no-store'})
        token, _ = Token.objects.get_or_create(user=user)
        User.objects.filter(pk=user.pk).update(last_login=timezone.now())
        AccessEvent.objects.create(user=user,action='sign_in')
        return Response({'message':'Login successful','token':token.key,'business':None,
                         'user':{'id':user.pk,'email':user.email,'username':user.username,'first_name':user.first_name},
                         'must_change_password':admin.must_change_password},headers={'Cache-Control':'no-store'})


class Access(AdminView):
    password_change_allowed = True
    def get(self, request):
        return Response({'allowed':True,'must_change_password':request.platform_member.must_change_password,
                         'username':request.user.username,'name':request.user.get_full_name(),'email':request.user.email})


class PasswordThrottle(SimpleRateThrottle):
    rate = '5/min'
    scope = 'platform_password'
    def get_cache_key(self, request, view):
        return self.cache_format % {'scope': self.scope, 'ident': request.user.pk}


class Password(AdminView):
    throttle_classes = [PasswordThrottle]
    password_change_allowed = True
    def post(self, request):
        old, new = request.data.get('current_password'), request.data.get('new_password')
        if not isinstance(old,str) or not request.user.check_password(old):
            raise ValidationError('The current password is incorrect.')
        if not isinstance(new,str) or not 12 <= len(new) <= 128 or old == new:
            raise ValidationError('Choose a new password with 12–128 characters.')
        try:
            validate_password(new, request.user)
        except DjangoValidationError as exc:
            raise ValidationError({'new_password':exc.messages})
        with transaction.atomic():
            request.user.set_password(new)
            request.user.save(update_fields=['password'])
            request.platform_member.must_change_password = False
            request.platform_member.save(update_fields=['must_change_password'])
            Token.objects.filter(user=request.user).delete()
            token = Token.objects.create(user=request.user)
            AccessEvent.objects.create(user=request.user,action='password_changed')
        return Response({'token':token.key,'must_change_password':False})


def devices():
    # Use each device's own grace period instead of trusting a stale is_online flag.
    cutoff = ExpressionWrapper(Value(timezone.now()) - ExpressionWrapper(Cast('offline_timeout', IntegerField()) * Value(timedelta(minutes=1)),output_field=DurationField()),output_field=DateTimeField())
    return model('devices').objects.annotate(connection_status=Case(
        When(is_active=False,then=Value('inactive')),
        When(last_ping__isnull=True,then=Value('never_reported')),
        When(last_ping__gte=cutoff,then=Value('online')),
        default=Value('offline'),output_field=CharField()))


def filtered(resource, params):
    qs = devices() if resource == 'devices' else model(resource).objects.all()
    company = params.get('company', '')
    if company:
        if resource not in COMPANY:
            raise ValidationError('This collection does not support a company filter.')
        try:
            company = int(company)
            if company <= 0:raise ValueError()
        except (TypeError,ValueError):raise ValidationError('Choose a valid company.')
        qs = qs.filter(**{COMPANY[resource]:company})
    q = params.get('q','').strip()[:120]
    if q:
        query = Q()
        for field in SEARCH[resource]:query |= Q(**{field+'__icontains':q})
        qs = qs.filter(query)
    status = params.get('status','')
    if status:
        if resource == 'devices':qs=qs.filter(connection_status=status)
        elif resource in ('alerts','maintenance','reports'):qs=qs.filter(status=status)
        elif resource == 'health':
            cutoff=timezone.now()-timedelta(minutes=15)
            if status=='healthy':qs=qs.filter(ok=True,checked_at__gte=cutoff)
            elif status=='failing':qs=qs.filter(ok=False)
            elif status=='stale':qs=qs.filter(Q(checked_at__lt=cutoff)|Q(checked_at__isnull=True))
            else:raise ValidationError('Invalid service status.')
        elif resource in ('companies','users'):qs=qs.filter(is_active=status=='active')
        else:raise ValidationError('This collection does not support a status filter.')
    severity=params.get('severity','')
    if severity:
        if resource!='alerts':raise ValidationError('Severity is only available for alerts.')
        qs=qs.filter(severity=severity)
    device_type=params.get('type','')
    if device_type:
        if resource!='devices':raise ValidationError('Equipment type is only available for devices.')
        qs=qs.filter(device_type=device_type)
    attention=params.get('attention','')
    if attention:
        if resource=='devices' and attention=='needs_attention':qs=qs.filter(connection_status__in=['offline','never_reported'])
        elif resource=='alerts' and attention=='unresolved':qs=qs.exclude(status__in=['resolved','false_positive'])
        elif resource=='maintenance' and attention in ['overdue','due_soon']:
            qs=qs.exclude(status__in=['completed','cancelled'])
            now=timezone.now()
            qs=qs.filter(scheduled_date__lt=now) if attention=='overdue' else qs.filter(scheduled_date__gte=now,scheduled_date__lte=now+timedelta(days=7))
        else:raise ValidationError('Invalid attention filter.')
    dates = {}
    for key, suffix in [('from','gte'),('to','lte')]:
        raw = params.get(key,'')
        if raw:
            if resource not in DATE:raise ValidationError('This collection does not support a date filter.')
            try:parsed=parse_date(raw)
            except ValueError:parsed=None
            if parsed is None:raise ValidationError('Use YYYY-MM-DD for dates.')
            dates[key]=parsed
            qs=qs.filter(**{DATE[resource]+'__date__'+suffix:parsed})
    if dates.get('from') and dates.get('to') and dates['from']>dates['to']:
        raise ValidationError('The end date must follow the start date.')
    sorts={
        'devices':{'name':'name','oldest_reading':'last_ping','newest':'-created_at','company':'company__name'},
        'companies':{'name':'name','newest':'-created_at'},
        'alerts':{'newest':'-triggered_at','oldest':'triggered_at'},
        'maintenance':{'soonest':'scheduled_date','latest':'-scheduled_date'},
        'reports':{'newest':'-generated_at','oldest':'generated_at'},
    }
    sort=params.get('sort','')
    if sort and sort not in sorts.get(resource,{}):raise ValidationError('Invalid sort order.')
    return qs.order_by(sorts.get(resource,{}).get(sort,ORDER[resource]), 'pk')


def rows(resource, qs):
    result = list(qs.values(*FIELDS[resource]))
    if resource == 'health':
        for row in result:row['stale'] = not row['checked_at'] or row['checked_at'] < timezone.now()-timedelta(minutes=15)
    if resource == 'devices':
        for row in result:row['mqtt_client_id'] = mqtt_client_id(row['id'])
    if resource == 'reports':
        companies = dict(model('companies').objects.filter(pk__in={r['business_id'] for r in result}).values_list('id','name'))
        for row in result:row['company_name'] = companies.get(row['business_id'],'Unavailable company')
    if resource == 'companies' and result:
        counts = {r['company_id']:r for r in devices().filter(company_id__in=[r['id'] for r in result]).order_by().values('company_id').annotate(total=Count('id'),online=Count('id',filter=Q(connection_status='online')))}
        for row in result:
            count=counts.get(row['id'],{})
            row.update(device_count=count.get('total',0),online_count=count.get('online',0))
    return result


def audit(request, action, resource=''):
    AccessEvent.objects.create(user=request.user,action=action,resource=resource,
                              filters={k:request.query_params[k][:120] for k in ('company','q','status','from','to','type','attention','sort','days','severity') if k in request.query_params})


def connection_counts(queryset):
    return dict(queryset.order_by().values('connection_status').annotate(total=Count('id')).values_list('connection_status','total'))


class Overview(AdminView):
    def get(self, request):
        scope = {'company':request.query_params.get('company','')}
        fleet = filtered('devices',scope)
        counts = connection_counts(fleet)
        alerts = filtered('alerts',scope)
        work = filtered('maintenance',scope)
        now = timezone.now()
        health = list(model('health').objects.values(*FIELDS['health']))
        for check in health:check['stale'] = not check['checked_at'] or check['checked_at'] < now-timedelta(minutes=15)
        audit(request,'view','overview')
        return Response({'generated_at':now,'counts':{
            'companies':filtered('companies',scope).count(),'devices':fleet.count(),
            'online':counts.get('online',0),'offline':counts.get('offline',0),
            'inactive':counts.get('inactive',0),'never_reported':counts.get('never_reported',0),
            'active_alerts':alerts.exclude(status__in=['resolved','false_positive']).count(),
            'overdue_maintenance':work.exclude(status__in=['completed','cancelled']).filter(scheduled_date__lt=now).count(),
            'reports':filtered('reports',scope).count()},
            'device_types':list(fleet.values('device_type').annotate(total=Count('id')).order_by('-total')),
            'companies':rows('companies',filtered('companies',scope)[:100]),
            'recent_alerts':rows('alerts',alerts[:6]),'health':health})


class Records(AdminView):
    def get(self, request, resource):
        qs=filtered(resource,request.query_params)
        try:
            page=int(request.query_params.get('page',1)); size=int(request.query_params.get('page_size',25))
            if not 1<=page<=100000 or not 1<=size<=100:raise ValueError()
        except (TypeError,ValueError):raise ValidationError('Invalid pagination.')
        audit(request,'view',resource)
        return Response({'count':qs.count(),'page':page,'page_size':size,'results':rows(resource,qs[(page-1)*size:page*size]),'generated_at':timezone.now()})


class Detail(AdminView):
    def get(self, request, resource, pk):
        qs=filtered(resource,{})
        try:obj=get_object_or_404(qs,pk=pk)
        except (ValueError,DjangoValidationError):raise ValidationError('Invalid record identifier.')
        row=rows(resource,qs.filter(pk=obj.pk))[0]
        if resource=='devices':
            from device.registry import family
            fam=family(obj.device_type)
            row.update(mqtt_username=obj.device_id,mqtt_topic=fam.data_topic(obj.device_id) if fam else None,
                       mqtt_port=8883,mqtt_tls=True,
                       identity_note='Phone setup sends this assigned ID automatically with the device’s own login. The ID is a label, not a password. Compatible firmware saves these settings; you do not type a different ID into each firmware build.')
        if resource=='reports':row['report_data']=obj.report_data
        audit(request,'detail',resource)
        return Response(row)


class Export(AdminView):
    def get(self, request, resource):
        qs=filtered(resource,request.query_params)
        if qs.count()>10000:raise ValidationError('Narrow the filters to 10,000 records or fewer before exporting.')
        result=rows(resource,qs)
        fields=list(FIELDS[resource])
        for extra in ('mqtt_client_id','company_name','device_count','online_count'):
            if result and extra in result[0]:fields.append(extra)
        stream=io.StringIO();writer=csv.writer(stream);writer.writerow(fields)
        for row in result:writer.writerow([csv_cell(row.get(k)) for k in fields])
        audit(request,'export',resource)
        response=HttpResponse('\ufeff'+stream.getvalue(),content_type='text/csv; charset=utf-8')
        response['Content-Disposition']=f'attachment; filename="artic-sentinel-{resource}-{timezone.now():%Y%m%d}.csv"'
        return response


class Insights(AdminView):
    def get(self, request):
        from .insights import build_insights
        result=build_insights(request.query_params)
        audit(request,'view','insights')
        return Response(result)
