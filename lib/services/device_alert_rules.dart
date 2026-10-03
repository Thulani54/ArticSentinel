import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import 'shared_preferences.dart';

class DeviceAlertRulesApi {
  static Future<Map<String, dynamic>> request(int deviceId,
      {Map<String, dynamic>? body}) async {
    final token = await Sharedprefs.getAuthTokenPreference();
    if (token == null) throw Exception('Sign in to configure your alerts.');
    final uri = Uri.parse(
        '${Constants.articBaseUrl2}api/push/devices/$deviceId/rules/');
    final headers = {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json'
    };
    final response = await (body == null
            ? http.get(uri, headers: headers)
            : http.put(uri, headers: headers, body: jsonEncode(body)))
        .timeout(const Duration(seconds: 20));
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not load alert settings. Please retry.');
    }
    if (response.statusCode != 200)
      throw Exception(data['error'] ?? 'Could not save alert settings.');
    return data;
  }
}
