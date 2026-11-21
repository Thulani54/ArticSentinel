import 'dart:convert';
import 'package:artic_sentinel/device_journal/device_journal_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('uses session token and sends exact idempotent refill payload',
      () async {
    late http.Request recorded;
    final api = DeviceJournalApi(
        tokenProvider: () async => 'mock-session',
        client: MockClient((request) async {
          recorded = request;
          return http.Response('{"refill":{"id":3}}', 201);
        }));
    final body = {'request_id': 'fixed-uuid', 'gas_kg': '9', 'cost': '300'};
    await api.request('devices/8/refills/', method: 'POST', body: body);
    expect(recorded.headers['Authorization'], 'Token mock-session');
    expect(
        recorded.url.path, endsWith('/api/device-journal/devices/8/refills/'));
    expect(jsonDecode(recorded.body), body);
  });
  test('unauthenticated requests never reach the network', () async {
    var called = false;
    final api = DeviceJournalApi(
        tokenProvider: () async => null,
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }));
    await expectLater(api.request('devices/8/refills/'),
        throwsA(isA<DeviceJournalException>()));
    expect(called, isFalse);
  });
  test('server revision conflict is shown rather than treated as success',
      () async {
    final api = DeviceJournalApi(
        tokenProvider: () async => 'mock-session',
        client: MockClient((_) async =>
            http.Response('{"error":"Reload before saving."}', 409)));
    await expectLater(
        api.request('alerts/1/team/', method: 'PATCH', body: {'revision': 0}),
        throwsA(isA<DeviceJournalException>()
            .having((e) => e.message, 'message', 'Reload before saving.')));
  });
  test('network and non-JSON failures produce safe actionable errors',
      () async {
    for (final fail in [true, false]) {
      final api = DeviceJournalApi(
          tokenProvider: () async => 'mock-session',
          client: MockClient((_) async {
            if (fail) throw http.ClientException('private socket info');
            return http.Response('<html>proxy unavailable</html>', 502);
          }));
      await expectLater(
          api.request('devices/7/scans/', query: {'q': 'A&B'}),
          throwsA(isA<DeviceJournalException>().having(
              (e) => e.message, 'message', contains('Check your connection'))));
    }
  });
}
