import ast
from pathlib import Path
p=Path('tmp/email-repair-20261108/maintenance_tasks.original.py');s=p.read_text();lines=s.splitlines(keepends=True)
f=next(f for f in ast.parse(s).body if isinstance(f,ast.FunctionDef) and f.name=='_send_email_direct')
replacement='''def _send_email_direct(subject, text_content, html_content, recipients, maintenance_id=None, device_id=None, reminder_type=None):
    """Use the authenticated, certificate-verified application email backend."""
    from django.core.mail import EmailMultiAlternatives
    headers = {'X-Mailer': 'Artic Sentinel Monitoring System'}
    for key, value in [('X-Maintenance-ID', maintenance_id), ('X-Device-ID', device_id), ('X-Reminder-Type', reminder_type)]:
        if value is not None:
            headers[key] = str(value)
    try:
        email = EmailMultiAlternatives(subject, text_content, settings.DEFAULT_FROM_EMAIL, recipients, headers=headers)
        email.attach_alternative(html_content, 'text/html')
        return email.send(fail_silently=False) == 1
    except Exception as exc:
        logger.error('Maintenance email failed: %s code=%s', type(exc).__name__, getattr(exc, 'smtp_code', None))
        return False
'''
s=''.join(lines[:f.lineno-1])+replacement+''.join(lines[f.end_lineno:])
compile(s,'maintenance/tasks.py','exec')
Path('tmp/email-repair-20261108/maintenance_tasks.patched.py').write_text(s)
