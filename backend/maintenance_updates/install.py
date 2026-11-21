"""Install reviewed maintenance guards without replacing unrelated host code."""
import ast
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path


def patch_file(path, transform):
    source = path.read_text()
    updated = transform(source)
    ast.parse(updated)
    if source != updated:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        path.with_suffix('.py.before-mobile-maintenance-' + stamp).write_text(source)
        path.write_text(updated)


def wrap(source):
    if '# Scoped mobile maintenance access.' in source:
        return source
    functions = [n.name for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.decorator_list and any('require_http_methods' in ast.unparse(d) for d in n.decorator_list)]
    return source + '\n\n# Scoped mobile maintenance access.\nfrom .access import maintenance_access\n' + '\n'.join(f'{name} = maintenance_access({name})' for name in functions) + '\n'


def install(root):
    target = root / 'maintenance'
    shutil.copy2(Path(__file__).with_name('access.py'), target / 'access.py')
    def views(source):
        source = source.replace("created_by_id=request.user.id if hasattr(request, 'user') else None,", "created_by_id=getattr(getattr(request.user, 'profile', None), 'pk', None),")
        source = source.replace('due_schedules = MaintenanceSchedule.objects.filter(', 'due_schedules = MaintenanceSchedule.objects.select_for_update().filter(')
        for name in ('DeviceMaintenance', 'MaintenanceSchedule'):
            original = ('maintenance' if name == 'DeviceMaintenance' else 'schedule') + f' = {name}.objects.create(\n            device=device,'
            patched = original.replace('            device=device,', "            id=data.get('client_request_id') or uuid.uuid4(),\n            device=device,")
            if original in source:
                source = source.replace(original, patched)
        if not any(isinstance(n, ast.Import) and any(alias.name == 'uuid' for alias in n.names) for n in ast.parse(source).body):
            source = 'import uuid\n' + source
        if "Q(end_date__gte=F('next_due'))" not in source:
            source = source.replace("next_due__lte=date.today()\n        )", "next_due__lte=date.today()\n        ).filter(Q(end_date__isnull=True) | Q(end_date__gte=F('next_due')))")
        if not any(isinstance(n, ast.ImportFrom) and n.module == 'django.db.models' and any(alias.name == 'F' for alias in n.names) for n in ast.parse(source).body):
            source = 'from django.db.models import F\n' + source
        source = source.replace('        schedule.save()\n\n        return JsonResponse', "        if 'frequency' in data or 'custom_frequency_days' in data:\n            schedule.next_due = schedule.calculate_next_due_date(schedule.last_generated or schedule.start_date)\n        schedule.save()\n\n        return JsonResponse") if 'schedule.next_due = schedule.calculate_next_due_date(schedule.last_generated' not in source else source
        return wrap(source)
    patch_file(target / 'views.py', views)
    patch_file(target / 'reports.py', wrap)
    report_service = root / 'services' / 'mqtt_data_service.py'
    if report_service.exists():
        def report_guard(source):
            marker = '# Scoped maintenance summary API.'
            if marker in source:
                return source
            if not any(isinstance(n, ast.ClassDef) and n.name == 'MaintenanceReportView' for n in ast.parse(source).body):
                raise RuntimeError('MaintenanceReportView not found; inspect this host before patching.')
            return source + '\n\n' + marker + '\nfrom django.utils.decorators import method_decorator as _maintenance_method_decorator\nfrom maintenance.access import maintenance_access as _maintenance_access\nMaintenanceReportView.dispatch = _maintenance_method_decorator(_maintenance_access)(MaintenanceReportView.dispatch)\n'
        patch_file(report_service, report_guard)
    print('Maintenance authentication, business scope and workflow guards installed.')

if __name__ == '__main__':
    install(Path(sys.argv[1]))
