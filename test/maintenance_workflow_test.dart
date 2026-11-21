import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/screens/maintanance.dart';
import 'package:artic_sentinel/screens/reports.dart';
import 'package:artic_sentinel/screens/schedule_maintenance.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> record(
        {String status = 'scheduled', bool checked = false}) =>
    {
      'id': 'record-1',
      'device': {'id': 31, 'name': 'Kitchen scale', 'device_id': 'GAS-031'},
      'maintenance_type': {
        'id': 'type-1',
        'name': 'Scale inspection',
        'category': 'inspection',
        'category_display': 'Inspection'
      },
      'scheduled_date': '2026-10-04T08:30:00Z',
      'status': status,
      'status_display': status == 'in_progress'
          ? 'In Progress'
          : status == 'completed'
              ? 'Completed'
              : 'Scheduled',
      'priority': 'normal',
      'priority_display': 'Normal',
      'work_description': 'Check scale calibration',
      'assigned_to': null,
      'parts_used': [],
      'materials_used': [],
      'observations': [],
      'before_photos': [],
      'after_photos': [],
      'documents': [],
      'created_at': '2026-10-03T08:00:00Z',
      'updated_at': '2026-10-03T08:00:00Z',
      'checklist_items': [
        {
          'id': 8,
          'description': 'Verify calibration',
          'item_description': 'Verify calibration',
          'is_completed': checked,
          'is_critical': true,
          'notes': '',
          'order': 0
        }
      ],
    };
http.Response response(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status,
        headers: {'content-type': 'application/json'});
http.Response fixtures(http.Request request) {
  final p = request.url.path;
  if (p.endsWith('/devices/list/'))
    return response({
      'devices': [
        {'id': 31, 'name': 'Kitchen scale', 'device_id': 'GAS-031'},
        {
          'id': 32,
          'name': 'Cold room probe',
          'device_id': 'FR-032',
          'device_type': 'device1',
          'connected_unit': {'id': 'unit-1', 'name': 'Cold room 1'}
        }
      ]
    });
  if (p.endsWith('/units/management/list/'))
    return response({
      'units': [
        {'id': 'unit-1', 'name': 'Cold room 1', 'location': 'Back kitchen'},
        {'id': 'unit-2', 'name': 'Freezer 2'}
      ]
    });
  if (p.endsWith('/maintenance/types/'))
    return response({
      'maintenance_types': [
        {
          'id': 'type-1',
          'name': 'Scale inspection',
          'category': 'inspection',
          'category_display': 'Inspection'
        }
      ]
    });
  if (p.endsWith('/assignable-users/'))
    return response({
      'users': [
        {'id': 42, 'full_name': 'Technician', 'username': 'tech'}
      ]
    });
  if (p.endsWith('/maintenance/dashboard/'))
    return response({
      'dashboard': {'upcoming_maintenance': []}
    });
  if (p.endsWith('/maintenance/list/'))
    return response({
      'maintenance_records': [record()]
    });
  if (p.endsWith('/maintenance/reminders/')) return response({'reminders': {}});
  if (p.endsWith('/maintenance/schedules/')) return response({'schedules': []});
  if (p.endsWith('/reports/monthly/')) return response({'reports': []});
  if (p.endsWith('/record-1/')) return response({'maintenance': record()});
  throw StateError('Unexpected request: ${request.method} $p');
}

Future<void> show(WidgetTester tester, Widget view,
    {double width = 390}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
      MaterialApp(theme: articMobileTheme(), home: Scaffold(body: view)));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues(
        {'AUTHTOKENKEY': 'test-token', 'USEREUIDKEY': 42, 'BUSINESSUIDKEY': 7});
    Constants.myBusiness = Business(
        businessUid: 7,
        businessName: 'Workshop',
        isActive: true,
        activeDevicesCount: 1,
        isPrimary: true);
  });
  testWidgets(
      'create maintenance submits real equipment and refreshes dashboard',
      (tester) async {
    var created = false;
    var listLoads = 0;
    Map<String, dynamic>? payload;
    await http.runWithClient(() async {
      await show(tester, MaintenanceDashboard());
      expect(find.text('Coming up'), findsOneWidget);
      expect(find.text('Due this week'), findsOneWidget);
      await tapVisible(tester, find.text('Schedule maintenance'));
      expect(find.text('What needs maintenance?'), findsOneWidget);
      // Units list their devices; devices without a unit are listed apart.
      expect(find.textContaining('Monitored by Cold room probe'), findsOneWidget);
      expect(find.text('DEVICES WITHOUT A UNIT'), findsOneWidget);
      expect(find.text('Link a device to schedule'), findsOneWidget); // Freezer 2
      await tapVisible(tester, find.text('Kitchen scale'));
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Scale inspection'));
      expect(find.text('Scale inspection — Kitchen scale'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('maintenance-work')), 'Check scale calibration');
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('Review'), findsWidgets);
      await tapVisible(tester, find.text('Schedule maintenance').last);
      expect(created, isTrue);
      expect(payload?['device_id'], 31);
      expect(payload?['status'], 'scheduled');
      expect(payload?['scheduled_date'], endsWith('Z'));
      expect(listLoads, greaterThanOrEqualTo(2));
      expect(payload?['work_description'], 'Check scale calibration');
      expect(payload?['client_request_id'], isNotNull);
      expect(find.byType(ScheduleMaintenanceScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              expect(request.headers['authorization'], 'Token test-token');
              if (request.url.path.endsWith('/maintenance/create/')) {
                created = true;
                payload = jsonDecode(request.body);
                return response(
                    {'success': true, 'message': 'Maintenance scheduled'}, 201);
              }
              if (request.url.path.endsWith('/maintenance/list/')) {
                listLoads++;
                return response({
                  'maintenance_records': created ? [record()] : []
                });
              }
              return fixtures(request);
            }));
  });
  testWidgets('record filters reset pagination and all pages remain reachable',
      (tester) async {
    final queries = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await show(tester, MaintenanceDashboard());
      await tapVisible(tester, find.text('Records').first);
      await tapVisible(tester, find.text('Load more records'));
      expect(queries.last['page'], 2);
      expect(find.text('Load more records'), findsNothing);
      await tapVisible(tester, find.text('Status').first);
      await tapVisible(tester, find.text('Completed').last);
      expect(queries.last['page'], 1);
      expect(queries.last['filters']['status'], 'completed');
      await tapVisible(tester, find.text('Clear All'));
      expect(queries.last['filters'], isEmpty);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/maintenance/list/')) {
                final q = Map<String, dynamic>.from(jsonDecode(request.body));
                queries.add(q);
                final r = record();
                r['id'] = 'page-${q['page']}';
                return response({
                  'maintenance_records': [r],
                  'pagination': {'has_next': q['page'] == 1}
                });
              }
              return fixtures(request);
            }));
  });
  testWidgets('maintenance setup does not fabricate devices on network failure',
      (tester) async {
    await http.runWithClient(() async {
      await show(tester, const ScheduleMaintenanceScreen());
      expect(find.textContaining('Unable to load maintenance setup'),
          findsOneWidget);
      expect(find.text('Main Production Server'), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async => r.url.path.endsWith('/devices/list/')
            ? response({}, 503)
            : fixtures(r)));
  });
  testWidgets('maintenance setup has equipment empty state', (tester) async {
    await http.runWithClient(() async {
      await show(tester, const ScheduleMaintenanceScreen());
      expect(find.text('No equipment to maintain'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async => r.url.path.endsWith('/devices/list/')
            ? response({'devices': []})
            : fixtures(r)));
  });
  testWidgets(
      'recurring scheduling validates and posts the selected device and interval',
      (tester) async {
    Map<String, dynamic>? sent;
    await http.runWithClient(() async {
      await show(tester, const ScheduleMaintenanceScreen(recurring: true));
      expect(find.text('Recurring maintenance'), findsOneWidget);
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('Choose the equipment that needs maintenance.'),
          findsOneWidget);
      await tapVisible(tester, find.text('Kitchen scale'));
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Scale inspection'));
      await tapVisible(tester, find.text('Every … days'));
      await tapVisible(tester, find.text('Continue'));
      expect(find.text('Enter 1 to 730 days.'), findsOneWidget);
      await tapVisible(tester, find.text('Weekly'));
      await tapVisible(tester, find.text('Technician'));
      await tapVisible(tester, find.text('Continue'));
      expect(find.textContaining('Repeats every week'), findsOneWidget);
      await tapVisible(tester, find.text('Create schedule'));
      expect(sent?['device_id'], 31);
      expect(sent?['maintenance_type_id'], 'type-1');
      expect(sent?['frequency'], 'weekly');
      expect(sent?['auto_assign_to_id'], 42);
      expect(sent?['client_request_id'], isNotNull);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              expect(r.headers['authorization'], 'Token test-token');
              if (r.url.path.endsWith('/schedule/create/')) {
                sent = jsonDecode(r.body);
                return response({'success': true}, 201);
              }
              return fixtures(r);
            }));
  });
  testWidgets('record edit persists assignment description and UTC schedule',
      (tester) async {
    Map<String, dynamic>? sent;
    await http.runWithClient(() async {
      await show(tester, MaintenanceEditorDialog(record: record()));
      await tester.enterText(
          find.byKey(const ValueKey('maintenance-description')),
          'Check regulator and calibration');
      final assign =
          find.widgetWithText(DropdownButtonFormField<String>, 'Unassigned');
      await tapVisible(tester, assign);
      await tapVisible(tester, find.text('Technician').last);
      await tapVisible(tester, find.text('Save changes'));
      expect(sent?['work_description'], 'Check regulator and calibration');
      expect(sent?['assigned_to_id'], 42);
      expect(sent?['scheduled_date'], endsWith('Z'));
      expect(sent?.containsKey('status'), isFalse);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.url.path.endsWith('/record-1/update/')) {
                sent = jsonDecode(r.body);
                return response({'success': true});
              }
              return fixtures(r);
            }));
  });
  testWidgets(
      'failed edit keeps entries and allows retry without false success',
      (tester) async {
    await http.runWithClient(() async {
      await show(tester, MaintenanceEditorDialog(record: record()));
      await tester.enterText(
          find.byKey(const ValueKey('maintenance-description')),
          'Keep this text');
      await tapVisible(tester, find.text('Save changes'));
      expect(find.textContaining('Unable to save changes'), findsOneWidget);
      expect(find.text('Keep this text'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async =>
            r.url.path.endsWith('/update/') ? response({}, 503) : fixtures(r)));
  });
  testWidgets('detail progresses start checklist complete using current user',
      (tester) async {
    String status = 'scheduled';
    bool checked = false;
    final actions = <String>[];
    await http.runWithClient(() async {
      await show(
          tester, const MaintenanceDetailScreen(maintenanceId: 'record-1'));
      await tapVisible(tester, find.text('Start job'));
      expect(status, 'in_progress');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Mark complete'));
      expect(actions, ['start']);
      expect(find.textContaining('Complete all critical checklist'),
          findsOneWidget);
      final check = find.byType(Checkbox).first;
      await tapVisible(tester, check);
      expect(checked, isTrue);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Mark complete'));
      expect(status, 'completed');
      expect(actions, ['start', 'complete']);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              expect(r.headers['authorization'], 'Token test-token');
              if (r.url.path.endsWith('/status/')) {
                final data = jsonDecode(r.body);
                expect(data['user_id'], 42);
                actions.add(data['action']);
                status =
                    data['action'] == 'start' ? 'in_progress' : 'completed';
                return response({'success': true});
              }
              if (r.url.path.contains('/checklist/8/update/')) {
                checked = jsonDecode(r.body)['mark_completed'];
                return response({'success': true});
              }
              if (r.url.path.endsWith('/record-1/'))
                return response(
                    {'maintenance': record(status: status, checked: checked)});
              return fixtures(r);
            }));
  });
  testWidgets('all detail tabs render on a narrow phone', (tester) async {
    await http.runWithClient(() async {
      await show(
          tester, const MaintenanceDetailScreen(maintenanceId: 'record-1'),
          width: 320);
      for (final title in [
        'Checklist',
        'Findings',
        'Timeline',
        'Documentation',
        'Overview'
      ]) {
        await tapVisible(tester, find.text(title).first);
        expect(tester.takeException(), isNull, reason: title);
      }
    }, () => MockClient((r) async => fixtures(r)));
  });
  testWidgets('all dashboard tabs render on a narrow phone', (tester) async {
    await http.runWithClient(() async {
      await show(tester, MaintenanceDashboard(), width: 320);
      for (final title in [
        'Records',
        'Scheduling',
        'Reminders',
        'Analytics',
        'Settings',
        'Overview'
      ]) {
        await tapVisible(tester, find.widgetWithText(Tab, title));
        expect(tester.takeException(), isNull, reason: title);
      }
    }, () => MockClient((r) async => fixtures(r)));
  });
  testWidgets('failed status update stays scheduled and exposes retry guidance',
      (tester) async {
    await http.runWithClient(() async {
      await show(
          tester, const MaintenanceDetailScreen(maintenanceId: 'record-1'));
      await tapVisible(tester, find.text('Start job'));
      expect(find.textContaining('Unable to update status'), findsOneWidget);
      expect(find.text('Start job'), findsOneWidget);
      expect(find.text('In Progress'), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async =>
            r.url.path.endsWith('/status/') ? response({}, 503) : fixtures(r)));
  });
  testWidgets('scheduling a unit records it against the device that monitors it',
      (tester) async {
    Map<String, dynamic>? sent;
    await http.runWithClient(() async {
      await show(tester, const ScheduleMaintenanceScreen());
      await tapVisible(tester, find.text('Cold room 1'));
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Scale inspection'));
      expect(find.text('Scale inspection — Cold room 1 (Cold room probe)'),
          findsOneWidget);
      await tapVisible(tester, find.text('Tomorrow'));
      await tapVisible(tester, find.text('High'));
      await tapVisible(tester, find.text('Technician'));
      await tapVisible(tester, find.text('Continue'));
      await tapVisible(tester, find.text('Schedule maintenance').last);
      expect(sent?['device_id'], 32);
      expect(sent?['priority'], 'high');
      expect(sent?['assigned_to_id'], 42);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.url.path.endsWith('/maintenance/create/')) {
                sent = jsonDecode(r.body);
                return response({'success': true}, 201);
              }
              return fixtures(r);
            }));
  });
  testWidgets(
      'duplicate creates a scheduled copy without overwriting the original',
      (tester) async {
    Map<String, dynamic>? saved;
    await http.runWithClient(() async {
      await show(
          tester,
          MaintenanceEditorDialog(
              record: record(status: 'completed'), duplicate: true));
      await tapVisible(tester, find.text('Create copy'));
      expect(saved?['status'], 'scheduled');
      expect(saved?['device_id'], 31);
      expect(saved?['maintenance_type_id'], 'type-1');
      expect(saved?.containsKey('id'), isFalse);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.url.path.endsWith('/maintenance/create/')) {
                saved = jsonDecode(r.body);
                return response({'success': true}, 201);
              }
              return fixtures(r);
            }));
  });
  testWidgets(
      'unchanged create retries reuse an operation ID and changed entries get a new ID',
      (tester) async {
    final payloads = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      await show(
          tester, MaintenanceEditorDialog(record: record(), duplicate: true));
      await tapVisible(tester, find.text('Create copy'));
      await tapVisible(tester, find.text('Create copy'));
      expect(
          payloads[0]['client_request_id'], payloads[1]['client_request_id']);
      expect(payloads[0]['client_request_id'],
          matches(RegExp(r'^[a-f0-9-]{36}$')));
      await tester.enterText(
          find.byKey(const ValueKey('maintenance-description')),
          'Different job');
      await tapVisible(tester, find.text('Create copy'));
      expect(payloads[2]['client_request_id'],
          isNot(payloads[1]['client_request_id']));
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async {
              if (r.url.path.endsWith('/maintenance/create/')) {
                payloads.add(Map<String, dynamic>.from(jsonDecode(r.body)));
                return response({}, 503);
              }
              return fixtures(r);
            }));
  });
  testWidgets('maintenance reports show real empty state and no sample action',
      (tester) async {
    await http.runWithClient(() async {
      await show(tester, const MaintenanceReportsDialog());
      expect(find.text('No maintenance reports yet'), findsOneWidget);
      expect(find.textContaining('Sample'), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => MockClient((r) async => fixtures(r)));
  });
  testWidgets(
      'record PDF uses actual data and failed saving keeps the report screen open',
      (tester) async {
    Uint8List? pdf;
    await http.runWithClient(() async {
      await show(
          tester,
          MaintenanceReportsDialog(
              initialMaintenanceId: 'record-1',
              pdfSaver: (bytes, name) async {
                pdf = bytes;
                throw const FileSystemException('test save failure');
              }));
      expect(pdf, isNotNull);
      final document = latin1.decode(pdf!);
      final streams =
          RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream').allMatches(document);
      final decoded = <String>[];
      for (final stream in streams) {
        try {
          decoded
              .add(latin1.decode(zlib.decode(latin1.encode(stream.group(1)!))));
        } catch (_) {
          decoded.add(stream.group(1)!);
        }
      }
      expect(decoded.join(' '), contains('record-1'));
      expect(find.byType(MaintenanceReportsDialog), findsOneWidget);
      expect(
          find.textContaining('Unable to generate the report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((r) async => r.url.path.endsWith('/observations/')
            ? response({'observations': []})
            : fixtures(r)));
  });
  test(
      'maintenance report failure is not returned as an empty successful report',
      () async {
    await http.runWithClient(() async {
      expect(
          () => MaintenanceReportApiService.getMaintenanceReport(
              businessId: 7, startDate: '2026-10-01', endDate: '2026-10-03'),
          throwsException);
    }, () => MockClient((r) async => response({}, 503)));
  });
}
