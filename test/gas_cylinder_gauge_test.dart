import 'dart:ui' as ui;

import 'package:artic_sentinel/gasmon/gas_core.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget gauge(double percent,
    {double entrance = 1, bool reducedMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Center(
        child: GasCylinderGauge(
          fill: entrance,
          band: GasBand.healthy,
          levelPct: percent,
          netKg: percent * .09,
          capacityKg: 9,
        ),
      ),
    ),
  );
}

Future<int> paintedPixel(WidgetTester tester, int x, int y) async {
  final paint = tester.widget<CustomPaint>(find.descendant(
    of: find.byType(GasCylinderGauge),
    matching: find.byType(CustomPaint),
  ));
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    paint.painter!.paint(Canvas(recorder), const Size(250, 300));
    final picture = recorder.endRecording();
    final image = await picture.toImage(250, 300);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final offset = (y * 250 + x) * 4;
    final color = (bytes.getUint8(offset + 3) << 24) |
        (bytes.getUint8(offset) << 16) |
        (bytes.getUint8(offset + 1) << 8) |
        bytes.getUint8(offset + 2);
    image.dispose();
    picture.dispose();
    return color;
  }))!;
}

void main() {
  const empty = 0xFFF2F6F9;
  const liquid = 0xFFED6A24;

  for (final percent in [10.0, 25.0, 50.0, 75.0]) {
    testWidgets('$percent percent paints the corresponding cylinder height',
        (tester) async {
      await tester.pumpWidget(gauge(percent));
      final surface = 282 - 216 * percent / 100;
      expect(await paintedPixel(tester, 48, (surface - 4).round()), empty);
      expect(await paintedPixel(tester, 48, (surface + 4).round()), liquid);
    });
  }

  testWidgets('zero and full levels clamp safely', (tester) async {
    await tester.pumpWidget(gauge(-10));
    expect(await paintedPixel(tester, 48, 260), empty);
    await tester.pumpWidget(gauge(110));
    await tester.pumpAndSettle();
    expect(await paintedPixel(tester, 48, 115), liquid);
  });

  testWidgets('entrance animates toward the measured level, not a full tank',
      (tester) async {
    await tester.pumpWidget(gauge(50, entrance: .5));
    expect(await paintedPixel(tester, 48, 224), empty);
    expect(await paintedPixel(tester, 48, 232), liquid);
    await tester.pumpWidget(gauge(50));
    expect(await paintedPixel(tester, 48, 170), empty);
    expect(await paintedPixel(tester, 48, 178), liquid);
  });

  testWidgets('new readings animate smoothly to their new level',
      (tester) async {
    await tester.pumpWidget(gauge(20));
    await tester.pumpWidget(gauge(80));
    expect(await paintedPixel(tester, 48, 174), empty);
    await tester.pump(const Duration(milliseconds: 325));
    expect(await paintedPixel(tester, 48, 174), liquid);
    expect(await paintedPixel(tester, 48, 115), empty);
    await tester.pumpAndSettle();
    expect(await paintedPixel(tester, 48, 115), liquid);
  });

  testWidgets('reduced motion skips entrance and subsequent animations',
      (tester) async {
    await tester.pumpWidget(gauge(50, entrance: 0, reducedMotion: true));
    expect(await paintedPixel(tester, 48, 170), empty);
    expect(await paintedPixel(tester, 48, 178), liquid);
    await tester.pumpWidget(gauge(80, reducedMotion: true));
    await tester.pump();
    expect(await paintedPixel(tester, 48, 115), liquid);
  });
}
