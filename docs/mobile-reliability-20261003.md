# Mobile reliability and workflows — 3 October 2026

This update implements the eight agreed Flutter improvements and repairs the maintenance workflow. It changes the mobile app and supporting API; the build and final verification totals are recorded below when release packaging completes.

## Features and entry points

| Feature | Where to find it | Behaviour |
| --- | --- | --- |
| Notification troubleshooting | Settings → Notifications | Shows phone permission, Android notification/channel status or Apple registration, account registration and server delivery status. **Send test notification** targets this phone only and is rate limited. Tapping a device notification resolves its ID against the signed-in account’s inventory before opening its details. Provider acceptance is distinguished from confirmed on-screen receipt. |
| Offline readings | Dashboard, Equipment, Performance and gas details | Saves successful inventory/read requests per account and business for later viewing, including after restarting the app. A **Saved readings** banner shows download time and retries while the view is open. Reading timestamps remain visible; cached gas is labelled **LAST REPORTED**, with connection state unconfirmed and current projections suppressed. Sign-out clears snapshots. Device commands and configuration writes are never queued for offline replay. |
| Scan to pair | Guided setup → **Scan device QR code** | Reads a versioned ArticSentinel setup label, fills the hardware ID/type and asks the user to confirm before continuing the existing setup steps. Camera failure or an unsupported label retains manual entry. A scan alone does not create or change a device. |
| Cylinder purchases and changes | Gas details → **Refill history** → **Log refill or cylinder change** | Records date, purchased kilograms, cost in ZAR, supplier and notes. Cylinder changes can include a capacity/empty-weight snapshot and zero purchase/cost. Monthly purchase totals are shown separately from observed consumption in available telemetry. **Switch gas** remains the place to apply cylinder configuration; cancelling a journal form writes nothing. |
| Bottle verification history | Bottle device dashboard or Performance → **Bottle scan history** | Searches reported bottle codes, filters verified/failed results and selects a date range. Results include time, direction, temperature and tray readings where reported. A code may appear more than once because repeated reports are not unique bottle events. Empty/error states and pagination are supported; the history follows the server’s 90-day telemetry retention. |
| Team alert handling | Alerts → alert details → **Team activity** | Assigns an active business member, records handover/action notes and resolves an alert with a required note. The server records the actor and time. Concurrent edits require reloading instead of silently replacing another person’s update. Both phone and larger-screen details use the same workflow. |
| Secure sessions and biometric unlock | Settings → Security → **Face ID / fingerprint unlock** | Moves session tokens into platform secure storage and removes retained account passwords from ordinary preferences. Optional biometric locking applies to the current account on this phone when leaving the app. The gate covers dialogs and notification destinations; users can sign in again if biometric unlock is unavailable. |
| Real maintenance reports | Reports and Maintenance → reports | Removes sample export actions and fabricated fallback devices. Reports use actual records; unavailable data produces an error or an explicit empty state. Mobile PDF exports use the system save/share chooser without broad storage permission. |

The pairing label uses an identifier-only format such as `articsentinel://pair?v=1&type=gas_cylinder&id=SCALE-EXAMPLE`. Approved ArticSentinel HTTPS `/pair` links use the same version, type and ID fields. Labels do not contain account tokens, Wi-Fi passwords or server addresses. Existing labels that do not follow this format can still be entered manually.

## Maintenance workflow

Maintenance now supports create, edit, duplicate, recurring schedule setup, pagination/filtering, start/checklist/complete actions and actual-record PDF export. Forms retain entries after failed saves. Critical checklist items must be completed before maintenance can be closed, and status failures do not report success. Records refresh when returning from details.

The backend derives actors from the authenticated profile and checks business access for records, schedules, checklists, observations and reports. It restricts assignments to active members, serializes parent-record updates and protects unchanged create retries with a request ID. Recurring generation respects schedule end dates.

See [maintenance verification](maintenance-qa-20261003.md) for the detailed workflow matrix and [backend maintenance patch](../backend/maintenance_updates/README.md) for the access and transition rules.

## Backend deployment

The supporting backend update was deployed successfully to the existing API host. Changed source/settings/URL files were backed up before installation. The device journal and push-diagnostic migrations were applied, Django checks passed, and the API was restarted. The final journal permission patch requiring active business profiles was also copied, checked and restarted.

The journal stores refill/change entries and team audit events. Bottle history queries the existing telemetry store read-only. Push diagnostics target the authenticated phone installation; they do not broadcast to other users. The maintenance patch reuses the existing maintenance schema. No sample records were seeded.

Implementation notes: [device journal](../backend/device_journal/README.md), [maintenance patch](../backend/maintenance_updates/README.md), [mobile push](../backend/mobile_push/README.md).

## Verification boundaries

Automated Flutter checks exercise real widgets and PDF generation with mocked services, including validation, retries, empty/error states, account isolation, offline restoration, device notification routing and maintenance transitions. Isolated Django tests exercise journal persistence, tenant boundaries, idempotency, assignment/resolve rules and the patched maintenance handlers using disposable SQLite and test fixtures. Test mail stays in memory. These tests do not create, complete or delete live customer maintenance records, alter real devices or send reminder emails.

The deployed maintenance handlers also passed 15 expected route results using the real token authenticator and PostgreSQL: create/retry, edit, start, critical-checklist blocking, checklist completion, completion, detail, analytics, monthly records, PDF and recurring schedule create/retry/update. Temporary rows stayed in one transaction and were rolled back; absence was verified afterward. Email, task dispatch, storage writes and new network connections were blocked. This was an in-process backend integration check, separate from the live read-only simulator checks. See [sanitized results](mobile-reliability-20261003/maintenance-postgres-verification.json).

Five journal previews were rendered at 390 × 844 logical pixels with the app theme and bundled fonts, then visually inspected. Their records are controlled UI fixtures. See [preview notes](mobile-reliability-20261003/journal-preview-notes.md). Simulator maintenance captures are saved alongside them. The final simulator build also loaded the cylinder journal from the deployed API, including actual observed consumption and its empty purchase-history state (`refill-history-live-ios.png`), and displayed notification diagnostics and the biometric settings entry point. A simulator or mocked flow is not proof of physical hardware behaviour.

The following still require a physical device or a deliberately isolated staging business:

- Scan a printed device QR label using a real camera, including denied camera permission and manual fallback.
- Enable and exercise Face ID/fingerprint unlock, cancellation and reauthentication on supported hardware.
- Receive and tap a test push on Android and iPhone; check foreground/background delivery, platform permissions and the device-alert channel. Provider acceptance alone does not prove the phone displayed it.
- Choose an actual attachment and complete PDF save/share through the Android and iOS system chooser.
- Exercise Bluetooth scale provisioning and physical bottle scan reporting with real hardware.
- Test concurrent maintenance edits and scheduled-worker generation under load, plus real reminder delivery to an agreed test recipient. The PostgreSQL workflow check was single-process and does not establish contention behaviour.

## Release verification

- Full Flutter regression suite: **263 tests passed**.
- Isolated backend checks before the final reminder-worker patch: **19 journal + 7 push diagnostics + 21 maintenance tests passed**.
- Deployed PostgreSQL maintenance workflow: **15 expected route results**, rollback verified, no messages sent.
- iOS: **1.0.0 (11)** built, reinstalled and reopened on iPhone 17 Pro / iOS 26.5; final maintenance form and live cylinder history inspected.
- Android: **1.0.0 (11)** release APK built; archive integrity and signing identity verified against the previous APK, supporting an in-place upgrade.
- APK: `/Users/thulanimoyo/Downloads/ArticSentinel-1.0.0-reliability-20261003.apk` (98398062 bytes).
- SHA-256: `0c2576259b8ee81524bb6988342366e570935805ba5b2aaf8401bef8a09f129b`.
- File metadata and verification: [build-verification.json](mobile-reliability-20261003/build-verification.json).
