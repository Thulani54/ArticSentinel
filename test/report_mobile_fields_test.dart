import 'package:artic_sentinel/screens/reports.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('phone report history keeps view and download actions reachable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: articMobileTheme(), home: const Scaffold(body: Reports())));
      await tester.pumpAndSettle();
      final actions = find.byTooltip('Report actions');
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      expect(find.text('View report'), findsOneWidget);
      expect(find.text('Download report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async => http.Response(
        '{"reports":[{"report_name":"Kitchen performance","generated_at":"2026-10-03T10:00:00Z"}]}',
        200)));
  });
  for (final index in [0, 1, 2]) {
    testWidgets('report $index uses full-width rounded phone controls',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: articMobileTheme(), home: const Scaffold(body: Reports())));
        await tester.pumpAndSettle();
        final type = ['device_performance', 'temperature_analytics', 'alerts_summary'][index];
        final button = find.byKey(ValueKey('configure-report-$type'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final dropdowns = find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(DropdownButton<String>));
        expect(dropdowns, findsAtLeastNWidgets(1));
        for (final dropdown in dropdowns.evaluate()) {
          final decorated = find
              .ancestor(
                  of: find.byWidget(dropdown.widget),
                  matching: find.byType(InputDecorator))
              .first;
          final decoration =
              tester.widget<InputDecorator>(decorated).decoration;
          expect(decoration.fillColor, const Color(0xFFF7F8FA));
          expect((decoration.enabledBorder! as OutlineInputBorder).borderRadius,
              BorderRadius.circular(32));
          expect(tester.getSize(decorated).width, 272);
        }
        if (index == 0) {
          await tester.tap(dropdowns.last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Temperature Only').last);
          await tester.pumpAndSettle();
          expect(tester.widget<DropdownButton<String>>(dropdowns.last).value,
              'temperature');
        }
        expect(tester.takeException(), isNull);
      },
          () => MockClient((request) async => http.Response(
              request.url.path.contains('get_devices_by_client')
                  ? '[]'
                  : '{"reports":[]}',
              200)));
    });
  }
}
