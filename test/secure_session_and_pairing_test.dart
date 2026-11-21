import 'dart:async';

import 'package:artic_sentinel/onboarding/device_pairing_code.dart';
import 'package:artic_sentinel/onboarding/device_setup_wizard.dart';
import 'package:artic_sentinel/services/biometric_lock.dart';
import 'package:artic_sentinel/services/secure_session_store.dart';
import 'package:artic_sentinel/services/shared_preferences.dart';
import 'package:artic_sentinel/widgets/biometric_session_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnavailableStorage extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      throw StateError('Key store unavailable');
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'ISLOGGEDIN': true,
      'USEREUIDKEY': 7,
      'AUTHTOKENKEY': 'test-token',
      'USERPASSWORDKEY': 'discard-this-password',
    });
  });

  test('legacy token migrates once and legacy password is erased', () async {
    final store = SecureSessionStore();
    expect(await store.readToken(), 'test-token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('AUTHTOKENKEY'), isFalse);
    expect(prefs.containsKey('USERPASSWORDKEY'), isFalse);
    expect(
        await const FlutterSecureStorage()
            .read(key: SecureSessionStore.tokenKey),
        'test-token');
    expect(await store.readToken(), 'test-token');
    await Sharedprefs.saveUserPasswordPreference('never-save-this');
    expect(prefs.containsKey('USERPASSWORDKEY'), isFalse);
  });

  test('logout ordered behind migration cannot resurrect credentials',
      () async {
    final store = SecureSessionStore();
    final reading = store.readToken();
    final clearing = store.clear();
    await reading;
    await clearing;
    expect(await store.readToken(), isNull);
    expect(await store.biometricOwner(), isNull);
    expect(
        (await SharedPreferences.getInstance()).getBool('ISLOGGEDIN'), false);
  });

  test('migration failure never returns a plaintext token and purges password',
      () async {
    final store = SecureSessionStore(storage: _UnavailableStorage());
    await expectLater(store.readToken(), throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('USERPASSWORDKEY'), false);
    // The token is retained only for a subsequent secure migration attempt.
    expect(prefs.getString('AUTHTOKENKEY'), 'test-token');
    final lock = BiometricLock(store: store, supported: true);
    await lock.initialize();
    expect(lock.locked, true);
  });

  test('logged-out preference invalidates orphaned keychain session', () async {
    FlutterSecureStorage.setMockInitialValues(
        {SecureSessionStore.tokenKey: 'orphan-token'});
    SharedPreferences.setMockInitialValues(
        {'ISLOGGEDIN': false, 'AUTHTOKENKEY': 'stale'});
    expect(await SecureSessionStore().readToken(), isNull);
  });

  test('concurrent read after new login cannot delete its secure token',
      () async {
    SharedPreferences.setMockInitialValues({'ISLOGGEDIN': false});
    final store = SecureSessionStore();
    final write = store.writeToken('new-server-token');
    final read = store.readToken();
    await write;
    expect(await read, 'new-server-token');
    expect((await SharedPreferences.getInstance()).getBool('ISLOGGEDIN'), true);
  });

  test('enabling requires enrolled biometrics and successful authentication',
      () async {
    final unavailable = BiometricLock(
        supported: true,
        hasBiometrics: () async => false,
        authenticate: (_) async => true);
    await unavailable.initialize();
    expect(await unavailable.setEnabled(true), false);
    expect(unavailable.enabled, false);
    final canceled = BiometricLock(
        supported: true,
        hasBiometrics: () async => true,
        authenticate: (_) async => false);
    await canceled.initialize();
    expect(await canceled.setEnabled(true), false);
    expect(await SecureSessionStore.instance.biometricOwner(), isNull);
  });

  test('biometric opt-in survives restart for same signed-in account only',
      () async {
    final lock = BiometricLock(
        supported: true,
        hasBiometrics: () async => true,
        authenticate: (_) async => true);
    await lock.initialize();
    expect(await lock.setEnabled(true), true);
    final restarted =
        BiometricLock(supported: true, authenticate: (_) async => false);
    await restarted.initialize();
    expect(restarted.locked, true);
    expect(await restarted.unlock(), false);
    expect(restarted.locked, true);
    (await SharedPreferences.getInstance()).setInt('USEREUIDKEY', 8);
    final anotherAccount = BiometricLock(supported: true);
    await anotherAccount.initialize();
    expect(anotherAccount.enabled, false);
    expect(anotherAccount.locked, false);
  });

  test('logout during authentication cannot unlock or re-enable a session',
      () async {
    final reply = Completer<bool>();
    final lock = BiometricLock(
        supported: true,
        hasBiometrics: () async => true,
        authenticate: (_) => reply.future);
    await lock.initialize();
    final enabling = lock.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    lock.sessionCleared();
    reply.complete(true);
    expect(await enabling, false);
    expect(lock.enabled, false);
  });

  testWidgets('app gate obscures private content after backgrounding',
      (tester) async {
    var permit = true;
    final lock = BiometricLock(
        supported: true,
        hasBiometrics: () async => true,
        authenticate: (_) async => permit);
    await lock.initialize();
    await lock.setEnabled(true);
    await tester.pumpWidget(MaterialApp(
        home: BiometricSessionGate(
            lock: lock,
            onSignIn: () {},
            child: const Scaffold(body: Text('Private readings')))));
    await tester.pumpAndSettle();
    expect(find.text('Private readings'), findsOneWidget);
    permit = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Private readings'), findsNothing);
    expect(find.text('Your workspace is locked'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(lock.locked, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Private readings'), findsNothing);
    permit = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Private readings'), findsOneWidget);
  });

  test('QR label supports versioned gas and bottle identifiers', () {
    final gas = DevicePairingCode.parse(
        'articsentinel://pair?v=1&type=gas_cylinder&id=1133');
    expect(gas?.deviceId, '1133');
    expect(gas?.deviceType, 'gas_cylinder');
    expect(
        DevicePairingCode.parse(
                'https://articsentinel.com/pair?v=1&type=device7&id=D7-001')
            ?.deviceType,
        'device7');
  });

  test(
      'QR rejects unknown hosts, credentials, duplicate parameters and unsafe IDs',
      () {
    for (final invalid in [
      'https://evil.example/pair?v=1&type=device7&id=D7-001',
      'https://articsentinel.com.evil.example/pair?v=1&type=device7&id=D7-001',
      'https://someone@articsentinel.com/pair?v=1&type=device7&id=D7-001',
      'http://articsentinel.com/pair?v=1&type=device7&id=D7-001',
      'https://articsentinel.com:8443/pair?v=1&type=device7&id=D7-001',
      'articsentinel://pair?v=1&type=device7&id=D7-001&id=other',
      'articsentinel://pair?v=2&type=device7&id=D7-001',
      'articsentinel://pair?v=1&type=unknown&id=D7-001',
      'articsentinel://pair?v=1&type=device7&id=../secret',
      'articsentinel://pair?v=1&type=device7&id=D7-001&token=secret',
      'articsentinel://pair?v=1&type=device7&id=D7-001#secret',
      'articsentinel://pair?v=1&type=device7&id=%FF',
      'D7-001',
    ]) {
      expect(DevicePairingCode.parse(invalid), isNull, reason: invalid);
    }
  });

  testWidgets('confirmed QR fills in existing wizard without registration',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: DeviceSetupWizard(
      initialDeviceType: 'gas_cylinder',
      scanCode: (_) async =>
          const DevicePairingCode(deviceId: 'D7-001', deviceType: 'device7'),
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Scan device QR code'));
    await tester.tap(find.text('Scan device QR code'));
    await tester.pumpAndSettle();
    expect(find.text('Meet your bottle vetting machine'), findsOneWidget);
    expect(find.text('D7-001'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
  });
}
