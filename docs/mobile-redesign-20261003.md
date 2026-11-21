# Mobile screen redesign — 3 October 2026

This second design pass covers the phone workspace from Dashboard through Settings. The previous visual refresh remains the baseline; these changes make the page structure more compact and consistent.

## Design changes

- A persistent phone navigation bar links Home, Equipment, Alerts and Settings. The drawer retains access to all existing routes.
- Dashboard groups equipment connectivity into one overview and makes device readings easier to scan. The assistant remains available from the heading.
- Shared compact headings replace oversized decorative banners. Equipment, performance, units, controls and locations keep their existing data and actions.
- Alerts use a grouped reading list; reports have a compact catalogue. Maintenance and communications use clearer summaries and consistent list hierarchy.
- Settings uses visible section tabs, an identity card and grouped details. Security, billing and access views follow the same visual system.

Inter, navy primary actions, white cards, pale page surfaces, full-screen phone dialogs, rounded controls and single-column forms follow the supplied brief. Desktop presentation is retained where phone-specific branches were added.

## Verification

| Check | Result |
| --- | --- |
| Mobile shell/navigation, shared forms, gas logic/layout, scale format, personal alert rules and report forms | 36 passed |
| Dashboard with populated equipment and missing readings at 320/430/800 px | 3 passed |
| Equipment, details, forms, Performance, Control and Location at 320/402/800 px | 18 passed |
| Operations loading/empty/populated layouts, tabs, alert details and report dropdowns | 14 passed (includes the 3 report form checks above) |
| Account views and section navigation at 320 px | 6 passed |
| HTML email preview, expansion and collapse at 320 px | 1 passed |

Analyzer comparisons found zero new diagnostics in the root/operations changes and zero new errors or warnings in equipment/account changes. Existing warnings remain. Test and analyzer logs are under `/tmp/artic-mobile-redesign-20261003/`, with operations logs at `/tmp/artic-operations-second-test.txt` and `/tmp/artic-operations-second-analyze.txt`.

The new dashboard test exposed five overflowing legacy pressure/compressor rows at 320 px. Text constraints were corrected. Performance checks exposed metric-card and chart-container constraints; those were corrected without changing data calculations or requests. The previous [functionality audit](mobile-visual-refresh-20261003.md) documents existing incomplete actions; its source line links refer to the first-pass snapshot and may have shifted. This redesign does not change their business logic. No backend or React changes, commits or pushes are included.

[Before-and-after gallery](mobile-redesign-20261003/index.html).


## Live simulator review

Verified on iPhone 17 Pro, iOS 26.5, signed into the supplied account. Dashboard loaded 13 devices and two online devices; Performance loaded eight-zone readings. Equipment, Units, Locations, Control, Reports, Alerts, Maintenance, Team & access, Profile, Security and Billing were visually reviewed. Screenshot pairs are in the gallery.

Live review also caught a legacy floating refresh badge overlapping the phone Assistant action. The phone now uses its existing inline reading timestamp; the desktop badge remains. The dashboard test includes the wrapper route that previously displayed this badge.

Communication email HTML is presented as readable text on phones, with a compact preview and an expandable full message. It uses the existing HTML parser dependency, removes non-visible markup, and keeps the API response unchanged.

Some existing email log responses contain only 103 characters of truncated opening HTML, with no readable body. Those show “No text preview available”; the app does not invent message content. The final simulator build was checked with this response.

These checks did not send messages, operate relays, submit forms, change roles or perform billing/account actions. Physical Bluetooth/push delivery and existing placeholder business functions are outside this visual redesign.

## Build delivery

Both the iOS simulator build and Android release build completed successfully. The final iOS app was installed and relaunched on the iPhone 17 Pro simulator, retaining the authenticated session. Home, Equipment, Alerts and Settings were opened through the bottom navigation in the final build. The simulator is left on Dashboard.

Android version 1.0.0, version code 5, is saved at `/Users/thulanimoyo/Documents/ArticSentinel-1.0.0-mobile-redesign-20261003.apk`.

SHA-256: `8ebbc8d678a6fa079b88772ee1ee914a53cc73a349fb319178699a44c0f1d9aa`.

Build logs: `/tmp/artic-mobile-redesign-20261003/ios-build.txt` and `/tmp/artic-mobile-redesign-20261003/android-build.txt`. Flutter reports existing iOS plugins that have not yet adopted Swift Package Manager; this did not prevent the simulator build.
