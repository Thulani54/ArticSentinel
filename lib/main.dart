import 'package:artic_sentinel/screens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:uuid/uuid.dart';

// Authentication screens
import 'authentication/login.dart';
import 'authentication/signup.dart';

// Main screens
import 'screens/alert.dart';
import 'screens/communication.dart';
import 'screens/dashboard_home.dart';
import 'screens/device_management.dart';
import 'screens/device_perfomance_tracking.dart';
import 'screens/geo_fencing.dart';
import 'screens/health_wellness.dart';
import 'screens/help.dart';
import 'screens/livestock_management.dart';
import 'screens/maintanance.dart';
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

Future<void> main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is logged in
  final bool isLoggedIn =
      await Sharedprefs.getUserLoggedInSharedPreference() ?? false;

  // Setup initial data if logged in
  if (isLoggedIn) {
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
  }

  // Determine initial route
  final initialRoute = isLoggedIn ? '/dashboard' : '/login';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({Key? key, required this.initialRoute}) : super(key: key);

  late final GoRouter _router = GoRouter(
    initialLocation: initialRoute,
    routes: [
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
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpPage(),
      ),

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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Artic Sentinel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
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
    return const ArticDashboard();
  }
}

// Wrapper to make ArticDashboardTab work properly in MainLayout
class _DashboardHomeWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ArticDashboardTab();
  }
}
