import 'dart:convert';

import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/models/unit.dart';
import 'package:artic_sentinel/screens/add_user_flow.dart';
import 'package:artic_sentinel/widgets/unit_link_sheets.dart';
import 'package:artic_sentinel/screens/team_members_tab.dart';
import 'package:artic_sentinel/screens/unit_flow.dart';
import 'package:artic_sentinel/widgets/mobile_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(WidgetTester t, Widget screen, {double width = 360, double scale = 1}) async {
    t.view.physicalSize = Size(width, 820);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
      theme: articMobileTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQueryData(
              size: Size(width, 820), textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
              body: Center(
                  child: FilledButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
                      child: const Text('open'))))),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String label) async {
    final f = find.text(label).last;
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> type(WidgetTester t, String label, String text) async {
    final f = find.widgetWithText(TextFormField, label);
    await t.ensureVisible(f);
    await t.enterText(f, text);
    await t.pump();
  }

  testWidgets('add unit: guided steps, refrigerant required, no invented specs', (t) async {
    Map<String, dynamic>? sent;
    await mount(t, UnitFlowScreen(onSave: (d) async => sent = d), width: 320, scale: 1.3);
    expect(find.text('Find the rating plate'), findsOneWidget);
    await tap(t, 'Continue');
    expect(find.text('Give the unit a name.'), findsOneWidget);
    await type(t, 'Unit name', 'Cold room 1');
    await type(t, 'Model number', 'CU-200');
    await type(t, 'Serial number', 'SN-778');
    await tap(t, 'Continue');
    expect(find.text('Where is it?'), findsOneWidget);
    await type(t, 'Location', 'Main kitchen');
    await tap(t, 'Continue');
    expect(find.text('Refrigeration details'), findsOneWidget);
    await tap(t, 'Add unit');
    expect(find.textContaining('Choose the refrigerant'), findsWidgets);
    expect(sent, isNull);
    await tap(t, 'R404A');
    await tap(t, 'Add unit');
    expect(sent!['name'], 'Cold room 1');
    expect(sent!['refrigerant_type'], 'r404a');
    expect(sent!['location'], 'Main kitchen');
    expect(sent!.containsKey('compressor_model'), isFalse);
    expect(sent!.containsKey('compressor_type'), isFalse); // left as "Not sure"
    expect(find.text('open'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('add unit: server rejection returns to the identity step', (t) async {
    await mount(t, UnitFlowScreen(onSave: (_) async => throw 'Serial number already exists'));
    await type(t, 'Unit name', 'Cold room 1');
    await type(t, 'Model number', 'CU-200');
    await type(t, 'Serial number', 'SN-778');
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await tap(t, 'R134a');
    await tap(t, 'Add unit');
    expect(find.text('Serial number already exists'), findsOneWidget);
    expect(find.text('Find the rating plate'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('add user: validates email, picks a role, hands over the password', (t) async {
    Map<String, String>? sent;
    await mount(t, AddUserFlowScreen(submit: (d) async {
      sent = d;
      return 'Temp-1234-abcd';
    }), width: 320, scale: 1.3);
    await type(t, 'First name', 'Nomsa');
    await type(t, 'Last name', 'Dlamini');
    await type(t, 'Email', 'not-an-email');
    await tap(t, 'Continue');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await type(t, 'Email', 'nomsa@example.com');
    await tap(t, 'Continue');
    expect(find.text('Choose their role'), findsOneWidget);
    await tap(t, 'Technician');
    await tap(t, 'Continue');
    expect(find.text('Review and add'), findsWidgets);
    await tap(t, 'Add Nomsa');
    expect(sent!['user_type'], 'technician');
    expect(sent!['email'], 'nomsa@example.com');
    expect(find.text('Temp-1234-abcd'), findsOneWidget);
    expect(find.text('Account created'), findsOneWidget);
    await tap(t, 'Done');
    expect(find.text('open'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('team list shows role filters and member details', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    await http.runWithClient(() async {
      await t.pumpWidget(MaterialApp(theme: articMobileTheme(), home: const Scaffold(body: TeamMembersTab())));
      await t.pumpAndSettle();
      expect(find.text('3'), findsOneWidget); // members
      expect(find.text('Can add users'), findsOneWidget);
      final chip = find.widgetWithText(ChoiceChip, 'Technician');
      await t.ensureVisible(chip);
      await t.pumpAndSettle();
      await t.tap(chip);
      await t.pumpAndSettle();
      expect(find.text('Sipho Nkosi'), findsOneWidget);
      expect(find.text('Lerato Mokoena'), findsNothing);
      await tap(t, 'Sipho Nkosi');
      expect(find.text('Cellphone'), findsOneWidget);
      expect(find.text('082 555 0101'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
        () => MockClient((request) async => http.Response(
            jsonEncode({
              'can_manage': true,
              'members': [
                {'firstname': 'Lerato', 'lastname': 'Mokoena', 'email': 'lerato@example.com',
                 'user_type': 'administrator', 'is_primary_contact': true},
                {'firstname': 'Sipho', 'lastname': 'Nkosi', 'email': 'sipho@example.com',
                 'user_type': 'technician', 'cellphone_number': '082 555 0101', 'job_title': 'Fridge tech'},
                {'firstname': 'Anna', 'lastname': 'Smit', 'email': 'anna@example.com', 'user_type': 'customer'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'})));
  });

  group('linking units and devices', () {
    setUp(() => Constants.myBusiness = Business(
        businessUid: 1, businessName: 'Test', isActive: true, activeDevicesCount: 0, isPrimary: true));

    http.Response devices() => http.Response(
        jsonEncode({
          'devices': [
            {'id': 1, 'name': 'Probe A', 'device_id': 'A', 'device_type': 'device1',
             'connected_unit': {'id': 'u1', 'name': 'Cold room 1'}},
            {'id': 2, 'name': 'Probe B', 'device_id': 'B', 'device_type': 'device2'},
            {'id': 3, 'name': 'Probe C', 'device_id': 'C', 'device_type': 'device1',
             'connected_unit': {'id': 'u2', 'name': 'Freezer 2'}},
          ]
        }),
        200,
        headers: {'content-type': 'application/json'});

    Future<void> openWith(WidgetTester t, Future<void> Function(BuildContext) open) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(MaterialApp(
          theme: articMobileTheme(),
          home: Builder(builder: (c) => Scaffold(body: Center(child: FilledButton(onPressed: () => open(c), child: const Text('open')))))));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('a unit links free devices and moves one from another unit', (t) async {
      final updates = <Map<String, dynamic>>[];
      bool? result;
      await http.runWithClient(() async {
        await openWith(t, (c) async => result = await showLinkDevicesToUnit(c, unitId: 'u1', unitName: 'Cold room 1'));
        expect(find.text('Link devices'), findsOneWidget);
        expect(find.textContaining('now on Freezer 2'), findsOneWidget);
        await t.tap(find.text('Probe B'));
        await t.tap(find.text('Probe C'));
        await t.tap(find.text('Probe A')); // untick: unlink
        await t.pumpAndSettle();
        expect(find.textContaining('will move here'), findsOneWidget);
        await t.tap(find.text('Save 3 changes'));
        await t.pumpAndSettle();
        expect(result, isTrue);
        expect(updates.map((u) => '${u['device_id']}:${u['connected_unit_id']}').toSet(),
            {'1:null', '2:u1', '3:u1'});
        expect(t.takeException(), isNull);
      }, () => MockClient((r) async {
            if (r.url.path.endsWith('/devices/update/')) {
              updates.add(jsonDecode(r.body));
              return http.Response('{"success": true}', 200);
            }
            return devices();
          }));
    });

    testWidgets('a device can choose a unit or none', (t) async {
      Map<String, dynamic>? update;
      final device = Device(id: 1, name: 'Probe A', deviceId: 'A', deviceType: 'device1',
          connectedUnit: ConnectedUnit.fromJson({'id': 'u1', 'name': 'Cold room 1'}));
      await http.runWithClient(() async {
        await openWith(t, (c) => showLinkUnitToDevice(c, device: device));
        expect(find.text('Cold room 1'), findsOneWidget);
        await t.tap(find.text('No unit'));
        await t.pumpAndSettle();
        await t.tap(find.text('Save'));
        await t.pumpAndSettle();
        expect(update?['connected_unit_id'], isNull);
        expect(update?.containsKey('connected_unit_id'), isTrue);
        expect(update?['device_id'], 1);
        expect(t.takeException(), isNull);
      }, () => MockClient((r) async {
            if (r.url.path.endsWith('/devices/update/')) {
              update = jsonDecode(r.body);
              return http.Response('{"success": true}', 200);
            }
            return http.Response(
                jsonEncode({'units': [{'id': 'u1', 'name': 'Cold room 1', 'location': 'Kitchen'}, {'id': 'u2', 'name': 'Freezer 2'}]}),
                200, headers: {'content-type': 'application/json'});
          }));
    });
  });
}
