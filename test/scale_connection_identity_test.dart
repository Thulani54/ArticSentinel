import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/gasmon/scale_connection_identity.dart';

void main() {
  Map<String, dynamic> settings() => {
        'device_id': 'TestGas4',
        'mqtt_client_id': 'AS_00000000000000000004',
        'mqtt_host': 'api.articsentinel.com',
        'mqtt_port': 8883,
        'mqtt_tls': true,
        'mqtt_user': 'TestGas4',
        'mqtt_pass': 'test-only-secret',
        'topic': 'gas_cylinder/TestGas4/data',
      };
  test('acknowledgement parsing does not reject a successful nullable error',
      () {
    expect(scaleSetupReplyRejected('{"success":true,"error":null}'), isFalse);
    expect(scaleSetupReplyRejected('OK'), isFalse);
    expect(scaleSetupReplyRejected('{"error":"bad settings"}'), isTrue);
    expect(scaleSetupReplyRejected('wrong password'), isTrue);
    expect(scaleSetupReplyRejected('{"status":"failed"}'), isTrue);
  });
  test('registered device identity is stable, unique and fits MQTT client IDs',
      () {
    expect(assignedScaleClientId(4), 'AS_00000000000000000004');
    expect(assignedScaleClientId(255), 'AS_000000000000000000FF');
    expect(assignedScaleClientId(4), isNot(assignedScaleClientId(5)));
    expect(assignedScaleClientId(0), isNull);
    expect(assignedScaleClientId(null), isNull);
  });
  test('setup forwards its assigned identity with its own credentials only',
      () {
    final result = validatedScaleSettings(
        {...settings(), 'account_token': 'do-not-forward'},
        registeredId: 4, deviceId: 'TestGas4');
    expect(result['mqtt_client_id'], assignedScaleClientId(4));
    expect(result['mqtt_pass'], 'test-only-secret');
    expect(result.containsKey('account_token'), isFalse);
    expect(() => result['mqtt_pass'] = 'changed', throwsUnsupportedError);
  });
  test(
      'missing identity, another device login and insecure connections stop setup',
      () {
    for (final entry in {
      'mqtt_client_id': '',
      'mqtt_user': 'TestGas1',
      'device_id': 'TestGas1',
      'topic': 'gas_cylinder/+/data',
      'mqtt_tls': false,
      'mqtt_port': 1883
    }.entries) {
      expect(
          () => validatedScaleSettings({...settings(), entry.key: entry.value},
              registeredId: 4, deviceId: 'TestGas4'),
          throwsFormatException);
    }
  });
  test('a stale or future reading cannot confirm a new setup', () {
    final start = DateTime.utc(2026, 11, 15, 12);
    expect(
        isReadingAfterSetup(
            start.subtract(const Duration(seconds: 1)), start, start),
        isFalse);
    expect(isReadingAfterSetup(start, start, start), isFalse);
    expect(
        isReadingAfterSetup(start.add(const Duration(seconds: 10)), start,
            start.add(const Duration(seconds: 12))),
        isTrue);
    expect(
        isReadingAfterSetup(start.add(const Duration(hours: 1)), start, start),
        isFalse);
    expect(isReadingAfterSetup(null, start, start), isFalse);
  });
}
