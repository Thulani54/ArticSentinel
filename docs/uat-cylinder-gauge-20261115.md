# Website cylinder shape and animation — 15 November 2026

Deployed to https://uat.articsentinel.com.

The SVG gauge now uses the Flutter mobile cylinder profiles: rounded shoulders
and heel, recessed brass valve, protective carrying guard, and a ventilated
foot ring. Capacity determines the proportions, with interpolation for custom
sizes. Flat colours and a readable value plaque match the mobile app.

Entrance animation uses 1,100 ms ease-out cubic. Reading changes interpolate
from the currently displayed fill over 650 ms, with interrupted animations
cancelled. Reduced-motion preference skips animation. Tick marks and fill share
one body coordinate system, so 50% settles at the halfway tick. SVG clip IDs are
unique per component instance. Gas calculations and telemetry settings were
not changed.

## Verification

- 36 Node tests passed and the production build succeeded.
- Browser checks ran locally and against published UAT assets for 9, 14, 19
  and 48 kg cylinders, including a 320 px phone viewport and desktop.
- Checked empty-to-50% entrance, exact final half-height, a 50%-to-80% update,
  reduced-motion immediate rendering, and absence of horizontal page overflow
  or JavaScript errors. API fixtures were intercepted; no equipment was changed.
- Inspected rendered 9 kg and 48 kg screenshots.
- Public HTML and entry JS/CSS matched the built files over verified HTTPS.

The previous site is backed up on the server at
`/home/vmrvsnyo/.codex-backups/uat-cylinder-20261115/site-before.tar.gz`.
Assets were uploaded before replacing index.html atomically. Existing hashed
assets remain available to already-open tabs. No backend restart was needed.

Published index SHA-256:
`7faf9b2d17269d4dd79df43599cb8c636ccfcb71b2fac317043c90c874e8c01a`.
