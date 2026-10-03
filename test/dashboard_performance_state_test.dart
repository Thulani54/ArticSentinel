import 'dart:async';
import 'dart:convert';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/models/dashboard.dart';
import 'package:artic_sentinel/screens/dashboard_home.dart' as home;
import 'package:artic_sentinel/screens/device_perfomance_tracking.dart' as perf;
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_reading_layout_test.dart' show device, reading, analytics;

class _NoMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int id, PlatformViewCreatedCallback callback,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

http.Response json(Object value) => http.Response(jsonEncode(value), 200);
const gasResponse = {
  'config': {
    'gas_capacity_kg': 9,
    'tare_kg': 7.6,
    'price_per_kg': 33,
    'low_threshold_pct': 10,
    'warning_threshold_pct': 30,
    'is_default': true
  },
  'latest': null,
  'readings': []
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalBusiness = Constants.myBusiness;
  final originalMaps = GoogleMapsFlutterPlatform.instance;
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    GoogleMapsFlutterPlatform.instance = _NoMap();
    Constants.myBusiness = Business(
        businessUid: 123,
        businessName: 'State test',
        isActive: true,
        activeDevicesCount: 0,
        isPrimary: true);
    Constants.myDisplayname = 'Test account';
    home.latestDeviceDataList = [
      LatestDeviceData.fromJson(reading(3))
    ]; // Legacy data from another screen/account must never leak.
  });
  tearDown(() {
    Constants.myBusiness = originalBusiness;
    GoogleMapsFlutterPlatform.instance = originalMaps;
    home.latestDeviceDataList = [];
  });
  Future<void> mount(WidgetTester t, Widget child,
      {double height = 800, double scale = 1, bool pending = false}) async {
    t.view.physicalSize = Size(320, height);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: MediaQuery(
            data: MediaQueryData(
                size: Size(320, height), textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: child))));
    if (pending) {
      await t.pump(const Duration(milliseconds: 1));
      await t.pump();
    } else {
      await t.pumpAndSettle();
    }
  }

  void noFridge() {
    for (final text in [
      'Key readings',
      'Performance Score',
      'Temperature Analytics',
      'Pressure Analytics',
      'Detailed Metrics - Refrigeration Unit',
      'Current Readings'
    ]) {
      expect(find.text(text), findsNothing);
    }
  }

  MockClient dashboardClient(
          {List<Map<String, dynamic>> inventory = const [],
          List<Map<String, dynamic>> rows = const [],
          bool fail = false}) =>
      MockClient((r) async {
        if (r.url.path == '/api/gas/readings/') {
          expectSync(r.method, 'POST');
          return json(gasResponse);
        }
        expectSync(r.method, 'GET');
        if (fail) return http.Response('Unavailable', 503);
        return switch (r.url.path) {
          '/get_devices_by_client/123/' => json(inventory),
          '/latest-device-data/123/' => json(rows),
          '/dashboard-data/' => json({
              'daily_aggregates': [],
              'hourly_aggregates': [],
              'current_data': [],
              'alerts': []
            }),
          '/alerts/' => json({'alerts': []}),
          _ => throw StateError('Unexpected request ${r.url}'),
        };
      });
  for (final screen in ['dashboard', 'performance']) {
    for (final scenario in ['empty', 'error']) {
      testWidgets(
          '$screen $scenario state fits short 320px enlarged text',
          (t) => http.runWithClient(() async {
                await mount(
                    t,
                    screen == 'dashboard'
                        ? const home.ArticDashboardTab()
                        : const perf.DevicePeformanceDashboard(companyId: 123),
                    height: 380,
                    scale: 1.4);
                expect(
                    find.text(scenario == 'empty'
                        ? 'No devices yet'
                        : 'Equipment could not be loaded'),
                    findsOneWidget);
                noFridge();
                expect(t.takeException(), isNull);
                await t.pumpWidget(const SizedBox.shrink());
                await t.pump(const Duration(seconds: 3));
              },
                  () => screen == 'dashboard'
                      ? dashboardClient(fail: scenario == 'error')
                      : MockClient((r) async {
                          expectSync(r.method, 'GET');
                          return scenario == 'error'
                              ? http.Response('', 503)
                              : json({'devices': []});
                        })));
    }
    testWidgets(
        '$screen gas-only offline inventory never shows refrigerator metrics',
        (t) => http.runWithClient(() async {
              final child = screen == 'dashboard'
                  ? const home.ArticDashboardTab()
                  : const perf.DevicePeformanceDashboard(companyId: 123);
              await mount(t, child);
              noFridge();
              expect(find.text('Waiting for the first reading'), findsWidgets);
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox.shrink());
              await t.pump(const Duration(seconds: 3));
            },
                () => screen == 'dashboard'
                    ? dashboardClient(inventory: [
                        {
                          ...device(1),
                          'device_type': 'gas_cylinder',
                          'is_online': false
                        }
                      ])
                    : MockClient((r) async {
                        if (r.url.path == '/api/gas/readings/') {
                          expectSync(r.method, 'POST');
                          return json(gasResponse);
                        }
                        expectSync(r.method, 'GET');
                        expectSync(r.url.path, '/api/companies/123/devices/');
                        return json({
                          'devices': [
                            {
                              ...device(1),
                              'device_type': 'gas_cylinder',
                              'is_online': false
                            }
                          ]
                        });
                      })));
  }
  for (final rows in [
    <Map<String, dynamic>>[],
    [
      {
        'device_id': 'TEST-0',
        'device_type': 'device1',
        'time': '2026-10-03T06:00:00Z'
      }
    ]
  ]) {
    testWidgets(
        'dashboard missing telemetry (${rows.length} rows) clears stale global metrics',
        (t) => http.runWithClient(() async {
              await mount(t, const home.ArticDashboardTab());
              expect(find.text('No readings yet'), findsOneWidget);
              noFridge();
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox.shrink());
              await t.pump(const Duration(seconds: 3));
            }, () => dashboardClient(inventory: [device(1)], rows: rows)));
  }
  testWidgets('successful empty refresh clears previous dashboard readings',
      (t) async {
    var empty = false;
    await http.runWithClient(() async {
      await mount(t, const home.ArticDashboardTab());
      expect(find.text('Harvest Status'), findsOneWidget);
      empty = true;
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 30));
      await t.pumpAndSettle();
      expect(find.text('No readings yet'), findsOneWidget);
      expect(find.text('Harvest Status'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async {
              expectSync(r.method, 'GET');
              if (r.url.path == '/latest-device-data/123/')
                return json(empty ? [] : [reading(3)]);
              return dashboardClient(inventory: [device(3)])
                  .send(http.Request(r.method, r.url))
                  .then(http.Response.fromStream);
            }));
  });
  testWidgets(
      'dashboard refresh failure retains current device readings with notice',
      (t) async {
    var fail = false;
    await http.runWithClient(() async {
      await mount(t, const home.ArticDashboardTab());
      expect(find.text('Harvest Status'), findsOneWidget);
      fail = true;
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 30));
      await t.pumpAndSettle();
      expect(find.text('Refresh unavailable'), findsOneWidget);
      expect(find.text('Harvest Status'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async {
              if (fail) return http.Response('', 503);
              return dashboardClient(inventory: [device(3)], rows: [reading(3)])
                  .send(http.Request(r.method, r.url))
                  .then(http.Response.fromStream);
            }));
  });
  testWidgets(
      'dashboard removed selection does not fall back to another reading',
      (t) async {
    var replace = false;
    await http.runWithClient(() async {
      await mount(t, const home.ArticDashboardTab());
      expect(find.text('Harvest Status'), findsOneWidget);
      replace = true;
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 30));
      await t.pumpAndSettle();
      expect(find.text('Harvest Status'), findsNothing);
      expect(find.text('No readings yet'), findsOneWidget);
      noFridge();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async => dashboardClient(inventory: [
              replace ? {...device(1), 'device_id': 'NEW'} : device(3)
            ], rows: [
              reading(3)
            ])
                .send(http.Request(r.method, r.url))
                .then(http.Response.fromStream)));
  });
  testWidgets(
      'performance empty analytics is an empty state rather than zero readings',
      (t) => http.runWithClient(() async {
            await mount(
                t, const perf.DevicePeformanceDashboard(companyId: 123));
            expect(find.text('No readings in this period'), findsOneWidget);
            expect(find.text('0.0°C'), findsNothing);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
          },
              () => MockClient((r) async {
                    expectSync(r.method, 'GET');
                    return json(r.url.path.contains('/companies/')
                        ? {
                            'devices': [device(2)]
                          }
                        : {});
                  })));
  for (final telemetry in [
    {
      'temperature_analytics': {
        'labels': ['10:00'],
        'timestamps': ['2026-10-03T10:00:00Z']
      }
    },
    {
      'temperature_analytics': {
        'labels': ['10:00'],
        'zone1': [null]
      }
    }
  ]) {
    testWidgets(
        'performance metadata or null-only telemetry is not a reading: $telemetry',
        (t) => http.runWithClient(() async {
              await mount(
                  t, const perf.DevicePeformanceDashboard(companyId: 123));
              expect(find.text('No readings in this period'), findsOneWidget);
              expect(find.text('0.0°C'), findsNothing);
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox.shrink());
            },
                () => MockClient((r) async {
                      expectSync(r.method, 'GET');
                      return json(r.url.path.contains('/companies/')
                          ? {
                              'devices': [device(2)]
                            }
                          : telemetry);
                    })));
  }
  for (final screen in ['dashboard', 'performance']) {
    testWidgets(
        '$screen network timeout provides Retry',
        (t) => http.runWithClient(() async {
              await mount(
                  t,
                  screen == 'dashboard'
                      ? const home.ArticDashboardTab()
                      : const perf.DevicePeformanceDashboard(companyId: 123),
                  pending: true);
              await t.pump(const Duration(seconds: 21));
              await t.pumpAndSettle();
              expect(
                  find.text('Equipment could not be loaded'), findsOneWidget);
              expect(find.text('Retry'), findsOneWidget);
              noFridge();
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox.shrink());
            },
                () => MockClient((r) {
                      expectSync(r.method, 'GET');
                      return Completer<http.Response>().future;
                    })));
  }
  testWidgets(
      'performance zero is a real reported reading',
      (t) => http.runWithClient(() async {
            await mount(
                t, const perf.DevicePeformanceDashboard(companyId: 123));
            expect(find.text('No readings in this period'), findsNothing);
            expect(find.text('0.0°C'), findsWidgets);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
          },
              () => MockClient((r) async {
                    expectSync(r.method, 'GET');
                    return json(r.url.path.contains('/companies/')
                        ? {
                            'devices': [device(2)]
                          }
                        : {
                            'temperature_analytics': {
                              'zone1': [0.0]
                            }
                          });
                  })));
  testWidgets(
      'performance selection failure cannot show the previous device data',
      (t) async {
    await http.runWithClient(() async {
      await mount(t, const perf.DevicePeformanceDashboard(companyId: 123));
      expect(find.text('1.0°C'), findsWidgets);
      t
          .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).first)
          .onChanged!('SECOND');
      await t.pumpAndSettle();
      expect(find.text('Readings could not be loaded'), findsOneWidget);
      expect(find.text('1.0°C'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async {
              expectSync(r.method, 'GET');
              if (r.url.path.contains('/companies/'))
                return json({
                  'devices': [
                    device(2),
                    {
                      ...device(2),
                      'id': 2,
                      'device_id': 'SECOND',
                      'name': 'Second device'
                    }
                  ]
                });
              if (r.url.queryParameters['device_id'] == 'SECOND')
                return http.Response('', 503);
              return json(analytics(2));
            }));
  });
  testWidgets('performance discards a delayed response after switching devices',
      (t) async {
    final first = Completer<http.Response>();
    Map<String, dynamic> response(double value) {
      final data = analytics(2);
      (data['temperature_analytics'] as Map<String, dynamic>)['zone1'] = [
        value
      ];
      return data;
    }

    await http.runWithClient(() async {
      await mount(t, const perf.DevicePeformanceDashboard(companyId: 123),
          pending: true);
      t
          .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>).first)
          .onChanged!('SECOND');
      await t.pumpAndSettle();
      expect(find.text('22.0°C'), findsWidgets);
      first.complete(json(response(99.0)));
      await t.pumpAndSettle();
      expect(find.text('22.0°C'), findsWidgets);
      expect(find.text('99.0°C'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async {
              expectSync(r.method, 'GET');
              if (r.url.path.contains('/companies/'))
                return json({
                  'devices': [
                    device(2),
                    {
                      ...device(2),
                      'id': 2,
                      'device_id': 'SECOND',
                      'name': 'Second device'
                    }
                  ]
                });
              if (r.url.queryParameters['device_id'] == 'TEST-0')
                return first.future;
              return json(response(22.0));
            }));
  });
  testWidgets(
      'performance background failure keeps labelled last-known readings',
      (t) async {
    var fail = false;
    await http.runWithClient(() async {
      await mount(t, const perf.DevicePeformanceDashboard(companyId: 123));
      expect(find.text('1.0°C'), findsWidgets);
      fail = true;
      await t.pump(const Duration(seconds: 30));
      await t.pumpAndSettle();
      expect(find.text('Refresh unavailable'), findsOneWidget);
      expect(find.text('1.0°C'), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((r) async {
              expectSync(r.method, 'GET');
              if (r.url.path.contains('/companies/'))
                return json({
                  'devices': [device(2)]
                });
              return fail ? http.Response('', 503) : json(analytics(2));
            }));
  });
}
