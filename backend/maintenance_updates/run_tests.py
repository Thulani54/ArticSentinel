"""Run guards against locally captured host handlers/models in disposable SQLite.

Usage: python backend/maintenance_updates/run_tests.py [snapshot_directory]
Snapshot files: artic-maintenance-models.py and artic-maintenance-views.py.
No production settings, database, credentials, network or mail are used.
"""
import os
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
snapshots = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/tmp')

with tempfile.TemporaryDirectory(prefix='artic-maintenance-tests-') as directory:
    root = Path(directory)
    for app in ('company', 'device', 'user', 'maintenance'):
        (root / app).mkdir()
        (root / app / '__init__.py').touch()
    (root / 'company/models.py').write_text('''from django.db import models
class Company(models.Model):
    name = models.CharField(max_length=100)
''')
    (root / 'device/models.py').write_text('''from django.db import models
class Device(models.Model):
    company = models.ForeignKey('company.Company', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    device_id = models.CharField(max_length=100)
    device_type = models.CharField(max_length=30, default='gas_cylinder')
''')
    (root / 'device/gas_views.py').write_text('''def _user_can_access(user, company):
    if user.is_superuser:
        return True
    profile = getattr(user, 'profile', None)
    return profile is not None and (profile.business_id == company.pk or profile.secondary_businesses.filter(pk=company.pk).exists())
''')
    (root / 'user/models.py').write_text('''from django.db import models
from django.conf import settings
class User(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile')
    business = models.ForeignKey('company.Company', on_delete=models.CASCADE)
    secondary_businesses = models.ManyToManyField('company.Company', related_name='secondary_members')
    is_active = models.BooleanField(default=True)
    user_type = models.CharField(max_length=30, default='member')
    def get_full_name(self):
        return self.user.get_full_name()
''')
    shutil.copy2(snapshots / 'artic-maintenance-models.py', root / 'maintenance/models.py')
    shutil.copy2(snapshots / 'artic-maintenance-views.py', root / 'maintenance/views.py')
    # Preserve the actual report module while installing wrappers. PDF rendering
    # is exercised by the app tests; this suite does not send files or mail.
    shutil.copy2(snapshots / 'artic-maintenance-reports.txt', root / 'maintenance/reports.py')
    (root / 'services').mkdir()
    (root / 'services/__init__.py').touch()
    (root / 'services/mqtt_data_service.py').write_text(
        'from datetime import datetime, timedelta\nfrom django.utils import timezone\nfrom rest_framework.views import APIView\nfrom rest_framework.response import Response\nfrom rest_framework import status\n' +
        (snapshots / 'artic-maintenance-report-class-complete.py').read_text())
    sys.path.insert(0, str(HERE))
    from install import install
    install(root)
    first = {str(path): path.read_text() for path in root.rglob('*.py')}
    install(root)
    assert first == {str(path): path.read_text() for path in root.rglob('*.py')}, 'Installer must be idempotent'
    shutil.copy2(HERE / 'tests.py', root / 'maintenance/tests.py')
    (root / 'settings.py').write_text('''SECRET_KEY = 'isolated-maintenance-test-key'
INSTALLED_APPS = ['django.contrib.auth', 'django.contrib.contenttypes', 'rest_framework.authtoken', 'company', 'device', 'user', 'maintenance']
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
MIGRATION_MODULES = {'company': None, 'device': None, 'user': None, 'maintenance': None}
DEFAULT_AUTO_FIELD = 'django.db.models.AutoField'
USE_TZ = True
TIME_ZONE = 'UTC'
REST_FRAMEWORK = {'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework.authentication.TokenAuthentication', 'rest_framework.authentication.SessionAuthentication']}
PASSWORD_HASHERS = ['django.contrib.auth.hashers.MD5PasswordHasher']
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
''')
    sys.path.insert(0, str(root))
    os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
    import django
    django.setup()
    from django.test.runner import DiscoverRunner
    failures = DiscoverRunner(verbosity=2).run_tests(['maintenance.tests'])
    sys.exit(bool(failures))
