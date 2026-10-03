import 'dart:convert';

import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_details_dialog.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_gauge.dart';
import 'package:artic_sentinel/gasmon/gas_cylinders_panel.dart';
import 'package:artic_sentinel/gasmon/gas_dashboard_card.dart';
import 'package:artic_sentinel/gasmon/gas_setup_card.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> savedConfig() => {
      'gas_capacity_kg': 9.0,
      'tare_kg': 12.0,
      'price_per_kg': 30.0,
      'low_threshold_pct': 20.0,
      'warning_threshold_pct': 50.0,
      'is_default': false,
      'updated_at': '2026-10-01T10:00:00Z',
    };

Map<String, dynamic> reading({double net = 4.5, DateTime? at}) => {
      'time': (at ?? DateTime.now()).toUtc().toIso8601String(),
      'net_kg': net,
      'gross_kg': net + 12,
      'battery_pct': 80,
    };

http.Response reply(
        {List<Map<String, dynamic>> rows = const [],
        Map<String, dynamic>? config}) =>
    http.Response(
        jsonEncode({
          'config': config ?? savedConfig(),
          'readings': rows,
          'latest': rows.isEmpty ? null : rows.last,
        }),
        200,
        headers: {'content-type': 'application/json'});

Device device({int? id = 42}) => Device(
      id: id,
      deviceId: 'scale-42',
      name: 'Kitchen gas cylinder',
      deviceType: 'gas_cylinder',
    );

Future<void> screen(WidgetTester tester, Widget child,
    {double width = 320}) async {
  tester.view.physicalSize = Size(width, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: articMobileTheme(),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

void expectNoPretendReading(WidgetTester tester) {
  expect(find.byType(GasCylinderGauge), findsNothing);
  expect(find.text('DEMO DATA'), findsNothing);
  expect(find.textContaining('Low gas —'), findsNothing);
  expect(find.text('Loading cylinder…'), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empty API telemetry contains no fabricated readings or alerts',
      () async {
    await http.runWithClient(() async {
      final result = await GasApi.load(deviceId: 42, demoKey: 'unused');
      expect(result.data.readings, isEmpty);
      expect(result.data.alerts, isEmpty);
      expect(result.data.hasReadings, isFalse);
      expect(result.config.tareKg, 12);
      expect(result.config.gasCapacityKg, 9);
    }, () => MockClient((_) async => reply()));
  });

  test('a genuine zero measurement remains a valid empty-cylinder reading',
      () async {
    await http.runWithClient(() async {
      final result = await GasApi.load(deviceId: 42, demoKey: 'unused');
      expect(result.data.hasReadings, isTrue);
      expect(result.data.currentLevelPct, 0);
    }, () => MockClient((_) async => reply(rows: [reading(net: 0)])));
  });

  test('failed API request throws instead of substituting a demonstration',
      () async {
    await http.runWithClient(() async {
      await expectLater(GasApi.load(deviceId: 42, demoKey: 'unused'),
          throwsA(isA<GasApiException>()));
    }, () => MockClient((_) async => http.Response('{}', 503)));
  });

  for (final details in [false, true]) {
    testWidgets(
        '${details ? 'details' : 'dashboard'} shows first-reading state without a gauge',
        (tester) async {
      await http.runWithClient(() async {
        await screen(
            tester,
            details
                ? GasCylinderDetailsDialog(device: device())
                : SingleChildScrollView(
                    child: GasDashboardCard(device: device())));
        expect(find.text('Waiting for the first reading'), findsOneWidget);
        expectNoPretendReading(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((_) async => reply()));
    });

    testWidgets(
        '${details ? 'details' : 'dashboard'} retries a failed initial load',
        (tester) async {
      var requests = 0;
      await http.runWithClient(() async {
        await screen(
            tester,
            details
                ? GasCylinderDetailsDialog(device: device())
                : SingleChildScrollView(
                    child: GasDashboardCard(device: device())));
        expect(
            find.text(
                details ? 'Readings unavailable' : 'Cylinder unavailable'),
            findsOneWidget);
        expectNoPretendReading(tester);
        await tester.ensureVisible(find.text('Retry'));
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.byType(GasCylinderGauge), findsOneWidget);
        expect(requests, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
          () => MockClient((_) async => ++requests == 1
              ? http.Response('{}', 503)
              : reply(rows: [reading()])));
    });

    testWidgets(
        '${details ? 'details' : 'dashboard'} keeps genuine history when refresh fails',
        (tester) async {
      var requests = 0;
      await http.runWithClient(() async {
        await screen(
            tester,
            details
                ? GasCylinderDetailsDialog(device: device())
                : SingleChildScrollView(
                    child: GasDashboardCard(device: device())));
        expect(find.byType(GasCylinderGauge), findsOneWidget);
        expect(find.text('LAST REPORTED'), findsOneWidget);
        await tester.pump(const Duration(seconds: 30));
        await tester.pumpAndSettle();
        expect(find.byType(GasCylinderGauge), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(
            tester
                .widget<GasCylinderGauge>(find.byType(GasCylinderGauge))
                .levelPct,
            50);
        expect(requests, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
          () => MockClient((_) async => ++requests == 1
              ? reply(rows: [
                  reading(at: DateTime.now().subtract(const Duration(days: 3)))
                ])
              : http.Response('{}', 503)));
    });

    testWidgets(
        '${details ? 'details' : 'dashboard'} unsaved device does not spin or invent readings',
        (tester) async {
      await screen(
          tester,
          details
              ? GasCylinderDetailsDialog(device: device(id: null))
              : SingleChildScrollView(
                  child: GasDashboardCard(device: device(id: null))));
      expectNoPretendReading(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('empty gas inventory has a useful state', (tester) async {
    await screen(tester,
        const SingleChildScrollView(child: GasCylindersPanel(devices: [])));
    expect(find.text('No gas cylinders yet'), findsOneWidget);
    expectNoPretendReading(tester);
  });

  for (final fail in [false, true]) {
    testWidgets('gas inventory card is honest for unavailable level: failed=$fail', (tester) async {
      await http.runWithClient(() async {
        await screen(tester, SingleChildScrollView(child: GasCylindersPanel(devices: [device()])));
        expect(find.text(fail ? 'Unavailable' : 'Not reporting'), findsOneWidget);
        expect(find.textContaining(fail ? 'Level unavailable' : 'Waiting for the first reading.'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expectNoPretendReading(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((_) async => fail ? http.Response('{}', 503) : reply()));
    });
  }

  for (final width in [320.0, 800.0]) {
    testWidgets(
        'Switch gas opens current setup and only writes on Save at $width',
        (tester) async {
      var config = savedConfig();
      final writes = <Map<String, dynamic>>[];
      await http.runWithClient(() async {
        await screen(tester, GasCylinderDetailsDialog(device: device()),
            width: width);
        await tester.tap(find.text('Switch gas'));
        await tester.pumpAndSettle();
        expect(find.byType(GasCylinderSetupDialog), findsOneWidget);
        final fields = find.descendant(
            of: find.byType(GasCylinderSetupDialog),
            matching: find.byType(TextField));
        expect(tester.widget<TextField>(fields.at(0)).controller!.text, '12');
        expect(tester.widget<TextField>(fields.at(1)).controller!.text, '9');
        expect(writes, isEmpty);
        final surface = find.descendant(
            of: find.byType(GasCylinderSetupDialog),
            matching: find.byType(Material)).first;
        expect(tester.getRect(surface).width,
            width < 600 ? width : lessThan(width));
        await tester.tap(find.byTooltip('Close cylinder setup'));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.tap(find.text('Switch gas'));
        await tester.pumpAndSettle();
        await tester.enterText(fields.at(1), '14');
        await tester.ensureVisible(find.text('Save setup'));
        await tester.tap(find.text('Save setup'));
        await tester.pumpAndSettle();
        expect(writes, hasLength(1));
        expect(writes.single['device_id'], 42);
        expect(writes.single['gas_capacity_kg'], 14);
        expect(writes.single['tare_kg'], 12);
        expect(find.text('Setup saved — levels recalculated.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
          () => MockClient((request) async {
                if (request.url.path.endsWith('config/update/')) {
                  final body = jsonDecode(request.body) as Map<String, dynamic>;
                  writes.add(body);
                  config = {
                    ...config,
                    ...body,
                    'updated_at': '2026-10-03T14:00:00Z'
                  };
                  return http.Response(jsonEncode({'config': config}), 200);
                }
                return reply(config: config);
              }));
    });
  }
}
