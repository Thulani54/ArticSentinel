import 'dart:convert';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/screens/dashboard_home.dart';
import 'package:artic_sentinel/screens/dashboard.dart' as dashboard_shell;
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// Maps are replaced so the layout test never creates a native view.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LayoutMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int creationId, PlatformViewCreatedCallback onPlatformViewCreated,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalBusiness = Constants.myBusiness;
  final originalName = Constants.myDisplayname;
  final originalMaps = GoogleMapsFlutterPlatform.instance;
  final originalFetching = GoogleFonts.config.allowRuntimeFetching;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    GoogleMapsFlutterPlatform.instance = _LayoutMap();
    Constants.myBusiness = Business(
        businessUid: 123,
        businessName: 'Layout test',
        isActive: true,
        activeDevicesCount: 1,
        isPrimary: true);
    Constants.myDisplayname = 'Equipment manager';
    latestDeviceDataList = [];
  });
  tearDown(() {
    Constants.myBusiness = originalBusiness;
    Constants.myDisplayname = originalName;
    GoogleMapsFlutterPlatform.instance = originalMaps;
    GoogleFonts.config.allowRuntimeFetching = originalFetching;
  });
  MockClient client({bool populatedZones = false}) => MockClient((request) async {
        expect(request.method, 'GET');
        final Object data = switch (request.url.path) {
          '/get_devices_by_client/123/' => [
              for (var i = 0; i < 2; i++)
                {
                  'id': i + 1,
                  'device_id': 'TEST-$i',
                  'name': 'Kitchen refrigeration monitoring equipment $i',
                  'device_type': populatedZones ? 'device2' : 'device1',
                  'is_online': i == 0,
                  'is_active': true,
                  'current_status': 'Active',
                  'latitude': '0',
                  'longitude': '0',
                  'created_at': '2026-01-01T00:00:00Z',
                  'updated_at': '2026-10-01T00:00:00Z',
                },
            ],
          '/latest-device-data/123/' => populatedZones ? [
            {
              'device_id': 'TEST-0', 'device_type': 'device2',
              'time': '2026-10-03T06:00:00Z',
              'custom_labels': {'zone_1': 'Frozen storage rear temperature'},
              for (var i = 1; i <= 8; i++) 'temp$i': -20.0 + i,
              for (var i = 1; i <= 8; i++) 'temp${i}_min': -25.0,
              for (var i = 1; i <= 8; i++) 'temp${i}_max': -10.0,
            }
          ] : [],
          '/dashboard-data/' => {
              'daily_aggregates': [],
              'hourly_aggregates': [],
              'current_data': [],
              'alerts': [],
              'timestamp': '2026-10-03T06:00:00Z'
            },
          '/alerts/' => {'alerts': []},
          _ => throw StateError('Unexpected request ${request.url.path}'),
        };
        return http.Response(jsonEncode(data), 200);
      });
  for (final width in [320.0, 430.0, 800.0]) {
    testWidgets(
        'dashboard loaded equipment and missing readings fit $width',
        (tester) => http.runWithClient(() async {
              tester.view.physicalSize = Size(width, 700);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await tester.pumpWidget(MaterialApp(
                  theme: articMobileTheme(),
                  home: Scaffold(body: width == 320
                  ? const dashboard_shell.ArticDashboard()
                  : const ArticDashboardTab())));
              await tester.pumpAndSettle();
              await tester.pump(const Duration(seconds: 2));
              expect(
                  find.text(width < 600
                      ? 'Equipment overview'
                      : 'Every connection counts.'),
                  findsOneWidget);
              expect(tester.takeException(), isNull);
              if (width < 600) {
                expect(find.textContaining('Last updated:'), findsNothing);
              }
              await tester.drag(find.byType(SingleChildScrollView).first,
                  const Offset(0, -650));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }, client));
  }
  for (final viewport in [(320.0, 1.0), (320.0, 1.3), (320.0, 1.4), (430.0, 1.0)]) {
    final (width, scale) = viewport;
    testWidgets('populated zone readings wrap on a $width phone at $scale scale',
        (tester) => http.runWithClient(() async {
              tester.view.physicalSize = Size(width, 800);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await tester.pumpWidget(MaterialApp(
                  theme: articMobileTheme(),
                  home: MediaQuery(
                    data: MediaQueryData(size: Size(width, 800),
                        textScaler: TextScaler.linear(scale)),
                    child: const Scaffold(body: ArticDashboardTab()),
                  )));
              await tester.pumpAndSettle();
              await tester.pump(const Duration(seconds: 2));
              expect(find.text('Temperature zones'), findsOneWidget);
              expect(find.text('Frozen storage rear temperature'), findsOneWidget);
              expect(find.text('Key readings'), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.ensureVisible(find.text('Frozen storage rear temperature'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }, () => client(populatedZones: true)));
  }

}
