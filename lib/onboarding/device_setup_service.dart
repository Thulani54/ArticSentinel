import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../gasmon/gas_api.dart';
import '../models/device.dart';
import '../services/shared_preferences.dart';

class DeviceSetupException implements Exception {
  const DeviceSetupException(this.message, {this.canEdit = false});
  final String message;
  final bool canEdit;
  @override
  String toString() => message;
}

class DeviceSetupResult {
  const DeviceSetupResult(this.device,
      {this.alreadyRegistered = false, this.gasConfig});
  final Device device;
  final bool alreadyRegistered;
  final GasConfig? gasConfig;
}

/// Authenticated setup uses the same device and cylinder endpoints as Equipment.
/// Keep one instance for the wizard so a failed second step never creates again.
class DeviceSetupService {
  DeviceSetupService(
      {http.Client? client, this.requestTimeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;
  final Map<String, Device> _created = {};
  final Set<String> _uncertainCreates = {};

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Future<({int business, Map<String, String> headers})> _session() async {
    final business = await Sharedprefs.getBusinessUidSharedPreference();
    final token = await Sharedprefs.getAuthTokenPreference();
    if (business == null || token == null || token.isEmpty) {
      throw const DeviceSetupException(
          'Sign in again before connecting a device.',
          canEdit: true);
    }
    return (
      business: business,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      }
    );
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const DeviceSetupException(
          'The server response could not be read. Your entries are kept; try again.');
    }
  }

  String _error(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Your account cannot connect this device. Sign in again or contact your administrator.';
    }
    if (response.statusCode == 400 || response.statusCode == 409) {
      return 'This device could not be linked. Check the ID on its label. If it belongs to another account, ask its owner to release it.';
    }
    return 'The device service is unavailable. Your entries are kept; try again.';
  }

  Future<List<Device>> _devices(
      int business, Map<String, String> headers) async {
    final response = await _client
        .post(
          Uri.parse('${Constants.articBaseUrl2}api/devices/list/'),
          headers: headers,
          body: jsonEncode({'business_id': business}),
        )
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw DeviceSetupException(_error(response));
    }
    final body = _decode(response);
    final rows = body is Map ? body['devices'] : body;
    if (rows is! List) {
      throw const DeviceSetupException(
          'Your device list could not be checked. Try again before adding the device.');
    }
    return rows
        .map((row) => Device.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<DeviceSetupResult> register(
      {required Device draft, GasConfig? gasConfig}) async {
    final session = await _session();
    final key = '${session.business}:${draft.deviceId.trim().toLowerCase()}';
    try {
      GasConfig? savedConfig;
      var created = _created[key];
      if (created == null) {
        // Reconcile before every create, including after a lost HTTP response.
        final existing = (await _devices(session.business, session.headers))
            .where((device) =>
                device.deviceId.trim().toLowerCase() ==
                draft.deviceId.trim().toLowerCase())
            .firstOrNull;
        if (existing != null) {
          if (existing.deviceType != draft.deviceType) {
            throw const DeviceSetupException(
                'This ID is already registered as another device type. Check it in Equipment.',
                canEdit: true);
          }
          if (!_uncertainCreates.contains(key)) {
            return DeviceSetupResult(existing, alreadyRegistered: true);
          }
          created = existing;
          _created[key] = existing;
        } else {
          _uncertainCreates.add(key);
          final response = await _client
              .post(
                Uri.parse('${Constants.articBaseUrl2}api/devices/create/'),
                headers: session.headers,
                body: jsonEncode({
                  'business_id': session.business,
                  'name': draft.name.trim(),
                  'device_id': draft.deviceId.trim(),
                  'device_type': draft.deviceType,
                  'is_active': true,
                  if (draft.location?.trim().isNotEmpty == true)
                    'location': draft.location!.trim(),
                }),
              )
              .timeout(requestTimeout);
          if (response.statusCode != 201 && response.statusCode != 200) {
            final rejected =
                response.statusCode >= 400 && response.statusCode < 500;
            if (rejected) _uncertainCreates.remove(key);
            throw DeviceSetupException(_error(response), canEdit: rejected);
          }
          final body = _decode(response);
          created = Device.fromJson(
              Map<String, dynamic>.from(body['device'] ?? body));
          if (created.id == null) {
            throw const DeviceSetupException(
                'The device was saved but its confirmation is incomplete. Retry to check your device list.');
          }
          _created[key] = created;
        }
      }
      if (draft.deviceType == 'gas_cylinder' && gasConfig != null) {
        // Recovered or resumed devices may already have a custom setup. Never
        // replace that setup, even when the create response was interrupted.
        final readingResponse = await _client
            .post(
              Uri.parse('${Constants.articBaseUrl2}api/gas/readings/'),
              headers: session.headers,
              body: jsonEncode({
                'business_id': session.business,
                'device_id': created.id,
                'days': 1
              }),
            )
            .timeout(requestTimeout);
        if (readingResponse.statusCode != 200) {
          throw const DeviceSetupException(
              'Your scale is registered. Cylinder setup could not be checked; retry to finish without adding it again.');
        }
        final readingBody = _decode(readingResponse);
        final config = readingBody is Map ? readingBody['config'] : null;
        if (config is! Map || config['is_default'] is! bool) {
          throw const DeviceSetupException(
              'Your scale is registered. Its cylinder setup could not be confirmed; retry to finish.');
        }
        savedConfig = _readConfig(config);
        if (config['is_default'] == true) {
          final response = await _client
              .post(
                Uri.parse('${Constants.articBaseUrl2}api/gas/config/update/'),
                headers: session.headers,
                body: jsonEncode({
                  'business_id': session.business,
                  'device_id': created.id,
                  ...gasConfig.toJson()
                }),
              )
              .timeout(requestTimeout);
          if (response.statusCode != 200) {
            throw const DeviceSetupException(
                'Your scale is registered. Cylinder setup was not saved; retry to finish without adding it again.');
          }
          final savedBody = _decode(response);
          savedConfig =
              _readConfig(savedBody is Map ? savedBody['config'] : null);
          if (savedConfig.isDefault) {
            throw const DeviceSetupException(
                'Your cylinder setup is not confirmed yet. Retry to finish.');
          }
        }
      }
      _uncertainCreates.remove(key);
      return DeviceSetupResult(created, gasConfig: savedConfig);
    } on TimeoutException {
      throw const DeviceSetupException(
          'The connection timed out. Your entries are kept. Retry checks for a saved device before adding anything.');
    } on http.ClientException {
      throw const DeviceSetupException(
          'Check your internet connection and retry. Your entries are kept.');
    }
  }

  GasConfig _readConfig(dynamic value) {
    try {
      if (value is! Map || value['is_default'] is! bool) {
        throw const FormatException();
      }
      return GasConfig.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      throw const DeviceSetupException(
          'Your scale is registered. Its cylinder setup confirmation could not be read; retry to check the saved values.');
    }
  }

  bool _recent(dynamic value) {
    final at = DateTime.tryParse(value?.toString() ?? '');
    if (at == null) return false;
    final age = DateTime.now().toUtc().difference(at.toUtc());
    return age >= const Duration(minutes: -2) &&
        age <= const Duration(minutes: 15);
  }

  /// Online status alone is not proof that a fresh measurement has arrived.
  Future<bool> hasReading(Device device) async {
    final session = await _session();
    try {
      if (device.deviceType == 'gas_cylinder') {
        final response = await _client
            .post(
              Uri.parse('${Constants.articBaseUrl2}api/gas/readings/'),
              headers: session.headers,
              body: jsonEncode({
                'business_id': session.business,
                'device_id': device.id,
                'days': 1
              }),
            )
            .timeout(requestTimeout);
        if (response.statusCode != 200) {
          throw DeviceSetupException(_error(response));
        }
        final body = _decode(response);
        final latest = body is Map ? body['latest'] : null;
        return latest is Map &&
            _recent(latest['time']) &&
            latest['gross_kg'] is num;
      }
      final response = await _client
          .get(
            Uri.parse(
                '${Constants.articBaseUrl2}latest-device-data/${session.business}/'),
            headers: session.headers,
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw DeviceSetupException(_error(response));
      }
      final rows = _decode(response);
      if (rows is! List) {
        throw const DeviceSetupException(
            'Readings could not be checked. Try again.');
      }
      final metricKeys = switch (device.deviceType) {
        'device1' => [
            'temperatureAir',
            'temperatureCoil',
            'temperatureDrain',
            'compressorLow',
            'compressorHigh',
            'compAmpPh1',
            'door'
          ],
        'device2' => [for (var i = 1; i <= 8; i++) 'temp$i'],
        'device3' => [
            'hs_temp',
            'ls_temp',
            'ice_temp',
            'air_temp',
            'wtrlvl',
            'harvsw'
          ],
        'device4' => [
            for (var i = 1; i <= 8; i++)
              for (var p = 1; p <= 3; p++) '${i}comph$p'
          ],
        'device5' => [for (var i = 1; i <= 16; i++) 'relay$i'],
        'device6' => [for (var i = 1; i <= 8; i++) 'prs$i'],
        'device7' => [
            'codeScan',
            'code_scan',
            'bottleTemp',
            'bottle_temp',
            for (var i = 1; i <= 4; i++) 'tray${i}wt'
          ],
        _ => <String>[],
      };
      return rows.whereType<Map>().any((row) =>
          row['device_id']?.toString().toLowerCase() ==
              device.deviceId.toLowerCase() &&
          _recent(row['time'] ?? row['timestamp']) &&
          metricKeys.any((key) {
            final value = row[key];
            return value is num ||
                value is bool ||
                (value is String && value.trim().isNotEmpty);
          }));
    } on TimeoutException {
      throw const DeviceSetupException(
          'The readings check timed out. Your device stays registered; try again.');
    } on http.ClientException {
      throw const DeviceSetupException(
          'Your device is registered. Check your internet connection and retry the readings check.');
    }
  }
}
