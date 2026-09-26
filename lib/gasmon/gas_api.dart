/// Client for the gas-cylinder endpoints (api/gas/*): the device's Cylinder
/// setup and the scale readings ingested over MQTT. Produces the same
/// [GasDeviceData] the dashboard renders, so live and demo data are
/// interchangeable.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../services/shared_preferences.dart';
import 'gas_core.dart';
import 'gas_demo_data.dart';

/// A device's Cylinder setup, as stored by api/gas/config/.
class GasConfig {
  const GasConfig({
    required this.gasCapacityKg,
    required this.tareKg,
    required this.pricePerKg,
    required this.lowPct,
    required this.warningPct,
    required this.isDefault,
    this.updatedAt,
  });

  factory GasConfig.fromJson(Map<String, dynamic> j) => GasConfig(
        gasCapacityKg: (j['gas_capacity_kg'] as num).toDouble(),
        tareKg: (j['tare_kg'] as num).toDouble(),
        pricePerKg: (j['price_per_kg'] as num).toDouble(),
        lowPct: (j['low_threshold_pct'] as num).toDouble(),
        warningPct: (j['warning_threshold_pct'] as num).toDouble(),
        isDefault: j['is_default'] == true,
        updatedAt: j['updated_at'] as String?,
      );

  final double gasCapacityKg;
  final double tareKg;
  final double pricePerKg;
  final double lowPct;
  final double warningPct;

  /// True until the setup has been saved for this device.
  final bool isDefault;
  final String? updatedAt;

  GasSpec get spec => GasSpec(
        gasKg: gasCapacityKg.round(),
        tareKg: tareKg,
        fullKg: tareKg + gasCapacityKg,
      );

  Map<String, dynamic> toJson() => {
        'gas_capacity_kg': gasCapacityKg,
        'tare_kg': tareKg,
        'price_per_kg': pricePerKg,
        'low_threshold_pct': lowPct,
        'warning_threshold_pct': warningPct,
      };
}

class GasApiException implements Exception {
  GasApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GasApi {
  static const int historyDays = 90;

  static Future<Map<String, String>> _headers() async {
    final token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final businessId = await Sharedprefs.getBusinessUidSharedPreference();
    final response = await http.post(
      Uri.parse('${Constants.articBaseUrl2}api/gas/$path'),
      headers: await _headers(),
      body: jsonEncode({'business_id': businessId, ...body}),
    );
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw GasApiException(_describeError(decoded, response.statusCode));
    }
    return decoded as Map<String, dynamic>;
  }

  /// Flattens DRF-style errors ({"error": {"field": ["msg"]}}) to one line.
  static String _describeError(dynamic body, int status) {
    final err = body is Map ? body['error'] ?? body['detail'] : null;
    if (err is String) return err;
    if (err is Map) {
      return err.values
          .map((v) => v is List ? v.join(' ') : v.toString())
          .join(' ');
    }
    return 'Request failed ($status)';
  }

  /// Live data when the scale has reported, otherwise demo data reshaped to
  /// the saved setup. Also returns the setup itself.
  static Future<({GasDeviceData data, GasConfig config})> load({
    required int deviceId,
    required String demoKey,
  }) async {
    final resp = await _post('readings/', {
      'device_id': deviceId,
      'days': historyDays,
    });
    final config = GasConfig.fromJson(resp['config'] as Map<String, dynamic>);
    final rows = (resp['readings'] as List).cast<Map<String, dynamic>>();
    final latest = resp['latest'] as Map<String, dynamic>?;

    if (rows.isEmpty && latest == null) {
      return (data: demoForConfig(demoKey, config), config: config);
    }

    final spec = config.spec;
    // Readings are normalised onto the current tare via the stored net
    // weight, so a cylinder swapped for a different model still reads right.
    GasReading toReading(Map<String, dynamic> r) => GasReading(
          at: DateTime.parse(r['time'] as String).toLocal(),
          weightKg: (r['net_kg'] as num).toDouble() + spec.tareKg,
        );
    final readings = rows.map(toReading).toList();
    if (latest != null) {
      final l = toReading(latest);
      if (readings.isEmpty || l.at.isAfter(readings.last.at)) {
        readings.add(l);
      }
    }

    return (
      data: GasDeviceData(
        spec: spec,
        readings: readings,
        alerts: deriveGasAlerts(readings,
            spec: spec, lowPct: config.lowPct, warningPct: config.warningPct),
        pricePerKg: config.pricePerKg,
        live: true,
        scaleGrossKg: (latest?['gross_kg'] as num?)?.toDouble(),
        batteryPct: (latest?['battery_pct'] as num?)?.toDouble(),
        lowPct: config.lowPct,
        warningPct: config.warningPct,
      ),
      config: config,
    );
  }

  /// Demo series re-expressed on the saved cylinder, so demo readouts match
  /// the setup: each reading keeps its fill fraction, scaled to the new
  /// capacity and shifted onto the new tare.
  static GasDeviceData demoForConfig(String demoKey, GasConfig? config) {
    final demo = generateGasDemoData(deviceKey: demoKey);
    if (config == null || config.isDefault) return demo;
    final spec = config.spec;
    final readings = demo.readings
        .map((r) => GasReading(
              at: r.at,
              weightKg: spec.tareKg +
                  netGasKg(currentKg: r.weightKg, tareKg: demo.spec.tareKg) /
                      demo.spec.capacityKg *
                      spec.capacityKg,
            ))
        .toList();
    return GasDeviceData(
      spec: spec,
      readings: readings,
      alerts: deriveGasAlerts(readings,
          spec: spec, lowPct: config.lowPct, warningPct: config.warningPct),
      pricePerKg: config.pricePerKg,
      lowPct: config.lowPct,
      warningPct: config.warningPct,
    );
  }

  static Future<GasConfig> saveConfig({
    required int deviceId,
    required GasConfig config,
  }) async {
    final resp = await _post('config/update/', {
      'device_id': deviceId,
      ...config.toJson(),
    });
    return GasConfig.fromJson(resp['config'] as Map<String, dynamic>);
  }
}
