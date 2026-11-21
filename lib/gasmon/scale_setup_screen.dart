/// "Connect scale" flow: find the scale over Bluetooth, open a secure session
/// with its setup code, give it Wi-Fi and a server login the server issues on
/// the spot, then wait until the server receives its first weight reading.
library;

import '../widgets/app_tone.dart';
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
import 'scale_connection_identity.dart';

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
  final _bssid = TextEditingController();
  bool _sendServerLogin = true;

  /// Set once the login was issued and handed to the scale, or why not.
  bool _loginSent = false;
  bool _issuing = false;
  bool _sending = false;
  Map<String, dynamic>? _pendingSettings;
  String? _loginNote;
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
    _pendingSettings = null;
    if (!kIsWeb) FlutterBluePlus.stopScan();
    _prov.removeListener(_onProvChanged);
    _prov.dispose();
    for (final c in [_ssid, _wifiPassword, _pop, _bssid]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onProvChanged() {
    if (!mounted) return;
    if (_prov.stage == ScaleSetupStage.connected && _sentAt != null) {
      _loginSent = _sendServerLogin && _pendingSettings != null;
    }
    setState(() {});
    if (_prov.stage == ScaleSetupStage.connected && _readingTimer == null) {
      _waitForFirstReading();
    }
  }

  // ---------------------------------------------------------------- scanning

  Future<bool> _ensurePermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // iOS prompts itself
    }
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
    if (_sending || _issuing) return;
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
    if (_sendServerLogin && !_canSendLogin) {
      _snack(
          'This scale cannot receive automatic setup in this mode. Use JSON or ask for a firmware update. Advanced options allow Wi-Fi-only setup for an already configured scale.');
      return;
    }
    setState(() => _sending = true);
    try {
      final settings = _sendServerLogin ? await _issueLogin() : null;
      if (!mounted || (_sendServerLogin && settings == null)) return;
      _readingTimer?.cancel();
      _readingTimer = null;
      _firstGrossKg = null;
      _readingTimedOut = false;
      _loginSent = false;
      _sentAt = DateTime.now();
      final bssid = bssidText.isEmpty ? null : bssidText.toLowerCase();
      if (_prov.stage == ScaleSetupStage.direct) {
        await _prov.sendDirect(
            ssid: ssid,
            password: _wifiPassword.text,
            format: _format,
            bssid: bssid,
            scaleSettings: settings);
      } else {
        await _prov.sendWifi(
            ssid: ssid,
            password: _wifiPassword.text,
            bssid: bssid,
            scaleSettings: settings);
      }
      if (!mounted) return;
      setState(() => _loginSent =
          settings != null && _prov.stage == ScaleSetupStage.connected);
      if (_prov.stage == ScaleSetupStage.failed) _waitForFirstReading();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The login rides along with the Wi-Fi details: in the scale's custom-data
  /// endpoint, or as extra keys when the direct format is JSON.
  bool get _canSendLogin => _prov.stage == ScaleSetupStage.direct
      ? _format == DirectFormat.json
      : _prov.hasCustomData;

  /// Reuse the in-memory login on transport retries. Never silently send only
  /// Wi-Fi when automatic registration failed, and never persist the password.
  Future<Map<String, dynamic>?> _issueLogin() async {
    final deviceId = widget.device.id;
    if (deviceId == null) return null;
    if (_pendingSettings != null) return _pendingSettings;
    setState(() {
      _issuing = true;
      _loginNote = null;
    });
    try {
      final creds = await GasApi.issueCredentials(deviceId: deviceId);
      _pendingSettings = validatedScaleSettings(creds.settings,
          registeredId: deviceId, deviceId: widget.device.deviceId);
      return _pendingSettings;
    } catch (e) {
      final why = e is GasApiException
          ? e.message
          : e is FormatException
              ? e.message
              : 'the server could not be reached';
      if (mounted) {
        setState(() => _loginNote =
            'Automatic setup paused: $why No Wi-Fi details were sent. Please retry.');
      }
      return null;
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
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
        final latest = r.data.hasReadings ? r.data.latest : null;
        if (latest != null &&
            isReadingAfterSetup(latest.at, _sentAt, DateTime.now())) {
          t.cancel();
          if (mounted) {
            _pendingSettings = null;
            setState(
                () => _firstGrossKg = r.data.scaleGrossKg ?? latest.weightKg);
          }
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
    _loginSent = false;
    _loginNote = null;
    await _prov.disconnect();
    setState(() => _selected = null);
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tone.bg(Colors.white),
      appBar: AppBar(
        backgroundColor: GasPalette.navy,
        foregroundColor: Tone.fg(Colors.white),
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
      'phone within a few metres, then find it below. Choose your Wi-Fi and we send '
      'this scale’s ID, topic and private login automatically. No IDs to type.',
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
            style: FilledButton.styleFrom(backgroundColor: GasPalette.primary),
            onPressed: _scanning ? null : _startScan,
            icon: _scanning
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Tone.fg(Colors.white)))
                : const Icon(Icons.bluetooth_searching),
            label: Text(_scanning ? 'Searching…' : 'Find scale'),
          ),
          const SizedBox(height: 8),
          for (final r in visible)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.scale_outlined, color: GasPalette.flame),
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
                  onPressed: _sending || _issuing ? null : _startOver,
                  child: const Text('Start over'))),
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
          _loginToggle(),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.primary),
            onPressed: scanning || _issuing || _sending ? null : _send,
            child: Text(_issuing
                ? 'Preparing automatic setup…'
                : 'Connect scale to Wi-Fi'),
          ),
          if (_loginNote != null) _loginWarning(),
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
                  onPressed: _sending || _issuing ? null : _startOver,
                  child: const Text('Start over'))),
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
          const SizedBox(height: 4),
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Advanced Bluetooth options'),
              children: [
                DropdownButtonFormField<GattEntry>(
                  isExpanded: true,
                  initialValue: _prov.writeTarget,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        labelText: 'Write to characteristic',
                        border: OutlineInputBorder(),
                      )),
                  items: [
                    for (final e in writable)
                      DropdownMenuItem(
                          value: e,
                          child:
                              Text(e.label, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (e) {
                    if (e != null) _prov.chooseWriteTarget(e);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DirectFormat>(
                  isExpanded: true,
                  initialValue: _format,
                  decoration: mobileInputDecoration(
                      context,
                      InputDecoration(
                        labelText: 'Format',
                        helperText:
                            'Use the format the scale firmware expects.',
                        border: OutlineInputBorder(),
                      )),
                  items: [
                    for (final f in DirectFormat.values)
                      DropdownMenuItem(
                          value: f,
                          child:
                              Text(f.label, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (f) => setState(() => _format = f ?? _format),
                ),
              ]),
          _loginToggle(),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.primary),
            onPressed: _issuing || _sending ? null : _send,
            child:
                Text(_issuing ? 'Preparing automatic setup…' : 'Connect scale'),
          ),
          if (_loginNote != null) _loginWarning(),
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
                    e.propsText,
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

  Widget _loginWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(_loginNote!,
          style: gasSmall(context).copyWith(color: GasPalette.warn)),
    );
  }

  Widget _loginToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Connection set up for you', style: gasTitle(context)),
        const SizedBox(height: 6),
        Text(
            'Your scale gets its own connection ID, topic and private password. '
            'The ID is a label, not a password. Only this scale’s login is replaced during setup.',
            style: gasSmall(context)),
        if (!_canSendLogin)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'This setup mode accepts Wi-Fi only. Automatic connection setup needs JSON or a supported secure setup endpoint.',
                  style: gasSmall(context).copyWith(color: GasPalette.warn))),
        ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Existing scale options'),
            children: [
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sendServerLogin,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _sendServerLogin = v),
                  title: const Text('Set up connection automatically'),
                  subtitle: const Text(
                      'Leave on for a new scale. Turn off only to change Wi-Fi on a scale that already has its own working server login.')),
              SelectableText(
                  'Connection ID: ${assignedScaleClientId(widget.device.id) ?? 'Save the device first'}',
                  style: gasSmall(context)),
            ]),
      ]),
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
          GEyebrow(
              gotReading ? '3 · Scale connected' : '3 · Checking connection'),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.wifi, color: GasPalette.good),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _prov.scaleIp != null
                    ? 'On ${_ssid.text.trim()} · IP ${_prov.scaleIp}'
                    : 'Wi-Fi details sent — waiting for a new reading',
                style: gasBody(context),
              ),
            ),
          ]),
          if (_loginSent) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.lock_outline, color: GasPalette.good),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'This scale’s connection ID, topic and private login were sent automatically.',
                    style: gasBody(context)),
              ),
            ]),
          ] else if (_loginNote != null)
            _loginWarning(),
          // Firmware replies can echo Wi-Fi or broker secrets; never render them.
          const SizedBox(height: 14),
          if (gotReading)
            Row(children: [
              Icon(Icons.check_circle, color: GasPalette.good),
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
              _loginSent
                  ? 'No new reading reached the server within 3 minutes. Connection details were '
                      'sent, but setup is not confirmed. Check power and Wi-Fi. Older firmware may need a one-time update to save automatic connection settings.'
                  : 'No new reading reached the server within 3 minutes. Check Wi-Fi and the scale’s '
                      'server login (Device ID ${widget.device.deviceId}, port $kMqttTlsPort).',
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
