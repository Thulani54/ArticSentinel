"""Isolated SQLite tests: no production settings, telemetry, broker or email."""
import os,sys,tempfile,shutil,ast
from pathlib import Path
HERE=Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='artic-email-tests-') as directory:
 root=Path(directory)
 for name in ['company','device','user','communication','alerts','exvr']:
  (root/name).mkdir();(root/name/'__init__.py').touch()
 (root/'company/models.py').write_text("from django.db import models\nclass Company(models.Model):\n name=models.CharField(max_length=100)\n")
 (root/'device/models.py').write_text('''from django.db import models
class Device(models.Model):
 company=models.ForeignKey('company.Company',on_delete=models.CASCADE)
 name=models.CharField(max_length=100)
 device_id=models.CharField(max_length=100)
 device_type=models.CharField(max_length=30,default='gas_cylinder')
 offline_timeout=models.IntegerField(default=10)
 is_active=models.BooleanField(default=True)
 is_online=models.BooleanField(default=True)
 location=models.CharField(max_length=100,default='Kitchen')
''')
 (root/'device/status.py').write_text('''from datetime import timedelta
from django.utils import timezone
def latest_reading_time(device): raise AssertionError('Telemetry must be mocked')
def is_online_at(latest,device): return latest is not None and timezone.now()-latest<=timedelta(minutes=device.offline_timeout or 10)
''')
 (root/'user/models.py').write_text('''from django.db import models
from django.conf import settings
class User(models.Model):
 user=models.ForeignKey(settings.AUTH_USER_MODEL,on_delete=models.CASCADE)
 business=models.ForeignKey('company.Company',on_delete=models.CASCADE)
 secondary_businesses=models.ManyToManyField('company.Company',related_name='secondary_profiles')
 is_active=models.BooleanField(default=True)
 email_notifications=models.BooleanField(default=True)
''')
 (root/'communication/models.py').write_text('''from django.db import models
class Template(models.Model):
 template_type=models.CharField(max_length=40)
class CommunicationLog(models.Model):
 device=models.ForeignKey('device.Device',on_delete=models.CASCADE)
 recipient=models.EmailField()
 template_used=models.ForeignKey(Template,on_delete=models.CASCADE)
 status=models.CharField(max_length=20)
 sent_at=models.DateTimeField(null=True)
''')
 (root/'alerts/tasks.py').write_text("def send_communication_with_template(**kwargs): raise AssertionError('Email must be mocked')\n")
 source=(HERE.parent.parent/'tmp/email-repair-20261108/alerts_tasks.patched.py').read_text()
 report=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='send_enhanced_analytics_pdf_email')
 with (root/'alerts/tasks.py').open('a') as f:
  f.write('\nimport logging,traceback\nfrom django.conf import settings\nfrom django.utils import timezone\nlogger=logging.getLogger(__name__)\n'+ast.get_source_segment(source,report)+'\n')
 source=(HERE.parent.parent/'tmp/email-repair-20261108/maintenance_tasks.patched.py').read_text()
 maintenance=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='_send_email_direct')
 (root/'maintenance_mail.py').write_text('import logging\nfrom django.conf import settings\nlogger=logging.getLogger(__name__)\n'+ast.get_source_segment(source,maintenance))
 shutil.copytree(HERE/'scale_connections',root/'scale_connections')
 shutil.copy2(HERE/'tests.py',root/'scale_connections/tests.py')
 shutil.copy2(HERE/'email_backend.py',root/'exvr/email_backend.py')
 (root/'settings.py').write_text('''SECRET_KEY='isolated-tests'
INSTALLED_APPS=['django.contrib.auth','django.contrib.contenttypes','company','device','user','communication','scale_connections']
DATABASES={'default':{'ENGINE':'django.db.backends.sqlite3','NAME':':memory:'}}
MIGRATION_MODULES={name:None for name in ['company','device','user','communication','scale_connections']}
USE_TZ=True
TIME_ZONE='UTC'
DEFAULT_AUTO_FIELD='django.db.models.BigAutoField'
EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend'
DEFAULT_FROM_EMAIL='alerts@example.invalid'
PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher']
''')
 sys.path.insert(0,str(root));os.environ['DJANGO_SETTINGS_MODULE']='settings'
 import django;django.setup()
 from django.test.runner import DiscoverRunner
 sys.exit(bool(DiscoverRunner(verbosity=2).run_tests(['scale_connections.tests'])))
