import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_session_store.dart';

/// An optional local lock on an existing signed-in account. It never creates a
/// server session, bypasses sign-in or stores the user's password.
class BiometricLock extends ChangeNotifier {
  BiometricLock({
    SecureSessionStore? store,
    Future<bool> Function()? hasBiometrics,
    Future<bool> Function(String reason)? authenticate,
    bool? supported,
  })  : _store = store ?? SecureSessionStore.instance,
        _hasBiometrics = hasBiometrics ?? _available,
        _authenticate = authenticate ?? _verify,
        supported = supported ??
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS));

  static final instance = BiometricLock();
  static final _local = LocalAuthentication();
  static Future<bool> _available() async =>
      (await _local.getAvailableBiometrics()).isNotEmpty;
  static Future<bool> _verify(String reason) => _local.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      persistAcrossBackgrounding: false);

  final SecureSessionStore _store;
  final Future<bool> Function() _hasBiometrics;
  final Future<bool> Function(String reason) _authenticate;
  final bool supported;
  bool initialized = false;
  bool enabled = false;
  bool locked = false;
  bool busy = false;
  String? message;
  Future<void>? _initializing;
  int _generation = 0;

  Future<String?> _sessionOwner() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ISLOGGEDIN') != true) return null;
    final uid = prefs.getInt('USEREUIDKEY');
    final token = await _store.readToken();
    return uid != null && uid > 0 && token != null && token.isNotEmpty
        ? '$uid'
        : null;
  }

  Future<void> initialize() => _initializing ??= _load();

  Future<void> _load() async {
    if (supported) {
      try {
        final owner = await _sessionOwner();
        enabled = owner != null && await _store.biometricOwner() == owner;
        locked = enabled;
      } catch (_) {
        // Do not expose a possibly protected account when storage cannot read.
        locked = true;
        message = 'Your saved session cannot be opened. Sign in again.';
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> setEnabled(bool value) async {
    if (!supported || busy) return false;
    busy = true;
    message = null;
    notifyListeners();
    final generation = _generation;
    try {
      final owner = await _sessionOwner();
      if (owner == null) {
        message = 'Sign in before setting up biometric unlock.';
        return false;
      }
      if (value && !await _hasBiometrics()) {
        message =
            'Set up Face ID or a fingerprint in your phone settings first.';
        return false;
      }
      if (!await _authenticate(value
          ? 'Confirm your identity to protect ArticSentinel'
          : 'Confirm your identity to turn off biometric unlock')) {
        message = 'No changes made. You can try again.';
        return false;
      }
      if (generation != _generation || await _sessionOwner() != owner) {
        return false;
      }
      await _store.setBiometricOwner(value ? owner : null);
      enabled = value;
      locked = false;
      return true;
    } catch (_) {
      message =
          'Biometric unlock is unavailable. Check your phone settings or try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void lock() {
    if (enabled && !busy && !locked) {
      locked = true;
      message = null;
      notifyListeners();
    }
  }

  Future<bool> unlock() async {
    if (!locked || busy || !enabled) return false;
    busy = true;
    message = null;
    notifyListeners();
    final generation = _generation;
    try {
      final owner = await _sessionOwner();
      if (owner == null || await _store.biometricOwner() != owner) {
        message = 'Your session has changed. Sign in again.';
        return false;
      }
      final verified = await _authenticate('Unlock your ArticSentinel account');
      if (generation != _generation) return false;
      if (verified && await _sessionOwner() == owner) {
        locked = false;
        return true;
      }
      message = 'Not unlocked. Try again or sign in with your account.';
      return false;
    } catch (_) {
      message =
          'Biometric unlock is unavailable. Try again or sign in with your account.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// A fresh server-authenticated sign-in starts unlocked, with opt-in reset.
  Future<void> sessionAuthenticated() async {
    await _store.setBiometricOwner(null);
    sessionCleared();
  }

  void sessionCleared() {
    _generation++;
    initialized = true;
    enabled = false;
    locked = false;
    message = null;
    notifyListeners();
  }
}
