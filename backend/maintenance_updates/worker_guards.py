"""Serialize existing maintenance reminder delivery with API lifecycle changes.

The lock deliberately covers SMTP and the sent flag. This prevents concurrent
jobs duplicating a successful send, but cannot provide exactly-once delivery if
SMTP accepts a message and the process dies before the database commits.
"""
from functools import wraps
import uuid

from django.db import transaction
from django.utils import timezone
from .models import DeviceMaintenance

REMINDER_FLAGS = {
    'three_day': 'three_day_reminder_sent',
    'two_day': 'two_day_reminder_sent',
    'day_before': 'day_before_reminder_sent',
    'upcoming': 'reminder_sent',
    'overdue': 'overdue_reminder_sent',
    'overdue_day2': 'overdue_day2_reminder_sent',
    'overdue_day3': 'overdue_day3_reminder_sent',
}


def serialize_reminder_delivery(send):
    @wraps(send)
    def checked(task, maintenance_id, reminder_type='upcoming'):
        flag = REMINDER_FLAGS.get(reminder_type)
        if flag is None:
            return False
        try:
            maintenance_id = uuid.UUID(str(maintenance_id))
        except (ValueError, TypeError, AttributeError):
            return False
        try:
            with transaction.atomic():
                # No select_related here: locking a nullable joined assignee
                # fails on PostgreSQL. This is the same parent row as API locks.
                maintenance = DeviceMaintenance.objects.select_for_update().get(pk=maintenance_id)
                now = timezone.now()
                overdue = reminder_type.startswith('overdue')
                eligible = (
                    maintenance.status in {'scheduled', 'overdue'} and maintenance.scheduled_date <= now
                    if overdue else maintenance.status == 'scheduled' and maintenance.scheduled_date > now
                )
                if not eligible or getattr(maintenance, flag):
                    return False
                # The existing function loads relations and records success on
                # this connection, while the parent row remains locked.
                return send(task, maintenance_id, reminder_type=reminder_type)
        except DeviceMaintenance.DoesNotExist:
            return False
    return checked


def mark_overdue_if_due(maintenance, now=None):
    """Do not let a stale checker overwrite started/completed/cancelled work."""
    now = now or timezone.now()
    DeviceMaintenance.objects.filter(
        pk=maintenance.pk, status='scheduled', scheduled_date__lt=now,
    ).update(status='overdue')
    try:
        maintenance.refresh_from_db()
    except DeviceMaintenance.DoesNotExist:
        return False
    return maintenance.status == 'overdue' and maintenance.scheduled_date < now
