import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/gasmon/gas_theme.dart';
import 'package:artic_sentinel/widgets/mobile_forms.dart';
import 'package:artic_sentinel/screens/device_management.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child,
      {double width = 360, double keyboard = 0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
                  child: Scaffold(body: child),
                ))));
    await tester.pumpAndSettle();
  }

  testWidgets('phone fields stack, remove icons and use radius 32',
      (tester) async {
    await mount(
        tester,
        Builder(
            builder: (context) => MobileDialog(
                    child: Column(children: [
                  MobileFormRow(children: [
                    Expanded(
                        child: TextField(
                            key: const Key('first'),
                            decoration: mobileInputDecoration(
                                context,
                                const InputDecoration(
                                    labelText: 'First',
                                    prefixIcon: Icon(Icons.person))))),
                    const SizedBox(width: 20),
                    Expanded(
                        child: TextField(
                            key: const Key('second'),
                            decoration: mobileInputDecoration(context,
                                const InputDecoration(labelText: 'Second')))),
                  ]),
                ]))));
    expect(find.byIcon(Icons.person), findsNothing);
    final first = tester.getRect(find.byKey(const Key('first')));
    final second = tester.getRect(find.byKey(const Key('second')));
    expect(first.width, 360);
    expect(second.top, greaterThanOrEqualTo(first.bottom));
    final decoration =
        tester.widget<TextField>(find.byKey(const Key('first'))).decoration!;
    expect((decoration.enabledBorder! as OutlineInputBorder).borderRadius,
        BorderRadius.circular(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop preserves field row and decoration', (tester) async {
    await mount(
        tester,
        Builder(
            builder: (context) => MobileFormRow(children: [
                  Expanded(
                      child: TextField(
                          key: const Key('first'),
                          decoration: mobileInputDecoration(
                              context,
                              const InputDecoration(
                                  prefixIcon: Icon(Icons.person))))),
                  const SizedBox(width: 20),
                  Expanded(child: TextField(key: const Key('second'))),
                ])),
        width: 1000);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('first'))).dy,
        tester.getTopLeft(find.byKey(const Key('second'))).dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add gas switches fields without overflow on a narrow phone',
      (tester) async {
    await mount(tester, const AddDeviceDialog(availableUnits: []), width: 320);
    await tester.tap(find.byKey(const ValueKey('mobile-device-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gas cylinder').last);
    await tester.pumpAndSettle();
    expect(find.text('Add gas cylinder'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('Gas capacity (kg)')), findsOneWidget);
    expect(find.byKey(const ValueKey('Empty cylinder weight (kg)')),
        findsOneWidget);
    expect(find.text('Phase type'), findsNothing);
    expect(find.text('Minimum temperature (°C)'), findsNothing);
    expect(tester.getSize(find.byType(Dialog)).width, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone dialog keeps save action reachable above keyboard',
      (tester) async {
    await mount(tester, const AddDeviceDialog(availableUnits: []),
        keyboard: 300);
    final button = tester.getRect(find.byType(FilledButton));
    expect(button.bottom, lessThanOrEqualTo(500));
    expect(button.left, greaterThanOrEqualTo(0));
    expect(button.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit device selected dropdown values stay legible on phones',
      (tester) async {
    await mount(tester, EditDeviceDialog(
      device: Device(name: 'Bathroom Gas', deviceId: '1133',
          deviceType: 'gas_cylinder', phaseType: 'single'),
      availableUnits: const [],
    ), width: 320);
    final dropdowns = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>));
    expect(dropdowns, isNotEmpty);
    for (final dropdown in dropdowns) {
      expect(dropdown.style?.color, GasPalette.ink);
      expect(dropdown.isExpanded, isTrue);
    }
    expect(tester.takeException(), isNull);
  });
}
