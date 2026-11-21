"""Install a reviewed source bundle on the server. No email is sent here."""
from pathlib import Path
import shutil
root=Path('/home/vmrvsnyo/exvr')
bundle=Path('/home/vmrvsnyo/email-repair-20261108')
backup=Path('/home/vmrvsnyo/.codex-backups/email-repair-20261108')
backup.mkdir(mode=0o700,parents=True,exist_ok=True)
for name in ['alerts/tasks.py','maintenance/tasks.py','exvr/email_backend.py','exvr/settings.py','communication/models.py']:
 target=backup/name
 target.parent.mkdir(parents=True,exist_ok=True)
 if not target.exists():shutil.copy2(root/name,target);target.chmod(0o600)
assert (root/'alerts/tasks.py').read_bytes()==(bundle/'alerts_tasks.original.py').read_bytes()
assert (root/'maintenance/tasks.py').read_bytes()==(bundle/'maintenance_tasks.original.py').read_bytes()
shutil.copy2(bundle/'alerts_tasks.patched.py',root/'alerts/tasks.py')
shutil.copy2(bundle/'maintenance_tasks.patched.py',root/'maintenance/tasks.py')
shutil.copy2(bundle/'email_backend.py',root/'exvr/email_backend.py')
shutil.copytree(bundle/'scale_connections',root/'scale_connections',dirs_exist_ok=True)
p=root/'exvr/settings.py';s=p.read_text()
if "INSTALLED_APPS += ['scale_connections']" not in s:
 s += "\n# Verified mail transport and durable scale connection alerts (2026-11-08).\nINSTALLED_APPS += ['scale_connections']\nEMAIL_BACKEND = 'exvr.email_backend.VerifiedEmailBackend'\nEMAIL_TLS_SERVER_NAME = 'arno.aserv.co.za'\nEMAIL_TIMEOUT = 20\n"
 p.write_text(s)
p=root/'communication/models.py';s=p.read_text()
if "('device_online', 'Device Back Online')" not in s:
 s=s.replace("        ('device_offline', 'Device Offline'),", "        ('device_offline', 'Device Offline'),\n        ('device_online', 'Device Back Online'),",1)
 p.write_text(s)
print('Source installed; run migration/checks before restarting workers.')
