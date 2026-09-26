import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import 'shared_preferences.dart';

/// Public Firebase app settings are supplied by the release build. Never put
/// the server service-account key or APNs signing key in a mobile app.
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

@pragma('vm:entry-point')
Future<void> gasPushBackground(RemoteMessage message) async {
  final options = mobileFirebaseOptions();
  if (options != null && Firebase.apps.isEmpty)
    await Firebase.initializeApp(options: options);
  // Notification payloads are shown by Android/APNs when the app is backgrounded.
}

class PushNotifications {
  PushNotifications._();
  static final instance = PushNotifications._();
  final status = ValueNotifier<String>('Phone notifications are off.');
  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _busy = false;
  VoidCallback? onOpen;
  bool _pendingOpen = false;
  String? _registeredToken;
  StreamSubscription<String>? _tokenUpdates;
  StreamSubscription<RemoteMessage>? _foreground, _opened;
  bool get configured => mobileFirebaseOptions() != null;
  bool get supported =>
      !kIsWeb &&
      [TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform);

  void _open() {
    if (onOpen == null) {
      _pendingOpen = true;
    } else {
      onOpen!();
    }
  }

  void attachOpenHandler(VoidCallback callback) {
    onOpen = callback;
    if (_pendingOpen) {
      _pendingOpen = false;
      callback();
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
          onDidReceiveNotificationResponse: (_) => _open());
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
              'gas_alerts', 'Gas level alerts',
              description: 'Cylinder alerts at 50%, 30% and 10%.',
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
                    'gas_alerts', 'Gas level alerts',
                    importance: Importance.high,
                    priority: Priority.high,
                    icon: 'ic_stat_gas')));
      });
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((_) => _open());
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
      if (initial != null || localLaunch?.didNotificationLaunchApp == true)
        _open();
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
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _registeredToken = token;
    status.value = data['delivery_configured'] == true
        ? 'Phone alerts enabled at 50%, 30% and 10% remaining.'
        : 'Phone registered. Server delivery configuration is still required.';
  }

  Future<void> unregister() async {
    if (!_ready) return;
    final auth = await Sharedprefs.getAuthTokenPreference();
    final token =
        _registeredToken ?? await FirebaseMessaging.instance.getToken();
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
    await FirebaseMessaging.instance.deleteToken();
    _registeredToken = null;
    status.value = 'Phone notifications are off.';
  }
}
