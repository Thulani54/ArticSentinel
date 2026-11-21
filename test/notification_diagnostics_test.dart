import 'package:artic_sentinel/screens/notification_settings.dart';
import 'package:artic_sentinel/services/notification_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known numeric device payload resolves only to the local device route',
      () {
    expect(
        NotificationTarget.fromData(
            {'device_id': '42', 'url': 'https://untrusted.test'}).route,
        '/notification-device/42');
    expect(NotificationTarget.fromData({'device_id': '../settings'}).route,
        '/notification-settings');
    expect(NotificationTarget.fromData({'device_id': '-1'}).deviceId, isNull);
    expect(
        NotificationTarget.fromData(
            {'kind': 'notification_test', 'device_id': '42'}).route,
        '/notification-settings');
  });
  testWidgets(
      'test notification reports provider acceptance without claiming phone delivery',
      (tester) async {
    int sent = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NotificationSettingsPage(
      loadDiagnostics: () async => {
        'supported': true,
        'configured': true,
        'permission': 'authorized',
        'registered': true,
        'delivery_configured': true
      },
      sendTest: () async {
        sent++;
        return 'Accepted by provider. Confirm it appears on this phone.';
      },
    ))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send test notification'));
    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();
    expect(sent, 1);
    expect(find.text('Accepted by provider. Confirm it appears on this phone.'),
        findsOneWidget);
  });
  testWidgets('failure remains actionable and does not display a success',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NotificationSettingsPage(
      loadDiagnostics: () async => {'supported': true, 'configured': true},
      sendTest: () async => throw StateError('Enable notifications first.'),
    ))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send test notification'));
    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();
    expect(find.text('Enable notifications first.'), findsOneWidget);
  });
}
