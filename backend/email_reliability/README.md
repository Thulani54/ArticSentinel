# Email reliability repair — 8 November 2026

This repository contains deployment helpers for the existing Django backend on
`/home/vmrvsnyo/exvr`; it is not a second complete copy of that backend.

Deployed changes:
- `email_backend.py` replaces `exvr/email_backend.py` with certificate-verified
  authenticated STARTTLS. `EMAIL_TLS_SERVER_NAME` is the provider's certificate
  identity; it must be independently verified if the hosting service changes.
- `scale_connections/` adds durable connection state/delivery tables and periodic
  gas-scale offline/recovery checks. It does not mutate device activation settings.
- `prepare_alert_patch.py` and `prepare_maintenance_patch.py` generate guarded
  edits from reviewed backend snapshots. Do not capture passwords in committed
  snapshots. The current `tmp/email-repair-20261108` captures are private/untracked.
- `communication_0003_device_online.py` records the deployed template-choice
  migration. `setup_database.py` creates the default recovery template, establishes
  silent baselines and enables the one-minute periodic task.
- `install.py` is a one-time, snapshot-checked installer, not an idempotent upgrade
  tool. It stores before-state source in a restricted server backup directory.

Validation:
- `python3 backend/email_reliability/run_tests.py` runs 20 isolated tests against
  SQLite and in-memory mail. It requires the reviewed patched source snapshots for
  the report/maintenance transport tests; no real broker, database or mail is used.
- `verify_live_rollback.py` was run through Django's shell against PostgreSQL with
  SMTP mocked and all records rolled back.
- One explicitly requested diagnostic email was delivered through Celery and SMTP
  to the user's Gmail inbox; Gmail confirmed SPF, DKIM and DMARC passes.

Connection checks use `offline_timeout` (10 minutes by default). The first reading
establishes a baseline without sending an email. New transitions are recorded
independently of the MQTT online flag, deduplicated by event/recipient, checked for
current membership/preferences, and retried up to five times. Success-only
cooldowns suppress repeated same-state mail for 30 minutes. Messages older than
one hour or superseded by a newer transition are cancelled. A crash between SMTP
acceptance and database commit can still produce a duplicate; SMTP is not an
exactly-once transport.

See `docs/incidents/email-alerts-20261108.md` for deployment, delivery verification
and the separate Redis compromise investigation.
