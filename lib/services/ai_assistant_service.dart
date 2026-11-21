import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/Constants.dart';

class AIChatResponse {
  final String sessionId;
  final String answer;
  final Map<String, dynamic> snapshot;
  final List<String> suggestedFollowups;
  final List<Map<String, dynamic>> toolCalls;

  AIChatResponse({
    required this.sessionId,
    required this.answer,
    required this.snapshot,
    required this.suggestedFollowups,
    required this.toolCalls,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) => AIChatResponse(
        sessionId: json['session_id'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        snapshot: (json['snapshot'] as Map?)?.cast<String, dynamic>() ?? const {},
        suggestedFollowups: ((json['suggested_followups'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        toolCalls: ((json['tool_calls'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
      );
}

/// Error whose [message] is safe to show to the user as-is.
class AIAssistantException implements Exception {
  final String message;
  const AIAssistantException(this.message);

  @override
  String toString() => message;
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
    final http.Response response;
    try {
      response = await http
          .post(
            _uri('api/ai/chat/'),
            headers: _headers(),
            body: jsonEncode({
              'business_id': businessId,
              'device_id': deviceId,
              'message': message,
              'history': history,
              if (sessionId != null) 'session_id': sessionId,
            }),
          )
          // The server may run several tool rounds against the model.
          .timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw const AIAssistantException(
          'The assistant is taking too long to respond. Please try again.');
    } on SocketException {
      throw const AIAssistantException(
          'No connection. Check your internet and try again.');
    } on http.ClientException {
      throw const AIAssistantException(
          'No connection. Check your internet and try again.');
    }
    if (response.statusCode >= 500) {
      throw AIAssistantException(_extractError(response,
          fallback: 'The assistant is unavailable right now. Please try again in a moment.'));
    }
    if (response.statusCode != 200) {
      throw AIAssistantException(_extractError(response));
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AIChatResponse.fromJson(body);
    } on FormatException {
      throw const AIAssistantException(
          'The assistant sent an unexpected reply. Please try again.');
    }
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

  static String _extractError(http.Response response, {String? fallback}) {
    try {
      final body = jsonDecode(response.body);
      final error = body is Map ? body['error']?.toString() : null;
      // Older servers sent raw tracebacks; only pass through short messages.
      if (error != null && error.isNotEmpty && error.length <= 160) return error;
    } catch (_) {}
    return fallback ?? 'Request failed (${response.statusCode})';
  }
}
