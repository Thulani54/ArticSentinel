import 'dart:convert';
import 'dart:async';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/screens/control.dart';
import 'package:artic_sentinel/screens/device_management.dart';
import 'package:artic_sentinel/screens/reports.dart';
import 'package:artic_sentinel/screens/units.dart';
import 'package:artic_sentinel/screens/settings/billing.dart';
import 'package:artic_sentinel/widgets/app_empty_state.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'AUTHTOKENKEY': 'test-only-token'});
    Constants.myBusiness = Business(
        businessUid: 123,
        businessName: 'Test',
        isActive: true,
        activeDevicesCount: 0,
        isPrimary: true);
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: articMobileTheme(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!),
        home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  final cases = <(String, Widget, String, String)>[
    (
      'devices',
      const DeviceManagement(),
      'Your first device starts here',
      'Devices could not be loaded'
    ),
    (
      'units',
      const UnitManagement(),
      'No units yet',
      'Units could not be loaded'
    ),
    (
      'control',
      const ControlScreen(),
      'No controllable devices yet',
      'Controls could not be loaded'
    ),
    (
      'reports',
      const Reports(companyId: 123),
      'No reports yet',
      'Reports could not be loaded'
    ),
  ];

  for (final item in cases) {
    testWidgets('${item.$1}: empty is visible and failure can retry',
        (tester) async {
      var fail = true;
      var requests = 0;
      await http.runWithClient(() async {
        await mount(tester, item.$2);
        // All states render even when their request fails on first launch.
        expect(find.text(item.$4), findsOneWidget);
        expect(find.text(item.$3), findsNothing);
        expect(find.byType(AppEmptyState), findsWidgets);
        expect(tester.takeException(), isNull);
        if (item.$1 == 'reports') {
          await tester.ensureVisible(find.text('Generated'));
          await tester.tap(find.text('Generated'));
          await tester.pumpAndSettle();
          expect(find.text('Reports could not be loaded'), findsWidgets);
          expect(find.text('No reports generated yet'), findsNothing);
        }
        fail = false;
        final before = requests;
        await tester.ensureVisible(find.text('Try again').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try again').last);
        await tester.pumpAndSettle();
        expect(requests, greaterThan(before));
        expect(find.text(item.$4), findsNothing);
        expect(find.text(item.$3), findsOneWidget);
        expect(find.byType(SvgPicture), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
      },
          () => MockClient((request) async {
                requests++;
                if (item.$1 == 'control' &&
                    request.url.path == '/api/devices/list/') {
                  expect(request.headers['authorization'],
                      'Token test-only-token');
                }
                if (fail) throw http.ClientException('private server address');
                return http.Response(
                    jsonEncode({
                      'success': true,
                      'devices': [],
                      'units': [],
                      'reports': []
                    }),
                    200);
              }));
    });
  }

  testWidgets('a stalled inventory request times out to a visible retry state',
      (tester) async {
    await http.runWithClient(() async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: articMobileTheme(),
          home: const Scaffold(body: DeviceManagement())));
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text('Devices could not be loaded'), findsOneWidget);
      expect(find.text('Your first device starts here'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((_) => Completer<http.Response>().future));
  });

  testWidgets('billing has an empty state instead of example invoices',
      (tester) async {
    await mount(tester, const BillManagement());
    expect(find.text('No bills yet'), findsOneWidget);
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Acme Corp.'), findsNothing);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Report history does not turn server errors into empty reports',
      () async {
    await http.runWithClient(() async {
      await expectLater(
          ReportApiService.getReportHistory(businessId: 123), throwsException);
    }, () => MockClient((_) async => http.Response('Unavailable', 503)));
  });

  testWidgets('all empty illustrations fit narrow screen with large text',
      (tester) async {
    await mount(
        tester,
        SingleChildScrollView(
            child: Column(children: [
          for (final kind in AppEmptyStateKind.values)
            AppEmptyState(
              kind: kind,
              title: 'Waiting for your first reading',
              message:
                  'Connect your device to see readings here. You can try again whenever you are ready.',
              actionLabel: 'Try again',
              onAction: () {},
            ),
        ])));
    expect(find.byType(SvgPicture),
        findsNWidgets(AppEmptyStateKind.values.length));
    expect(tester.takeException(), isNull);
  });
}
