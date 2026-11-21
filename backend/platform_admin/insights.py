"""Scoped operational analytics derived from stored events, never simulated uptime."""
from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo
from django.db.models import Count, Q
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework.exceptions import ValidationError

ZONE = ZoneInfo('Africa/Johannesburg')
CLOSED_ALERTS = ['resolved','false_positive']
CLOSED_WORK = ['completed','cancelled']


def build_insights(params):
    from .views import filtered, rows
    try:
        days = int(params.get('days',30))
        if days not in (7,30,90):raise ValueError()
    except (ValueError,TypeError):raise ValidationError('Choose 7, 30 or 90 days.')
    now = timezone.now()
    today = now.astimezone(ZONE).date()
    first = today-timedelta(days=days-1)
    start = datetime.combine(first,time.min,tzinfo=ZONE)
    scope = {'company':params.get('company','')}
    fleet, alerts, work, reports, companies = [filtered(key,scope) for key in ('devices','alerts','maintenance','reports','companies')]
    active_alerts = alerts.exclude(status__in=CLOSED_ALERTS)
    open_work = work.exclude(status__in=CLOSED_WORK)
    overdue = open_work.filter(scheduled_date__lt=now)
    due_soon = open_work.filter(scheduled_date__gte=now,scheduled_date__lte=now+timedelta(days=7))
    daily = {(first+timedelta(days=n)).isoformat():{'date':(first+timedelta(days=n)).isoformat(),'alerts':0,'resolved':0,'reports':0,'completed_maintenance':0} for n in range(days)}
    for queryset,field,metric in [(alerts,'triggered_at','alerts'),(alerts.filter(status='resolved'),'resolved_at','resolved'),(reports.filter(status='completed'),'generated_at','reports'),(work.filter(status='completed'),'actual_end_date','completed_maintenance')]:
        values=queryset.filter(**{field+'__gte':start,field+'__lte':now}).order_by().annotate(day=TruncDate(field,tzinfo=ZONE)).values('day').annotate(total=Count('pk'))
        for row in values:
            key=row['day'].isoformat()
            if key in daily:daily[key][metric]=row['total']
    fleet_groups = {x['company_id']:x for x in fleet.order_by().values('company_id').annotate(total=Count('pk'),online=Count('pk',filter=Q(connection_status='online')),offline=Count('pk',filter=Q(connection_status='offline')),never_reported=Count('pk',filter=Q(connection_status='never_reported')),inactive=Count('pk',filter=Q(connection_status='inactive')))}
    alert_groups = {x['company_id']:x for x in active_alerts.order_by().values('company_id').annotate(alerts=Count('pk'),critical=Count('pk',filter=Q(severity='critical')))}
    work_groups = dict(overdue.order_by().values('device__company_id').annotate(total=Count('pk')).values_list('device__company_id','total'))
    comparisons=[]
    for company in companies.values('id','name'):
        group=fleet_groups.get(company['id'],{})
        item={'id':company['id'],'name':company['name'],**{key:group.get(key,0) for key in ('total','online','offline','never_reported','inactive')},'alerts':alert_groups.get(company['id'],{}).get('alerts',0),'critical_alerts':alert_groups.get(company['id'],{}).get('critical',0),'overdue':work_groups.get(company['id'],0)}
        active=item['total']-item['inactive']
        item['coverage_pct']=round(item['online']/active*100,1) if active else None
        comparisons.append(item)
    comparisons.sort(key=lambda x:(-x['critical_alerts'],-x['offline']-x['never_reported'],-x['overdue'],-x['alerts'],x['name'].casefold()))
    attention=[]
    for row in active_alerts.filter(severity__in=['critical','high']).order_by('-triggered_at').values('id','title','severity','company_id','company__name','device__name','triggered_at')[:5]:
        attention.append({'id':'alert-'+str(row['id']),'title':row['title'],'company':row['company__name'],'device':row['device__name'],'reason':row['severity'].title()+' unresolved alert','time':row['triggered_at'],'tab':'alerts','company_id':row['company_id'],'attention':'unresolved'})
    for row in fleet.filter(connection_status__in=['offline','never_reported']).order_by('last_ping','pk').values('id','name','company_id','company__name','last_ping','connection_status')[:5]:
        attention.append({'id':'device-'+str(row['id']),'title':row['name'],'company':row['company__name'],'device':row['name'],'reason':'Not reporting' if row['last_ping'] else 'Never reported','time':row['last_ping'],'tab':'devices','company_id':row['company_id'],'attention':'needs_attention'})
    for row in overdue.order_by('scheduled_date').values('id','device__name','device__company_id','device__company__name','maintenance_type__name','scheduled_date')[:5]:
        attention.append({'id':'work-'+str(row['id']),'title':row['maintenance_type__name'],'company':row['device__company__name'],'device':row['device__name'],'reason':'Overdue maintenance','time':row['scheduled_date'],'tab':'maintenance','company_id':row['device__company_id'],'attention':'overdue'})
    return {'generated_at':now,'days':days,'timezone':str(ZONE),'period_start':first,'period_end':today,
            'activity':list(daily.values()),'totals':{key:sum(x[key] for x in daily.values()) for key in ('alerts','resolved','reports','completed_maintenance')},
            'companies':comparisons[:20],'company_count':len(comparisons),'attention':attention,
            'upcoming':rows('maintenance',due_soon.order_by('scheduled_date')[:6]),
            'backlog':{'critical_alerts':active_alerts.filter(severity='critical').count(),'unresolved_alerts':active_alerts.count(),'overdue_maintenance':overdue.count(),'due_next_7_days':due_soon.count(),
                       'devices_not_reporting':fleet.filter(connection_status__in=['offline','never_reported']).count()},
            'coverage_note':'Current reporting coverage uses active devices and each device’s offline grace period. It is not historical uptime.'}
