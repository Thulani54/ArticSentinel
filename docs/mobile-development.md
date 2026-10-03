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
flutter build apk --release --build-number 7 --dart-define-from-file=config/firebase.mobile.json
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
