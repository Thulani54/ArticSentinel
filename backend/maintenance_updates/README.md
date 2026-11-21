# Maintenance access and workflow patch

`install.py <host-project-root>` installs `maintenance/access.py` and makes small,
syntax-checked changes to the existing maintenance handlers. Changed source files
receive timestamped backups. Running the installer twice leaves source unchanged.
It also protects `services.mqtt_data_service.MaintenanceReportView`, which serves
`GET /api/maintenance/report/`; this report is separate from `maintenance/reports.py`.

The boundary authenticates through the configured DRF authenticators and enforces
company membership for records, schedules, checklists, observations and reports.
Actors come from the authenticated profile. Only active members can be assigned.
Status actions enforce start → complete, block incomplete critical checklist items,
and reject terminal-state transitions. Direct edits cannot supply actual work times
or a performer to bypass completion. Writes and checklist changes hold a parent
record lock; failed legacy handler responses roll back partial writes.

Maintenance and schedule create payloads may include `client_request_id`, a UUID
retained by the app until its form fields change. That UUID becomes the row ID.
Same-payload retries return the existing row with status 201; collisions or changed
payloads return 409. There is no schema migration. Older clients without the UUID
retain ordinary create behavior. Request IDs must not be reused for another form.

Schedule generation locks due schedules and excludes due dates after their end
date. Updating a frequency recalculates the next date. Existing duplicate schedules
return a clear conflict instead of a generic server error.

## Isolated tests

Run `python backend/maintenance_updates/run_tests.py /path/to/snapshots` in a Python
environment with Django and Django REST Framework. The runner uses disposable
SQLite, local-only users/devices, in-memory email and these captured source files:

- `artic-maintenance-models.py`
- `artic-maintenance-views.py`
- `artic-maintenance-reports.txt`
- `artic-maintenance-report-class-complete.py`

The last file contains only the complete `MaintenanceReportView` class. The runner
adds its imports, applies the installer twice, then exercises the actual patched
handlers and models. No production settings, credentials, database or email are
used. Analytics tests verify authorization before executing the actual class and
assert all ten SQL queries retain the authorized company parameter using a fake
report cursor. PostgreSQL aggregate semantics and row-lock contention still need
integration verification on PostgreSQL; SQLite cannot prove those behaviors.
