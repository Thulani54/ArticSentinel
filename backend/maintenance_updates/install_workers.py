"""Install the reviewed worker guards without changing templates or settings."""
import ast
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

MARKER = '# Serialized maintenance reminder delivery.'


def patch_tasks(source):
    if MARKER in source:
        return source
    ast.parse(source)
    old = "@shared_task(bind=True, max_retries=3)\ndef send_maintenance_reminder_email("
    new = "@shared_task(bind=True, max_retries=3)\n@serialize_reminder_delivery\ndef send_maintenance_reminder_email("
    if source.count(old) != 1:
        raise RuntimeError('Expected reminder task definition not found; inspect host source.')
    source = source.replace(old, new, 1)
    old = """                # Update status to overdue if not already
                if maintenance.status != 'overdue':
                    maintenance.status = 'overdue'
                    maintenance.save(update_fields=['status'])"""
    new = """                # Recheck the current row after an atomic conditional update.
                if not mark_overdue_if_due(maintenance, now):
                    continue"""
    if source.count(old) != 1:
        raise RuntimeError('Expected overdue transition not found; inspect host source.')
    source = source.replace(old, new, 1)
    old = """                        # Update status to overdue if not already
                        if maintenance.status != 'overdue':
                            maintenance.status = 'overdue'
                            maintenance.save(update_fields=['status'])"""
    new = """                        # Never regress work already started or closed.
                        if not mark_overdue_if_due(maintenance, now):
                            continue"""
    if source.count(old) != 1:
        raise RuntimeError('Expected legacy repair transition not found; inspect host source.')
    source = source.replace(old, new, 1)
    old = "status__in=['scheduled', 'overdue', 'in_progress']"
    if source.count(old) != 1:
        raise RuntimeError('Expected legacy reminder status filter not found.')
    source = source.replace(old, "status__in=['scheduled', 'overdue']", 1)
    # A successful sendmail means accepted recipients must not get a second
    # message merely because closing the SMTP connection failed.
    if source.count('        server.quit()') != 2:
        raise RuntimeError('Expected two SMTP close points; inspect host source.')
    source = source.replace('        server.quit()', '''        try:
            server.quit()
        except Exception:
            try:
                server.close()
            except Exception:
                pass''')
    source = MARKER + '\nfrom .worker_guards import serialize_reminder_delivery, mark_overdue_if_due\n' + source
    ast.parse(source)
    return source


def install(root):
    target = root / 'maintenance' / 'tasks.py'
    source = target.read_text()
    updated = patch_tasks(source)
    if source != updated:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        target.with_suffix('.py.before-reminder-guards-' + stamp).write_text(source)
    shutil.copy2(Path(__file__).with_name('worker_guards.py'), target.with_name('worker_guards.py'))
    if source != updated:
        target.write_text(updated)
    print('Maintenance reminder guards installed; restart the Celery worker to load them.')


if __name__ == '__main__':
    install(Path(sys.argv[1]))
