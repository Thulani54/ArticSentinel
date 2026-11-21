# Flutter mobile visual refresh — 3 October 2026

This handoff records verified visual changes and known limitations. The refreshed app has been built for iOS Simulator and Android. Final delivery details are recorded below.

## Scope

Flutter mobile presentation only: spacing, Inter typography, pale page surfaces, white cards, navy primary actions, pill buttons, full-screen phone dialogs, and forms that remain readable at 320 px. Existing routes, API calls, models and business behavior were preserved. The React website and backend are outside this work.

The work covers the mobile shell/theme, equipment and unit screens, performance views, alerts, reports, maintenance, communications, settings, roles and help. The final visual sweep also corrected Location tabs and the Control device selector/heading constraints. Existing gas and authentication flows are regression targets. Fonts are bundled for offline use: Inter 400–800 plus regular italic, and Lato Light 300 for the wordmark. OFL licenses and pinned upstream provenance are in [the font assets](../lib/assets/fonts/SOURCES.json).

Live checks used sign-in followed by read-only screen navigation. No data-entry forms or administrative mutations were submitted. `integration_test/auth_flow_test.dart` was deliberately excluded because it creates real accounts. Temporary widget checks used local fixtures or the Flutter test environment, without production data writes.

## Verified checks

63 focused checks passed across the groups below and the additional form/rule checks recorded under Simulator verification. Targeted reruns are not counted twice.

| Check | Result | Evidence log |
| --- | --- | --- |
| Required gas domain, mobile gas layout and scale format regression tests | 17 passed | `/tmp/artic-required-tests.txt` |
| Mobile shell/navigation and shared form checks | 6 passed | `/tmp/artic-mobile-shell-tests.txt` |
| Operations layouts: alert details at 320/430/800 px; alert/report/communication/maintenance loading and tab states at 320 px | 7 passed | `/tmp/artic-operations-layout-test.txt` |
| Equipment and unit lists, filters, details and add-unit steps at 320/800 px | 10 mocked checks passed | `/tmp/equipment-smoke.log` |
| Settings personal/business, help/FAQ, security/terms, billing search/filter, and role dialogs at 320 px | 5 passed | `/tmp/account-review-test.txt` |
| Location tabs and populated Control selectors/headings at 320/402/800 px | 6 mocked checks passed | `/tmp/location-control-smoke-after.txt` |
| Bundled font manifests/licenses and GoogleFonts loading with runtime fetching disabled | 2 passed; the same run repeated the 5 account checks successfully | `/tmp/artic-bundled-font-tests.txt` |

Required regression command:

```sh
flutter test test/gasmon_test.dart test/gas_mobile_layout_test.dart test/scale_direct_format_test.dart
```

The shell tests are in [test/mobile_shell_test.dart](../test/mobile_shell_test.dart). Temporary checks remain outside the repository: `/tmp/artic_operations_layout_test.dart`, `/tmp/equipment_visual_smoke_temp_test.dart`, `/tmp/account_mobile_smoke_test.dart`, and `/tmp/artic_bundled_fonts_test.dart`. Their logs are temporary execution evidence supporting the simulator pass.

Analyzer checks recorded no errors. The shared shell/theme analysis reported zero errors and zero warnings (six existing informational lints). The shell test file reported no issues. Settings/roles/help remained at their baseline of 14 warnings and 144 infos; operations remained at 32 warnings and 454 infos. Existing diagnostics were not presented as a clean repository-wide analysis. `flutter pub get` succeeded after adding the font assets, without adding packages.

## Existing functionality gaps retained

These were found in the existing implementation and were not converted into new features during the visual pass.

| Area | Observed limitation | Source |
| --- | --- | --- |
| Personal/business profiles | Save simulates a delay and updates local `Constants`; there is no profile persistence request in these save methods. | [Personal save](../lib/screens/settings/settings.dart#L1891), [business save](../lib/screens/settings/settings.dart#L2792) |
| Security | Save and account-deletion request only call an empty `setState`. | [Save](../lib/screens/settings/security.dart#L141), [deletion request](../lib/screens/settings/security.dart#L636) |
| Billing | Invoices are hard-coded mock data. Send/view/edit/duplicate/delete actions display messages rather than persist invoice operations. | [Invoice data](../lib/screens/settings/billing.dart#L100), [actions](../lib/screens/settings/billing.dart#L1518) |
| Roles | Search stores text without filtering the list; role menu actions and the post-create refresh are empty. | [Search](../lib/screens/roles.dart#L758), [menu](../lib/screens/roles.dart#L898), [refresh](../lib/screens/roles.dart#L1541) |
| Permissions/audit | Permission selection is a placeholder; audit history is not implemented in this view. | [Permission selection](../lib/screens/roles.dart#L2829), [audit tab](../lib/screens/roles.dart#L1366) |
| Help | Live Chat and Submit Ticket callbacks are empty. | [Support actions](../lib/screens/help.dart#L181) |
| Terms | Existing text references Silver Spectrum and a different product. Legal copy was left intact. | [Terms content](../lib/screens/settings/terms.dart#L39) |

Successful layout checks do not establish that these unfinished features work. They also do not establish physical Bluetooth provisioning, push delivery, or persisted profile/billing changes.

## Simulator verification

Verified on iPhone 17 Pro, iOS 26.5. Fresh sign-in with the supplied account succeeded. Dashboard loaded 13 devices; device search found the pressure monitor by its ID, and the online filter reduced the list to two devices. Equipment details and personal-alert conditions opened correctly. No alert rules were saved.

The simulator pass covered:

- Dashboard, drawer, equipment cards, ID search, online filter, equipment details, and pressure-based personal alert fields.
- Registration form switching from refrigeration to the gas-cylinder fields; form dismissed without creating a device.
- Performance telemetry (eight zones), graphs and expandable reporting dates.
- Personal/business settings, profile edit/cancel, security and billing navigation.
- Alerts and full-screen detail view; no acknowledgement/resolution performed.
- Reports, history counters and report configuration; no new report generated.
- All six maintenance tabs, communication overview/providers/templates/logs/queues, team/roles/permissions/requests/audit tabs, unit empty state and add-unit form, and Help FAQ expansion.

The broader check also found overflowing location tabs and an unbounded device selector that prevented Control from painting. Both received presentation-only constraint fixes, and six mocked layout tests passed at 320, 402 and 800 px. API calls and state handling remained intact. The final installed build was checked again: Control renders its populated device selector and relay cards, and Location displays its tabs without clipping. Report dropdowns and the updated Security card were also visually verified. Live writes, notification permissions, Bluetooth provisioning, physical-device push delivery, account deletion, payments, role changes and message sending were not exercised.

Additional validation: the existing mobile form and personal-alert rule tests passed all 7 checks (`/tmp/artic-forms-alert-tests.txt`). Three new mocked 320px report-form tests passed in [test/report_mobile_fields_test.dart](../test/report_mobile_fields_test.dart), including selection of a performance metric. Updated security layout passed its targeted 320px check with no new analyzer diagnostics.

Before/after captures are available in the [local comparison gallery](mobile-visual-refresh-20261003/index.html). Captures use the existing account's data and are local artifacts, not published assets.

## Build delivery

Release APK: [ArticSentinel-1.0.0-visual-refresh-20261003.apk](/Users/thulanimoyo/Documents/ArticSentinel-1.0.0-visual-refresh-20261003.apk) (77.9 MB), version 1.0.0, build 4.

SHA-256: `79669c1705084d25f9e154e289f5b36fc971c8cc970bd14a1c99378fcfe6a522`.

Both final builds succeeded with the simulator-driven layout corrections included. The iOS app was installed and launched successfully on the simulator; its authenticated session remains open. The Android APK uses a build-number override of 4 so it can update the previously delivered build 3; source `pubspec.yaml` is unchanged at 1.0.0+1. No packages, backend endpoints, authentication logic or routes were changed.

The final incremental iOS build completed in 22.1 seconds, and Android release compilation completed in 70.2 seconds. Build logs are `/tmp/artic-ios-verified-build.txt` and `/tmp/artic-android-verified-build.txt`.

Android release builds using `--no-pub` encountered stale generated registration for development-only plugins. Running a normal, pub-enabled release build regenerated the appropriate metadata and succeeded without Android dependency or configuration changes. Build commands were run sequentially for final delivery.

An old placeholder counter test (`test/widget_test.dart`) is not an app test: its widget pump is commented out. It was not used as evidence; the targeted tests above exercised the real app components.

No commits, pushes, website deployments or backend changes were made.
