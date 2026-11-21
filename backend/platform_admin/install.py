"""Install platform routes and add stable client IDs to MQTT setup responses."""
import ast
from pathlib import Path
import shutil
import sys

root=Path(sys.argv[1]); backup=Path(sys.argv[2]);backup.mkdir(parents=True,exist_ok=True,mode=0o700)
for relative in ['exvr/settings.py','exvr/urls.py','device/mqtt_login.py']:
    path=root/relative;old=path.read_text();new=old
    if relative.endswith('settings.py') and 'platform_admin.apps.PlatformAdminConfig' not in old:
        new += "\n# Dedicated platform oversight; company permissions remain separate.\nINSTALLED_APPS += ['platform_admin.apps.PlatformAdminConfig']\n"
    elif relative=='exvr/urls.py' and "include('platform_admin.urls')" not in old:
        assert old.count('urlpatterns = [')==1
        new=old.replace('urlpatterns = [',"urlpatterns = [\n    path('api/platform-admin/', include('platform_admin.urls')),")
    elif relative=='device/mqtt_login.py' and "'mqtt_client_id':" not in old:
        new=old.replace('from . import registry','from . import registry\nfrom platform_admin.policy import mqtt_client_id')
        new=new.replace("'mqtt_host': PUBLIC_HOST,","'mqtt_host': PUBLIC_HOST,\n        'mqtt_client_id': mqtt_client_id(device.pk),")
        new=new.replace("'supported': login_error(device) is None,","'supported': login_error(device) is None,\n        'mqtt_client_id': mqtt_client_id(device.pk),")
        assert new.count("'mqtt_client_id':")==2
    ast.parse(new)
    if new!=old:
        target=backup/relative.replace('/','_')
        if not target.exists():shutil.copy2(path,target);target.chmod(0o600)
        path.write_text(new)
print('Platform routes and MQTT setup identity fields installed.')
