# Product information requests

This standalone Django app accepts product enquiries from the mobile catalogue,
including people who have not created an account. It stores each submission and
two independent email delivery records before acknowledging success. Celery beat
drains the delivery table once a minute; SMTP failures retry with increasing delay
(up to six hours). A failure to save the request never produces a success response.

## API

`POST /api/products/enquiries/`, JSON, no authentication required. The endpoint does
not expose customer enquiries or use client-supplied email recipients.

Fields: `request_id` (UUID, retain it when retrying the same form), `product_type`
(`gas_cylinder` or `device1` through `device7`), `name` (2–120), `email` (valid email,
maximum 254), `phone` (optional, maximum 40), `company` (optional, maximum 160),
`message` (10–2000), and `contact_consent: true`.

201 means durably received; retrying the same reference and fields returns 200.
Both return `success`, `reference`, `delivery_status: queued`, and a readable
`message`. This means queued for delivery, not guaranteed inbox delivery. Reusing
a reference with changed fields returns 409. Invalid fields return 400 with an
`error` summary and `fields`; rate limits return 429 with `Retry-After`; missing
recipient configuration or unavailable storage returns 503.

Rate limits use database counts under a short lock shared by web workers: three
new enquiries per email per hour, 20 per source per hour, 100 total per hour.
Source addresses are stored only as a keyed hash. Idempotent retries are not
charged again. A trusted reverse proxy may supply `X-Real-IP` only when it
overwrites that header on every request; otherwise leave proxy trust disabled.

## Installation

1. Copy `product_enquiries` into the Django project and add
   `product_enquiries.apps.ProductEnquiriesConfig` to `INSTALLED_APPS`.
2. Include its URLs at `api/products/` and migrate `product_enquiries`.
3. Set `PRODUCT_ENQUIRY_RECIPIENTS` to a server-side tuple containing the two admin
   emails. No mail credentials or admin addresses are required in the mobile app.
   Existing `EMAIL_*` and `DEFAULT_FROM_EMAIL` settings are used with a 20-second
   connection timeout.
4. Add `product_enquiries.tasks.deliver_pending` to `CELERY_BEAT_SCHEDULE` every
   60 seconds. Restart the web, Celery worker and beat containers.

Records and delivery status are available to authorized Django administrators.
Pending messages can be manually requeued from the delivery list. Emails use a
fixed sender and allowlisted product subject; customer input appears as plain
text, and the validated contact email is used as Reply-To. Logs contain delivery
IDs and exception class names, never message bodies or SMTP exception details.
SMTP cannot guarantee exactly-once delivery after a worker crash immediately
after a mail server accepted a message; the stable Message-ID helps deduplication.

## Safe verification

Run tests with an isolated in-memory database and local-memory mail backend:

```sh
DJANGO_SETTINGS_MODULE=product_enquiries.test_settings python -m django test product_enquiries -v 2
```

These tests send no real email and do not connect to production databases. They
cover all eight products, consent/length validation, recipient injection,
idempotency/conflicts, email/IP limits, configuration/storage failures, and
per-recipient mail retry behavior.

## Deployment verified 3 October 2026

Installed on the existing API at `https://api.articsentinel.com/api/products/`.
The configured recipients are the two user-specified accounts for Thulani and
Surprise; both were confirmed active before configuration. The existing SMTP
connection authenticated successfully without sending a test email. Django
system checks and the migration passed; the worker registered the delivery task
and beat runs it every 60 seconds. A live empty-form request returned HTTP 400;
the enquiry and delivery tables remained empty. The 19 isolated tests passed.

The separate `backend/google_onboarding_patch.py` adds `is_new_account` to the
existing Google sign-in response only, so the app can start setup after Google
registration. Five tests execute that actual handler with mocked Google/database
dependencies and verify new, existing, disabled and rejected sign-ins. Reapplying
the patch is safe. No accounts were created during these tests.
