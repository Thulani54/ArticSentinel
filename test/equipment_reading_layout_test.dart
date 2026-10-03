import 'dart:convert';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/screens/dashboard_home.dart' as dashboard;
import 'package:artic_sentinel/screens/device_perfomance_tracking.dart'
    as performance;
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LayoutMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int id, PlatformViewCreatedCallback callback,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

Map<String, dynamic> device(int type) => {
      'id': 1,
      'device_id': 'TEST-0',
      'name': 'Kitchen equipment with a long device name',
      'device_type': 'device$type',
      'is_online': true,
      'is_active': true,
      'current_status': 'Active',
      'latitude': '0',
      'longitude': '0',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    };
Map<String, dynamic> reading(int type) => {
      'device_id': 'TEST-0',
      'device_type': 'device$type',
      'time': '2026-10-03T06:00:00Z',
      'custom_labels': {
        'zone_1': 'Frozen storage rear temperature',
        'comp_1': 'Kitchen compressor with long equipment label'
      },
      for (var i = 1; i <= 8; i++) 'temp$i': -20.0 + i,
      for (var i = 1; i <= 8; i++) 'temp${i}_min': -25.0,
      for (var i = 1; i <= 8; i++) 'temp${i}_max': -10.0,
      for (var i = 1; i <= 8; i++) 'temp${i}_min_time': '2026-10-01T15:06:00Z',
      'hs_temp': 44.2,
      'ls_temp': -5.2,
      'ice_temp': -16.5,
      'air_temp': 23.4,
      'wtrlvl': 46.2,
      'harvsw': false,
      'last_harvest_time': '2026-10-01T10:15:00Z',
      'harvest_count': 125,
      'wtrlvlLastEmpty': '2026-10-01T15:06:00Z',
      'wtrlvlLastFull': '2026-10-02T15:06:00Z',
      'hs_temp_min': 20.1,
      'hs_temp_max': 54.3,
      'hs_temp_min_time': '2026-10-01T15:06:00Z',
      'hs_temp_max_time': '2026-10-01T12:13:00Z',
      'amps': 5.3,
      'power_kw': 1.4,
      'energy_consumed_24h': 32.6,
      'daily_cost_estimate': 81.5,
      'energy_cost_24h': 81.5,
      for (var c = 1; c <= 8; c++)
        for (var ph = 1; ph <= 3; ph++) '${c}comph$ph': (c + ph).toDouble(),
      for (var i = 1; i <= 8; i++) 'comp${i}_avg_min': 1.2,
      for (var i = 1; i <= 8; i++) 'comp${i}_avg_max': 14.6,
      for (var i = 1; i <= 8; i++)
        'comp${i}_avg_min_time': '2026-10-01T15:06:00Z',
      for (var i = 1; i <= 8; i++)
        'comp${i}_avg_max_time': '2026-10-01T12:13:00Z',
      for (var i = 1; i <= 16; i++) 'relay$i': i.isOdd,
      for (var i = 1; i <= 16; i++) 'relay${i}_on_pct': 46.2,
      for (var i = 1; i <= 8; i++) 'prs$i': 100.0 + i,
      for (var i = 1; i <= 8; i++) 'prs${i}_min': 99.4,
      for (var i = 1; i <= 8; i++) 'prs${i}_max': 125.2,
      for (var i = 1; i <= 8; i++) 'prs${i}_min_time': '2026-10-01T15:06:00Z',
      for (var i = 1; i <= 8; i++) 'prs${i}_max_time': '2026-10-01T12:13:00Z',
      for (var i = 1; i <= 4; i++) 'tray${i}wt': 10.0 + i,
      'code_scan': 'CASTLE-LITE-300G-11458-LONG-SCAN-CODE',
      'scan_verified': true,
      'bottle_temp': 4.6,
    };
Map<String, dynamic> analytics(int type) => {
      'device_type': 'device$type',
      'temperature_analytics': {
        for (var i = 1; i <= 8; i++) 'zone$i': [i.toDouble()],
        'hs_temp': [44.2],
        'ls_temp': [-5.2],
        'ice_temp': [-16.5],
        'air_temp': [23.4],
      },
      'water_analytics': {
        'water_level': [46.2]
      },
      'amps_analytics': {
        'amps': [5.3]
      },
      'ice_machine_summary': {
        'total_harvests': 125,
        'total_readings': 1234,
        for (final k in [
          'high_side_temp',
          'low_side_temp',
          'ice_temp',
          'air_temp',
          'water_level',
          'amps'
        ])
          k: {'min': -5.2, 'max': 44.2, 'avg': 22.5}
      },
      'zone_summary': {
        'total_readings': 78,
        'zones': [
          for (var i = 1; i <= 8; i++)
            {
              'zone': i,
              'min': -2.3,
              'max': 14.4,
              'avg': 4.0,
              'min_time': '2026-10-01T15:06:00Z',
              'max_time': '2026-10-01T12:13:00Z'
            }
        ]
      },
      'overall_statistics': {
        'total_readings': 1234,
        'active_compressors': 8,
        'overall_avg_load': 8.4,
        'overall_max_load': 14.6,
        'overall_min_load': 1.2,
        'compressors': {
          for (var i = 1; i <= 8; i++)
            'compressor$i': {
              'average_amp': 8.4,
              'min_amp_time': '2026-10-01T15:06:00Z',
              'max_amp_time': '2026-10-01T12:13:00Z',
              'phase_imbalance_pct': 12.5,
              'phases': {
                for (var p = 1; p <= 3; p++)
                  'phase$p': {'min': 1.2, 'max': 14.6, 'avg': 8.4}
              }
            }
        },
        'relays': {
          for (var i = 1; i <= 16; i++)
            'relay$i': {
              'duty_cycle_pct': 46.2,
              'current_state': i.isOdd,
              'state_changes': 123,
              'runtime_hours': 14.5
            }
        },
        'sensors': {
          for (var i = 1; i <= 8; i++)
            'sensor$i': {
              'avg': 101.2,
              'min': 99.4,
              'max': 125.2,
              'min_time': '2026-10-01T15:06:00Z',
              'max_time': '2026-10-01T12:13:00Z',
              'stability_score': 83.0
            }
        },
        'tray_weights': {
          for (var i = 1; i <= 4; i++)
            'tray$i': {'min': 4.5, 'max': 15.5, 'avg': 12.2}
        },
        'total_scans': 25,
        'verified_scans': 22,
        'verification_rate': 88.0,
        'total_bottles': 15,
        'scans_in': 25,
        'scans_out': 10,
        'active_scans': 15,
        'temperature': {'min': 2.5, 'max': 8.5, 'avg': 4.6},
      }
    };
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final oldError = FlutterError.onError;
    FlutterError.onError = (details) { FlutterError.dumpErrorToConsole(details); oldError?.call(details); };
    addTearDown(() => FlutterError.onError = oldError);
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
    dashboard.latestDeviceDataList = [];
    dashboard.selectedDeviceId = null;
  });
  MockClient client(int type) => MockClient((req) async {
        expect(req.method, 'GET');
        final Object result = switch (req.url.path) {
          '/get_devices_by_client/123/' => [device(type)],
          '/latest-device-data/123/' => [reading(type)],
          '/dashboard-data/' => {
              'daily_aggregates': [],
              'hourly_aggregates': [],
              'current_data': [],
              'alerts': [],
              'timestamp': '2026-10-03T06:00:00Z'
            },
          '/alerts/' => {'alerts': []},
          '/api/companies/123/devices/' => {
              'devices': [device(type)]
            },
          '/api/device-metrics/' => analytics(type),
          _ => throw StateError('Unexpected request ${req.url.path}'),
        };
        return http.Response(jsonEncode(result), 200);
      });
  Future<void> mount(
      WidgetTester tester, Widget child, double width, double scale) async {
    final oldError = FlutterError.onError;
    FlutterError.onError = (details) { print(details.toString()); oldError?.call(details); };
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 900), textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: child))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
  }

  for (final type in [2, 3, 4, 5, 6, 7]) {
    for (final size in [(320.0, 1.0), (320.0, 1.4), (430.0, 1.0)]) {
      final (width, scale) = size;
      testWidgets(
          'dashboard device$type $width scale$scale readings stack',
          (tester) => http.runWithClient(() async {
                await mount(
                    tester, const dashboard.ArticDashboardTab(), width, scale);
                expect(tester.takeException(), isNull);
                final labels = switch (type) {
                  2 => ['Frozen storage rear temperature', 'Zone 2'],
                  3 => ['Harvest Status', 'Water Level'],
                  4 => [
                      'Kitchen compressor with long equipment label',
                      'Comp 2'
                    ],
                  5 => ['Relay 1', 'Relay 2'],
                  6 => ['Pressure 1', 'Pressure 2'],
                  _ => ['Tray 1', 'Tray 2']
                };
                for (final label in labels)
                  expect(find.text(label), findsWidgets);
                final first = tester.getTopLeft(find.text(labels[0]).first);
                final second = tester.getTopLeft(find.text(labels[1]).last);
                expect(second.dy, greaterThan(first.dy + 20));
                if (type == 3) {
                  final gauge =
                      find.byKey(const ValueKey('phone-water-level-gauge'));
                  expect(gauge, findsOneWidget);
                  final ring = find.descendant(
                      of: gauge, matching: find.byType(PieChart));
                  final ringRect = tester.getRect(ring);
                  final containerRect = tester.getRect(gauge);
                  expect(ringRect.width, lessThanOrEqualTo(144));
                  expect(containerRect.contains(ringRect.topLeft), isTrue);
                  expect(containerRect.contains(ringRect.bottomRight), isTrue);
                  expect(find.textContaining('Harvests (24h): 125'),
                      findsOneWidget);
                  expect(find.textContaining('Empty:'), findsWidgets);
                  await tester.ensureVisible(gauge);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                }
                await tester.pumpWidget(const SizedBox.shrink());
              }, () => client(type)));
      testWidgets(
          'performance device$type $width scale$scale readings fit',
          (tester) => http.runWithClient(() async {
                await mount(
                    tester,
                    const performance.DevicePeformanceDashboard(companyId: 123),
                    width,
                    scale);
                expect(tester.takeException(), isNull);
                final labels = switch (type) {
                  2 => ['Zone 1', 'Zone 2'],
                  3 => ['Ice Temp', 'High Side Temp'],
                  4 => ['Comp 1', 'Comp 2'],
                  5 => ['Relay 1', 'Relay 2'],
                  6 => ['Sensor 1', 'Sensor 2'],
                  _ => ['Tray 1', 'Tray 2']
                };
                for (final label in labels)
                  expect(find.text(label), findsWidgets);
                expect(
                    tester.getTopLeft(find.text(labels[1]).first).dy,
                    greaterThan(
                        tester.getTopLeft(find.text(labels[0]).first).dy + 20));
                await tester.ensureVisible(find.text(labels[1]).first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await tester.pumpWidget(const SizedBox.shrink());
              }, () => client(type)));
    }
  }
}
