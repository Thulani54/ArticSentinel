"""Only an in-memory test host; never reads the deployed Django settings."""
from device_journal.test_settings import *
import sys
import types
module = types.ModuleType('device.gas_views')
def can_access(user, company):
    if user.is_superuser:
        return True
    profile = getattr(user, 'profile', None)
    return profile is not None and (profile.business_id == company.pk or profile.secondary_businesses.filter(pk=company.pk).exists())
module._user_can_access = can_access
sys.modules['device.gas_views'] = module
INSTALLED_APPS = [*INSTALLED_APPS, 'mobile_push']
MIGRATION_MODULES = {**MIGRATION_MODULES, 'mobile_push': None}
ROOT_URLCONF = 'mobile_push.diagnostics_test_urls'
