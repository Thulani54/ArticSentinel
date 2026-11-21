"""Isolated SQLite host: no production settings, email, telemetry or accounts."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'test_host'))
SECRET_KEY = 'device-journal-isolated-tests'
INSTALLED_APPS = ['django.contrib.auth', 'django.contrib.contenttypes', 'rest_framework', 'company', 'device', 'alerts', 'device_journal']
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
ROOT_URLCONF = 'device_journal.urls'
USE_TZ = True
TIME_ZONE = 'Africa/Johannesburg'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
MIGRATION_MODULES = {'company': None, 'device': None, 'alerts': None, 'device_journal': None}
