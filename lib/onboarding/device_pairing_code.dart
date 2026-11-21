import '../products/product_catalog.dart';

/// The versioned label contains identifiers only, never an API address, login
/// token or Wi-Fi password. Scanning cannot register a device by itself.
class DevicePairingCode {
  const DevicePairingCode({required this.deviceId, required this.deviceType});
  final String deviceId;
  final String deviceType;

  /// Supported label format:
  /// articsentinel://pair?v=1&type=gas_cylinder&id=1133
  /// https://articsentinel.com/pair?v=1&type=device7&id=D7-001
  static DevicePairingCode? parse(String raw) {
    if (raw.length > 512 || raw.trim() != raw) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment) {
      return null;
    }
    final trusted = (uri.scheme == 'articsentinel' &&
            uri.host == 'pair' &&
            uri.path.isEmpty) ||
        (uri.scheme == 'https' &&
            const {'articsentinel.com', 'uat.articsentinel.com'}
                .contains(uri.host) &&
            uri.path == '/pair');
    if (!trusted) return null;
    Map<String, List<String>> query;
    try {
      query = uri.queryParametersAll;
    } on FormatException {
      return null;
    }
    if (query.length != 3 ||
        !query.keys.every(const {'v', 'type', 'id'}.contains) ||
        query.values.any((values) => values.length != 1) ||
        query['v']?.single != '1') {
      return null;
    }
    final id = query['id']?.single ?? '';
    final type = query['type']?.single ?? '';
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$').hasMatch(id) ||
        ProductCatalog.byType(type) == null) {
      return null;
    }
    return DevicePairingCode(deviceId: id, deviceType: type);
  }
}
