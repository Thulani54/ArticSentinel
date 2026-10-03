import 'dart:ui' as ui;

import 'package:artic_sentinel/gasmon/gas_core.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget gauge(double percent,
    {double entrance = 1,
    bool reducedMotion = false,
    double capacity = 9,
    double screenWidth = 390}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(screenWidth, 844),
        disableAnimations: reducedMotion,
      ),
      child: Center(
        child: GasCylinderGauge(
          fill: entrance,
          band: GasBand.healthy,
          levelPct: percent,
          netKg: percent * capacity / 100,
          capacityKg: capacity,
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
      final surface = 270 - 174 * percent / 100;
      expect(await paintedPixel(tester, 46, (surface - 4).round()), empty);
      expect(await paintedPixel(tester, 46, (surface + 4).round()), liquid);
    });
  }

  testWidgets('zero and full levels clamp safely', (tester) async {
    await tester.pumpWidget(gauge(-10));
    expect(await paintedPixel(tester, 46, 245), empty);
    await tester.pumpWidget(gauge(110));
    await tester.pumpAndSettle();
    expect(await paintedPixel(tester, 46, 139), liquid);
  });

  testWidgets('entrance animates toward the measured level, not a full tank',
      (tester) async {
    await tester.pumpWidget(gauge(50, entrance: .5));
    expect(await paintedPixel(tester, 46, 224), empty);
    expect(await paintedPixel(tester, 46, 232), liquid);
    await tester.pumpWidget(gauge(50));
    expect(await paintedPixel(tester, 46, 179), empty);
    expect(await paintedPixel(tester, 46, 187), liquid);
  });

  testWidgets('new readings animate smoothly to their new level',
      (tester) async {
    await tester.pumpWidget(gauge(20));
    await tester.pumpWidget(gauge(80));
    expect(await paintedPixel(tester, 46, 174), empty);
    await tester.pump(const Duration(milliseconds: 325));
    expect(await paintedPixel(tester, 46, 174), liquid);
    expect(await paintedPixel(tester, 46, 139), empty);
    await tester.pumpAndSettle();
    expect(await paintedPixel(tester, 46, 139), liquid);
  });

  testWidgets('reduced motion skips entrance and subsequent animations',
      (tester) async {
    await tester.pumpWidget(gauge(50, entrance: 0, reducedMotion: true));
    expect(await paintedPixel(tester, 46, 179), empty);
    expect(await paintedPixel(tester, 46, 187), liquid);
    await tester.pumpWidget(gauge(80, reducedMotion: true));
    await tester.pump();
    expect(await paintedPixel(tester, 46, 139), liquid);
  });

  for (final shape in [
    (capacity: 5.0, top: 130.5, sampleX: 165),
    (capacity: 14.0, top: 79.5, sampleX: 181),
    (capacity: 19.0, top: 66.0, sampleX: 179),
    (capacity: 48.0, top: 51.0, sampleX: 164),
    // Custom capacity between presets retains a proportional silhouette.
    (capacity: 16.5, top: 72.75, sampleX: 180),
  ]) {
    testWidgets('${shape.capacity} kg shape keeps an accurate half-full level',
        (tester) async {
      await tester.pumpWidget(gauge(50, capacity: shape.capacity));
      final surface = (shape.top + 270) / 2;
      expect(await paintedPixel(tester, shape.sampleX, (surface - 4).round()),
          empty);
      expect(await paintedPixel(tester, shape.sampleX, (surface + 4).round()),
          liquid);
    });
  }

  testWidgets('switching cylinder capacity changes its proportions',
      (tester) async {
    await tester.pumpWidget(gauge(100));
    expect(await paintedPixel(tester, 185, 230), liquid);
    await tester.pumpWidget(gauge(100, capacity: 48));
    await tester.pumpAndSettle();
    expect(await paintedPixel(tester, 185, 230), 0);
    expect(await paintedPixel(tester, 65, 110), liquid);
  });

  testWidgets('saved capacity rounding retains the compact cylinder',
      (tester) async {
    await tester.pumpWidget(gauge(50, capacity: (8.1 + 9) - 8.1));
    expect(await paintedPixel(tester, 46, 179), empty);
    expect(await paintedPixel(tester, 46, 187), liquid);
  });

  testWidgets('wider screens retain the original gauge geometry',
      (tester) async {
    await tester.pumpWidget(gauge(50, screenWidth: 1024));
    expect(await paintedPixel(tester, 46, 170), empty);
    expect(await paintedPixel(tester, 46, 178), liquid);
  });
}
