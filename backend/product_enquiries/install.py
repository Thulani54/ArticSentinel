"""Install only this app's settings and URL mount into an existing Django host.

Usage: python product_enquiries/install.py PROJECT_DIR ADMIN_EMAIL_1 ADMIN_EMAIL_2
Run migrations and restart affected services separately after reviewing checks.
"""
import ast
import sys
from datetime import datetime, timezone
from pathlib import Path


def write_with_backup(path, content):
    original = path.read_text()
    if content == original:
        return
    ast.parse(content)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    path.with_suffix(f'.py.before-product-enquiries-{stamp}').write_text(original)
    path.write_text(content)


def install(project, recipients):
    if len(recipients) != 2 or any('@' not in item for item in recipients):
        raise ValueError('Provide both administrator email addresses.')
    settings_path = project / 'settings.py'
    settings = settings_path.read_text()
    marker = '# Product enquiries: durable requests and administrator notifications.'
    if marker not in settings:
        settings += '\n\n' + marker + '\n'
        settings += "INSTALLED_APPS += ['product_enquiries.apps.ProductEnquiriesConfig']\n"
        settings += f'PRODUCT_ENQUIRY_RECIPIENTS = {tuple(recipients)!r}\n'
        settings += '# The API nginx proxy overwrites X-Real-IP on every request.\n'
        settings += 'PRODUCT_ENQUIRY_TRUST_REAL_IP = True\n'
        settings += "CELERY_BEAT_SCHEDULE['product-enquiry-delivery'] = {\n"
        settings += "    'task': 'product_enquiries.tasks.deliver_pending', 'schedule': 60.0,\n}\n"
        write_with_backup(settings_path, settings)
    urls_path = project / 'urls.py'
    urls = urls_path.read_text()
    if "include('product_enquiries.urls')" not in urls:
        if urls.count('urlpatterns = [') != 1:
            raise ValueError('Inspect URL configuration before installing.')
        urls = urls.replace('urlpatterns = [', "urlpatterns = [\n    path('api/products/', include('product_enquiries.urls')),")
        write_with_backup(urls_path, urls)
    print('Product enquiry settings and URL mount are installed; migrate and restart next.')


if __name__ == '__main__':
    install(Path(sys.argv[1]), sys.argv[2:])
