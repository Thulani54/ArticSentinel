# Device onboarding and product enquiries — 3 October 2026

The mobile flow uses existing device and gas endpoints. Two isolated integration
patches accompany the new `product_enquiries/` Django application:

- `google_onboarding_patch.py` adds `is_new_account` to Google sign-in responses,
  true only for an account created by that request. Existing sign-ins keep false.
- `pairing_authorization_patch.py` protects the effective `list_devices` and
  `create_device` definitions. The server contained earlier protected definitions
  overridden by later unprotected functions. Only the effective list/create
  handlers are changed: Django REST Framework authentication plus the existing
  gas business-access helper (primary business, secondary business, superuser).

Both patch scripts back up their source target and are idempotent. Server paths
are `/home/vmrvsnyo/exvr/user/team_views.py` and
`/home/vmrvsnyo/exvr/device/views.py`. Existing Token, Bearer-token and session
authentication settings are preserved. Older app builds that call device lists
without an auth header must be updated; the new app supplies its session token.

## Verification

All tests mock network and database operations or use isolated in-memory Django
settings. They do not create user accounts, devices or product enquiries on the
live service, and do not send real email.

```sh
python3 test_google_onboarding_patch.py user/team_views.py
DJANGO_SETTINGS_MODULE=product_enquiries.test_settings python test_pairing_authorization_patch.py device/views.py device/gas_views.py
DJANGO_SETTINGS_MODULE=product_enquiries.test_settings python -m django test product_enquiries -v 2
```

Five Google-signup tests, eight device-authorization tests, and 19 product-enquiry
tests passed before deployment. `manage.py check` passed. The enquiry app migration
was applied, its Celery task registered, and the existing SMTP service authenticated
without sending test mail. See `product_enquiries/README.md` for API details and
the email queue behavior.

## Confirmed pairing contracts

- `POST api/devices/create/`: authenticated; body `business_id` and device fields;
  HTTP 201 with `success`, `device`, `message`.
- `POST api/devices/list/`: authenticated; body `business_id`; HTTP 200 with
  `success`, `devices`, `total`.
- `POST api/gas/config/`: body `business_id`, `device_id`; response
  `config.is_default` distinguishes saved setup from unsaved defaults.
- `POST api/gas/readings/`: `latest.time` is the newest reported reading;
  `latest: null` means no readings. Gas is not handled by the generic latest-data
  router, so it must use this endpoint.
- Generic latest-device-data GET returns a JSON list, with `time` ISO timestamps.
  Metadata-only rows have `time: null`, `systemStatus: no_data`.
- Bottle-vetting rows use `codeScan`, `tray1wt`–`tray4wt`, `bottleTemp`,
  `scanVerified`. A default false scan-verification value alone is not proof that
  readings have arrived.
