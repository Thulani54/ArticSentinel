import 'notification_target.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import 'shared_preferences.dart';

/// Public Firebase app settings may be supplied by the release build. When they
/// are not, Android falls back to android/app/google-services.json, which the
/// Google Services Gradle plugin compiles into the APK. Never put the server
/// service-account key or APNs signing key in a mobile app.
FirebaseOptions? mobileFirebaseOptions() {
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const sender = String.fromEnvironment('FIREBASE_SENDER_ID');
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final app = ios
      ? const String.fromEnvironment('FIREBASE_IOS_APP_ID')
      : const String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  final key = ios
      ? const String.fromEnvironment('FIREBASE_IOS_API_KEY')
      : const String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  if ([project, sender, app, key].any((v) => v.isEmpty)) return null;
  return FirebaseOptions(
      apiKey: key,
      appId: app,
      messagingSenderId: sender,
      projectId: project,
      iosBundleId: ios ? 'com.navario.articSentinel' : null);
}

bool get _firebaseAvailable =>
    mobileFirebaseOptions() != null ||
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

@pragma('vm:entry-point')
Future<void> gasPushBackground(RemoteMessage message) async {
  if (_firebaseAvailable && Firebase.apps.isEmpty)
    await Firebase.initializeApp(options: mobileFirebaseOptions());
  // Notification payloads are shown by Android/APNs when the app is backgrounded.
}

class PushNotifications {
  PushNotifications._();
  static final instance = PushNotifications._();
  final status = ValueNotifier<String>('Phone notifications are off.');
  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _busy = false;
  void Function(NotificationTarget)? onOpen;
  NotificationTarget? pendingTarget;
  String? _registeredToken;
  Future<void>? _registration;
  bool _unregistering = false;
  StreamSubscription<String>? _tokenUpdates;
  StreamSubscription<RemoteMessage>? _foreground, _opened;
  bool get configured => _firebaseAvailable;
  bool get supported =>
      !kIsWeb &&
      [TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform);

  void _open([Map<String, dynamic> data = const {}]) {
    pendingTarget = NotificationTarget.fromData(data);
    onOpen?.call(pendingTarget!);
  }

  void resumePendingOpen() {
    final target = pendingTarget;
    if (target != null) onOpen?.call(target);
  }

  void attachOpenHandler(void Function(NotificationTarget) callback) {
    onOpen = callback;
    resumePendingOpen();
  }

  Map<String, dynamic> _payload(String? value) {
    try {
      return Map<String, dynamic>.from(jsonDecode(value ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> initialize() async {
    if (_ready || !supported || _busy) return;
    if (!configured) {
      status.value =
          'Push notifications need the Firebase release configuration.';
      return;
    }
    _busy = true;
    try {
      if (Firebase.apps.isEmpty)
        await Firebase.initializeApp(options: mobileFirebaseOptions());
      FirebaseMessaging.onBackgroundMessage(gasPushBackground);
      await _local.initialize(
          settings: const InitializationSettings(
              android: AndroidInitializationSettings('ic_stat_gas'),
              iOS: DarwinInitializationSettings(
                  requestAlertPermission: false,
                  requestBadgePermission: false,
                  requestSoundPermission: false)),
          onDidReceiveNotificationResponse: (response) =>
              _open(_payload(response.payload)));
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
              'gas_alerts', 'Device alerts',
              description: 'Your device threshold notifications.',
              importance: Importance.high));
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
              alert: true, badge: true, sound: true);
      _foreground = FirebaseMessaging.onMessage.listen((message) async {
        if (defaultTargetPlatform != TargetPlatform.android) return;
        final n = message.notification;
        if (n == null) return;
        await _local.show(
            id: (message.messageId ?? DateTime.now().toIso8601String())
                    .hashCode &
                0x7fffffff,
            title: n.title,
            body: n.body,
            payload: jsonEncode(message.data),
            notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                    'gas_alerts', 'Device alerts',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: 'ic_stat_gas')));
      });
      _opened = FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _open(message.data));
      _tokenUpdates =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        try {
          await _register(token);
        } catch (_) {
          status.value = 'Notification registration needs retrying.';
        }
      });
      _ready = true;
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      final localLaunch = await _local.getNotificationAppLaunchDetails();
      if (initial != null) {
        _open(initial.data);
      } else if (localLaunch?.didNotificationLaunchApp == true) {
        _open(_payload(localLaunch?.notificationResponse?.payload));
      }
      await sync();
    } catch (_) {
      status.value = 'Could not initialize phone notifications. Try again.';
    } finally {
      _busy = false;
    }
  }

  Future<void> enable() async {
    await initialize();
    if (!_ready) return;
    try {
      final permission = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        status.value =
            'Notifications are blocked. Enable ArticSentinel notifications in phone settings.';
        return;
      }
      await sync();
    } catch (_) {
      status.value =
          'Could not enable notifications. Check your connection and retry.';
    }
  }

  Future<void> sync() async {
    if (!_ready) return;
    if (await Sharedprefs.getUserLoggedInSharedPreference() != true) return;
    try {
      final p = await FirebaseMessaging.instance.getNotificationSettings();
      if (![AuthorizationStatus.authorized, AuthorizationStatus.provisional]
          .contains(p.authorizationStatus)) {
        status.value = 'Phone notifications are off.';
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        status.value =
            'Waiting for Apple notification registration. Retry shortly.';
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (_) {
      status.value =
          'Could not register this phone. Check your connection and retry.';
    }
  }

  Future<void> _register(String token) async {
    if (_unregistering) return;
    final previous = _registration;
    final done = Completer<void>();
    _registration = done.future;
    try {
      if (previous != null) await previous;
      if (!_unregistering) await _registerNow(token);
    } finally {
      if (identical(_registration, done.future)) _registration = null;
      done.complete();
    }
  }

  Future<void> _registerNow(String token) async {
    final auth = await Sharedprefs.getAuthTokenPreference();
    final business = await Sharedprefs.getBusinessUidSharedPreference();
    if (auth == null ||
        business == null ||
        await Sharedprefs.getUserLoggedInSharedPreference() != true) return;
    final response = await http
        .post(Uri.parse('${Constants.articBaseUrl2}api/push/register/'),
            headers: {
              'Authorization': 'Token $auth',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'business_id': business,
              'token': token,
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android'
            }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw StateError('Registration failed');
    if (_unregistering ||
        auth != await Sharedprefs.getAuthTokenPreference() ||
        business != await Sharedprefs.getBusinessUidSharedPreference() ||
        await Sharedprefs.getUserLoggedInSharedPreference() != true) return;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _registeredToken = token;
    status.value = data['delivery_configured'] == true
        ? 'Phone alerts enabled. Configure thresholds on each device.'
        : 'Phone registered. Server delivery configuration is still required.';
  }

  Future<Map<String, dynamic>> _phoneRequest(String path, String token) async {
    final auth = await Sharedprefs.getAuthTokenPreference();
    if (auth == null || auth.isEmpty)
      throw StateError('Sign in to check phone notifications.');
    final response = await http
        .post(Uri.parse('${Constants.articBaseUrl2}api/push/$path'),
            headers: {
              'Authorization': 'Token $auth',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'token': token}))
        .timeout(const Duration(seconds: 25));
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError(
          'The notification service could not be reached. Try again.');
    }
    if (response.statusCode != 200)
      throw StateError(
          data['error'] as String? ?? 'The notification request failed.');
    return data;
  }

  Future<Map<String, dynamic>> diagnostics() async {
    final result = <String, dynamic>{
      'supported': supported,
      'configured': configured
    };
    if (!supported || !configured) return result;
    await initialize();
    if (!_ready) {
      result['error'] = status.value;
      return result;
    }
    final permission =
        await FirebaseMessaging.instance.getNotificationSettings();
    result['permission'] = permission.authorizationStatus.name;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final platform = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      result['system_enabled'] = await platform?.areNotificationsEnabled();
      final channels = await platform?.getNotificationChannels();
      final channel = channels?.where((c) => c.id == 'gas_alerts').firstOrNull;
      result['channel_enabled'] =
          channel != null && channel.importance != Importance.none;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      result['apple_registered'] =
          await FirebaseMessaging.instance.getAPNSToken() != null;
      if (result['apple_registered'] != true) return result;
    }
    final token = await FirebaseMessaging.instance.getToken();
    result['phone_token_ready'] = token != null;
    if (token != null) {
      try {
        result.addAll(await _phoneRequest('status/', token));
      } catch (error) {
        result['error'] = error.toString().replaceFirst('Bad state: ', '');
      }
    }
    return result;
  }

  Future<String> sendTest() async {
    await initialize();
    await sync();
    if (!_ready) throw StateError(status.value);
    final permission =
        await FirebaseMessaging.instance.getNotificationSettings();
    if (![AuthorizationStatus.authorized, AuthorizationStatus.provisional]
        .contains(permission.authorizationStatus)) {
      throw StateError(
          'Allow notifications in phone settings before sending a test.');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final platform = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final channels = await platform?.getNotificationChannels();
      final channel = channels?.where((c) => c.id == 'gas_alerts').firstOrNull;
      if (await platform?.areNotificationsEnabled() == false ||
          channel?.importance == Importance.none) {
        throw StateError(
            'Enable notifications and the Device alerts channel in phone settings first.');
      }
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      throw StateError(
          'Waiting for Apple notification registration. Try again shortly.');
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null)
      throw StateError(
          'This phone has no notification registration yet. Enable notifications first.');
    final result = await _phoneRequest('test/', token);
    if (result['accepted'] != true)
      throw StateError('The test was not accepted. Try again.');
    return result['message'] as String;
  }

  Future<void> unregister() async {
    _unregistering = true;
    try {
      await _registration;
      await _unregisterNow();
    } finally {
      _unregistering = false;
    }
  }

  Future<void> _unregisterNow() async {
    if (!_ready) return;
    final auth = await Sharedprefs.getAuthTokenPreference();
    // Sign-out must not wait on Play Services; an unreachable FCM can hang.
    String? token = _registeredToken;
    try {
      token ??= await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (auth != null && token != null) {
      try {
        await http
            .post(Uri.parse('${Constants.articBaseUrl2}api/push/unregister/'),
                headers: {
                  'Authorization': 'Token $auth',
                  'Content-Type': 'application/json'
                },
                body: jsonEncode({'token': token}))
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        /* Deleting the FCM token below also prevents delivery to this installation. */
      }
    }
    try {
      await FirebaseMessaging.instance
          .deleteToken()
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
    _registeredToken = null;
    status.value = 'Phone notifications are off.';
  }
}
