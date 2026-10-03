import 'dart:convert';

import 'package:artic_sentinel/screens/communication.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('phone email preview removes markup and expands without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const message = '''<html><head><title>Hidden subject</title>
<style>body { color: red; }</style></head><body style="color: red">
<h1>Equipment &amp; temperature alert</h1>
<p>The kitchen unit has reported a reading outside its configured range.</p>
<p>Please check its recent readings and inspect the equipment before resolving the alert.</p>
<div>Temperature: 12 &deg;C<br>Location: Main kitchen</div>
<script>doNotExecuteOrDisplay()</script></body></html>''';
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        home: Scaffold(body: CommunicationDashboard()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final text = find.textContaining('Equipment & temperature alert');
      expect(text, findsOneWidget);
      expect(find.text('Kitchen temperature notice'), findsOneWidget);
      expect(tester.widget<Text>(text).maxLines, 3);
      expect(find.textContaining('<html>'), findsNothing);
      expect(find.text('No text preview available'), findsOneWidget);
      expect(find.textContaining('doNotExecuteOrDisplay'), findsNothing);
      expect(find.textContaining('body { color'), findsNothing);
      expect(find.textContaining('Hidden subject'), findsNothing);
      await tester.ensureVisible(find.text('Show full message'));
      await tester.tap(find.text('Show full message'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).maxLines, isNull);
      expect(tester.widget<Text>(text).data,
          contains('Temperature: 12 °C\nLocation: Main kitchen'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Show less'));
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(text).maxLines, 3);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async {
      return http.Response(
        jsonEncode(request.url.path.contains('/communication/logs/')
            ? {
                'logs': [
                  {
                    'communication_type_display': 'Email',
                    'status_display': 'Delivered',
                    'created_at': '2026-10-03T10:00:00Z',
                    'subject': 'Kitchen temperature notice',
                    'message': message,
                  },
                  {
                    'communication_type_display': 'Email',
                    'status_display': 'Delivered',
                    'created_at': '2026-10-03T10:00:00Z',
                    'message': '<html><body style="font-family: Arial;">',
                  }
                ]
              }
            : <String, dynamic>{}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }));
  });
}
