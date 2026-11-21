import 'dart:async';
import 'dart:convert';
import 'package:artic_sentinel/constants/Constants.dart';
import 'package:artic_sentinel/services/offline_read_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artic_sentinel/services/secure_session_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Uri endpoint(String path) => Uri.parse('${Constants.articBaseUrl2}$path');
  test('saved readings survive a new client and are explicitly marked',
      () async {
    final first = OfflineReadClient(
        client: MockClient(
            (_) async => http.Response('{"devices":[{"id":2}]}', 200)),
        sessionScope: () async => '7:9');
    await first.post(endpoint('api/devices/list/'), body: '{"business_id":9}');
    first.close();
    final reopened = OfflineReadClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
        sessionScope: () async => '7:9');
    final response = await reopened.post(endpoint('api/devices/list/'),
        body: '{"business_id":9}');
    expect(jsonDecode(response.body)['devices'][0]['id'], 2);
    expect(response.headers['x-artic-snapshot-at'], isNotNull);
    expect(reopened.status.value, isNotNull);
    reopened.close();
  });
  test('separate accounts cannot reuse each others snapshots', () async {
    bool online = true;
    var scope = '7:9';
    final client = OfflineReadClient(
        client: MockClient((_) async => online
            ? http.Response('[]', 200)
            : throw http.ClientException('offline')),
        sessionScope: () async => scope);
    await client.get(endpoint('latest-device-data/9/'));
    online = false;
    scope = '8:9';
    await expectLater(client.get(endpoint('latest-device-data/9/')),
        throwsA(isA<http.ClientException>()));
    client.close();
  });
  test('trusted reads replace stale caller auth regardless of header case',
      () async {
    SharedPreferences.setMockInitialValues(
        {'ISLOGGEDIN': true, 'USEREUIDKEY': 7, 'BUSINESSUIDKEY': 9});
    FlutterSecureStorage.setMockInitialValues(
        {SecureSessionStore.tokenKey: 'current-token'});
    Map<String, String>? sent;
    final client = OfflineReadClient(client: MockClient((request) async {
      sent = request.headers;
      return http.Response('[]', 200);
    }));
    await client.get(endpoint('latest-device-data/9/'), headers: {
      'authorization': 'Token stale-token',
      'Content-Type': 'application/json'
    });
    expect(sent?['authorization'], 'Token current-token');
    expect(sent?['content-type'], 'application/json');
    client.close();
  });
  test('missing secure token cannot reuse real-session cached readings',
      () async {
    SharedPreferences.setMockInitialValues(
        {'ISLOGGEDIN': true, 'USEREUIDKEY': 7, 'BUSINESSUIDKEY': 9});
    FlutterSecureStorage.setMockInitialValues(
        {SecureSessionStore.tokenKey: 'current-token'});
    var online = true;
    final client = OfflineReadClient(client: MockClient((request) async {
      if (!online) {
        expect(request.headers['authorization'], isNull);
        throw http.ClientException('offline');
      }
      return http.Response('[]', 200);
    }));
    final uri = endpoint('latest-device-data/9/');
    await client.get(uri);
    await const FlutterSecureStorage().delete(key: SecureSessionStore.tokenKey);
    online = false;
    await expectLater(
        client.get(uri, headers: {'Authorization': 'Token stale-token'}),
        throwsA(isA<http.ClientException>()));
    client.close();
  });
  test(
      'authorization denial clears other endpoint caches and rejects pending reads',
      () async {
    var online = true;
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final client = OfflineReadClient(
        sessionScope: () async => '7:9',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/pending/')) {
            started.complete();
            return pending.future;
          }
          if (request.url.path.endsWith('/denied/'))
            return http.Response('{}', 403);
          return http.Response('[]', online ? 200 : 503);
        }));
    final uri = endpoint('latest-device-data/9/');
    await client.get(uri);
    final pendingCall = client.get(endpoint('latest-device-data/pending/'));
    final rejected = expectLater(pendingCall, throwsStateError);
    await started.future;
    expect(
        (await client.get(endpoint('latest-device-data/denied/'))).statusCode,
        403);
    pending.complete(http.Response('[]', 200));
    await rejected;
    online = false;
    expect((await client.get(uri)).statusCode, 503);
    expect(client.status.value, isNull);
    client.close();
  });
  test('403 invalidates saved data and never falls back', () async {
    int code = 200;
    final client = OfflineReadClient(
        client: MockClient((_) async => http.Response('{}', code)),
        sessionScope: () async => '7:9');
    final uri = endpoint('latest-device-data/9/');
    await client.get(uri);
    code = 403;
    expect((await client.get(uri)).statusCode, 403);
    code = 503;
    expect((await client.get(uri)).statusCode, 503);
    expect(client.status.value, isNull);
    client.close();
  });
  test('writes and credential endpoints are never cached or replayed',
      () async {
    bool online = true;
    final client = OfflineReadClient(
        client: MockClient((_) async => online
            ? http.Response('{"ok":true}', 200)
            : throw http.ClientException('offline')),
        sessionScope: () async => '7:9');
    final uri = endpoint('api/gas/credentials/issue/');
    await client.post(uri, body: '{}');
    online = false;
    await expectLater(
        client.post(uri, body: '{}'), throwsA(isA<http.ClientException>()));
    client.close();
  });
  test('successful reconnection replaces fallback and clears its status',
      () async {
    bool online = true;
    final client = OfflineReadClient(
        client: MockClient((_) async => online
            ? http.Response('[]', 200)
            : http.Response('unavailable', 503)),
        sessionScope: () async => '7:9');
    final uri = endpoint('latest-device-data/9/');
    await client.get(uri);
    online = false;
    await client.get(uri);
    expect(client.status.value, isNotNull);
    online = true;
    await client.get(uri);
    expect(client.status.value, isNull);
    client.close();
  });
  test('logout clears snapshots and rejects an in-flight old-account result',
      () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final client = OfflineReadClient(
        client: MockClient((_) {
          started.complete();
          return pending.future;
        }),
        sessionScope: () async => '7:9');
    final call = client.get(endpoint('latest-device-data/9/'));
    final check = expectLater(call, throwsStateError);
    await started.future;
    await OfflineReadClient.clearAllSnapshots();
    pending.complete(http.Response('[]', 200));
    await check;
    client.close();
  });
}
