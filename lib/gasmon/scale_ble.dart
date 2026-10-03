/// Wi-Fi setup for gas scales over Bluetooth, using ESP-IDF unified
/// provisioning (protocomm, security 1: Curve25519 + AES-CTR with an optional
/// proof-of-possession code) via esp_provisioning_ble.
///
/// The transport resolves endpoints the way Espressif's own apps do: by the
/// name each characteristic carries in its user-description descriptor
/// (0x2901, e.g. "prov-session"), falling back to the default UUID layout.
/// That keeps working when the firmware uses its own service UUID or
/// registers extra endpoints.
///
/// Scales with their own Bluetooth setup instead (e.g. "ESP_Config") get a
/// direct mode, like writing in LightBlue: the app lists the GATT table,
/// writes the Wi-Fi details to a writable characteristic and shows whatever
/// the scale notifies back.
library;

import 'dart:async';
import 'dart:convert';

import 'package:esp_provisioning_ble/esp_provisioning_ble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Default service UUID used by ESP-IDF / Arduino WiFiProv examples.
const String kProvServiceUuid = '021a9004-0382-4aea-bff4-6b3f1c5adfb4';

/// Default endpoint -> 16-bit id layout within [kProvServiceUuid].
const Map<String, String> kDefaultEndpoints = {
  'prov-scan': 'ff50',
  'prov-session': 'ff51',
  'prov-config': 'ff52',
  'proto-ver': 'ff53',
  'custom-data': 'ff54',
};

/// True when a scan result looks like a scale waiting for Wi-Fi setup:
/// advertising the provisioning service, or named like one (PROV_xxxx,
/// GasMonitor, ESP_Config, …).
bool looksLikeProvisioningScale(ScanResult r) {
  final name = r.advertisementData.advName.isNotEmpty
      ? r.advertisementData.advName
      : r.device.platformName;
  final upper = name.toUpperCase();
  final advertisesService = r.advertisementData.serviceUuids
      .any((g) => g.str128.toLowerCase() == kProvServiceUuid);
  return advertisesService ||
      upper.startsWith('PROV_') ||
      upper.contains('GAS') ||
      upper.contains('SCALE') ||
      upper.contains('ESP') ||
      upper.contains('CONFIG');
}

class ScaleTransport implements ProvTransport {
  ScaleTransport(this.device);

  final BluetoothDevice device;
  final Map<String, BluetoothCharacteristic> _endpoints = {};

  /// Everything discovered on the scale, and each characteristic's
  /// user-description name where it has one (keyed by service/char UUID).
  List<BluetoothService> services = [];
  final Map<String, String> charNames = {};

  /// Endpoint names the scale exposes (e.g. prov-session, custom-data).
  Set<String> get endpoints => _endpoints.keys.toSet();

  /// True when the scale speaks ESP-IDF unified provisioning.
  bool get isStandardProvisioning => _endpoints.containsKey('prov-session');

  static final _userDescription = Guid('2901');

  @override
  Future<bool> connect() async {
    await disconnect();
    try {
      // mtu: 512 is requested on Android; iOS negotiates on its own.
      await device.connect(timeout: const Duration(seconds: 20));
    } catch (e) {
      debugPrint('[scale] connect failed: $e');
      return false;
    }
    try {
      services = await device.discoverServices();
      await _resolveEndpoints(services);
    } catch (e) {
      debugPrint('[scale] service discovery failed: $e');
      return false;
    }
    return device.isConnected;
  }

  Future<void> _resolveEndpoints(List<BluetoothService> services) async {
    _endpoints.clear();

    // 1. By name, from each characteristic's user-description descriptor.
    for (final service in services) {
      for (final c in service.characteristics) {
        for (final d in c.descriptors) {
          if (d.uuid.str128 != _userDescription.str128) continue;
          try {
            final name = utf8
                .decode(await d.read(), allowMalformed: true)
                .replaceAll('\u0000', '')
                .trim();
            if (name.isNotEmpty) {
              _endpoints[name] = c;
              charNames['${c.serviceUuid.str128}/${c.uuid.str128}'] = name;
            }
          } catch (e) {
            debugPrint('[scale] could not read descriptor: $e');
          }
        }
      }
    }
    if (_endpoints.containsKey('prov-session')) return;

    // 2. Fallback: the default UUID layout under the default service.
    final byUuid = {
      for (final e in kDefaultEndpoints.entries)
        '${kProvServiceUuid.substring(0, 4)}${e.value}${kProvServiceUuid.substring(8)}':
            e.key,
    };
    for (final service in services) {
      for (final c in service.characteristics) {
        final name = byUuid[c.uuid.str128.toLowerCase()];
        if (name != null) _endpoints[name] = c;
      }
    }
  }

  @override
  Future<Uint8List> sendReceive(String epName, Uint8List data) async {
    final c = _endpoints[epName];
    if (c == null) {
      throw StateError('The scale has no "$epName" endpoint');
    }
    if (data.isNotEmpty) {
      await c.write(data.toList(), withoutResponse: false);
    }
    return Uint8List.fromList(await c.read());
  }

  @override
  Future<bool> disconnect() async {
    if (!device.isConnected) return true;
    try {
      await device.disconnect();
      return true;
    } catch (e) {
      debugPrint('[scale] disconnect failed: $e');
      return false;
    }
  }

  @override
  Future<bool> checkConnect() async => device.isConnected;
}

/// What the scale reports about itself on the unencrypted proto-ver endpoint,
/// e.g. {"prov":{"ver":"v1.1","sec_ver":1,"cap":["wifi_scan"]}}.
class ScaleProtocol {
  const ScaleProtocol(
      {this.version, this.securityVersion, this.capabilities = const []});

  final String? version;
  final int? securityVersion;
  final List<String> capabilities;

  bool get canScanWifi => capabilities.contains('wifi_scan');
  bool get needsNoPop => capabilities.contains('no_pop');
}

enum ScaleSetupStage {
  idle,
  connecting,
  securing,
  ready, // secure session open; Wi-Fi can be scanned/sent
  scanningWifi,
  sending,
  waitingForWifi,
  connected, // scale joined Wi-Fi
  failed,
  direct, // connected to a scale with its own (non-standard) Bluetooth setup
}

/// How the Wi-Fi details are written in direct mode.
enum DirectFormat {
  json('JSON  {"ssid":…,"password":…}'),
  comma('ssid,password'),
  lines('ssid and password on separate lines');

  const DirectFormat(this.label);
  final String label;

  /// [bssid] and [extra] (e.g. the server login) are only carried by the
  /// JSON format.
  List<int> encode(String ssid, String password,
          {String? bssid, Map<String, dynamic>? extra}) =>
      utf8.encode(switch (this) {
        DirectFormat.json => jsonEncode({
            'ssid': ssid,
            'password': password,
            if (bssid != null) 'bssid': bssid,
            ...?extra,
          }),
        DirectFormat.comma => '$ssid,$password',
        DirectFormat.lines => '$ssid\n$password',
      });
}

/// One characteristic in the scale's GATT table, as LightBlue would list it.
class GattEntry {
  GattEntry({required this.characteristic, this.name, this.value});

  final BluetoothCharacteristic characteristic;
  final String? name; // from the 0x2901 user description, if any
  final String? value; // current value, if readable

  String get serviceUuid => characteristic.serviceUuid.str128;
  String get uuid => characteristic.uuid.str128;
  CharacteristicProperties get props => characteristic.properties;
  bool get writable => props.write || props.writeWithoutResponse;
  bool get notifies => props.notify || props.indicate;

  String get label => name?.isNotEmpty == true
      ? '$name (${characteristic.uuid.str})'
      : characteristic.uuid.str;

  String get propsText => [
        if (props.read) 'read',
        if (props.write) 'write',
        if (props.writeWithoutResponse) 'write-no-response',
        if (props.notify) 'notify',
        if (props.indicate) 'indicate',
      ].join(', ');
}

/// A BSSID (access point MAC) like aa:bb:cc:dd:ee:ff.
final RegExp kBssidPattern = RegExp(r'^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$');

/// Standard Bluetooth services that never carry Wi-Fi setup.
const _genericServices = {'1800', '1801', '180a', '180f'};

/// Drives one scale through connect -> secure session -> Wi-Fi -> status.
class ScaleProvisioning extends ChangeNotifier {
  ScaleTransport? _transport;
  EspProv? _prov;
  Timer? _statusTimer;
  int _statusPolls = 0;

  ScaleSetupStage stage = ScaleSetupStage.idle;
  String? error;
  ScaleProtocol protocol = const ScaleProtocol();
  List<WifiAP> networks = [];
  String? scaleIp;
  String? customDataReply;

  // Direct mode (non-standard scales)
  List<GattEntry> gatt = [];
  GattEntry? writeTarget;
  final List<String> directReplies = [];
  final List<StreamSubscription<List<int>>> _notifySubs = [];

  bool get hasCustomData =>
      _transport?.endpoints.contains('custom-data') ?? false;

  void _set(ScaleSetupStage s, {String? err}) {
    stage = s;
    error = err;
    notifyListeners();
  }

  /// Connects and opens the encrypted session. [pop] is the scale's
  /// proof-of-possession code; leave empty for scales set up without one.
  Future<void> connect(BluetoothDevice device, String pop) async {
    await disconnect(notify: false);
    _set(ScaleSetupStage.connecting);

    final transport = ScaleTransport(device);
    if (!await transport.connect()) {
      _set(ScaleSetupStage.failed,
          err: device.isConnected
              ? "This device doesn't offer Wi-Fi setup. Make sure the scale is in setup mode."
              : "Couldn't connect. Move closer to the scale and try again.");
      await transport.disconnect();
      return;
    }
    _transport = transport;

    if (!transport.isStandardProvisioning) {
      await _enterDirectMode(transport);
      return;
    }

    protocol = await _readProtocol(transport);
    final sec = protocol.securityVersion;
    if (sec != null && sec != 1) {
      _set(ScaleSetupStage.failed,
          err:
              'The scale uses security version $sec; this app supports version 1. '
              'Ask the firmware developer to build it with security 1.');
      await transport.disconnect();
      return;
    }

    _set(ScaleSetupStage.securing);
    final trimmed = pop.trim();
    _prov = EspProv(
      transport: transport,
      security: Security1(pop: trimmed.isEmpty ? null : trimmed),
    );
    final status = await _prov!.establishSession();
    switch (status) {
      case EstablishSessionStatus.connected:
        _set(ScaleSetupStage.ready);
      case EstablishSessionStatus.keymismatch:
        _set(ScaleSetupStage.failed,
            err:
                'Wrong setup code (PoP). Check the code on the scale label and try again.');
        await transport.disconnect();
      case EstablishSessionStatus.disconnected:
        _set(ScaleSetupStage.failed,
            err:
                'The scale disconnected while securing the connection. Try again.');
    }
  }

  /// Lists the scale's GATT table and picks the characteristic to write the
  /// Wi-Fi details to, preferring one whose name or UUID mentions Wi-Fi.
  Future<void> _enterDirectMode(ScaleTransport t) async {
    final entries = <GattEntry>[];
    for (final service in t.services) {
      if (_genericServices.contains(service.uuid.str.toLowerCase())) continue;
      for (final c in service.characteristics) {
        String? value;
        if (c.properties.read) {
          try {
            final raw = await c.read();
            value = raw.isEmpty ? '' : utf8.decode(raw, allowMalformed: true);
          } catch (_) {}
        }
        entries.add(GattEntry(
          characteristic: c,
          name: t.charNames['${c.serviceUuid.str128}/${c.uuid.str128}'],
          value: value,
        ));
      }
    }
    gatt = entries;
    final writable = entries.where((e) => e.writable).toList();
    int score(GattEntry e) {
      final text = '${e.name ?? ''} ${e.uuid} ${e.value ?? ''}'.toLowerCase();
      return ['wifi', 'ssid', 'cred', 'config', 'prov']
          .where(text.contains)
          .length;
    }

    writable.sort((a, b) => score(b).compareTo(score(a)));
    writeTarget = writable.isNotEmpty ? writable.first : null;
    if (writeTarget == null) {
      _set(ScaleSetupStage.failed,
          err:
              'The scale connected but has no characteristic that accepts writes, so it '
              "can't take Wi-Fi details over Bluetooth. Check that it's in setup mode.");
      return;
    }
    _set(ScaleSetupStage.direct);
  }

  void chooseWriteTarget(GattEntry e) {
    writeTarget = e;
    notifyListeners();
  }

  /// Direct mode: subscribes to the scale's notify characteristics, writes
  /// the Wi-Fi details in [format], then waits briefly for a reply.
  Future<void> sendDirect({
    required String ssid,
    required String password,
    required DirectFormat format,
    String? bssid,
    Map<String, dynamic>? scaleSettings,
  }) async {
    final target = writeTarget;
    if (target == null) return;
    _set(ScaleSetupStage.sending);
    directReplies.clear();
    for (final subscription in _notifySubs) {
      await subscription.cancel();
    }
    _notifySubs.clear();
    try {
      for (final e in gatt.where((e) => e.notifies)) {
        try {
          await e.characteristic.setNotifyValue(true);
          _notifySubs.add(e.characteristic.onValueReceived.listen((v) {
            final text = utf8.decode(v, allowMalformed: true).trim();
            if (text.isEmpty) return;
            directReplies.add(text);
            final ip =
                RegExp(r'\b(\d{1,3}(?:\.\d{1,3}){3})\b').firstMatch(text);
            if (ip != null) scaleIp = ip.group(1);
            notifyListeners();
          }));
        } catch (err) {
          debugPrint('[scale] notify on ${e.uuid} failed: $err');
        }
      }
      final bytes =
          format.encode(ssid, password, bssid: bssid, extra: scaleSettings);
      final p = target.props;
      await target.characteristic.write(
        bytes,
        withoutResponse: !p.write && p.writeWithoutResponse,
        allowLongWrite:
            p.write && bytes.length > (target.characteristic.device.mtuNow - 3),
      );
    } catch (e) {
      debugPrint('[scale] direct write failed: $e');
      _set(ScaleSetupStage.failed, err: scaleConnectionError(e));
      return;
    }

    // Give the scale a moment to answer; a reply mentioning failure stops here,
    // anything else hands over to the server check for the first reading.
    _set(ScaleSetupStage.waitingForWifi);
    for (var i = 0; i < 20 && scaleIp == null; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final last =
          directReplies.isEmpty ? '' : directReplies.last.toLowerCase();
      if (last.contains('fail') ||
          last.contains('error') ||
          last.contains('wrong')) {
        _set(ScaleSetupStage.failed,
            err: 'The scale replied: ${directReplies.last}');
        return;
      }
      if (last.contains('connected') ||
          last.contains('success') ||
          last == 'ok') break;
      if (!(await _transport?.checkConnect() ?? false))
        break; // scale rebooted onto Wi-Fi
    }
    _set(ScaleSetupStage.connected);
  }

  /// The GATT table as text, for sharing with the firmware developer.
  String gattReport(String deviceName) {
    final b = StringBuffer('Scale: $deviceName\n');
    String? service;
    for (final e in gatt) {
      if (e.serviceUuid != service) {
        service = e.serviceUuid;
        b.writeln('Service $service');
      }
      b.writeln(
          '  Char ${e.uuid}${e.name != null ? ' "${e.name}"' : ''} [${e.propsText}]'
          '${e.value != null ? ' value="${e.value}"' : ''}');
    }
    return b.toString();
  }

  Future<ScaleProtocol> _readProtocol(ScaleTransport t) async {
    if (!t.endpoints.contains('proto-ver')) return const ScaleProtocol();
    try {
      final raw = await t.sendReceive(
          'proto-ver', Uint8List.fromList(utf8.encode('---')));
      final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      final prov = (json['prov'] as Map?)?.cast<String, dynamic>() ?? {};
      return ScaleProtocol(
        version: prov['ver'] as String?,
        securityVersion: (prov['sec_ver'] as num?)?.toInt(),
        capabilities: ((prov['cap'] as List?) ?? []).cast<String>(),
      );
    } catch (e) {
      debugPrint('[scale] proto-ver unreadable: $e');
      return const ScaleProtocol();
    }
  }

  /// Asks the scale to scan for Wi-Fi networks (strongest first, one entry
  /// per network name).
  Future<void> scanWifi() async {
    if (_prov == null) return;
    _set(ScaleSetupStage.scanningWifi);
    try {
      final found = await _prov!.startScanWiFi();
      final bySsid = <String, WifiAP>{};
      for (final ap in found) {
        if (ap.ssid.isEmpty) continue;
        final seen = bySsid[ap.ssid];
        if (seen == null || ap.rssi > seen.rssi) bySsid[ap.ssid] = ap;
      }
      networks = bySsid.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      _set(ScaleSetupStage.ready);
    } catch (e) {
      debugPrint('[scale] wifi scan failed: $e');
      networks = [];
      _set(ScaleSetupStage.ready,
          err:
              "The scale couldn't list Wi-Fi networks — type the network name instead.");
    }
  }

  /// Sends optional app settings on custom-data, then the Wi-Fi credentials,
  /// and polls until the scale joins the network or gives up.
  Future<void> sendWifi({
    required String ssid,
    required String password,
    String? bssid,
    Map<String, dynamic>? scaleSettings,
  }) async {
    if (_prov == null) return;
    _set(ScaleSetupStage.sending);
    try {
      if (scaleSettings != null && hasCustomData) {
        final reply = await _prov!.sendReceiveCustomData(
            Uint8List.fromList(utf8.encode(jsonEncode(scaleSettings))));
        customDataReply = utf8.decode(reply, allowMalformed: true);
      }
      final accepted = await _prov!
          .sendWifiConfig(ssid: ssid, password: password, bssid: bssid);
      if (!accepted) {
        _set(ScaleSetupStage.failed,
            err: 'The scale rejected the Wi-Fi details.');
        return;
      }
      if (!await _prov!.applyWifiConfig()) {
        _set(ScaleSetupStage.failed,
            err: "The scale couldn't apply the Wi-Fi details.");
        return;
      }
    } catch (e) {
      debugPrint('[scale] send failed: $e');
      _set(ScaleSetupStage.failed,
          err: 'Lost the connection while sending the Wi-Fi details.');
      return;
    }
    _pollStatus();
  }

  void _pollStatus() {
    _set(ScaleSetupStage.waitingForWifi);
    _statusPolls = 0;
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (++_statusPolls > 45) {
        timer.cancel();
        _set(ScaleSetupStage.failed,
            err:
                "The scale didn't confirm the connection within 45 s. Check the password and that the network is 2.4 GHz.");
        return;
      }
      try {
        final s = await _prov!.getStatus();
        switch (s.state) {
          case WifiConnectionState.Connected:
            timer.cancel();
            scaleIp = s.deviceIp;
            _set(ScaleSetupStage.connected);
          case WifiConnectionState.Connecting:
          case WifiConnectionState.Disconnected:
            break; // still joining
          case WifiConnectionState.ConnectionFailed:
            timer.cancel();
            _set(ScaleSetupStage.failed,
                err: s.failedReason == WifiConnectFailedReason.AuthError
                    ? 'Wrong Wi-Fi password.'
                    : s.failedReason == WifiConnectFailedReason.NetworkNotFound
                        ? "The scale can't see that network. It must be 2.4 GHz and in range."
                        : "The scale couldn't join the network.");
        }
      } catch (e) {
        // Many scales end the Bluetooth session as soon as Wi-Fi is up.
        timer.cancel();
        if (!(await _transport?.checkConnect() ?? false)) {
          _set(ScaleSetupStage.connected);
        } else {
          _set(ScaleSetupStage.failed,
              err: 'Lost the connection while checking Wi-Fi status.');
        }
      }
    });
  }

  Future<void> disconnect({bool notify = true}) async {
    _statusTimer?.cancel();
    for (final sub in _notifySubs) {
      await sub.cancel();
    }
    _notifySubs.clear();
    gatt = [];
    writeTarget = null;
    directReplies.clear();
    await _transport?.disconnect();
    _transport = null;
    _prov = null;
    networks = [];
    scaleIp = null;
    customDataReply = null;
    protocol = const ScaleProtocol();
    if (notify) _set(ScaleSetupStage.idle);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    for (final sub in _notifySubs) {
      sub.cancel();
    }
    _transport?.disconnect();
    super.dispose();
  }
}

/// Keep platform diagnostics out of the normal recovery message.
String scaleConnectionError(Object error) {
  final text = error.toString();
  if (text.contains('133') ||
      text.contains('GATT_ERROR') ||
      text.toLowerCase().contains('disconnected')) {
    return 'The Bluetooth connection closed while sending Wi-Fi settings. The scale may have restarted to join Wi-Fi. Check for a live reading first. If none arrives, keep the phone nearby, close other Bluetooth apps, restart the scale in setup mode, and reconnect.';
  }
  if (text.toLowerCase().contains('timeout'))
    return 'The scale did not respond in time. Move closer, keep the scale powered on, and reconnect.';
  return 'The scale could not confirm the Wi-Fi settings. Check the setup code and Wi-Fi details, then reconnect.';
}
