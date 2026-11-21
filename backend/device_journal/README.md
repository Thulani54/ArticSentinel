# Device journal and alert collaboration

This Django supplement adds persisted cylinder refill purchases, read-only bottle scan history from Timescale and collaborative alert assignment/notes/resolution.

## Install in the existing host

Copy `device_journal/` beside `manage.py`, then use the host's Python environment:

```sh
python device_journal/install.py exvr
python manage.py check
python manage.py migrate device_journal
```

Restart the API service after validation. Installer makes timestamped settings/URL backups and is repeatable. No Celery tasks, email delivery or firmware changes are needed. The only new database tables are `CylinderRefill`, `AlertTeamState` and `AlertTeamEvent`. Resolving through the team endpoint updates the existing Alert status and timestamp atomically with its resolution note.

## API contracts

All endpoints under `/api/device-journal/` require authentication and verify primary or secondary business membership against the actual device/alert. Superusers may access devices but assignee choices require both an active account and an active business profile. Inactive profiles cannot access the journal.

- `GET devices/<numeric-pk>/refills/?month=YYYY-MM&offset=0`: month totals (`total_cost`, `purchased_kg`, `count`) and 50 records; `next_offset` is null when complete.
- `POST devices/<numeric-pk>/refills/`: `request_id` UUID, `purchased_on` YYYY-MM-DD, `gas_kg`, `cost` in ZAR, optional `supplier`, `notes`, `kind` (`refill` default or `cylinder_change`), `capacity_kg` and `tare_kg` configuration snapshot. Numbers use at most two decimals; gas 0.01–200 kg for refill purchases (0 is allowed for a cylinder change without a purchase), nonnegative cost, no future purchase dates. Retries with identical UUID/body return the original entry. Conflicting UUID reuse returns 409. Logging a purchase does not change scale telemetry, gas configuration or alert thresholds.
- `GET devices/<numeric-pk>/scans/?from=YYYY-MM-DD&to=YYYY-MM-DD&q=...&result=all|verified|failed&offset=0`: up to 50 raw recorded scan readings. Empty code telemetry is excluded. Date range up to 90 days; database retention is 90 days. Filters are applied in SQL with bound parameters. Only code, time, verification result, direction, manufacturer, temperature and tray weights are returned, never `auth_key`. Unknown verification stays unknown. Code repetitions are retained because firmware does not expose a unique scan-event identifier; the UI describes recorded scans, not inferred unique bottles.
- `GET alerts/<id>/team/`: authoritative status, assignment, revision, active members and latest 30 team events.
- `PATCH alerts/<id>/team/`: `revision`, `action` (`assign`, `note`, `resolve`), optional `assigned_to` auth-user ID/null, `note`. Notes and resolution require 5–2000 characters. Revision mismatches return409; the user reloads before retrying. Actor attribution is server-derived. Assignment changes, handovers and resolution are auditable. No messages are sent by team actions.

Existing legacy alert endpoints are not removed by this supplement; the Flutter details screen uses the team resolution endpoint to require a resolution note. Other clients can still use existing legacy behavior.

## Mobile entry points

Gas detail → **Refill history** → **Log refill or cylinder change**. Choose the entry type; a cylinder change can record 0 purchased kilograms/cost and optionally its capacity and empty weight. The existing saved configuration prefills that snapshot when available. Apply configuration changes separately with **Switch gas**; closing/cancelling the history form never changes configuration or writes a journal entry. Month summary separates receipt spending/purchased kilograms from observed scale consumption (available readings only, following existing 48-hour gap policy). Older months may have purchases but no retained telemetry.

Bottle device dashboard/performance → **Bottle scan history**. Search by code, filter verified/failed and choose date range.

Alert details → **Team activity**. Select a responsible person, save assignment, add handover notes, or resolve with a note. Phone inputs stack vertically; refill form fills the phone screen, desktop uses a constrained dialog.

## Verification

```sh
PYTHONPATH=backend DJANGO_SETTINGS_MODULE=device_journal.test_settings python -m django test device_journal.test_api
flutter test test/device_journal_test.dart test/device_journal_api_test.dart
```

Django tests use SQLite in-memory and a small isolated host model fixture under `test_host`; they never import production settings or contact a device/database/mail server. Tests cover tenant boundaries, secondary membership, validation, duplicate retries, actor attribution, optimistic conflicts, atomic resolution and bound scan queries. Flutter tests mock HTTP/services and exercise save/retry, forms, scan filters, empty/error views, team assignment and resolution. Physical scales/bottle machines and real end-user alert actions are not modified by these tests.
