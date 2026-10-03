import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/gasmon/gas_demo_data.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_details_dialog.dart';
import 'package:artic_sentinel/gasmon/scale_ble.dart';
import 'package:artic_sentinel/gasmon/gas_widgets.dart';
import 'package:artic_sentinel/models/device.dart';

void main() {
  test(
      'Bluetooth connection failures show useful recovery without raw diagnostics',
      () {
    final error =
        scaleConnectionError(StateError('android-code: 133 | GATT_ERROR'));
    expect(error, contains('Check for a live reading'));
    expect(error, isNot(contains('GATT_ERROR')));
  });
  for (final width in [320.0, 430.0]) {
    for (final live in [false, true]) {
      testWidgets('gas view at ${width}px stays in its layout with live=$live',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final demo = generateGasDemoData(deviceKey: 'layout-test');
        final data = GasDeviceData(
            spec: demo.spec,
            readings: demo.readings,
            alerts: demo.alerts,
            pricePerKg: demo.pricePerKg,
            live: live);
        final config = GasConfig(
            gasCapacityKg: data.spec.capacityKg,
            tareKg: data.spec.tareKg,
            pricePerKg: data.pricePerKg,
            lowPct: 20,
            warningPct: 50,
            isDefault: false);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: GasCylinderDetailsDialog(
          device: Device(
              name: 'Bathroom cylinder with a long display name',
              deviceId: '1133',
              deviceType: 'gas_cylinder'),
          loadData: () async => (data: data, config: config),
        ))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Same sections as the website's gas page.
        expect(find.text(live ? 'LIVE SCALE' : 'DEMO DATA'), findsOneWidget);
        expect(find.textContaining('Showing demo data.', findRichText: true),
            live ? findsNothing : findsOneWidget);
        expect(find.text('Current level'), findsOneWidget);
        expect(find.text('Readings'), findsOneWidget);
        for (final grid in find.byType(GTileGrid).evaluate()) {
          final readingTiles = find.descendant(
              of: find.byWidget(grid.widget), matching: find.byType(GTile));
          final tileBounds = [
            for (final tile in readingTiles.evaluate())
              tester.getRect(find.byWidget(tile.widget)),
          ];
          expect(tileBounds.length, greaterThanOrEqualTo(4));
          for (var i = 1; i < tileBounds.length; i++) {
            expect(tileBounds[i].left, tileBounds.first.left);
            expect(tileBounds[i].top,
                greaterThanOrEqualTo(tileBounds[i - 1].bottom));
          }
        }
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -2400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Usage — last 30 days'), findsOneWidget);
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -2400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
