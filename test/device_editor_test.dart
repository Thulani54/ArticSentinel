import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/screens/device_editor.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Device fridge() => Device(
      id: 7,
      name: 'Cold room',
      deviceId: 'FR-001',
      deviceType: 'device1',
      location: 'Kitchen',
      targetTempMin: 0,
      targetTempMax: 5,
      phaseType: 'single');

  Future<void> mount(WidgetTester t, Widget editor,
      {double width = 360, double keyboard = 0, double scale = 1}) async {
    t.view.physicalSize = Size(width, 820);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
      theme: articMobileTheme(),
      // builder: applies to every route, including the pushed editor.
      builder: (context, child) => MediaQuery(
          data: MediaQueryData(
              size: Size(width, 820),
              viewInsets: EdgeInsets.only(bottom: keyboard),
              textScaler: TextScaler.linear(scale),
              disableAnimations: true),
          child: child!),
      home: Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => editor)),
                        child: const Text('open'))))),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String label) async {
    final finder = find.text(label).last;
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('narrow phone: read-only ID, sections and a validated save',
      (t) async {
    Device? saved;
    String? savedUnit = 'unset';
    await mount(
        t,
        DeviceEditorScreen(
            device: fridge(),
            onSave: (d, unit) async {
              saved = d;
              savedUnit = unit;
            }),
        width: 320,
        scale: 1.3);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('FR-001'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextFormField, 'Device name'), 'Walk-in cold room');
    await tap(t, 'Next');
    expect(find.text('How it runs'), findsWidgets);
    expect(find.text('Safety first'), findsNothing);
    await t.enterText(find.widgetWithText(TextFormField, 'Highest (°C)'), '-1');
    await tap(t, 'Save changes');
    expect(find.text('The highest temperature must be above the lowest.'), findsWidgets);
    expect(saved, isNull);
    await tap(t, 'Freezer -22 to -18 °C');
    await tap(t, 'Three phase');
    await tap(t, 'Next');
    expect(find.text('Hardware and service'), findsWidgets);
    await tap(t, 'Save changes');
    expect(saved!.name, 'Walk-in cold room');
    expect(saved!.deviceId, 'FR-001');
    expect(saved!.targetTempMin, -22);
    expect(saved!.targetTempMax, -18);
    expect(saved!.phaseType, 'three');
    expect(saved!.location, 'Kitchen');
    expect(savedUnit, isNull);
    expect(find.text('open'), findsOneWidget); // editor closed
    expect(t.takeException(), isNull);
  });

  testWidgets('save stays reachable above the keyboard', (t) async {
    await mount(t, DeviceEditorScreen(device: fridge(), onSave: (_, __) async {}),
        keyboard: 300);
    final save = t.getRect(find.byKey(const ValueKey('editor-save')));
    expect(save.bottom, lessThanOrEqualTo(520));
    expect(save.left, greaterThanOrEqualTo(0));
    expect(save.right, lessThanOrEqualTo(360));
    expect(t.takeException(), isNull);
  });

  testWidgets('gas cylinders link to their cylinder setup instead of ranges',
      (t) async {
    var opened = 0;
    await mount(
        t,
        DeviceEditorScreen(
            device: Device(id: 3, name: 'Kitchen gas', deviceId: 'GAS-1', deviceType: 'gas_cylinder'),
            onSave: (_, __) async {},
            onOpenCylinderSetup: () => opened++));
    await tap(t, 'Next');
    expect(find.text('Safe temperature range'), findsNothing);
    expect(find.text('Supply'), findsNothing);
    await tap(t, 'Open cylinder setup');
    expect(opened, 1);
    expect(t.takeException(), isNull);
  });

  testWidgets('wide web layout: side panel steps jump between sections',
      (t) async {
    await mount(t, DeviceEditorScreen(device: fridge(), onSave: (_, __) async {}),
        width: 1280);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tap(t, 'Hardware and service');
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Service dates'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a failed save keeps the editor open with entries', (t) async {
    await mount(
        t,
        DeviceEditorScreen(
            device: fridge(), onSave: (_, __) async => throw Exception('offline')));
    await t.enterText(find.widgetWithText(TextFormField, 'Device name'), 'Renamed');
    await tap(t, 'Save changes');
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.text('Renamed'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
