import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';

class AIChatResponse {
  final String sessionId;
  final String answer;
  final Map<String, dynamic> snapshot;

  AIChatResponse({
    required this.sessionId,
    required this.answer,
    required this.snapshot,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) => AIChatResponse(
        sessionId: json['session_id'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        snapshot: (json['snapshot'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class AIAlertSettings {
  final bool enabled;
  final bool compressorHealth;
  final bool leakDetection;
  final bool smartDefrost;
  final String minSeverity;

  AIAlertSettings({
    required this.enabled,
    required this.compressorHealth,
    required this.leakDetection,
    required this.smartDefrost,
    required this.minSeverity,
  });

  factory AIAlertSettings.fromJson(Map<String, dynamic> json) => AIAlertSettings(
        enabled: json['enabled'] as bool? ?? false,
        compressorHealth: json['enable_compressor_health'] as bool? ?? true,
        leakDetection: json['enable_leak_detection'] as bool? ?? true,
        smartDefrost: json['enable_smart_defrost'] as bool? ?? true,
        minSeverity: json['min_severity_to_alert'] as String? ?? 'medium',
      );

  Map<String, dynamic> toUpdatePayload() => {
        'enabled': enabled,
        'enable_compressor_health': compressorHealth,
        'enable_leak_detection': leakDetection,
        'enable_smart_defrost': smartDefrost,
        'min_severity_to_alert': minSeverity,
      };
}

class AIAssistantService {
  static Uri _uri(String path) => Uri.parse('${Constants.articBaseUrl2}$path');

  static Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (Constants.authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${Constants.authToken}';
    }
    return headers;
  }

  static Future<AIChatResponse> sendMessage({
    required int businessId,
    required String deviceId,
    required String message,
    required List<Map<String, String>> history,
    String? sessionId,
  }) async {
    final response = await http.post(
      _uri('api/ai/chat/'),
      headers: _headers(),
      body: jsonEncode({
        'business_id': businessId,
        'device_id': deviceId,
        'message': message,
        'history': history,
        if (sessionId != null) 'session_id': sessionId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AIChatResponse.fromJson(body);
  }

  static Future<AIAlertSettings> getSettings(int businessId) async {
    final response = await http.post(
      _uri('api/ai/settings/get/'),
      headers: _headers(),
      body: jsonEncode({'business_id': businessId}),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
    return AIAlertSettings.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<AIAlertSettings> updateSettings({
    required int businessId,
    required AIAlertSettings settings,
  }) async {
    final payload = settings.toUpdatePayload()..['business_id'] = businessId;
    final response = await http.post(
      _uri('api/ai/settings/update/'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
    return AIAlertSettings.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) return body['error'].toString();
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}
