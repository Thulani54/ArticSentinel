/// "Connect scale" flow: find the scale over Bluetooth, open a secure session
/// with its setup code, give it Wi-Fi (and optionally its server login), then
/// wait until the server receives its first weight reading.
library;

import '../widgets/mobile_forms.dart';

import 'dart:async';

import 'package:esp_provisioning_ble/esp_provisioning_ble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/device.dart';
import 'gas_api.dart';
import 'gas_core.dart';
import 'gas_theme.dart';
import 'gas_widgets.dart';
import 'scale_ble.dart';

const String kMqttHost = 'api.articsentinel.com';
const int kMqttTlsPort = 8883;

class ScaleSetupScreen extends StatefulWidget {
  const ScaleSetupScreen({super.key, required this.device});

  final Device device;

  @override
  State<ScaleSetupScreen> createState() => _ScaleSetupScreenState();
}

class _ScaleSetupScreenState extends State<ScaleSetupScreen> {
  final _prov = ScaleProvisioning();

  // Step 1: find the scale
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  BluetoothAdapterState _adapter = BluetoothAdapterState.unknown;
  List<ScanResult> _found = [];
  bool _scanning = false;
  bool _showAll = false;
  BluetoothDevice? _selected;

  // Step 2: Wi-Fi
  final _ssid = TextEditingController();
  final _wifiPassword = TextEditingController();
  final _pop = TextEditingController();
  final _mqttPassword = TextEditingController();
  final _bssid = TextEditingController();
  bool _sendServerLogin = true;
  bool _hideWifiPassword = true;
  DirectFormat _format = DirectFormat.json;

  // Step 3: first reading
  DateTime? _sentAt;
  Timer? _readingTimer;
  int _readingPolls = 0;
  double? _firstGrossKg;
  bool _readingTimedOut = false;

  @override
  void initState() {
    super.initState();
    _prov.addListener(_onProvChanged);
    if (!kIsWeb) {
      _adapterSub = FlutterBluePlus.adapterState.listen((s) {
        if (mounted) setState(() => _adapter = s);
      });
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _adapterSub?.cancel();
    _readingTimer?.cancel();
    if (!kIsWeb) FlutterBluePlus.stopScan();
    _prov.removeListener(_onProvChanged);
    _prov.dispose();
    for (final c in [_ssid, _wifiPassword, _pop, _mqttPassword, _bssid]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onProvChanged() {
    if (!mounted) return;
    setState(() {});
    if (_prov.stage == ScaleSetupStage.connected && _readingTimer == null) {
      _waitForFirstReading();
    }
  }

  // ---------------------------------------------------------------- scanning

  Future<bool> _ensurePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android)
      return true; // iOS prompts itself
    final results = await [
      ph.Permission.bluetoothScan,
      ph.Permission.bluetoothConnect,
      ph.Permission
          .locationWhenInUse, // needed for scanning on Android 11 and older
    ].request();
    final ok = results[ph.Permission.bluetoothScan]!.isGranted &&
        results[ph.Permission.bluetoothConnect]!.isGranted;
    if (!ok && mounted) {
      _snack('Allow "Nearby devices" for ArticSentinel to find the scale.');
    }
    return ok;
  }

  Future<void> _startScan() async {
    if (!await _ensurePermissions()) return;
    if (_adapter != BluetoothAdapterState.on) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {
          _snack('Turn Bluetooth on to find the scale.');
          return;
        }
      } else {
        _snack('Turn Bluetooth on to find the scale.');
        return;
      }
    }
    setState(() {
      _found = [];
      _scanning = true;
    });
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final r in results) {
          final i =
              _found.indexWhere((f) => f.device.remoteId == r.device.remoteId);
          if (i >= 0) {
            _found[i] = r;
          } else {
            _found.add(r);
          }
        }
        _found.sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
      await FlutterBluePlus.isScanning.where((s) => !s).first;
    } catch (e) {
      _snack('Bluetooth scan failed: $e');
    }
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() => _selected = device);
    await _prov.connect(device, _pop.text);
    if (_prov.stage == ScaleSetupStage.ready && _prov.protocol.canScanWifi) {
      await _prov.scanWifi();
    }
  }

  // ------------------------------------------------------------ Wi-Fi + send

  Future<void> _send() async {
    final ssid = _ssid.text.trim();
    if (ssid.isEmpty) {
      _snack('Choose or type the Wi-Fi network name.');
      return;
    }
    final bssidText = _bssid.text.trim();
    if (bssidText.isNotEmpty && !kBssidPattern.hasMatch(bssidText)) {
      _snack('BSSID must look like aa:bb:cc:dd:ee:ff, or be left empty.');
      return;
    }
    final bssid = bssidText.isEmpty ? null : bssidText.toLowerCase();
    final id = widget.device.deviceId;
    final settings =
        _prov.hasCustomData && _sendServerLogin && _mqttPassword.text.isNotEmpty
            ? {
                'device_id': id,
                'mqtt_host': kMqttHost,
                'mqtt_port': kMqttTlsPort,
                'mqtt_user': id,
                'mqtt_pass': _mqttPassword.text,
                'topic': 'gas_cylinder/$id/data',
              }
            : null;
    _sentAt = DateTime.now();
    if (_prov.stage == ScaleSetupStage.direct) {
      await _prov.sendDirect(
          ssid: ssid,
          password: _wifiPassword.text,
          format: _format,
          bssid: bssid);
      if (_prov.stage == ScaleSetupStage.failed) _waitForFirstReading();
      return;
    }
    await _prov.sendWifi(
        ssid: ssid,
        password: _wifiPassword.text,
        bssid: bssid,
        scaleSettings: settings);
  }

  /// After Wi-Fi is up, poll the server until the scale's first reading lands.
  void _waitForFirstReading() {
    final deviceId = widget.device.id;
    if (deviceId == null) return;
    _readingTimer?.cancel();
    _readingPolls = 0;
    _readingTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (++_readingPolls > 36) {
        t.cancel();
        if (mounted) setState(() => _readingTimedOut = true);
        return;
      }
      try {
        final r = await GasApi.load(
            deviceId: deviceId, demoKey: widget.device.deviceId);
        final latest = r.data.live ? r.data.latest : null;
        final since =
            (_sentAt ?? DateTime.now()).subtract(const Duration(minutes: 1));
        if (latest != null && latest.at.isAfter(since)) {
          t.cancel();
          if (mounted)
            setState(
                () => _firstGrossKg = r.data.scaleGrossKg ?? latest.weightKg);
        }
      } catch (e) {
        debugPrint('[scale] waiting for first reading: $e');
      }
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _startOver() async {
    _readingTimer?.cancel();
    _readingTimer = null;
    _sentAt = null;
    _firstGrossKg = null;
    _readingTimedOut = false;
    await _prov.disconnect();
    setState(() => _selected = null);
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: GasPalette.navy,
        foregroundColor: Colors.white,
        title: Text('Connect scale · ${widget.device.deviceId}'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: kIsWeb ? [_webNotice()] : _steps(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webNotice() {
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Use the phone app for this', style: gasTitle(context)),
          const SizedBox(height: 8),
          Text(
            'Setting up a scale\'s Wi-Fi needs Bluetooth, which the ArticSentinel '
            'Android and iPhone apps can use. Open this device in the app and tap "Connect scale".',
            style: gasBody(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _steps() {
    final stage = _prov.stage;
    final connectedToScale = stage.index >= ScaleSetupStage.ready.index &&
        stage != ScaleSetupStage.failed;
    return [
      _intro(),
      const SizedBox(height: 16),
      if (_firstGrossKg == null &&
          !connectedToScale &&
          stage != ScaleSetupStage.connecting &&
          stage != ScaleSetupStage.securing)
        _findStep(),
      if (stage == ScaleSetupStage.connecting ||
          stage == ScaleSetupStage.securing)
        _progress(stage == ScaleSetupStage.connecting
            ? 'Connecting to ${_nameOf(_selected)}…'
            : 'Securing the connection…'),
      if (stage == ScaleSetupStage.failed && _firstGrossKg == null) ...[
        const SizedBox(height: 12),
        _errorBox(_prov.error ?? 'Something went wrong.'),
      ],
      if (stage == ScaleSetupStage.ready ||
          stage == ScaleSetupStage.scanningWifi)
        _wifiStep(),
      if (stage == ScaleSetupStage.direct) _directStep(),
      if (stage == ScaleSetupStage.sending ||
          stage == ScaleSetupStage.waitingForWifi)
        _progress(stage == ScaleSetupStage.sending
            ? 'Sending the Wi-Fi details…'
            : 'Waiting for the scale to join ${_ssid.text.trim()}…'),
      if (stage == ScaleSetupStage.connected || _firstGrossKg != null)
        _doneStep(),
    ];
  }

  Widget _intro() {
    return Text(
      'Put the scale in setup mode (it advertises over Bluetooth), keep your '
      'phone within a few metres, then find it below.',
      style: gasBody(context).copyWith(color: GasPalette.ink2),
    );
  }

  Widget _findStep() {
    final visible =
        _showAll ? _found : _found.where(looksLikeProvisioningScale).toList();
    final hidden = _found.length - visible.length;
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GEyebrow('1 · Find the scale'),
          const SizedBox(height: 12),
          TextField(
            controller: _pop,
            decoration: mobileInputDecoration(
                context,
                InputDecoration(
                  labelText: 'Setup code (PoP)',
                  helperText:
                      'Printed on the scale label. Leave empty if it has none.',
                  border: OutlineInputBorder(),
                )),
          ),
          const SizedBox(height: 12),
          if (_adapter == BluetoothAdapterState.off)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Bluetooth is off.',
                  style: gasSmall(context).copyWith(color: GasPalette.crit)),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.flame),
            onPressed: _scanning ? null : _startScan,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bluetooth_searching),
            label: Text(_scanning ? 'Searching…' : 'Find scale'),
          ),
          const SizedBox(height: 8),
          for (final r in visible)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.scale_outlined, color: GasPalette.flame),
              title: Text(_nameOf(r.device, r)),
              subtitle: Text('${r.device.remoteId} · signal ${r.rssi} dBm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _connect(r.device),
            ),
          if (!_scanning && _found.isNotEmpty && visible.isEmpty)
            Text('No scales in setup mode found.', style: gasSmall(context)),
          if (hidden > 0)
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll
                  ? 'Show scales only'
                  : 'Show all $hidden other Bluetooth devices'),
            ),
        ],
      ),
    );
  }

  Widget _wifiStep() {
    final scanning = _prov.stage == ScaleSetupStage.scanningWifi;
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GEyebrow('2 · Wi-Fi for ${_nameOf(_selected)}',
              trailing: TextButton(
                  onPressed: _startOver, child: const Text('Start over'))),
          const SizedBox(height: 4),
          Text('The scale needs a 2.4 GHz network.', style: gasSmall(context)),
          if (_prov.error != null) ...[
            const SizedBox(height: 8),
            Text(_prov.error!,
                style: gasSmall(context).copyWith(color: GasPalette.warn)),
          ],
          const SizedBox(height: 8),
          if (scanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final WifiAP ap in _prov.networks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              selected: _ssid.text == ap.ssid,
              selectedColor: GasPalette.flameDeep,
              onTap: () => setState(() => _ssid.text = ap.ssid),
              leading: Icon(_ssid.text == ap.ssid
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(ap.ssid),
              subtitle: Text(
                  '${ap.private ? 'Secured' : 'Open'} · ${_signal(ap.rssi)}'),
            ),
          if (_prov.protocol.canScanWifi && !scanning)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _prov.scanWifi,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Search for networks again'),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _ssid,
            onChanged: (_) => setState(() {}),
            decoration: mobileInputDecoration(
                context,
                InputDecoration(
                    labelText: 'Network name', border: OutlineInputBorder())),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wifiPassword,
            obscureText: _hideWifiPassword,
            decoration: mobileInputDecoration(
                context,
                InputDecoration(
                  labelText: 'Wi-Fi password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_hideWifiPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _hideWifiPassword = !_hideWifiPassword),
                  ),
                )),
          ),
          _bssidField(),
          if (_prov.hasCustomData) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendServerLogin,
              onChanged: (v) => setState(() => _sendServerLogin = v),
              title: const Text('Also send the server login'),
              subtitle: Text(
                'Device ID ${widget.device.deviceId}, $kMqttHost:$kMqttTlsPort. '
                'Use the password issued for this scale.',
              ),
            ),
            if (_sendServerLogin)
              TextField(
                controller: _mqttPassword,
                obscureText: true,
                decoration: mobileInputDecoration(
                    context,
                    InputDecoration(
                      labelText: 'Scale server password',
                      helperText:
                          'Leave empty to keep what the scale already has.',
                      border: OutlineInputBorder(),
                    )),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.flame),
            onPressed: scanning ? null : _send,
            child: const Text('Connect scale to Wi-Fi'),
          ),
        ],
      ),
    );
  }

  /// Wi-Fi step for scales with their own Bluetooth setup (not ESP-IDF
  /// provisioning): write the details to a characteristic, LightBlue-style.
  Widget _directStep() {
    final writable = _prov.gatt.where((e) => e.writable).toList();
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GEyebrow('2 · Wi-Fi for ${_nameOf(_selected)}',
              trailing: TextButton(
                  onPressed: _startOver, child: const Text('Start over'))),
          const SizedBox(height: 4),
          Text(
            'This scale has its own Bluetooth setup. The app writes the Wi-Fi details '
            'straight to it. The scale needs a 2.4 GHz network.',
            style: gasSmall(context),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ssid,
            onChanged: (_) => setState(() {}),
            decoration: mobileInputDecoration(context, InputDecoration(
                labelText: 'Network name', border: OutlineInputBorder())),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wifiPassword,
            obscureText: _hideWifiPassword,
            decoration: mobileInputDecoration(context, InputDecoration(
              labelText: 'Wi-Fi password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_hideWifiPassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _hideWifiPassword = !_hideWifiPassword),
              ),
            )),
          ),
          _bssidField(),
          const SizedBox(height: 4),
          DropdownButtonFormField<GattEntry>(
            isExpanded: true,
            initialValue: _prov.writeTarget,
            decoration: mobileInputDecoration(context, InputDecoration(
              labelText: 'Write to characteristic',
              border: OutlineInputBorder(),
            )),
            items: [
              for (final e in writable)
                DropdownMenuItem(
                    value: e,
                    child: Text(e.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (e) {
              if (e != null) _prov.chooseWriteTarget(e);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DirectFormat>(
            isExpanded: true,
            initialValue: _format,
            decoration: mobileInputDecoration(context, InputDecoration(
              labelText: 'Format',
              helperText: 'Use the format the scale firmware expects.',
              border: OutlineInputBorder(),
            )),
            items: [
              for (final f in DirectFormat.values)
                DropdownMenuItem(
                    value: f,
                    child: Text(f.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (f) => setState(() => _format = f ?? _format),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.flame),
            onPressed: _send,
            child: const Text('Write Wi-Fi to scale'),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
                'Bluetooth details (${_prov.gatt.length} characteristics)',
                style: gasSmall(context).copyWith(fontWeight: FontWeight.w700)),
            children: [
              for (final e in _prov.gatt)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.label,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12)),
                  subtitle: Text(
                    '${e.propsText}${e.value != null && e.value!.isNotEmpty ? '\nvalue: ${e.value}' : ''}',
                    style: gasSmall(context),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                        text: _prov.gattReport(_nameOf(_selected))));
                    _snack(
                        'Bluetooth details copied — paste them to the firmware developer.');
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Optional access-point pin: only needed when several access points share
  /// the network name (mesh, dual-band) and the scale must join one of them.
  Widget _bssidField() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: _bssid.text.isNotEmpty,
      title: Text('Advanced',
          style: gasSmall(context).copyWith(fontWeight: FontWeight.w700)),
      children: [
        TextField(
          controller: _bssid,
          autocorrect: false,
          decoration: mobileInputDecoration(
              context,
              const InputDecoration(
                labelText: 'Access point BSSID (optional)',
                hintText: 'aa:bb:cc:dd:ee:ff',
                helperText:
                    'Only if several access points share this network name. Leave empty otherwise.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              )),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _doneStep() {
    final gotReading = _firstGrossKg != null;
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GEyebrow('3 · Connected'),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.wifi, color: GasPalette.good),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _prov.scaleIp != null
                    ? 'On ${_ssid.text.trim()} · IP ${_prov.scaleIp}'
                    : 'Wi-Fi details accepted',
                style: gasBody(context),
              ),
            ),
          ]),
          for (final reply in _prov.directReplies) ...[
            const SizedBox(height: 4),
            Text('Scale said: $reply', style: gasSmall(context)),
          ],
          if (_prov.customDataReply != null) ...[
            const SizedBox(height: 6),
            Text('Scale replied to the server login: ${_prov.customDataReply}',
                style: gasSmall(context)),
          ],
          const SizedBox(height: 14),
          if (gotReading)
            Row(children: [
              const Icon(Icons.check_circle, color: GasPalette.good),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'First reading received: ${kg1(_firstGrossKg!)} on the scale.',
                    style:
                        gasBody(context).copyWith(fontWeight: FontWeight.w700)),
              ),
            ])
          else if (_readingTimedOut)
            Text(
              'No reading reached the server within 3 minutes. The scale is on Wi-Fi, so check its '
              'server login (Device ID ${widget.device.deviceId}, port $kMqttTlsPort, password).',
              style: gasSmall(context).copyWith(color: GasPalette.warn),
            )
          else
            Row(children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Waiting for its first weight reading…',
                      style: gasBody(context))),
            ]),
          const SizedBox(height: 16),
          MobileFormRow(children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GasPalette.navy),
              onPressed: () => Navigator.of(context).pop(gotReading),
              child: const Text('Done'),
            ),
            const SizedBox(width: 10),
            TextButton(
                onPressed: _startOver, child: const Text('Set up another')),
          ]),
        ],
      ),
    );
  }

  Widget _progress(String text) {
    return GPanel(
      child: Row(children: [
        const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: gasBody(context))),
      ]),
    );
  }

  Widget _errorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GasPalette.crit.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GasPalette.crit.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Connection needs checking', style: gasTitle(context)),
        const SizedBox(height: 8),
        Text(text, style: gasBody(context)),
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: _startOver, child: const Text('Reconnect scale')),
      ]),
    );
  }

  String _nameOf(BluetoothDevice? d, [ScanResult? r]) {
    if (d == null) return 'the scale';
    final adv = r?.advertisementData.advName ?? '';
    if (adv.isNotEmpty) return adv;
    if (d.platformName.isNotEmpty) return d.platformName;
    return 'Unnamed device';
  }

  String _signal(int rssi) => rssi >= -60
      ? 'strong signal'
      : rssi >= -75
          ? 'good signal'
          : 'weak signal';
}
