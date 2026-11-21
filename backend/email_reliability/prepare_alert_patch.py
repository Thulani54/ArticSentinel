from pathlib import Path
import textwrap
source=Path('tmp/email-repair-20261108/alerts_tasks.original.py').read_text()
s=source
start=s.index('            # Send via SMTP - try port 25 first',s.index('def send_communication_with_template('))
end=s.index('\n        else:\n            logger.error(f"Unsupported communication type:',start)
s=s[:start]+'''            from exvr.email_backend import send_html_email
            try:
                success = send_html_email(recipient, subject or 'Notification', message)
                provider_response = {'transport': 'authenticated_starttls'}
            except Exception as exc:
                success = False
                provider_response = {'error': type(exc).__name__, 'smtp_code': getattr(exc, 'smtp_code', None)}
                logger.error('Verified email transport failed: %s code=%s', type(exc).__name__, getattr(exc, 'smtp_code', None))
'''+s[end:]
for function,end_marker in [('check_no_data_alert','        # --- Alert Generation Logic'),('check_device_sensor_alerts','        # --- SENSOR ALERTS LOGIC')]:
 start=s.index('        # Store previous status to detect changes',s.index('def '+function+'('))
 end=s.index(end_marker,start)
 old=s[start:end]
 replacement='''        if device.device_type == 'gas_cylinder':
            # Scale connection transitions have their own durable state; MQTT
            # writes is_online and must not erase an offline-to-online edge.
            from device.status import is_online
            new_is_online = is_online(device)
            new_is_active = device.is_active
            current_status = 'online' if new_is_online else 'offline'
        else:
'''+textwrap.indent(old,'    ')
 s=s[:start]+replacement+s[end:]
# Generic notification path: failures must not suppress another legitimate attempt.
s=s.replace("            created_at__gte=cooldown_start,\n", "            created_at__gte=cooldown_start,\n            status__in=['sent', 'delivered'],\n",1)
# Recovery templates should not notify inactive login accounts.
s=s.replace("            is_active=True,\n        ).select_related('user').distinct()", "            is_active=True, user__is_active=True,\n        ).select_related('user').distinct()",1)
# Include actual device table mappings rather than reading a fridge table for a scale.
needle="                    'device6': 'device6_data',\n                }"
assert needle in s
s=s.replace(needle,"                    'device6': 'device6_data',\n                    'device7': 'device7_data',\n                    'gas_cylinder': 'gas_cylinder_data',\n                }",1)
compile(s,'alerts/tasks.py','exec')
Path('tmp/email-repair-20261108/alerts_tasks.patched.py').write_text(s)
print('Prepared verified SMTP and independent scale-state patch')
# Route report attachments through the same configured, verified Django backend.
start=s.index('    # Email configurations to try',s.index('def send_enhanced_analytics_pdf_email('))
end=s.index('    try:\n        current_time',start)
s=s[:start]+s[end:]
start=s.index('        # Try each email configuration',s.index('def send_enhanced_analytics_pdf_email('))
end=s.index('    except Exception as e:\n        logger.error(f"Error in email sending function',start)
s=s[:start]+'''        from django.core.mail import EmailMultiAlternatives
        email = EmailMultiAlternatives(subject, text_content, settings.DEFAULT_FROM_EMAIL, recipient_emails)
        email.attach_alternative(html_content, 'text/html')
        if pdf_buffer:
            email.attach(f"arctic_sentinel_3day_analytics_{current_time.strftime('%Y%m%d_%H%M')}.pdf", pdf_buffer, 'application/pdf')
        return email.send(fail_silently=False) == 1

'''+s[end:]
s=s.replace('This email was sent using an improved delivery system with multiple fallback options\n                    to ensure reliable delivery of your Arctic Sentinel reports.', 'This report is sent through the authenticated ArticSentinel email service.')
# The requested new recovery channel is scoped to scales, not all equipment.
start=s.index('def send_device_status_notification(')
pos=s.index('        device = Device.objects.get(id=device_id)',start)+len('        device = Device.objects.get(id=device_id)')
s=s[:pos]+"\n        if status == 'online' and device.device_type != 'gas_cylinder':\n            return\n"+s[pos:]
compile(s,'alerts/tasks.py','exec')
Path('tmp/email-repair-20261108/alerts_tasks.patched.py').write_text(s)
