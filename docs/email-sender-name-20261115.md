# Email sender name — 15 November 2026

Corrected the live Django `DEFAULT_FROM_EMAIL` display name from
`Arctic Sentinel` to `Artic Sentinel`. The mailbox address, SMTP configuration
and credentials were unchanged.

The previous settings file is stored privately on the server at
`/home/vmrvsnyo/.codex-backups/email-brand-20261115/settings.py`.
Do not copy that file into this repository; it contains server configuration.

Verified a constructed MIME From header resolves to `Artic Sentinel`, without
sending a message. Checked all email communication templates: none contained
the spelling `Arctic`. Restarted only `exvr_web`, `exvr_celery_worker` and
`exvr_celery_beat` to load the correction.

Future messages use the corrected sender. Existing received messages retain
their original headers. The maintenance patch generator's X-Mailer label was
also corrected locally for subsequent installations.
