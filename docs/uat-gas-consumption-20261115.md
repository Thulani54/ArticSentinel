# UAT gas-consumption parity — 15 November 2026

Published the mobile consumption correction to https://uat.articsentinel.com.
Small signed weight changes cancel within each day; the existing refill
threshold and 48-hour gap handling are retained. No temperature compensation
or fixed creep deduction has been added.

The website includes the latest telemetry in consumption history, matching the
gas-level reading. The daily card and usage totals display two decimal places.
PDF exports now include daily consumption and cost rows from the same selected
range as the dashboard. Weekly charts group those daily points, preserving
range totals and the daily peak. CSV exports retain the original reading series.

Empty telemetry and failed requests no longer generate demo readings. Failed
refreshes retain last-known readings with a visible warning; initial failures
provide Retry. Phone gas readouts use one column. Chart tooltips are contained
so they cannot cause horizontal page scrolling.

## Validation

- 29 Node tests passed, including the November 8 observations, fluctuations,
  refills, gaps, date boundaries, weekly totals, and latest-reading inclusion.
- Vite production build succeeded.
- Headless Chrome checked desktop and 390 px layouts, error/empty states,
  and a PDF download, both locally and using the deployed UAT assets.
- Those browser checks used intercepted API fixtures, not changes to customer
  equipment. The same fixture displayed 0.31 kg / R11.97 in the card and PDF.
- Exported PDF text and rendered page were inspected.
- Public HTML and entry JS/CSS matched the local build byte-for-byte over
  verified HTTPS. The unauthenticated gas endpoint returned HTTP 403, confirming
  that the existing API proxy responds and access remains protected.
- No backend restart, migration, or physical-device write was required.

## Deployment and rollback

Web root: `/var/www/uat.articsentinel.com` on the existing SSH host.
The prior site was archived to
`/home/vmrvsnyo/.codex-backups/uat-gas-20261115/site-before.tar.gz`.
Assets were copied before atomically replacing index.html. Old hashed assets
were retained for already-open tabs.

Published index SHA-256:
`7ee1f3572b37945b4209dd38ab9f9a321fa7283d3416e1a5185a4d9f9e040802`.

Refresh the website and regenerate reports to use the correction. Old PDF
files remain unchanged. The main articsentinel.com deployment was not changed.
