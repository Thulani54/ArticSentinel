import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../models/device.dart';
import 'shared_preferences.dart';

/// A unit as needed for linking and picking: just enough to show and match.
class UnitSummary {
  const UnitSummary(
      {required this.id,
      required this.name,
      this.location,
      this.model,
      this.serial});
  final String id;
  final String name;
  final String? location;
  final String? model;
  final String? serial;

  factory UnitSummary.fromJson(Map<String, dynamic> j) => UnitSummary(
        id: '${j['id']}',
        name: '${j['name'] ?? 'Unit'}',
        location: (j['location'] as String?)?.trim().isEmpty == true
            ? null
            : j['location'] as String?,
        model: j['model_number'] as String?,
        serial: j['serial_number'] as String?,
      );
}

/// Linking devices and units (a device belongs to at most one unit).
/// Uses the same endpoints as Equipment and Units.
class UnitLinks {
  UnitLinks._();

  static Future<({int business, Map<String, String> headers})>
      _session() async {
    final business = await Sharedprefs.getBusinessUidSharedPreference() ??
        (Constants.myBusiness.businessUid == 0
            ? null
            : Constants.myBusiness.businessUid);
    if (business == null) throw 'Sign in again to continue.';
    final token = await Sharedprefs.getAuthTokenPreference();
    return (
      business: business,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      }
    );
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final s = await _session();
    final http.Response r;
    try {
      r = await http
          .post(Uri.parse('${Constants.articBaseUrl2}$path'),
              headers: s.headers,
              body: jsonEncode({'business_id': s.business, ...body}))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw 'Check your connection and try again.';
    }
    dynamic data;
    try {
      data = jsonDecode(r.body);
    } catch (_) {}
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final error = data is Map ? data['error']?.toString() : null;
      throw (error != null && error.length <= 160)
          ? error
          : 'The request could not be completed.';
    }
    return data;
  }

  static Future<List<Device>> devices() async {
    final data =
        await _post('api/devices/list/', {'include_unit_details': true});
    final rows = data is Map ? data['devices'] : data;
    if (rows is! List) throw 'Your devices could not be loaded.';
    return rows
        .map((r) => Device.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<List<UnitSummary>> units() async {
    final data = await _post('api/units/management/list/', {});
    final rows = data is Map ? data['units'] : data;
    if (rows is! List) throw 'Your units could not be loaded.';
    return rows
        .map((r) => UnitSummary.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Link [devicePk] to [unitId], or unlink it when [unitId] is null.
  static Future<void> setUnit(int devicePk, String? unitId) => _post(
      'api/devices/update/',
      {'device_id': devicePk, 'connected_unit_id': unitId});
}
