# Historical performance for inactive equipment

`inactive-performance-history.patch` removes only the active-status restriction from the existing `DeviceMetricsView` read. The device/company lookup remains intact and device settings are not changed. This allows the web UI to use the same rich metrics response as Flutter for inactive equipment.

Applied to `/home/vmrvsnyo/exvr/services/mqtt_data_service.py` on 2026-09-25. Original source backup: `/home/vmrvsnyo/backups/uat-website/mqtt-before-inactive-history.py`. Gunicorn workers were gracefully reloaded with HUP. The backend repository is separate from this frontend repository; this patch records the deployed change without including unrelated server changes.

Validation: the metrics view returned HTTP 200 for all 11 non-gas devices in company 1, querying 2026-07-19 through 2026-08-06. D7-001 returned 90 readings with daily and hourly activity. Device1 without data returns synthetic zero buckets, so the frontend checks actual reading counts before displaying analytics.

Existing limitation: device1 maintenance insight generation logs a missing `device_maintenance_urgency_log` table, although the metrics request succeeds. This patch does not alter database schema or maintenance logic.

## Operations parity (2026-09-26)

`operations-actions.patch` restores acknowledge semantics, adds the separate false-positive route, and authenticates role creation with the existing DRF Token/Bearer support. It changes only the affected views/routes and requires a graceful Gunicorn reload. Existing role permissions and company filtering are retained. Validate with mocked alert objects before applying; do not acknowledge real alerts as a smoke test.

## Gas scale server logins (2026-10-01)

`gas-scale-credentials.patch` adds `GasScaleCredential` (migration `device/0019`), `POST /api/gas/credentials/issue/` and `/status/`, and a revoke-on-delete signal. It also records the host side: `/usr/local/sbin/exvr-mqtt-credsync` plus the `exvr-mqtt-credsync.path`/`.service` systemd units. The web container writes a hashed request (`{"username","hash"}` or `{"username","delete":true}`) to `~/exvr/mosquitto/pending`. The host unit merges it into the broker `passwd` file and reloads Mosquitto with HUP, so connected clients stay connected. Plaintext passwords are never written to disk. Backups: `*.bak.20261001` beside each changed file, and `/root/mosquitto-passwd.bak.20261001`.

Validation used a temporary device `CREDTEST-GAS`, not GAS-001, because issuing a login rotates the scale's password. Results: issue returned 200 and a TLS login on 8883 was accepted; a wrong password was refused (code 5); an explicit revoke and deleting the device each removed the login. The passwd file ended with only `gas-bridge` and `GAS-001`.

## Sign-up v2, team members, Google sign-in (2026-10-03)

`signup-team-google-auth.patch` adds `user/team_views.py` with `POST /api/signup/v2/` (account_type company/personal; always creates a NEW company — the old `/api/signup/` joined an existing company when the name matched, which would have granted access to its devices), `GET /api/team/members/` + `POST /api/team/members/add/` (primary contact / administrators / managers only; generated temporary password returned once), and `POST /api/auth/google/` (verifies a Google ID token against `GOOGLE_OAUTH_CLIENT_IDS` from `.env`, links or registers by verified email). `user/views.py`'s login success payload was extracted into `build_login_success_response(user)` and is reused by Google sign-in; password login behaviour is unchanged (verified live). Backups: `user/views.py.bak.20261003`, `exvr/urls.py.bak.20261003`. The web container was recreated to pick up the new env var.
