import 'package:artic_sentinel/device_journal/alert_team_panel.dart';
import 'package:artic_sentinel/device_journal/bottle_scan_history.dart';
import 'package:artic_sentinel/device_journal/cylinder_refill_history.dart';
import 'package:artic_sentinel/device_journal/device_journal_api.dart';
import 'package:artic_sentinel/gasmon/gas_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

class FakeJournalApi extends DeviceJournalApi {
  final requests = <({
    String path,
    String method,
    Map<String, dynamic>? body,
    Map<String, String>? query
  })>[];
  bool fail = false;
  Map<String, dynamic> refill = {
    'total_cost': '300.00',
    'purchased_kg': '9.00',
    'count': 0,
    'refills': <dynamic>[],
    'next_offset': null
  };
  Map<String, dynamic> scans = {'scans': <dynamic>[], 'next_offset': null};
  Map<String, dynamic> team = {
    'revision': 0,
    'status': 'active',
    'assigned_to': null,
    'assigned_name': null,
    'members': [
      {'id': 7, 'name': 'Alex Technician'}
    ],
    'events': <dynamic>[]
  };
  @override
  Future<Map<String, dynamic>> request(String path,
      {String method = 'GET',
      Map<String, dynamic>? body,
      Map<String, String>? query}) async {
    requests.add((path: path, method: method, body: body, query: query));
    if (fail) {
      throw const DeviceJournalException(
          'Connection interrupted. Please retry.');
    }
    if (path.endsWith('/scans/')) return Map.of(scans);
    if (path.endsWith('/team/')) {
      if (method == 'PATCH') {
        team = {
          ...team,
          'revision': (team['revision'] as int) + 1,
          if (body!['action'] == 'assign') 'assigned_to': body['assigned_to'],
          if (body['action'] == 'resolve') 'status': 'resolved',
          'events': [
            {
              'actor': 'Test User',
              'action': body['action'],
              'assignee': 'Alex Technician',
              'note': body['note'],
              'created_at': DateTime.now().toUtc().toIso8601String()
            }
          ]
        };
      }
      return Map.of(team);
    }
    return Map.of(refill);
  }
}

Future<void> pumpPhone(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
      MaterialApp(theme: ThemeData(fontFamily: 'Inter'), home: child));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'refill summary separates purchases from observed usage and excludes outages',
      (tester) async {
    final api = FakeJournalApi();
    final now = DateTime.now();
    await pumpPhone(
        tester,
        CylinderRefillHistoryPage(
            deviceId: 8,
            deviceName: 'Kitchen gas',
            api: api,
            readings: [
              GasReading(at: DateTime(now.year, now.month, 1, 8), weightKg: 18),
              GasReading(at: DateTime(now.year, now.month, 1, 9), weightKg: 17),
              GasReading(
                  at: DateTime(now.year, now.month, 1, 10), weightKg: 22),
              GasReading(
                  at: DateTime(now.year, now.month, 5, 10), weightKg: 12),
            ]));
    expect(find.text('R 300.00'), findsOneWidget);
    expect(find.text('1.00 kg'), findsOneWidget);
    expect(
        api.requests.single.query!['month'], DateFormat('yyyy-MM').format(now));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'refill form validates and reuses idempotency key after uncertain save',
      (tester) async {
    final api = FakeJournalApi();
    await pumpPhone(
        tester,
        CylinderRefillHistoryPage(
            deviceId: 8, deviceName: 'Kitchen gas', api: api));
    await tester.tap(find.text('Log refill or cylinder change'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save entry'));
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.enterText(find.byType(TextFormField).at(0), '9');
    await tester.enterText(find.byType(TextFormField).at(1), '300');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'Neighbourhood supplier');
    api.fail = true;
    await tester.ensureVisible(find.text('Save entry'));
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    final first = api.requests.last.body!['request_id'];
    expect(find.text('Connection interrupted. Please retry.'), findsOneWidget);
    api.fail = false;
    await tester.ensureVisible(find.text('Save entry'));
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    final posts = api.requests.where((r) => r.method == 'POST').toList();
    expect(posts.last.body!['request_id'], first);
    expect(posts.last.body!['supplier'], 'Neighbourhood supplier');
    expect(find.text('Refill history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('cylinder change records configuration and allows no purchase',
      (tester) async {
    final api = FakeJournalApi();
    await pumpPhone(
        tester,
        CylinderRefillHistoryPage(
            deviceId: 8,
            deviceName: 'Kitchen gas',
            api: api,
            capacityKg: 19,
            tareKg: 17.2));
    await tester.tap(find.text('Log refill or cylinder change'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cylinder change').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save entry'), 350,
        scrollable: find
            .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    final post = api.requests.firstWhere((r) => r.method == 'POST');
    expect(post.body!['kind'], 'cylinder_change');
    expect(post.body!['gas_kg'], '0');
    expect(post.body!['cost'], '0');
    expect(post.body!['capacity_kg'], '19.00');
    expect(post.body!['tare_kg'], '17.20');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'bottle history shows empty state and applies failed and code filters',
      (tester) async {
    final api = FakeJournalApi();
    await pumpPhone(tester,
        BottleScanHistoryPage(deviceId: 7, deviceName: 'Bottles', api: api));
    expect(find.text('No matching scans'), findsOneWidget);
    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();
    expect(api.requests.last.query!['result'], 'failed');
    await tester.enterText(find.byType(TextField), 'LOT-42');
    await tester.tap(find.text('Search readings'));
    await tester.pumpAndSettle();
    expect(api.requests.last.query!['q'], 'LOT-42');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'bottle history shows failed verification and preserves long codes',
      (tester) async {
    final api = FakeJournalApi()
      ..scans = {
        'scans': [
          {
            'time': DateTime.now().toUtc().toIso8601String(),
            'code': 'LOT-1234-bottle-long-identifier-5678',
            'verified': false,
            'direction': 'in',
            'tray_kg': [1, 2, null, 0]
          },
        ],
        'next_offset': null
      };
    await pumpPhone(tester,
        BottleScanHistoryPage(deviceId: 7, deviceName: 'Bottles', api: api));
    await tester.ensureVisible(find.text('Failed verification'));
    await tester.pumpAndSettle();
    expect(find.text('LOT-1234-bottle-long-identifier-5678'), findsOneWidget);
    expect(find.text('Tray 3: —'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('scan API error shows retry and never invents rows',
      (tester) async {
    final api = FakeJournalApi()..fail = true;
    await pumpPhone(tester,
        BottleScanHistoryPage(deviceId: 7, deviceName: 'Bottles', api: api));
    expect(find.text('Scans unavailable'), findsOneWidget);
    api.fail = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No matching scans'), findsOneWidget);
  });
  testWidgets('team assignment uses member ID and latest revision',
      (tester) async {
    final api = FakeJournalApi();
    await pumpPhone(
        tester,
        Scaffold(
            body: SingleChildScrollView(
                child: AlertTeamPanel(alertId: 9, api: api))));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Technician').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save assignment'));
    await tester.pumpAndSettle();
    expect(api.requests.last.body!['assigned_to'], 7);
    expect(api.requests.last.body!['revision'], 0);
    expect(api.team['revision'], 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'team resolution requires note and confirms server result before callback',
      (tester) async {
    final api = FakeJournalApi();
    var resolved = false;
    await pumpPhone(
        tester,
        Scaffold(
            body: SingleChildScrollView(
                child: AlertTeamPanel(
                    alertId: 9, api: api, onResolved: () => resolved = true))));
    await tester.ensureVisible(find.text('Resolve with note'));
    await tester.tap(find.text('Resolve with note'));
    await tester.pumpAndSettle();
    expect(resolved, isFalse);
    expect(api.requests.where((r) => r.method == 'PATCH'), isEmpty);
    await tester.enterText(find.byType(TextField),
        'Replaced the cylinder and checked the reading');
    api.fail = true;
    await tester.ensureVisible(find.text('Resolve with note'));
    await tester.tap(find.text('Resolve with note'));
    await tester.pumpAndSettle();
    expect(resolved, isFalse);
    api.fail = false;
    await tester.ensureVisible(find.text('Resolve with note'));
    await tester.tap(find.text('Resolve with note'));
    await tester.pumpAndSettle();
    expect(resolved, isTrue);
    expect(find.text('Resolve with note'), findsNothing);
    expect(api.requests.last.body!['action'], 'resolve');
    expect(tester.takeException(), isNull);
  });
}
