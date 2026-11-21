import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/Constants.dart';
import 'shared_preferences.dart';

/// A last-known snapshot is a read-only fallback, never a queued command.
class OfflineSnapshot {
  const OfflineSnapshot(this.savedAt);
  final DateTime savedAt;
}

class OfflineReadClient {
  OfflineReadClient(
      {http.Client? client,
      this.sessionScope,
      this.timeout = const Duration(seconds: 12)})
      : _client = client ?? http.Client();
  final http.Client _client;
  final Future<String?> Function()? sessionScope;
  final Duration timeout;
  final status = ValueNotifier<OfflineSnapshot?>(null);
  final Map<String, DateTime> _fallbacks = {};
  final Map<String, String> _fallbackPaths = {};
  int _viewEpoch = 0;
  bool _closed = false;
  static const _prefix = 'artic.reading.snapshot.v1.';
  static int _sessionEpoch = 0;

  static Future<void> clearAllSnapshots() async {
    _sessionEpoch++;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }

  Future<String?> _scope() async {
    if (sessionScope != null) return sessionScope!();
    if (await Sharedprefs.getUserLoggedInSharedPreference() != true)
      return null;
    final user = await Sharedprefs.getUserUidSharedPreference();
    final business = await Sharedprefs.getBusinessUidSharedPreference();
    if (user == null ||
        business == null ||
        user.toString() == '0' ||
        business.toString() == '0') return null;
    return '$user:$business';
  }

  bool _readOnly(String method, Uri uri) {
    final base = Uri.parse(Constants.articBaseUrl2);
    if (uri.origin != base.origin) return false;
    final path = uri.path;
    if (method == 'POST') {
      return path.endsWith('/api/gas/readings/') ||
          path.endsWith('/api/devices/list/') ||
          path.endsWith('/api/units/list/');
    }
    return method == 'GET' &&
        (path.contains('/get_devices_by_client/') ||
            path.contains('/latest-device-data/') ||
            path.endsWith('/dashboard-data/') ||
            path.endsWith('/api/device-metrics/') ||
            RegExp(r'/api/companies/\d+/devices/$').hasMatch(path) ||
            RegExp(r'/api/devices/[^/]+/$').hasMatch(path));
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      _read('GET', uri, headers: headers);
  Future<http.Response> post(Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      _read('POST', uri, headers: headers, body: body);

  void _publish(String key, DateTime? savedAt,
      {String? path, required int viewEpoch}) {
    if (_closed || viewEpoch != _viewEpoch) return;
    if (savedAt == null) {
      _fallbacks.remove(key);
      _fallbackPaths.remove(key);
    } else {
      _fallbacks[key] = savedAt;
      _fallbackPaths[key] = path ?? '';
    }
    final dates = _fallbacks.values.toList()..sort();
    status.value = dates.isEmpty ? null : OfflineSnapshot(dates.first);
  }

  /// Clear view status when switching accounts/devices, not stored snapshots.
  void resetStatus({bool preserveInventory = false}) {
    _viewEpoch++;
    bool inventory(String path) =>
        path.endsWith('/api/devices/list/') ||
        path.endsWith('/api/units/list/') ||
        path.contains('/get_devices_by_client/') ||
        RegExp(r'/api/companies/\d+/devices/$').hasMatch(path);
    final remove = _fallbacks.keys
        .where((key) =>
            !preserveInventory || !inventory(_fallbackPaths[key] ?? ''))
        .toList();
    for (final key in remove) {
      _fallbacks.remove(key);
      _fallbackPaths.remove(key);
    }
    final dates = _fallbacks.values.toList()..sort();
    if (!_closed)
      status.value = dates.isEmpty ? null : OfflineSnapshot(dates.first);
  }

  Future<http.Response> _read(String method, Uri uri,
      {Map<String, String>? headers, Object? body}) async {
    final epoch = _sessionEpoch;
    final viewEpoch = _viewEpoch;
    final scope = await _scope();
    final query = Map.fromEntries(uri.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
    final canonical =
        uri.replace(queryParameters: query.isEmpty ? null : query).toString();
    final key =
        '$_prefix${base64Url.encode(utf8.encode('$scope|$method|$canonical|${body ?? ''}'))}';
    final auth = await Sharedprefs.getAuthTokenPreference();
    final trusted = uri.origin == Uri.parse(Constants.articBaseUrl2).origin;
    final eligible = scope != null &&
        _readOnly(method, uri) &&
        (sessionScope != null || auth != null && auth.isNotEmpty);
    final requestHeaders = <String, String>{
      for (final entry in (headers ?? <String, String>{}).entries)
        if (!trusted || entry.key.toLowerCase() != 'authorization')
          entry.key: entry.value,
      if (trusted && auth != null && auth.isNotEmpty)
        'Authorization': 'Token $auth',
    };
    http.Response? response;
    Object? failure;
    try {
      response = await (method == 'POST'
              ? _client.post(uri, headers: requestHeaders, body: body)
              : _client.get(uri, headers: requestHeaders))
          .timeout(timeout);
    } catch (error) {
      failure = error;
    }
    if (epoch != _sessionEpoch ||
        scope != await _scope() ||
        trusted && auth != await Sharedprefs.getAuthTokenPreference()) {
      throw StateError('The signed-in account changed. Reload your readings.');
    }
    if (trusted &&
        response != null &&
        (response.statusCode == 401 || response.statusCode == 403)) {
      // Explicit access denial revokes prior snapshots across endpoints, also
      // preventing an already-running older request from saving them again.
      await clearAllSnapshots();
      resetStatus();
      return response;
    }
    if (!eligible) {
      if (response != null) return response;
      throw failure!;
    }
    final prefs = await SharedPreferences.getInstance();
    if (response != null && response.statusCode < 500) {
      _publish(key, null, viewEpoch: viewEpoch);
      if (response.statusCode == 404) {
        await prefs.remove(key); // Revoked access must never reveal a fallback.
      } else if (response.statusCode == 200 &&
          response.bodyBytes.length <= 1500000) {
        try {
          final data = jsonDecode(response.body);
          if ((data is List || data is Map) &&
              !(data is Map &&
                  (data['success'] == false || data.containsKey('error')))) {
            final savedAt = DateTime.now().toUtc();
            if (epoch != _sessionEpoch) throw StateError('Session changed');
            await prefs.setString(
                key,
                jsonEncode({
                  'saved_at': savedAt.toIso8601String(),
                  'body': response.body
                }));
            if (epoch != _sessionEpoch) await prefs.remove(key);
            final keys =
                prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
            keys.sort((a, b) {
              String stamp(String k) {
                try {
                  return (jsonDecode(prefs.getString(k)!) as Map)['saved_at']
                      as String;
                } catch (_) {
                  return '';
                }
              }

              return stamp(a).compareTo(stamp(b));
            });
            for (final old
                in keys.take((keys.length - 24).clamp(0, keys.length))) {
              await prefs.remove(old);
            }
          }
        } catch (_) {/* A disk or JSON error must not break a good response. */}
      }
      return response;
    }
    final saved = prefs.getString(key);
    if (saved != null) {
      try {
        final snapshot = jsonDecode(saved) as Map;
        final savedAt = DateTime.parse(snapshot['saved_at'] as String);
        final text = snapshot['body'] as String;
        jsonDecode(text);
        _publish(key, savedAt, path: uri.path, viewEpoch: viewEpoch);
        return http.Response(text, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
          'x-artic-snapshot-at': savedAt.toIso8601String(),
        });
      } catch (_) {
        await prefs.remove(key);
      }
    }
    if (response != null) return response;
    throw failure!;
  }

  void close() {
    _closed = true;
    _client.close();
    status.dispose();
  }
}
