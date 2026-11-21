import 'package:artic_sentinel/gasmon/gas_api.dart';
import 'package:artic_sentinel/gasmon/gas_cylinder_details_dialog.dart';
import 'package:artic_sentinel/gasmon/gas_dashboard_card.dart';
import 'package:artic_sentinel/services/offline_read_client.dart';
import 'package:artic_sentinel/services/secure_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gas_state_and_setup_test.dart' as fixture;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'ISLOGGEDIN': true, 'USEREUIDKEY': 7, 'BUSINESSUIDKEY': 9});
    FlutterSecureStorage.setMockInitialValues(
        {SecureSessionStore.tokenKey: 'signed-in-test-session'});
  });
  for (final details in [false, true]) {
    testWidgets(
        'cached recent gas reading is marked historical in ${details ? 'details' : 'dashboard'}',
        (tester) async {
      final cache = OfflineReadClient(
          client: MockClient(
              (_) async => fixture.reply(rows: [fixture.reading()])));
      await GasApi.load(deviceId: 42, demoKey: '', reader: cache);
      cache.close();
      await http.runWithClient(() async {
        await fixture.screen(
            tester,
            details
                ? GasCylinderDetailsDialog(device: fixture.device())
                : SingleChildScrollView(
                    child: GasDashboardCard(device: fixture.device())),
            width: 390);
        expect(find.text('Saved readings'), findsOneWidget);
        expect(find.text('LIVE SCALE'), findsNothing);
        expect(find.text('LAST REPORTED'), findsOneWidget);
        if (details) {
          expect(find.text('Connection unconfirmed'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => MockClient((_) async => throw http.ClientException('offline')));
    });
  }
}
