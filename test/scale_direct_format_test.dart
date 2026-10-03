import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/gasmon/scale_ble.dart';

void main() {
  const login = {
    'device_id': 'GAS-001',
    'mqtt_host': 'api.articsentinel.com',
    'mqtt_port': 8883,
    'mqtt_user': 'GAS-001',
    'mqtt_pass': 'issued-secret',
    'topic': 'gas_cylinder/GAS-001/data',
  };

  test('JSON direct format carries Wi-Fi, BSSID and the server login', () {
    final decoded = jsonDecode(utf8.decode(DirectFormat.json
        .encode('Home', 'pw', bssid: 'aa:bb:cc:dd:ee:ff', extra: login)));
    expect(decoded, {
      'ssid': 'Home',
      'password': 'pw',
      'bssid': 'aa:bb:cc:dd:ee:ff',
      ...login,
    });
  });

  test('JSON direct format without a login stays Wi-Fi only', () {
    expect(utf8.decode(DirectFormat.json.encode('Home', 'pw')),
        '{"ssid":"Home","password":"pw"}');
  });

  test('plain formats never carry the login', () {
    expect(utf8.decode(DirectFormat.comma.encode('Home', 'pw', extra: login)),
        'Home,pw');
    expect(utf8.decode(DirectFormat.lines.encode('Home', 'pw', extra: login)),
        'Home\npw');
  });
}
