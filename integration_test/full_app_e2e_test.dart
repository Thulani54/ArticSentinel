/// Full end-to-end run against the real backend, driven through the real UI
/// on a simulator/device. Hardware is simulated outside the app by an MQTT
/// publisher that uses the same device IDs (see E2E_TAG).
///
///   welcome tour → create a company account → link a refrigeration monitor
///   and a gas scale (waiting for their first MQTT readings) → dashboard →
///   equipment, alerts and settings tabs → personal alert rule → push
///   notification test → AI assistant → sign out and sign in again.
///
/// Run:
///   flutter test integration_test/full_app_e2e_test.dart -d <device> \
///     --dart-define=E2E_TAG=<tag> --dart-define=E2E_PASSWORD=<password>
/// Device IDs are E2E-R-<tag> (refrigeration) and E2E-G-<tag> (gas); the
/// account is e2e-<tag>@example.com.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artic_sentinel/main.dart';

const tag = String.fromEnvironment('E2E_TAG');
const password = String.fromEnvironment('E2E_PASSWORD');
const email = 'e2e-$tag@example.com';
const fridgeId = 'E2E-R-$tag';
const gasId = 'E2E-G-$tag';
const fridgeName = 'E2E Cold Room';
const gasName = 'E2E Kitchen Gas';

/// The host watches the log for these markers and screenshots the simulator.
Future<void> step(WidgetTester tester, String name) async {
  // ignore: avoid_print
  print('E2E-STEP $name');
  await settle(tester, const Duration(milliseconds: 1500));
}

/// Asks the host to act outside the app (tap a system prompt, change the
/// simulated hardware's readings).
void action(String name) {
  // ignore: avoid_print
  print('E2E-ACTION $name');
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
  // ignore: avoid_print
  print('E2E-STEP timeout');
  await settle(tester, const Duration(milliseconds: 800));
  throw TestFailure('Timed out waiting for $finder');
}

Finder fieldWithLabel(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label);

Future<void> enter(WidgetTester tester, String label, String text) async {
  final f = fieldWithLabel(label);
  await waitFor(tester, f);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(f.first, text);
  await tester.pump(const Duration(milliseconds: 150));
}

/// Scrolls the screen up until a lazily built widget exists.
Future<void> reveal(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.dragFrom(
        Offset(size.width / 2, size.height * 0.6), const Offset(0, -320));
    await settle(tester, const Duration(milliseconds: 500));
  }
}

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  await settle(tester, const Duration(milliseconds: 600));
  if (f.evaluate().isEmpty) await reveal(tester, f);
  await waitFor(tester, f);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

/// Taps "Check for a reading" until the wizard confirms one arrived.
Future<void> waitForReading(WidgetTester tester, String what) async {
  final end = DateTime.now().add(const Duration(minutes: 4));
  while (DateTime.now().isBefore(end)) {
    await settle(tester, const Duration(seconds: 2));
    if (find.text('Your device is reporting').evaluate().isNotEmpty) return;
    final check = find.text('Check for a reading');
    if (check.evaluate().isNotEmpty) {
      await tester.ensureVisible(check.first);
      await tester.tap(check.first, warnIfMissed: false);
    }
    await settle(tester, const Duration(seconds: 6));
  }
  throw TestFailure('No MQTT reading reached the wizard for $what');
}

Future<void> linkDevice(WidgetTester tester,
    {required String product,
    required String id,
    required String name,
    bool gas = false}) async {
  await waitFor(tester, find.text('What are you connecting?'));
  await tapText(tester, product);
  await enter(tester, 'Device ID', id);
  await enter(tester, gas ? 'Cylinder name' : 'Device name', name);
  await enter(tester, 'Location (optional)', 'E2E test site');
  await step(tester, '${gas ? 'gas' : 'fridge'}-identify');
  await tapText(tester, 'Continue');
  if (gas) {
    await waitFor(tester, find.text('Set your cylinder size'));
    await tapText(tester, '9 kg');
    await enter(tester, 'Empty cylinder weight (kg)', '10.5');
    await step(tester, 'gas-cylinder-size');
    await tapText(tester, 'Continue');
  } else {
    await step(tester, 'fridge-power');
    await tapText(tester, 'Continue');
  }
  await waitFor(tester, find.text('Link device'));
  await step(tester, '${gas ? 'gas' : 'fridge'}-ready-to-link');
  await tapText(tester, 'Link device');
  await waitFor(
      tester,
      find.textContaining(RegExp(
          r'Your device is (registered|reporting)|Already in your workspace')),
      timeout: const Duration(seconds: 60));
  await step(tester, '${gas ? 'gas' : 'fridge'}-registered');
  await waitForReading(tester, name);
  await step(tester, '${gas ? 'gas' : 'fridge'}-reporting');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('full app end-to-end', (tester) async {
    expect(tag, isNotEmpty, reason: 'pass --dart-define=E2E_TAG');
    expect(password, isNotEmpty, reason: 'pass --dart-define=E2E_PASSWORD');
    (await SharedPreferences.getInstance()).clear();

    // --- Splash → welcome tour ---
    await tester.pumpWidget(MyApp(initialRoute: '/splash'));
    await waitFor(tester, find.text('Next'),
        timeout: const Duration(seconds: 20));
    await step(tester, 'welcome');
    await tapText(tester, 'Next');
    await tapText(tester, 'Next');
    await tapText(tester, 'Create an account');

    // --- Create the account ---
    await waitFor(tester, find.text('Who is this account for?'));
    await tapText(tester, 'Continue');
    await waitFor(tester, find.text('Tell us about yourself'));
    await enter(tester, 'Company name', 'E2E Test Co $tag');
    await enter(tester, 'First name', 'Eve');
    await enter(tester, 'Last name', 'Tester');
    await enter(tester, 'Email', email);
    await step(tester, 'signup-details');
    await tapText(tester, 'Continue');
    await waitFor(tester, find.text('Secure your account'));
    await enter(tester, 'Password', password);
    await enter(tester, 'Confirm password', password);
    await tapText(tester, 'Create account');

    // --- Device setup wizard: refrigeration monitor, then gas scale ---
    await waitFor(tester, find.text('Do you have a device to connect?'),
        timeout: const Duration(seconds: 60));
    await step(tester, 'setup-welcome');
    await tapText(tester, 'Yes, I have a device');
    await linkDevice(tester,
        product: 'Refrigeration monitor', id: fridgeId, name: fridgeName);
    await tapText(tester, 'Connect another device');
    if (find.text('Yes, I have a device').evaluate().isNotEmpty) {
      await tapText(tester, 'Yes, I have a device');
    }
    await linkDevice(tester,
        product: 'Gas cylinder scale', id: gasId, name: gasName, gas: true);
    await tapText(tester, 'Open my workspace');

    // --- Dashboard shows both devices with live data ---
    await waitFor(tester, find.text('Dashboard'),
        timeout: const Duration(seconds: 60));
    await settle(tester, const Duration(seconds: 4));
    await step(tester, 'dashboard');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await step(tester, 'dashboard-scrolled');

    // --- Equipment: both devices listed ---
    await tapText(tester, 'Equipment');
    await waitFor(tester, find.text(fridgeName));
    await waitFor(tester, find.text(gasName));
    await step(tester, 'equipment');

    // --- Phone notifications: permission, registration, test push ---
    await tapText(tester, 'Settings');
    await tapText(tester, 'Notifications');
    await waitFor(tester, find.text('Phone notifications'));
    await step(tester, 'notifications-before');
    await tapText(tester, 'Enable / reconnect notifications');
    action('allow'); // host taps iOS "Allow"
    await settle(tester, const Duration(seconds: 12));
    final registered = find.text('This phone is registered');
    for (var i = 0; i < 6 && registered.evaluate().isEmpty; i++) {
      await settle(tester, const Duration(seconds: 5));
      await tester.dragFrom(const Offset(200, 300), const Offset(0, 400));
      await settle(tester, const Duration(seconds: 1));
    }
    await waitFor(tester, registered, timeout: const Duration(seconds: 30));
    await step(tester, 'notifications-registered');
    await tapText(tester, 'Send test notification');
    await settle(tester, const Duration(seconds: 6));
    // Reported, not asserted: delivery depends on the Firebase project's
    // APNs key, which is outside the app.
    // ignore: avoid_print
    print('E2E-RESULT push-test '
        '${find.textContaining('could not accept').evaluate().isEmpty ? 'accepted' : 'rejected by provider'}');
    await step(tester, 'notifications-test-sent');

    // --- Personal alert rule on the refrigeration monitor ---
    await tapText(tester, 'Equipment');
    await tapText(tester, fridgeName);
    await settle(tester, const Duration(seconds: 3));
    await step(tester, 'fridge-detail');
    await tapFinder(tester, find.textContaining(RegExp(r'^Configure (my )?alerts$')));
    await waitFor(tester, find.text('Add condition'));
    await tapText(tester, 'Add condition');
    await tapFinder(tester, find.text('At or below'));
    await tapFinder(tester, find.text('At or above').last);
    await enter(tester, 'Thresholds (°C)', '8');
    await step(tester, 'alert-rule');
    await tapText(tester, 'Save my alerts');
    await waitFor(tester, find.text('Your device alert rules are saved.'));
    await step(tester, 'alert-rule-saved');
    await tester.pageBack();
    await settle(tester, const Duration(seconds: 1));
    await tapFinder(tester, find.byTooltip('Close'));
    await settle(tester, const Duration(seconds: 1));

    // --- Breach the threshold over MQTT; the phone should get a push ---
    action('hot');
    await settle(tester, const Duration(seconds: 100));
    await step(tester, 'after-threshold-breach');

    // --- Alerts tab ---
    await tapText(tester, 'Alerts');
    await settle(tester, const Duration(seconds: 4));
    await step(tester, 'alerts');

    // --- AI assistant on the dashboard ---
    await tapText(tester, 'Home');
    await settle(tester, const Duration(seconds: 3));
    await tapFinder(tester, find.byTooltip('Ask the assistant'));
    await waitFor(tester, find.text('AI Assistant'));
    final ask = find.byWidgetPredicate((w) =>
        w is TextField &&
        (w.decoration?.hintText ?? '').startsWith('Ask anything'));
    await tapFinder(tester, ask);
    await tester.enterText(ask, 'How is this unit doing right now?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, const Duration(seconds: 3));
    await step(tester, 'assistant-thinking');
    // The input is disabled while the assistant is answering.
    bool answering() => ask
        .evaluate()
        .any((e) => (e.widget as TextField).enabled == false);
    final end = DateTime.now().add(const Duration(seconds: 150));
    while (DateTime.now().isBefore(end) && answering()) {
      await settle(tester, const Duration(seconds: 2));
    }
    await settle(tester, const Duration(seconds: 1));
    await step(tester, 'assistant-answer');
    expect(answering(), isFalse, reason: 'the assistant never answered');
    expect(find.text('Retry'), findsNothing,
        reason: 'the assistant returned an error');
    Navigator.of(tester.element(find.text('AI Assistant'))).pop();
    await settle(tester, const Duration(seconds: 1));

    // --- Sign out, then sign in with the new account ---
    await tapFinder(tester, find.byTooltip('Open navigation'));
    await tapText(tester, 'Sign out');
    final confirm = find.widgetWithText(FilledButton, 'Sign out');
    await settle(tester, const Duration(seconds: 1));
    if (confirm.evaluate().isNotEmpty) await tapFinder(tester, confirm);
    await waitFor(tester, find.text('Sign in'),
        timeout: const Duration(seconds: 30));
    await step(tester, 'signed-out');
    await enter(tester, 'Email', email);
    await enter(tester, 'Password', password);
    await tapText(tester, 'Sign in');
    await waitFor(tester, find.text('Dashboard'),
        timeout: const Duration(seconds: 60));
    await settle(tester, const Duration(seconds: 3));
    await step(tester, 'signed-in-again');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
