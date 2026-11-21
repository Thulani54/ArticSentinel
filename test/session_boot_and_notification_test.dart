import 'dart:async';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/main.dart' show restoreSignedInSession;
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/screens/notification_device.dart';
import 'package:artic_sentinel/services/secure_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReadFailureStore extends SecureSessionStore {
  @override
  Future<String?> readToken() async => throw StateError('Keychain unavailable');
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'ISLOGGEDIN': true,
      'USEREUIDKEY': 7,
      'BUSINESSUIDKEY': 9,
      'USERNAMEKEY': 'Current Account',
      'USEREMAILKEY': 'current@example.test',
    });
    FlutterSecureStorage.setMockInitialValues(
        {SecureSessionStore.tokenKey: 'current-token'});
  });

  test('keychain read failure after migration safely falls back to sign-in',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'artic.reading.snapshot.v1.test', 'stale private readings');
    Constants.authToken = 'stale-token';
    Constants.user_uid = 99;
    Constants.myEmail = 'previous@example.test';
    expect(await restoreSignedInSession(store: _ReadFailureStore()), false);
    expect(prefs.getBool('ISLOGGEDIN'), false);
    expect(prefs.containsKey('artic.reading.snapshot.v1.test'), false);
    expect(Constants.authToken, isEmpty);
    expect(Constants.myEmail, isEmpty);
    expect(Constants.user_uid, 0);
  });

  test('valid startup restores secure token and matching account scope',
      () async {
    expect(await restoreSignedInSession(), true);
    expect(Constants.authToken, 'current-token');
    expect(Constants.user_uid, 7);
    expect(Constants.business_uid, 9);
    expect(Constants.myEmail, 'current@example.test');
  });

  test('missing secure token does not restore a preference-only session',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    expect(await restoreSignedInSession(), false);
    expect(
        (await SharedPreferences.getInstance()).getBool('ISLOGGEDIN'), false);
  });

  testWidgets(
      'notification inventory timeout becomes retryable and ignores late result',
      (tester) async {
    final late = Completer<List<Device>>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: NotificationDevicePage(
      deviceId: 42,
      requestTimeout: const Duration(milliseconds: 50),
      loadDevices: () => ++calls == 1 ? late.future : Future.value([]),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'The connection is taking too long. Check your network and retry.'),
        findsOneWidget);
    late.complete([
      Device(
          id: 42,
          name: 'Late private equipment',
          deviceId: 'G42',
          deviceType: 'gas_cylinder')
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Late private equipment'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('This equipment is no longer available to your account.'),
        findsOneWidget);
  });

  testWidgets('notification inventory cannot publish after account changes',
      (tester) async {
    final pending = Completer<List<Device>>();
    await tester.pumpWidget(MaterialApp(
        home: NotificationDevicePage(
            deviceId: 42, loadDevices: () => pending.future)));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('USEREUIDKEY', 8);
    pending.complete([
      Device(
          id: 42,
          name: 'Previous account equipment',
          deviceId: 'G42',
          deviceType: 'gas_cylinder')
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Previous account equipment'), findsNothing);
    expect(
        find.text(
            'Your account has changed. Reopen this notification from your current account.'),
        findsOneWidget);
  });
}
