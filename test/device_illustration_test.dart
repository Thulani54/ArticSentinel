import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/widgets/device_illustration.dart';
import 'package:artic_sentinel/widgets/mobile_equipment_card.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('every equipment illustration loads from the bundled assets',
      (tester) async {
    const types = [
      'gas_cylinder',
      'device1',
      'device2',
      'device3',
      'device4',
      'device5',
      'device6',
      'device7',
      'unknown',
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Wrap(children: [
        for (final type in types) DeviceIllustration(type: type),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceIllustration), findsNWidgets(9));
    expect(tester.takeException(), isNull);
    expect(types.map(deviceIllustrationAsset).toSet(), hasLength(9));
    expect(deviceIllustrationAsset(' Gas Cylinder '),
        deviceIllustrationAsset('gas_cylinder'));
  });

  for (final scale in [1.0, 1.4]) {
    testWidgets(
        'equipment card wraps long values and preserves actions at $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = 0;
      var menus = 0;
      final device = Device(
        name: 'Kitchen refrigeration monitoring equipment',
        deviceId: '0X000060-LONG-DEVICE-IDENTIFIER',
        deviceType: 'device6',
        location: 'Ground floor kitchen equipment storage room',
        isActive: false,
      );
      await tester.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: MediaQuery(
          data: MediaQueryData(
              size: const Size(320, 900), textScaler: TextScaler.linear(scale)),
          child: Scaffold(
              body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MobileEquipmentCard(
              device: device,
              onOpen: () => opened++,
              actions: IconButton(
                  tooltip: 'Device actions',
                  onPressed: () => menus++,
                  icon: const Icon(Icons.more_horiz)),
            ),
          )),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(device.location!), findsOneWidget);
      expect(find.text(device.deviceId), findsOneWidget);
      await tester.tap(find.text(device.name));
      await tester.pumpAndSettle();
      expect(opened, 1);
      await tester.tap(find.byTooltip('Device actions'));
      await tester.pumpAndSettle();
      expect(menus, 1);
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
