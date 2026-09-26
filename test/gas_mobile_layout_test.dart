import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/gasmon/gas_demo_data.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_details_dialog.dart';
import 'package:artic_sentinel/gasmon/scale_ble.dart';
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
  for (final live in [false, true]) {
    testWidgets('gas view at 320px stays in its layout with live=$live',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
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
      if (!live) {
        expect(find.text('No live reading yet'), findsOneWidget);
        expect(find.text('DEMO DATA'), findsNothing);
      }
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
