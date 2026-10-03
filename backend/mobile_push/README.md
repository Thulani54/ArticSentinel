# Personal device phone alerts

Django/Celery service for live device notifications. Gas cylinders default to 50%, 30%, and 10% until a user saves personal rules.

- Authenticated phone registration is scoped to the user's primary or secondary business.
- Uses configured cylinders and readings no older than 15 minutes; no demo data.
- A weight below the cylinder tare is treated as a calibration/removal condition.
- Each downward threshold notifies once, with 5 percentage points of hysteresis before rearming.
- A jump over several thresholds sends only the most urgent message.
- Durable delivery records retry with backoff, drop old alerts, and disable unregistered tokens.
- Authorization is rechecked before delivery.

Install `google-auth>=2.40,<3` alongside the existing requests dependency. Copy `mobile_push` into the Django project, add `mobile_push.apps.MobilePushConfig` to INSTALLED_APPS, and include its URLs at `api/push/`. Apply the included migrations. Add a Celery beat entry for `mobile_push.tasks.check_gas_levels` every 60 seconds and restart the affected worker/beat processes.

Supply a dedicated Firebase Cloud Messaging service-account JSON at `/app/.secrets/fcm-service-account.json` (or `ARTIC_FCM_SERVICE_ACCOUNT`). Restrict filesystem permissions and never commit this file. Delivery remains disabled until the file exists. The account needs the Firebase Cloud Messaging API Admin role in its project, and the FCM API must be enabled.

For mobile release builds provide public Firebase app settings with `--dart-define-from-file`:
`FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_ANDROID_API_KEY`, `FIREBASE_IOS_APP_ID`, and `FIREBASE_IOS_API_KEY`.

Android app ID: `com.navario.artic_sentinel`. iOS bundle ID: `com.navario.articSentinel`. Enable Push Notifications on the Apple app identifier and upload an APNs authentication key to the Firebase iOS app. Use `APS_ENVIRONMENT=development` for development signing and production for distribution.

Run policy tests with `python -m unittest mobile_push.test_thresholds`. Verify notifications on physical Android and iOS phones after granting notification permission. No real notification is sent by the automated tests.

## This deployment

Firebase project: `articsentinel-mobile-2026` (ArticSentinel Mobile). Public app configuration is in `config/firebase.mobile.json`; native Android/iOS Firebase files are also included. These client identifiers are not server credentials.

Build Android: `flutter build apk --release --build-name 1.0.2 --build-number 3 --dart-define-from-file=config/firebase.mobile.json`.

Build iOS with the same define file and your Apple signing team. APNs credentials must be configured in Firebase before iPhone delivery can work.

Server checks: `python manage.py shell -c "import unittest; r=unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromNames([\"mobile_push.test_thresholds\",\"mobile_push.test_api\",\"mobile_push.test_rules\"])); assert r.wasSuccessful()"`. These tests mock registration writes and do not notify real users.

## Personal rules

Open a device, choose **My phone alerts → Configure my alerts**, select a reading and enter a comma-separated threshold list. Percentages use 0–100; other readings use their displayed units. Conditions support at-or-below and at-or-above; switches support on/off. Save an empty list to disable threshold alerts for that user and device. Other users are unaffected.

Authenticated GET/PUT `api/push/devices/<device_id>/rules/` supplies the device-specific metric catalog and personal rules. PUT requires the returned revision; stale edits return 409. A maximum of 50 unique thresholds is accepted. Business access is checked on saving, evaluation and delivery. Matching rules retain their state when edited; deleted rules cancel pending deliveries.

The existing minute schedule evaluates gas, refrigeration, temperature probes, ice machines, compressor current, relays, pressure and bottle-vetting readings through a fixed telemetry allowlist. Only readings up to 15 minutes old are used. Each condition fires once until the reading recovers by the displayed reset margin. When multiple thresholds for a reading are crossed together, only the most urgent is delivered. Custom rules replace legacy gas defaults for that user, including an empty rule list.

Physical-phone delivery must still be verified with permission granted and a fresh reading crossing a saved threshold. iOS additionally needs an eligible Apple team, Push Notifications entitlement, and Firebase APNs credentials.
