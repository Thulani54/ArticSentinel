/// End-to-end registration + login against the real backend, driven through
/// the real UI on a device/simulator:
///   welcome tour → create a company account → add a purchased device →
///   dashboard, then a fresh sign-in with the same credentials.
///
/// Run:  flutter test integration_test/auth_flow_test.dart -d <device id>
/// The account it creates is named uiflow-<timestamp>@example.com so it can
/// be cleaned up on the server afterwards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artic_sentinel/main.dart';

Future<void> waitFor(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Finder fieldWithLabel(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label);

Future<void> enter(WidgetTester tester, String label, String text) async {
  final f = fieldWithLabel(label);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(f.first, text);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final tag = DateTime.now().millisecondsSinceEpoch;
  final email = 'uiflow-$tag@example.com';
  final password = 'UiFlow!$tag';

  testWidgets('register end-to-end, then sign in again', (tester) async {
    (await SharedPreferences.getInstance()).clear();

    // --- Splash → welcome tour (first launch) ---
    await tester.pumpWidget(MyApp(initialRoute: '/splash'));
    await waitFor(tester, find.text('Next'), timeout: const Duration(seconds: 15));
    await tapText(tester, 'Next');
    await tapText(tester, 'Next');
    await waitFor(tester, find.text('Create an account'));
    await tapText(tester, 'Create an account');

    // --- Step 1: account type (company stays selected) ---
    await waitFor(tester, find.text('Who is this account for?'));
    expect(find.text('A company'), findsOneWidget);
    await tapText(tester, 'Continue');

    // --- Step 2: details ---
    await waitFor(tester, find.text('Tell us about yourself'));
    await enter(tester, 'Company name', 'UI Flow Test Co $tag');
    await enter(tester, 'First name', 'Ui');
    await enter(tester, 'Last name', 'Flow');
    await enter(tester, 'Email', email);
    await tapText(tester, 'Continue');

    // --- Step 3: password ---
    await waitFor(tester, find.text('Secure your account'));
    await enter(tester, 'Password', password);
    await enter(tester, 'Confirm password', password);
    await tapText(tester, 'Create account');

    // --- Step 4: add a purchased device (gas cylinder) ---
    await waitFor(tester, find.text('Add your devices'));
    await tapText(tester, 'Refrigeration unit'); // open the type dropdown
    await waitFor(tester, find.text('Gas cylinder'));
    await tapText(tester, 'Gas cylinder');
    await enter(tester, 'Device ID (on the unit)', 'UIFLOW-$tag');
    await enter(tester, 'Name it (e.g. Kitchen fridge)', 'E2E test cylinder');
    await tapText(tester, 'Finish and open my dashboard');

    // --- Dashboard (signup + login + device creation over the network) ---
    await waitFor(tester, find.textContaining('Welcome back'),
        timeout: const Duration(seconds: 60));

    // Tear the app down so its refresh timers are disposed.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));

    // --- Fresh sign-in with the account we just created ---
    (await SharedPreferences.getInstance()).clear();
    await tester.pumpWidget(MyApp(initialRoute: '/login'));
    await waitFor(tester, find.text('Sign in'));
    await enter(tester, 'Email', email);
    await enter(tester, 'Password', password);
    await tapText(tester, 'Sign in');
    await waitFor(tester, find.textContaining('Welcome back'),
        timeout: const Duration(seconds: 60));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
