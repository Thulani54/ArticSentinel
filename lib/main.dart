import 'widgets/app_tone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/secure_session_store.dart';
import 'services/offline_read_client.dart';
import 'widgets/biometric_session_gate.dart';
import 'screens/notification_settings.dart';
import 'screens/notification_device.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'services/push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/mobile_theme.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:uuid/uuid.dart';

// Authentication screens
import 'authentication/login.dart';
import 'authentication/signup_flow.dart';
import 'onboarding/device_setup_wizard.dart';
import 'products/products_page.dart';

// Main screens
import 'screens/alert.dart';
import 'screens/communication.dart';
import 'screens/control.dart';
import 'screens/dashboard_home.dart';
import 'screens/device_management.dart';
import 'screens/device_perfomance_tracking.dart';
import 'screens/geo_fencing.dart';
import 'screens/health_wellness.dart';
import 'screens/help.dart';
import 'screens/landing_page.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screens.dart';
import 'screens/livestock_management.dart';
import 'screens/maintanance.dart';
import 'screens/reports.dart';
import 'screens/roles.dart';
import 'screens/units.dart';

// Settings screens
import 'screens/settings/billing.dart';
import 'screens/settings/security.dart';
import 'screens/settings/settings.dart';
import 'screens/settings/terms.dart';

import 'constants/Constants.dart';
import 'layouts/main_layout.dart';
import 'models/business.dart';
import 'services/shared_preferences.dart';

bool isloggedin = false;
bool isAdmin = false;
var uuid = const Uuid();

/// Restore a complete session before choosing the first route. A key-store
/// failure must lead to sign-in, never prevent the app from drawing a screen.
Future<bool> restoreSignedInSession({SecureSessionStore? store}) async {
  final storage = store ?? SecureSessionStore.instance;
  try {
    await storage.initialize();
    if (await Sharedprefs.getUserLoggedInSharedPreference() != true) {
      throw StateError('No saved sign-in.');
    }
    final token = await storage.readToken();
    if (token == null || token.isEmpty) throw StateError('No saved token.');
    Constants.authToken = token;
    Constants.user_uid = await Sharedprefs.getUserUidSharedPreference() ?? 0;
    Constants.business_uid =
        await Sharedprefs.getBusinessUidSharedPreference() ?? 0;
    //Constants.business_name
    Constants.myDisplayname =
        (await Sharedprefs.getUserNameSharedPreference()) ?? '';
    Constants.myUsername = Constants.myDisplayname;
    Constants.myEmail =
        (await Sharedprefs.getUserEmailSharedPreference()) ?? '';
    Constants.business_name =
        (await Sharedprefs.getBusinessNameSharedPreference()) ?? '';
    Constants.myBusiness =
        await Sharedprefs.getBusinessDataPreference() ?? Business.empty();
    return true;
  } catch (_) {
    Constants.authToken = '';
    Constants.user_uid = 0;
    Constants.business_uid = 0;
    Constants.myDisplayname = '';
    Constants.myUsername = '';
    Constants.myEmail = '';
    Constants.business_name = '';
    Constants.myBusiness = Business.empty();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(
          Sharedprefs.sharedPreferenceUserLoggedInKey, false);
      await OfflineReadClient.clearAllSnapshots();
    } catch (_) {
      // If platform storage itself is unavailable, still show the public app.
    }
    return false;
  }
}

Future<void> main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await restoreSignedInSession();
  await AppAppearance.load();

  // Determine initial route
  // Phones open on the splash screen, which routes to the welcome tour on
  // first launch; the web keeps its landing page.
  final initialRoute = isLoggedIn ? '/dashboard' : (kIsWeb ? '/' : '/splash');

  final app = MyApp(initialRoute: initialRoute);
  runApp(app);
  PushNotifications.instance.attachOpenHandler((target) async {
    final loggedIn =
        await Sharedprefs.getUserLoggedInSharedPreference() == true &&
            (await Sharedprefs.getAuthTokenPreference())?.isNotEmpty == true;
    if (!loggedIn) {
      app._router.go('/login');
      return;
    }
    PushNotifications.instance.pendingTarget = null;
    app._router.push(target.route);
  });
  unawaited(PushNotifications.instance.initialize());
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({Key? key, required this.initialRoute}) : super(key: key);

  late final GoRouter _router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      // Landing page (public home page)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const LandingPage(),
      ),

      // Authentication routes (no layout)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (BuildContext context, GoRouterState state) => SignUpFlowPage(
            initialDeviceType: state.uri.queryParameters['type']),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => ProductsPage(
          onBack: () async {
            if (context.canPop()) {
              context.pop();
              return;
            }
            final signedIn =
                await Sharedprefs.getUserLoggedInSharedPreference() ?? false;
            if (context.mounted) {
              context.go(signedIn ? '/dashboard' : '/welcome');
            }
          },
          onLinkDevice: (type) async {
            final signedIn =
                await Sharedprefs.getUserLoggedInSharedPreference() ?? false;
            if (!context.mounted) return;
            context.push(Uri(
                path: signedIn ? '/device-setup' : '/signup',
                queryParameters: {'type': type}).toString());
          },
        ),
      ),
      GoRoute(
        path: '/device-setup',
        name: 'device-setup',
        redirect: (context, state) async {
          final signedIn =
              await Sharedprefs.getUserLoggedInSharedPreference() ?? false;
          final token = await Sharedprefs.getAuthTokenPreference();
          if (signedIn && token != null && token.isNotEmpty) return null;
          return Uri(path: '/login', queryParameters: {
            'next': 'device-setup',
            if (state.uri.queryParameters['type'] != null)
              'type': state.uri.queryParameters['type']!,
          }).toString();
        },
        builder: (context, state) => DeviceSetupWizard(
          initialDeviceType: state.uri.queryParameters['type'],
          onDone: () => context.go('/dashboard'),
          onBrowseProducts: () => context.push('/products'),
        ),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreens(),
      ),

      GoRoute(
          path: '/notification-device/:id',
          builder: (context, state) => NotificationDevicePage(
              deviceId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),
      GoRoute(
          path: '/notification-settings',
          builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: const NotificationSettingsPage())),

      // Main shell route with persistent layout
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MainLayout(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          // Dashboard routes
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (BuildContext context, GoRouterState state) =>
                _DashboardWrapper(),
          ),
          GoRoute(
            path: '/dashboard-home',
            name: 'dashboard-home',
            builder: (BuildContext context, GoRouterState state) =>
                _DashboardHomeWrapper(),
          ),

          // Activity and tracking routes
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (BuildContext context, GoRouterState state) =>
                const NotificationPage(),
          ),

          // Device management routes
          GoRoute(
            path: '/device-management',
            name: 'device-management',
            builder: (BuildContext context, GoRouterState state) =>
                const DeviceManagement(),
          ),
          GoRoute(
            path: '/device-performance',
            name: 'device-performance',
            builder: (BuildContext context, GoRouterState state) =>
                _DevicePerformanceWrapper(),
          ),

          // Livestock management routes
          GoRoute(
            path: '/livestock-management',
            name: 'livestock-management',
            builder: (BuildContext context, GoRouterState state) =>
                const LivestockManagement(),
          ),

          // Health and wellness routes
          GoRoute(
            path: '/health-wellness',
            name: 'health-wellness',
            builder: (BuildContext context, GoRouterState state) =>
                const HealthWellness(),
          ),

          // Geo-fencing routes
          GoRoute(
            path: '/geo-fencing',
            name: 'geo-fencing',
            builder: (BuildContext context, GoRouterState state) =>
                const EnhancedGeoFencing(),
          ),

          // Communication routes
          GoRoute(
            path: '/communication',
            name: 'communication',
            builder: (BuildContext context, GoRouterState state) =>
                CommunicationDashboard(),
          ),

          // Maintenance routes
          GoRoute(
            path: '/maintenance',
            name: 'maintenance',
            builder: (BuildContext context, GoRouterState state) =>
                MaintenanceDashboard(),
          ),

          // Control route (relay control, schedules)
          GoRoute(
            path: '/control',
            name: 'control',
            builder: (BuildContext context, GoRouterState state) =>
                const ControlScreen(),
          ),

          // Reports route
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (BuildContext context, GoRouterState state) =>
                const Reports(),
          ),

          // Units and roles routes
          GoRoute(
            path: '/units',
            name: 'units',
            builder: (BuildContext context, GoRouterState state) =>
                _UnitManagementWrapper(),
          ),
          GoRoute(
            path: '/roles',
            name: 'roles',
            builder: (BuildContext context, GoRouterState state) =>
                const RoleManagementPage(),
          ),

          // Help route
          GoRoute(
            path: '/help',
            name: 'help',
            builder: (BuildContext context, GoRouterState state) =>
                const HelpSupport(),
          ),

          // Settings routes
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (BuildContext context, GoRouterState state) =>
                const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/billing',
            name: 'settings-billing',
            builder: (BuildContext context, GoRouterState state) =>
                const BillManagement(),
          ),
          GoRoute(
            path: '/settings/security',
            name: 'settings-security',
            builder: (BuildContext context, GoRouterState state) =>
                const SecurityPage(),
          ),
          GoRoute(
            path: '/settings/terms',
            name: 'settings-terms',
            builder: (BuildContext context, GoRouterState state) =>
                const TermsOfUse(),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AppearanceScope(
        builder: (context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Artic Sentinel',
              // Palette colours switch instantly, so the theme must too.
              themeAnimationDuration: Duration.zero,
              theme: kIsWeb
                  ? ThemeData(
                      colorScheme:
                          ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                      useMaterial3: true,
                    )
                  : articMobileTheme(),
              routerConfig: _router,
              builder: (context, child) => BiometricSessionGate(
                  onSignIn: () => _router.go('/login'),
                  child: child ?? const SizedBox.shrink()),
            ));
  }
}

// Wrapper to make DevicePeformanceDashboard work properly in MainLayout
class _DevicePerformanceWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DevicePeformanceDashboard(
        companyId: Constants.myBusiness.businessUid);
  }
}

// Wrapper to make UnitManagement work properly in MainLayout
class _UnitManagementWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const UnitManagement();
  }
}

// Wrapper to make ArticDashboard work properly in MainLayout
class _DashboardWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The readings dashboard owns loading, saved snapshots and refresh.
    return const ArticDashboardTab();
  }
}

// Wrapper to make ArticDashboardTab work properly in MainLayout
class _DashboardHomeWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ArticDashboardTab();
  }
}
