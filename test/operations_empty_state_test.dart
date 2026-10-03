import 'dart:async';
import 'dart:convert';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/screens/alert.dart';
import 'package:artic_sentinel/screens/communication.dart';
import 'package:artic_sentinel/screens/maintanance.dart';
import 'package:artic_sentinel/screens/roles.dart';
import 'package:artic_sentinel/screens/team_members_tab.dart';
import 'package:artic_sentinel/widgets/app_empty_state.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _emptyResponse(http.Request request) {
  final path = request.url.path;
  Object data = <String, dynamic>{};
  if (path.contains('/team/members/')) {
    data = {'members': [], 'can_manage': false};
  } else if (path.contains('/roles/') ||
      path.contains('/permissions/') ||
      path.contains('/permission-requests/')) {
    data = <Object>[];
  } else if (path.contains('/maintenance/dashboard/')) {
    data = {
      'dashboard': {'upcoming_maintenance': []}
    };
  } else if (path.contains('/maintenance/list/')) {
    data = {'maintenance_records': []};
  } else if (path.contains('/maintenance/types/')) {
    data = {'maintenance_types': []};
  } else if (path.contains('/maintenance/reminders/')) {
    data = {'reminders': {}};
  } else if (path.contains('/maintenance/schedules/')) {
    data = {'schedules': []};
  } else if (path.contains('/alerts/list/')) {
    data = {'alerts': [], 'count': 0};
  }
  return http.Response(jsonEncode(data), 200,
      headers: {'content-type': 'application/json'});
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late Business originalBusiness;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalBusiness = Constants.myBusiness;
    Constants.myBusiness = Business(
      businessUid: 1,
      businessName: 'Test business',
      isActive: true,
      activeDevicesCount: 0,
      isPrimary: true,
    );
  });
  tearDown(() => Constants.myBusiness = originalBusiness);

  Future<void> show(WidgetTester tester, Widget screen,
      {bool settle = true}) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: articMobileTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.4)),
        child: child!,
      ),
      home: Scaffold(body: screen),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  final screens = <(String, Widget Function(), String, String, String)>[
    (
      'messages',
      () => CommunicationDashboard(),
      'No messages yet',
      'Unable to load messages',
      '/communication/logs/'
    ),
    (
      'maintenance',
      () => MaintenanceDashboard(),
      'No upcoming maintenance scheduled',
      'Unable to load maintenance',
      '/maintenance/schedules/'
    ),
    (
      'access',
      () => RoleManagementPage(),
      'No team members yet',
      'Unable to load team access',
      '/roles/'
    ),
    (
      'team',
      () => const TeamMembersTab(),
      'No team members yet',
      'Unable to load your team',
      '/team/members/'
    ),
    (
      'alerts',
      () => const NotificationPage(),
      'No alerts in this category',
      'Unable to load alerts',
      '/alerts/list/'
    ),
  ];

  for (final screen in screens) {
    testWidgets(
        '${screen.$1}: successful empty response shows an illustrated state',
        (tester) async {
      await http.runWithClient(() async {
        await show(tester, screen.$2());
        expect(find.text(screen.$3), findsOneWidget);
        expect(find.byType(AppEmptyState), findsWidgets);
        expect(find.text(screen.$4), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => MockClient((request) async => _emptyResponse(request)));
    });

    testWidgets(
        '${screen.$1}: failure stays distinct from empty and Retry reloads',
        (tester) async {
      var fail = true;
      var requests = 0;
      await http.runWithClient(() async {
        await show(tester, screen.$2());
        expect(find.text(screen.$4), findsOneWidget);
        expect(find.text(screen.$3), findsNothing);
        expect(find.textContaining('private-diagnostic'), findsNothing);
        expect(tester.takeException(), isNull);
        final previousRequests = requests;
        fail = false;
        await tester.ensureVisible(find.text('Retry'));
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(requests, greaterThan(previousRequests));
        expect(find.text(screen.$4), findsNothing);
        expect(find.text(screen.$3), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
          () => MockClient((request) async {
                if (request.url.path.contains(screen.$5)) {
                  requests++;
                  if (fail) {
                    if (screen.$1 == 'team' || screen.$1 == 'alerts') {
                      throw http.ClientException(
                          'private-diagnostic: connection failed');
                    }
                    return http.Response(
                        'private-diagnostic: server failed', 503);
                  }
                }
                return _emptyResponse(request);
              }));
    });
  }

  testWidgets('a stalled request times out without accepting a late response',
      (tester) async {
    final pending = Completer<http.Response>();
    var stalled = true;
    await http.runWithClient(() async {
      await show(tester, CommunicationDashboard(), settle: false);
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load messages'), findsOneWidget);
      pending.complete(http.Response(
          jsonEncode({
            'logs': [
              {
                'subject': 'Late response should not appear',
                'message': 'Late data'
              }
            ],
          }),
          200));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load messages'), findsOneWidget);
      expect(find.text('Late response should not appear'), findsNothing);
      stalled = false;
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No messages yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              if (stalled &&
                  request.url.path.contains('/communication/logs/')) {
                return pending.future;
              }
              return _emptyResponse(request);
            }));
  });

  testWidgets(
      'alert totals failure hides fabricated counts and offers its own retry',
      (tester) async {
    await http.runWithClient(() async {
      await show(tester, const NotificationPage());
      expect(find.text('Alert totals unavailable'), findsOneWidget);
      expect(find.text('Retry totals'), findsOneWidget);
      expect(find.text('All  0'), findsNothing);
      expect(find.text('No alerts in this category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async =>
            request.url.path.contains('/alerts/statistics/')
                ? http.Response('private-diagnostic', 503)
                : _emptyResponse(request)));
  });
}
