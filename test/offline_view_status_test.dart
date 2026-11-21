import 'dart:async';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/services/offline_read_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Uri endpoint(String path) => Uri.parse('${Constants.articBaseUrl2}$path');
  test(
      'changing analytics preserves cached inventory warning but clears previous series',
      () async {
    var online = true;
    final client = OfflineReadClient(
        sessionScope: () async => '1:2',
        client:
            MockClient((_) async => http.Response('{}', online ? 200 : 503)));
    final inventory = endpoint('api/companies/2/devices/');
    final readings = endpoint('api/device-metrics/?device_id=1');
    await client.get(inventory);
    await client.get(readings);
    online = false;
    await client.get(inventory);
    await client.get(readings);
    client.resetStatus(preserveInventory: true);
    expect(client.status.value, isNotNull);
    online = true;
    await client.get(inventory);
    expect(client.status.value, isNull,
        reason: 'Old analytics fallback was discarded.');
    client.close();
  });
  test(
      'previous device fallback completing after reset cannot restore stale banner',
      () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    var online = true;
    final client = OfflineReadClient(
        sessionScope: () async => '1:2',
        client: MockClient((_) async {
          if (online) return http.Response('{}', 200);
          started.complete();
          return pending.future;
        }));
    final readings = endpoint('api/device-metrics/?device_id=1');
    await client.get(readings);
    online = false;
    final late = client.get(readings);
    await started.future;
    client.resetStatus(preserveInventory: true);
    pending.complete(http.Response('{}', 503));
    await late;
    expect(client.status.value, isNull);
    client.close();
  });
}
