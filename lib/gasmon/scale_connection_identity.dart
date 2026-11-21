import 'dart:convert';

/// Connection identifiers are public labels. Authentication uses the separate,
/// device-scoped password issued by the server, never a shared broker secret.
String? assignedScaleClientId(int? registeredId) {
  if (registeredId == null || registeredId <= 0) return null;
  final hex = registeredId.toRadixString(16).toUpperCase();
  if (hex.length > 20) return null;
  return 'AS_${hex.padLeft(20, '0')}';
}

Map<String, dynamic> validatedScaleSettings(Map<String, dynamic> settings,
    {required int registeredId, required String deviceId}) {
  const requiredKeys = [
    'device_id',
    'mqtt_host',
    'mqtt_client_id',
    'mqtt_user',
    'mqtt_pass',
    'topic'
  ];
  if (requiredKeys.any((key) =>
          settings[key] is! String || (settings[key] as String).isEmpty) ||
      settings['mqtt_client_id'] != assignedScaleClientId(registeredId) ||
      settings['device_id'] != deviceId ||
      settings['mqtt_user'] != deviceId ||
      settings['topic'] != 'gas_cylinder/$deviceId/data' ||
      settings['mqtt_port'] != 8883 ||
      settings['mqtt_tls'] != true) {
    throw const FormatException(
        'The server could not confirm this scale’s connection details. Try again before sending Wi-Fi settings.');
  }
  return Map.unmodifiable({
    for (final key in [...requiredKeys, 'mqtt_port', 'mqtt_tls'])
      key: settings[key]
  });
}

/// An old reading must not mark a new setup attempt as successful.
bool isReadingAfterSetup(
        DateTime? readingAt, DateTime? startedAt, DateTime now) =>
    readingAt != null &&
    startedAt != null &&
    readingAt.isAfter(startedAt) &&
    !readingAt.isAfter(now.add(const Duration(seconds: 30)));

/// Firmware can use JSON or a short text acknowledgement. A nullable "error"
/// property in a success response is not a rejection.
bool scaleSetupReplyRejected(String raw) {
  final text = raw.trim().toLowerCase();
  try {
    final value = jsonDecode(text);
    if (value is Map) {
      final error = value['error'];
      return value['success'] == false ||
          value['ok'] == false ||
          ['error', 'failed', 'failure', 'rejected']
              .contains(value['status']) ||
          (error != null && error != false && error != 0 && error != '');
    }
  } on FormatException {/* Plain text firmware response. */}
  return RegExp(r'\b(error|failed|failure|rejected|wrong|fail)\b')
      .hasMatch(text);
}
