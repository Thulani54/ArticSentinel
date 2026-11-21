"""Mount the journal app; run migrations/restart separately after checking."""
import ast
import sys
from datetime import datetime, timezone
from pathlib import Path

def save(path, value):
    old = path.read_text()
    if old == value:
        return
    ast.parse(value)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    path.with_suffix(f'.py.before-device-journal-{stamp}').write_text(old)
    path.write_text(value)

def install(project):
    settings_file = project / 'settings.py'
    settings = settings_file.read_text()
    marker = '# Device journal: refill records, scan history and team alert actions.'
    if marker not in settings:
        settings += '\n\n' + marker + "\nINSTALLED_APPS += ['device_journal.apps.DeviceJournalConfig']\n"
        save(settings_file, settings)
    urls_file = project / 'urls.py'
    urls = urls_file.read_text()
    if "include('device_journal.urls')" not in urls:
        if urls.count('urlpatterns = [') != 1:
            raise ValueError('Inspect urlpatterns before installing.')
        urls = urls.replace('urlpatterns = [', "urlpatterns = [\n    path('api/device-journal/', include('device_journal.urls')),")
        save(urls_file, urls)

if __name__ == '__main__':
    install(Path(sys.argv[1]))
