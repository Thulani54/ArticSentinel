// Data screens render in dark mode without errors. With
// --dart-define=DARK_GALLERY_OUT=<dir> each screen is also saved as a PNG.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_details_dialog.dart';
import 'package:artic_sentinel/gasmon/gas_demo_data.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/screens/dashboard_home.dart' as dashboard;
import 'package:artic_sentinel/screens/device_perfomance_tracking.dart'
    as performance;
import 'package:artic_sentinel/widgets/app_tone.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment_reading_layout_test.dart' as fixtures;

const _out = String.fromEnvironment('DARK_GALLERY_OUT');

class _NoMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int id, PlatformViewCreatedCallback callback,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(rootBundle.load('lib/assets/fonts/inter/Inter-$w.ttf'));
  }
  await inter.load();
}

MockClient _client(int type) => MockClient((req) async {
      final Object result = switch (req.url.path) {
        '/get_devices_by_client/123/' => [fixtures.device(type)],
        '/latest-device-data/123/' => [fixtures.reading(type)],
        '/dashboard-data/' => {
            'daily_aggregates': [],
            'hourly_aggregates': [],
            'current_data': [],
            'alerts': [],
            'timestamp': '2026-10-03T06:00:00Z'
          },
        '/alerts/' => {'alerts': []},
        '/api/companies/123/devices/' => {
            'devices': [fixtures.device(type)]
          },
        '/api/device-metrics/' => fixtures.analytics(type),
        _ => <String, dynamic>{},
      };
      return http.Response(jsonEncode(result), 200);
    });

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(400, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('gallery'),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: articMobileTheme(),
          home: Scaffold(body: child))));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _shoot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (_out.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('gallery')));
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$_out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    GoogleMapsFlutterPlatform.instance = _NoMap();
    Constants.myBusiness = Business(
        businessUid: 123,
        businessName: 'Dark mode',
        isActive: true,
        activeDevicesCount: 1,
        isPrimary: true);
    Constants.myDisplayname = 'Equipment manager';
    dashboard.latestDeviceDataList = [];
    dashboard.selectedDeviceId = null;
    Tone.dark = true;
    addTearDown(() => Tone.dark = false);
  });

  for (final type in [2, 3, 4, 5, 6, 7]) {
    testWidgets('dark dashboard device$type',
        (tester) => http.runWithClient(() async {
              await _mount(tester, const dashboard.ArticDashboardTab());
              await _shoot(tester, 'dashboard-device$type');
              await tester.pumpWidget(const SizedBox.shrink());
            }, () => _client(type)));
    testWidgets('dark equipment detail device$type',
        (tester) => http.runWithClient(() async {
              await _mount(tester,
                  const performance.DevicePeformanceDashboard(companyId: 123));
              await _shoot(tester, 'performance-device$type');
              await tester.pumpWidget(const SizedBox.shrink());
            }, () => _client(type)));
  }

  testWidgets('dark gas cylinder', (tester) async {
    final demo = generateGasDemoData(deviceKey: 'dark-gallery');
    final data = GasDeviceData(
        spec: demo.spec,
        readings: demo.readings,
        alerts: demo.alerts,
        pricePerKg: demo.pricePerKg,
        live: true);
    final config = GasConfig(
        gasCapacityKg: data.spec.capacityKg,
        tareKg: data.spec.tareKg,
        pricePerKg: data.pricePerKg,
        lowPct: 20,
        warningPct: 50,
        isDefault: false);
    await _mount(
        tester,
        GasCylinderDetailsDialog(
          device: Device(
              name: 'Kitchen cylinder',
              deviceId: '1133',
              deviceType: 'gas_cylinder'),
          loadData: () async => (data: data, config: config),
        ));
    await _shoot(tester, 'gas-cylinder');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
