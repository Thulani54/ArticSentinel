/// Dark mode, driven through the real UI on a simulator/device.
///
///   welcome tour and sign-in in light → the phone switches to dark and the
///   app follows without a restart → sign-up, products → signed-in tabs →
///   Settings › Appearance: Light overrides the phone, System follows it.
///
/// Run:
///   flutter test integration_test/dark_mode_e2e_test.dart -d <device>
/// The host screenshots the simulator at each E2E-STEP marker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/gasmon/gas_theme.dart';
import 'package:artic_sentinel/main.dart';
import 'package:artic_sentinel/widgets/app_tone.dart';

Future<void> step(WidgetTester tester, String name) async {
  await settle(tester, const Duration(milliseconds: 1200));
  // ignore: avoid_print
  print('E2E-STEP $name');
  await settle(tester, const Duration(milliseconds: 1500));
}

Future<void> settle(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  await waitFor(tester, f);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(f.first, warnIfMissed: false);
  await settle(tester, const Duration(milliseconds: 600));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

void setPhoneDark(WidgetTester tester, bool dark) {
  tester.platformDispatcher.platformBrightnessTestValue =
      dark ? Brightness.dark : Brightness.light;
}

/// The page colour actually painted by the visible screen.
Color pageColour(WidgetTester tester) {
  final scaffolds = find.byType(Scaffold).evaluate().toList();
  final ctx = scaffolds.isEmpty
      ? tester.element(find.byType(MaterialApp))
      : scaffolds.last;
  return Theme.of(ctx).scaffoldBackgroundColor;
}

void expectDark(WidgetTester tester, bool dark, String where) {
  expect(Tone.dark, dark, reason: '$where: palette');
  expect(Theme.of(tester.element(find.byType(Navigator).first)).brightness,
      dark ? Brightness.dark : Brightness.light,
      reason: '$where: theme');
  expect(pageColour(tester).computeLuminance() < 0.1, dark,
      reason: '$where: page colour ${pageColour(tester)}');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('dark mode follows the phone and the setting', (tester) async {
    (await SharedPreferences.getInstance()).clear();
    setPhoneDark(tester, false);
    await AppAppearance.load();

    // --- Light: splash → welcome tour → sign in ---
    await tester.pumpWidget(MyApp(initialRoute: '/splash'));
    await waitFor(tester, find.text('Next'),
        timeout: const Duration(seconds: 20));
    expectDark(tester, false, 'welcome (light)');
    await step(tester, 'light-welcome');

    // --- The phone switches to dark while the app is open ---
    setPhoneDark(tester, true);
    await settle(tester, const Duration(milliseconds: 500));
    expectDark(tester, true, 'welcome after the phone switched');
    await step(tester, 'dark-welcome');
    await tapText(tester, 'Next');
    await step(tester, 'dark-welcome-2');
    await tapText(tester, 'Next');
    await step(tester, 'dark-welcome-3');

    // ...and back, mid-flow, without losing the screen.
    setPhoneDark(tester, false);
    await settle(tester, const Duration(milliseconds: 500));
    expectDark(tester, false, 'welcome after the phone switched back');
    await step(tester, 'light-welcome-3');
    setPhoneDark(tester, true);
    await settle(tester, const Duration(milliseconds: 500));

    await tapText(tester, 'Create an account');
    await waitFor(tester, find.text('Who is this account for?'));
    expectDark(tester, true, 'sign-up');
    await step(tester, 'dark-signup');
    await tapText(tester, 'Continue');
    await waitFor(tester, find.text('Tell us about yourself'));
    await step(tester, 'dark-signup-details');

    // --- Sign-in and products, reached through the router ---
    final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
    router.go('/login');
    await waitFor(tester, find.text('Sign in'));
    expectDark(tester, true, 'sign-in');
    await step(tester, 'dark-login');
    router.push('/products');
    await settle(tester, const Duration(seconds: 2));
    await step(tester, 'dark-products');

    // --- Signed-in screens. The token is not valid, so screens show their
    // offline/error states; the layout and colours are what is checked. ---
    Constants.authToken = 'dark-mode-e2e';
    Constants.business_name = 'Dark Mode Co';
    Constants.myDisplayname = 'Eve Tester';
    router.go('/dashboard');
    await waitFor(tester, find.text('Home'), timeout: const Duration(seconds: 20));
    await settle(tester, const Duration(seconds: 4));
    expectDark(tester, true, 'dashboard');
    await step(tester, 'dark-dashboard');

    for (final tab in ['Equipment', 'Alerts', 'Settings']) {
      await tapText(tester, tab);
      await settle(tester, const Duration(seconds: 3));
      await step(tester, 'dark-${tab.toLowerCase()}');
    }

    for (final section in ['Notifications', 'Security', 'Terms', 'Billing']) {
      await tapText(tester, section);
      await settle(tester, const Duration(seconds: 3));
      await step(tester, 'dark-settings-${section.toLowerCase()}');
    }

    // --- Settings › Appearance ---
    await tapText(tester, 'Profile');
    await waitFor(tester, find.text('Appearance'));
    await step(tester, 'dark-settings-appearance');

    await tapText(tester, 'Light');
    expectDark(tester, false, 'Light chosen while the phone is dark');
    expect(AppAppearance.mode.value, ThemeMode.light);
    await step(tester, 'appearance-light');

    await tapText(tester, 'System');
    expectDark(tester, true, 'System chosen while the phone is dark');
    await step(tester, 'appearance-system-dark');

    await tapText(tester, 'Dark');
    setPhoneDark(tester, false);
    await settle(tester, const Duration(milliseconds: 500));
    expectDark(tester, true, 'Dark chosen while the phone is light');
    await step(tester, 'appearance-dark-phone-light');

    // The choice survives a restart.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode'), 'dark');

    await tapText(tester, 'System');
    expectDark(tester, false, 'System chosen while the phone is light');
    expect(GasPalette.page, const Color(0xFFF2F6F9));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
