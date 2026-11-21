# Gas consumption discrepancy — 8 November 2026

The mobile PDF showed 0.93 kg / R36.46 while the current-day card showed
0.3 kg / R11.97. These were different calculations, not just different rounding.
The card used the starting weight minus the latest weight. The PDF, charts and
burn-rate estimate added every downward step and discarded every upward step.
Repeated scale fluctuations therefore inflated the report.

A read-only check of the server's hourly readings for the 43 kg tare cylinder
found a local-day baseline of 36.357 kg net and a final sampled value of
36.022 kg at the 21:00 bucket. Downward steps totalled 0.984 kg, upward steps
0.649 kg, and the net reduction was 0.335 kg. This later snapshot is not the
exact snapshot used by the screenshots. No telemetry or cylinder setup was
changed during the investigation.

## Calculation

- Charts, PDF/CSV daily totals, today's card, costs and burn-rate estimates
  use the same daily aggregation.
- Signed weight changes cancel small fluctuations within a day before the
  result is clamped at zero.
- The existing greater-than-1.5 kg refill heuristic splits the calculation:
  usage before and after a detected refill is retained, and added gas is not
  consumption. This is an estimate based on readings, not confirmation of a
  physical refill. Slow/small refills or large disturbances remain limitations
  of the existing detector.
- Gaps longer than 48 hours remain unmeasured. Today's card excludes future
  readings and returns zero when no current-day usage can be calculated.
- Today's usage displays two decimal places, matching report rows.

The Flutter implementation is in `lib/gasmon/gas_core.dart`; the equivalent
React implementation is in `artic-web-new/src/lib/gas/gasCore.js`.
Previously exported PDFs are static; regenerate them with the updated app.

## Validation

Regression cases cover the observed November 8 hourly readings, repeated
fluctuations without usage, refills, stale/empty data, long gaps, unsorted
readings and future readings. A rendered Flutter card test verifies
0.31 kg / R11.97 for an example previously overcounted as 0.93 kg / R36.46.
Narrow mobile layouts and the web production build are also checked.

Results: 21 Flutter checks and 24 web checks passed. Targeted Dart analysis
reported no issues; the React production build succeeded. The web changes
are prepared locally and have not been deployed to UAT in this task.

Android release build 12 completed successfully (version 1.0.0). The APK was
saved to `/Users/thulanimoyo/Downloads/ArticSentinel-1.0.0-gas-consumption-20261108.apk`.
Its package remains `com.navario.artic_sentinel`, its signature verifies and
its signing certificate matches the previous build 11, allowing an in-place
update. Phone installation and a fresh export still need to be done on the
user's device.
