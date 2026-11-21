import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/Constants.dart';
import '../services/shared_preferences.dart';

class DeviceJournalException implements Exception {
  const DeviceJournalException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Requests are authenticated against the active session. No offline mutations
/// are queued: the server must confirm a refill or team action before success.
class DeviceJournalApi {
  DeviceJournalApi(
      {http.Client? client, Future<String?> Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? Sharedprefs.getAuthTokenPreference;
  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  Future<Map<String, dynamic>> request(String path,
      {String method = 'GET',
      Map<String, dynamic>? body,
      Map<String, String>? query}) async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const DeviceJournalException('Sign in again to view this history.');
    }
    final uri = Uri.parse('${Constants.articBaseUrl2}api/device-journal/$path')
        .replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Authorization': 'Token $token',
        'Content-Type': 'application/json'
      });
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 25));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeviceJournalException(decoded is Map
            ? (decoded['error'] ??
                    decoded['detail'] ??
                    'Unable to complete this request.')
                .toString()
            : 'Unable to complete this request.');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const DeviceJournalException(
            'The server returned an unreadable response.');
      }
      return decoded;
    } on DeviceJournalException {
      rethrow;
    } catch (_) {
      throw const DeviceJournalException(
          'Could not connect. Check your connection and retry.');
    }
  }

  void dispose() => _client.close();
}
