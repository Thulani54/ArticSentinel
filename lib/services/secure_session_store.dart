import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credentials stay in Keychain/Keystore. SharedPreferences holds only profile
/// metadata and the non-secret flag used to choose the initial route.
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                  accessibility:
                      KeychainAccessibility.first_unlock_this_device),
            );

  static final instance = SecureSessionStore();
  static const tokenKey = 'artic.session.token.v1';
  static const biometricOwnerKey = 'artic.session.biometric-owner.v1';
  static const _legacyToken = 'AUTHTOKENKEY';
  static const _legacyPassword = 'USERPASSWORDKEY';
  final FlutterSecureStorage _storage;
  Future<void>? _pending;

  // Startup, push registration and route guards can all read simultaneously.
  // Serialize migration and logout so a late migration cannot restore a token.
  Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _pending;
    final completed = Completer<void>();
    _pending = completed.future;
    Future<T> run() async {
      try {
        if (previous != null) await previous;
        return await action();
      } finally {
        if (identical(_pending, completed.future)) _pending = null;
        completed.complete();
      }
    }

    return run();
  }

  @visibleForTesting
  void resetPendingOperationsForTest() => _pending = null;

  Future<void> initialize() => _serial(_migrate);

  Future<void> _migrate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPassword);
    if (prefs.getBool('ISLOGGEDIN') == false) {
      await prefs.remove(_legacyToken);
      await _storage.delete(key: tokenKey);
      await _storage.delete(key: biometricOwnerKey);
      return;
    }
    final legacy = prefs.getString(_legacyToken);
    if (legacy != null && legacy.isNotEmpty) {
      // Remove the old copy only after a verified secure write. Fail closed if
      // the platform key store is unavailable; never use plaintext as fallback.
      await _storage.write(key: tokenKey, value: legacy);
      if (await _storage.read(key: tokenKey) != legacy) {
        throw StateError('The secure session could not be saved.');
      }
      await prefs.remove(_legacyToken);
    }
  }

  Future<String?> readToken() => _serial(() async {
        await _migrate();
        return _storage.read(key: tokenKey);
      });

  Future<void> writeToken(String token) => _serial(() async {
        if (token.isEmpty) throw ArgumentError('A session token is required.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_legacyPassword);
        await _storage.write(key: tokenKey, value: token);
        if (await _storage.read(key: tokenKey) != token) {
          throw StateError('The secure session could not be saved.');
        }
        await prefs.remove(_legacyToken);
        // Publish the flag while still holding the session queue. A concurrent
        // push/route read cannot mistake this new token for an orphaned logout.
        await prefs.setBool('ISLOGGEDIN', true);
      });

  Future<String?> biometricOwner() =>
      _serial(() => _storage.read(key: biometricOwnerKey));

  Future<void> setBiometricOwner(String? owner) => _serial(() => owner == null
      ? _storage.delete(key: biometricOwnerKey)
      : _storage.write(key: biometricOwnerKey, value: owner));

  Future<void> clear() => _serial(() async {
        final prefs = await SharedPreferences.getInstance();
        // The flag invalidates an orphaned key even if secure deletion fails.
        await prefs.setBool('ISLOGGEDIN', false);
        await prefs.remove(_legacyToken);
        await prefs.remove(_legacyPassword);
        try {
          await _storage.delete(key: tokenKey);
          await _storage.delete(key: biometricOwnerKey);
        } catch (_) {
          // An unreadable key store (e.g. a lost Keystore key) would otherwise
          // block every future sign-in. It only holds this app's session.
          await _storage.deleteAll();
        }
      });
}
