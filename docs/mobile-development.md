# ArticSentinel mobile development

The Flutter application is at the repository root. Run commands there.

## Build

The release was validated with Flutter 3.47.1 and Dart 3.13.1. Use a compatible
Flutter SDK with its bundled Dart SDK. Restore packages:

```sh
flutter pub get
```

The repository includes Firebase **client** configuration for the Android and
iOS applications. Include the Dart defines when building so notification
initialization receives the matching app identifiers:

```sh
flutter run --dart-define-from-file=config/firebase.mobile.json
flutter build ios --simulator --dart-define-from-file=config/firebase.mobile.json
flutter build apk --release --build-number 10 --dart-define-from-file=config/firebase.mobile.json
```

Increment the build number for subsequent distributed releases. Device builds
for iOS require the appropriate Apple signing setup. Server service-account
credentials, APNs private keys and signing keys are not client configuration
and must remain outside Git.

## Mobile UI regression checks

```sh
flutter test \
  test/mobile_shell_test.dart \
  test/mobile_forms_test.dart \
  test/mobile_dialog_presentation_test.dart \
  test/device_illustration_test.dart \
  test/equipment_reading_layout_test.dart \
  test/gas_cylinder_gauge_test.dart \
  test/gas_mobile_layout_test.dart
```

These checks cover responsive forms, navigation, bundled device illustrations,
readings at narrow widths and enlarged text, safe dialog bounds, gas-fill
geometry, animations and reduced motion. They use local fixtures and mock
responses; they do not create live devices or issue hardware commands.

The mobile refinement release passed 74 targeted checks and was built for the
iOS simulator and Android. Existing analyzer warnings remain in older code.

## Presentation conventions

- Phone layouts use a 600-pixel breakpoint for fullscreen forms/details and
  single-column reading cards. Wider screens retain dialog presentation.
- Open responsive modal content with `showMobileDialog` and build it with
  `MobileDialog` or `MobileAlertDialog` from `lib/widgets/mobile_forms.dart`.
- Use `mobileInputDecoration` for phone fields: radius 32 and no leading icon.
- Navigation uses Iconsax. Device type illustrations live in
  `lib/assets/devices/`, with a sensor-board fallback for unknown types.
- `GasCylinderGauge.fill` is entrance-animation progress. `levelPct` determines
  the actual gas fraction; 50 percent must settle at half height.
- On phones, the gas cylinder silhouette follows its configured capacity, with
  compact, medium and tall proportions for 9, 14, 19 and 48 kg cylinders.
  Custom sizes interpolate between these illustrative shapes. The valve guard
  and foot ring sit outside the body used to calculate the fill and scale.

## Empty data and device selection

The dashboard scopes readings to the active account and selected device. Gas
cylinders use their own readings panel; they never fall back to refrigeration
metrics. Inventory, empty telemetry and request failures are separate states.

Use `AppEmptyState` from `lib/widgets/app_empty_state.dart` with relevant text,
its supplied SVG illustration and an action when recovery is possible. Keep
last-known readings explicitly labelled after a refresh failure. Read timeouts
must surface a retry action without manufacturing zeros or demo readings.

`Switch gas` opens the responsive Cylinder setup editor. Opening or cancelling
the editor does not write configuration; the Save action uses the existing API.

Additional mocked regression checks:

```sh
flutter test test/dashboard_performance_state_test.dart \
  test/inventory_empty_state_test.dart \
  test/operations_empty_state_test.dart \
  test/gas_state_and_setup_test.dart
```

## Signup, setup and product enquiries

Account creation now finishes and signs in before opening `/device-setup`.
The customer can connect equipment, browse the public `/products` catalogue,
or skip to their workspace. Products and Connect a device are also available
from the drawer. New Google accounts receive the same setup invitation.

Setup has three illustrated, animated steps for each supported device type.
Gas scales capture capacity and the cylinder's stamped empty weight, then open
the existing Bluetooth/Wi-Fi provisioning flow after registration. Bottle
vetting machines use their own network controls; the guide does not claim a
Bluetooth feature. Registered and reporting are separate states: confirmation
requires a recent measurement for the selected device. Retrying an interrupted
setup checks the existing inventory and preserves saved cylinder settings.

The product catalogue covers all eight device types and uses the supported
telemetry as its feature list. Public enquiries post to
`/api/products/enquiries/`; the response confirms durable receipt, not inbox
delivery. The server queues separate emails to the two configured admins and
retries SMTP failures. The same unedited form reuses its request UUID so a lost
response does not create duplicate enquiries. See
[`backend/product_enquiries/README.md`](../backend/product_enquiries/README.md)
for installation, validation, rate limits and delivery monitoring.

Focused checks use mock accounts, devices and email delivery:

```sh
flutter test test/signup_guided_setup_test.dart \
  test/device_setup_wizard_test.dart test/products_page_test.dart \
  test/mobile_shell_test.dart
```

Do not use live account creation, device registration or enquiry submission to
run these checks. Hardware provisioning still needs a real nearby scale;
simulators and mocked tests cannot prove a physical Bluetooth connection.

Build 10 was packaged on 3 October 2026 after 65 combined Flutter checks and
32 isolated backend checks passed. The APK archive and Android version code
were verified. Preview images are in `docs/mobile-onboarding-20261003/`.
Install this build to update older Control requests that did not include
authentication; the device list/create endpoints now enforce business access.
