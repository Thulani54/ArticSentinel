# Mobile UI cleanup — 3 October 2026

This pass simplifies the Flutter phone workspace from Dashboard to Settings. It retains the existing Inter typography, navy actions, pale page background, white cards, rounded controls and single-column form fields.

## Changes

- Smaller shared headings, fewer repeated descriptions, a quieter app header and lighter drawer selection.
- A compact equipment overview and grouped key readings on Dashboard. Temperature zones use available width and text size to avoid cramped cards.
- Device and unit status filters use compact pills. Equipment lists use grouped rows; selectors and detail panels have fewer nested surfaces.
- Alerts, report history, maintenance and communication logs have simpler rows, headings and actions. Email previews retain the HTML-to-text handling.
- Settings uses quieter tabs, an inline identity area and aligned read-only values. Security, Billing, Terms, Help and Access use the same spacing and hierarchy.
- The phone-alert card in equipment details uses compact account-only guidance and two clear actions; it stacks the actions when space or text size requires it.

The changes are visual. API calls, routes, models, services, authentication, gas logic, dependencies and backend code are preserved. No Git commits, pushes or deployments are included.

## Verification

Checks cover phone widths from 320 pixels, larger text, tablet layouts, navigation, empty/loading/populated states and existing form interactions. The screenshots compare this pass with the immediately preceding redesign.

| Targeted checks | Result |
| --- | --- |
| Shell, dashboard, forms, gas logic/layout, scale format and personal alert rules | 40 passed |
| Equipment, details, units, performance, controls and locations | 25 passed |
| Active-filter result counts at 320px with normal and enlarged text | 2 passed |
| Operations pages, report actions and email previews | 16 passed |
| Settings, access and help, including 320px at 1.4× text | 8 passed |
| Compact phone-alert card, disabled actions and long status text | 5 passed |

Analyzer comparisons show no new errors or warnings. Existing analyzer findings remain. Checks caught and corrected constrained chart headings, temperature cards, the Billing metric strip, and result counts hidden by active filters.

The final app was installed and launched on the iPhone 17 Pro simulator running iOS 26.5, retaining the signed-in account. Live review covered Dashboard, Equipment/details, Performance, Units, Communications, Locations, Control, Reports, Alerts, Maintenance, Team/Roles, Settings/Profile, Security, Billing, Terms and Help. No live forms, messages, account changes, or relay commands were submitted.

Locations still showed blank map tiles during review; only its layout was verified. Existing truncated email log responses correctly show “No text preview available.”

Logs are under `/tmp/artic-clean-ui-20261003/`, with operations logs at `/tmp/artic-operations-clean-test.txt` and `/tmp/artic-operations-clean-analyze.txt`, and the alert-card checks at `/tmp/artic-device-alert-card-test.txt`.

[Before-and-after gallery](mobile-cleanup-20261003/index.html)

Existing incomplete business actions remain documented in the [earlier functionality audit](mobile-visual-refresh-20261003.md). That audit's source line links refer to its original snapshot. Physical Bluetooth and push delivery, live writes and map-tile delivery are not part of this visual verification.

## Builds

Both the final iOS simulator build and Android release build completed successfully. Android version 1.0.0, version code 6, is saved at `/Users/thulanimoyo/Documents/ArticSentinel-1.0.0-clean-ui-20261003.apk`.

SHA-256: `97b4e25024346f9b62cea10da3e2a4ce27f301545786559ce51d6849e7201536`.

Build logs: `/tmp/artic-clean-ui-20261003/ios-build.txt` and `/tmp/artic-clean-ui-20261003/android-build.txt`. Existing Flutter plugin/Kotlin migration notices did not prevent either build.
