import '../widgets/app_tone.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_api.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/scale_setup_screen.dart';
import '../models/device.dart';
import '../products/product_catalog.dart';
import '../widgets/device_illustration.dart';
import '../widgets/mobile_forms.dart';
import 'device_setup_guide.dart';
import 'device_setup_service.dart';
import 'setup_flow_frame.dart';
import 'device_pairing_code.dart';
import 'device_qr_scanner.dart';

export 'device_setup_service.dart';

/// A resumable, authenticated equipment setup. Account creation happens before
/// opening this screen; skipping never discards the newly created account.
class DeviceSetupWizard extends StatefulWidget {
  const DeviceSetupWizard(
      {super.key,
      this.onDone,
      this.onBrowseProducts,
      this.initialDeviceType,
      this.service,
      this.scanCode,
      this.fromEquipment = false,
      this.scaleSetupBuilder});
  final VoidCallback? onDone;
  final VoidCallback? onBrowseProducts;
  final String? initialDeviceType;
  final DeviceSetupService? service;
  final Widget Function(Device device)? scaleSetupBuilder;
  final Future<DevicePairingCode?> Function(BuildContext context)? scanCode;

  /// Opened from Equipment: skip the onboarding welcome and offer Cancel
  /// instead of "Set up later".
  final bool fromEquipment;

  @override
  State<DeviceSetupWizard> createState() => _DeviceSetupWizardState();
}

class _DeviceSetupWizardState extends State<DeviceSetupWizard> {
  late final DeviceSetupService _service =
      widget.service ?? DeviceSetupService();
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  final _tare = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  String _phase = 'single';
  // -2: welcome; -1: product choice; 0..2: the three setup steps.
  int _step = -2;
  String? _type;
  bool _busy = false;
  bool _draftLocked = false;
  bool _hasReading = false;
  bool _checked = false;
  String? _error;
  DeviceSetupResult? _result;
  bool get _isGas => _type == 'gas_cylinder';
  bool get _isBottle => _type == 'device7';
  DeviceSetupGuide get _guide => DeviceSetupGuide.forType(_type);
  static const _stepNames = ['Identify', 'Fit and set up', 'Connect and link'];
  ProductDefinition? get _product =>
      _type == null ? null : ProductCatalog.byType(_type!);
  bool get _canScan =>
      widget.scanCode != null ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  Future<void> _scan() async {
    if (_busy || _draftLocked) return;
    final code = await (widget.scanCode?.call(context) ??
        Navigator.of(context).push<DevicePairingCode>(
          MaterialPageRoute(builder: (_) => const DeviceQrScanner()),
        ));
    if (!mounted || code == null) return;
    setState(() {
      if (_type != code.deviceType) {
        _capacity.clear();
        _tare.clear();
      }
      _type = code.deviceType;
      _id.text = code.deviceId;
    });
    _go(0);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDeviceType != null &&
        ProductCatalog.byType(widget.initialDeviceType!) != null) {
      _type = widget.initialDeviceType;
      _step = 0;
    } else if (widget.fromEquipment) {
      _step = -1;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _name,
      _location,
      _capacity,
      _tare,
      _min,
      _max
    ]) {
      controller.dispose();
    }
    _scroll.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _done() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).maybePop(_result?.device);
    }
  }

  Future<void> _save() async {
    if (_busy || _result != null) return;
    setState(() {
      _busy = true;
      _draftLocked = true;
      _error = null;
    });
    try {
      final result = await _service.register(
        draft: Device(
            name: _name.text.trim(),
            deviceId: _id.text.trim(),
            deviceType: _type,
            location: _location.text.trim(),
            targetTempMin: _hasRange ? _number(_min.text) : null,
            targetTempMax: _hasRange ? _number(_max.text) : null,
            phaseType:
                _guide.settings.contains(SetupSetting.phase) ? _phase : null),
        gasConfig: _isGas
            ? GasConfig(
                gasCapacityKg: _number(_capacity.text)!,
                tareKg: _number(_tare.text)!,
                pricePerKg: 0,
                lowPct: 20,
                warningPct: 40,
                isDefault: false,
              )
            : null,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _busy = false;
      });
      await _checkReading();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (error is DeviceSetupException && error.canEdit) {
          _draftLocked = false;
        }
        _error = error is DeviceSetupException
            ? error.message
            : 'Setup could not be completed. Your entries are kept; retry to check the device before adding it again.';
      });
    }
  }

  Future<void> _checkReading() async {
    if (_busy || _result == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final received = await _service.hasReading(_result!.device);
      if (!mounted) return;
      setState(() {
        _hasReading = received;
        _checked = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is DeviceSetupException
          ? error.message
          : 'Your device is registered. Readings could not be checked; try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connectScale() async {
    if (_result == null || _busy) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          widget.scaleSetupBuilder?.call(_result!.device) ??
          ScaleSetupScreen(device: _result!.device),
    ));
    if (mounted) await _checkReading();
  }

  void _another() {
    for (final controller in [
      _id,
      _name,
      _location,
      _capacity,
      _tare,
      _min,
      _max
    ]) {
      controller.clear();
    }
    _phase = 'single';
    setState(() {
      _result = null;
      _type = null;
      _draftLocked = false;
      _hasReading = false;
      _checked = false;
    });
    _go(-1);
  }

  bool get _hasRange => _guide.settings.contains(SetupSetting.temperatureRange);

  void _back() {
    if (_step == -2 || (widget.fromEquipment && _step == -1)) {
      _done();
      return;
    }
    _go(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final inSteps = _step >= 0;
    return PopScope(
      canPop: !_busy,
      child: SetupFlowFrame(
        title: _step < 0
            ? (widget.fromEquipment ? 'Add a device' : 'Set up your workspace')
            : _product!.title,
        steps:
            _stepNames, // the side panel previews them before a type is chosen
        step: inSteps ? (_result != null ? 2 : _step) : null,
        complete: _hasReading,
        deviceType: _type,
        deviceLabel:
            _type == null ? 'Choose what you’re connecting' : _product!.summary,
        busy: _busy,
        onBack: _draftLocked || _step == -2 ? null : _back,
        closeLabel: _result != null
            ? 'Done'
            : widget.fromEquipment
                ? 'Cancel'
                : 'Set up later',
        onClose: _done,
        scrollController: _scroll,
        sideNote: inSteps && _guide.safety != null && _result == null
            ? SetupNote(
                icon: Iconsax.danger,
                title: 'Safety first',
                text: _guide.safety!,
                tone: SetupNoteTone.safety)
            : null,
        footer: inSteps ? _footer() : null,
        body: Form(
            key: _form,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reducedMotion ? 0 : 260),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                  key: ValueKey('$_step-$_type-${_result != null}'),
                  child: _step == -2
                      ? _welcome()
                      : _step == -1
                          ? _choose()
                          : _setupStep()),
            )),
      ),
    );
  }

  TextStyle _text(double size,
          {FontWeight weight = FontWeight.w500,
          Color? color}) =>
      GoogleFonts.inter(
          fontSize: size, height: 1.45, fontWeight: weight, color: color ?? GasPalette.ink);

  Widget _heading(String title, String explanation) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _text(27, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(explanation, style: _text(15, color: GasPalette.ink2)),
        const SizedBox(height: 24),
      ]);

  Widget _welcome() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _SetupIllustration(type: 'gas_cylinder', step: -2),
        _heading('Do you have a device to connect?',
            'Bring your equipment into your workspace. We’ll help you identify it, set it up and check its first reading.'),
        _choice(
            'Yes, I have a device',
            'Connect a gas scale, bottle vetting machine or monitoring device.',
            Iconsax.add_circle,
            () => _go(-1)),
        const SizedBox(height: 12),
        if (widget.onBrowseProducts != null)
          _choice(
              'Explore our products',
              'Find the right equipment and ask our team for more information.',
              Iconsax.box,
              widget.onBrowseProducts!),
        const SizedBox(height: 12),
        TextButton(
            onPressed: _done, child: const Text('Explore my workspace first')),
      ]);

  Widget _choice(
          String title, String subtitle, IconData icon, VoidCallback action) =>
      Material(
          color: GasPalette.panelAlt,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: action,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: GasPalette.series, size: 26),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(title,
                                style: _text(16, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: _text(13, color: GasPalette.ink2)),
                          ])),
                    ])),
          ));

  Widget _choose() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading('What are you connecting?',
            'Choose the type shown on your equipment. Each guide takes three short steps.'),
        if (_canScan)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Iconsax.scan_barcode),
                  label: const Text('Scan device QR code'))),
        _productGrid(),
      ]);

  Widget _productGrid() => LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= 560 ? 2 : 1;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final product in ProductCatalog.products)
            SizedBox(width: width, child: _productCard(product)),
        ]);
      });

  Widget _productCard(ProductDefinition product) => Material(
        color: Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: GasPalette.border)),
        child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() => _type = product.type);
              _go(0);
            },
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  DeviceIllustration(type: product.type, size: 60),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(product.title,
                            style: _text(15, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(product.summary,
                            style: _text(12, color: GasPalette.ink2)),
                      ])),
                  const SizedBox(width: 8),
                  Icon(Iconsax.arrow_right_3,
                      size: 18, color: GasPalette.ink2),
                ]))),
      );

  Widget _setupStep() {
    final registered = _result != null;
    final guide = _guide;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_step == 0) ...[
        SetupScene(asset: DeviceSetupGuide.scene('find-id'), deviceType: _type),
        _heading(
            _isGas
                ? 'Meet your gas scale'
                : _isBottle
                    ? 'Meet your bottle vetting machine'
                    : 'Identify your device',
            'Find the device ID on its label or setup screen. Use that exact ID so readings arrive in the right place.'),
        if (_canScan)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder()),
                  onPressed: _draftLocked ? null : _scan,
                  icon: const Icon(Iconsax.scan_barcode),
                  label: const Text('Scan device QR code'))),
        _field(_id, 'Device ID',
            helper: 'Use the hardware ID, not a name you make up.',
            required: true),
        _field(_name, _isGas ? 'Cylinder name' : 'Device name',
            helper: _isGas
                ? 'For example: Kitchen gas'
                : 'For example: Front counter',
            required: true),
        _field(_location, 'Location (optional)',
            helper: 'Where your team will find it, e.g. Back store room.'),
      ] else if (_step == 1) ...[
        SetupScene(
            asset: DeviceSetupGuide.scene(guide.fitScene), deviceType: _type),
        _heading(guide.fitTitle, guide.fitIntro),
        for (var i = 0; i < guide.fitSteps.length; i++)
          SetupInstructionTile(
              number: i + 1,
              icon: guide.fitSteps[i].icon,
              title: guide.fitSteps[i].title,
              text: guide.fitSteps[i].text),
        if (_isGas) ...[
          const SizedBox(height: 4),
          Text('Gas capacity', style: _text(14, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final kg in [9, 14, 19, 48])
              ChoiceChip(
                  label: Text('$kg kg'),
                  selected: _number(_capacity.text) == kg,
                  onSelected: (_) => setState(() => _capacity.text = '$kg')),
          ]),
          const SizedBox(height: 16),
          _field(_capacity, 'Gas capacity (kg)',
              helper: 'Choose a size above, or enter your own.',
              numeric: true,
              required: true),
          _field(_tare, 'Empty cylinder weight (kg)',
              helper:
                  'Copy the TARE or TW weight stamped on this cylinder. Do not include gas.',
              numeric: true,
              required: true),
          _note(Iconsax.info_circle, 'Use the stamped weight',
              'Empty weights vary, even for cylinders of the same size. We never guess this value.'),
        ],
        if (_hasRange) ...[
          const SizedBox(height: 4),
          Text('Safe temperature range (optional)',
              style: _text(15, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Readings outside this range are flagged, and the AI assistant uses it to judge the unit.',
              style: _text(13, color: GasPalette.ink2)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final preset in guide.presets)
              ChoiceChip(
                  label: Text(
                      '${preset.label} ${_fmt(preset.min)} to ${_fmt(preset.max)} °C'),
                  selected: _number(_min.text) == preset.min &&
                      _number(_max.text) == preset.max,
                  onSelected: (_) => setState(() {
                        _min.text = _fmt(preset.min);
                        _max.text = _fmt(preset.max);
                      })),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _tempField(_min, 'Lowest (°C)')),
            const SizedBox(width: 12),
            Expanded(child: _tempField(_max, 'Highest (°C)')),
          ]),
        ],
        if (guide.settings.contains(SetupSetting.phase)) ...[
          const SizedBox(height: 4),
          Text('Supply', style: _text(15, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in const [
              ('single', 'Single phase'),
              ('three', 'Three phase')
            ])
              ChoiceChip(
                  label: Text(option.$2),
                  selected: _phase == option.$1,
                  onSelected: _draftLocked
                      ? null
                      : (_) => setState(() => _phase = option.$1)),
          ]),
          const SizedBox(height: 20),
        ],
        if (guide.safety != null && !_wide(context))
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SetupNote(
                  icon: Iconsax.danger,
                  title: 'Safety first',
                  text: guide.safety!,
                  tone: SetupNoteTone.safety)),
      ] else if (!registered) ...[
        SetupScene(
            asset: DeviceSetupGuide.scene('power-network'), deviceType: _type),
        _heading(
            _isGas ? 'Ready to link' : 'Give it power and a connection',
            _isGas
                ? 'Save your cylinder, then we’ll help connect the scale to Wi-Fi using Bluetooth on your phone.'
                : 'Link this hardware ID to your workspace, then check for its first reading.'),
        for (var i = 0; i < guide.connectSteps.length; i++)
          SetupInstructionTile(
              number: i + 1,
              icon: guide.connectSteps[i].icon,
              title: guide.connectSteps[i].title,
              text: guide.connectSteps[i].text),
        const SizedBox(height: 4),
        _review(),
        const SizedBox(height: 16),
        _note(Iconsax.shield_tick, 'Your device, your readings',
            'Only this device’s measurements will appear in its dashboard. You can set your own alert levels after setup.'),
      ] else ...[
        _SetupIllustration(type: _type!, step: _step, complete: _hasReading),
        _heading(
            _hasReading
                ? 'Your device is reporting'
                : _result!.alreadyRegistered
                    ? 'Already in your workspace'
                    : 'Your device is registered',
            _hasReading
                ? 'A measurement has reached ArticSentinel. Open your workspace to see readings and set alerts.'
                : _result!.alreadyRegistered
                    ? 'We found this device in your account and kept its existing settings.'
                    : 'Registration is complete. We’ll only mark the connection ready when a measurement reaches ArticSentinel.'),
        _review(),
        const SizedBox(height: 18),
        _note(
            _hasReading ? Iconsax.tick_circle : Iconsax.timer_1,
            _hasReading
                ? 'Reading received'
                : _busy
                    ? 'Checking for a reading…'
                    : _checked
                        ? 'Waiting for a fresh reading'
                        : 'Readings have not been checked',
            _hasReading
                ? 'You can finish here and continue in your dashboard.'
                : _isGas
                    ? 'Connect the scale below. If it is already online, check again after it sends a weight.'
                    : 'Keep the machine powered and connected. Check again after it reports.'),
        if (_isGas) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: _busy ? null : _connectScale,
              icon: const Icon(Iconsax.bluetooth),
              label: const Text('Connect scale to Wi-Fi')),
        ],
        TextButton.icon(
            onPressed: _busy ? null : _checkReading,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('Check for a reading')),
        TextButton(
            onPressed: _busy ? null : _another,
            child: const Text('Connect another device')),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        Semantics(
            liveRegion: true,
            child: _note(Iconsax.info_circle, 'Setup needs attention', _error!,
                error: true)),
      ],
    ]);
  }

  Widget _review() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_result?.device.name ?? _name.text.trim(),
              style: _text(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${_product!.title} · ${_id.text.trim()}',
              style: _text(13, color: GasPalette.ink2)),
          if (_location.text.trim().isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_location.text.trim(),
                    style: _text(13, color: GasPalette.ink2))),
          if (_hasRange &&
              _number(_min.text) != null &&
              _number(_max.text) != null)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    'Safe range ${_min.text.trim()} to ${_max.text.trim()} °C',
                    style: _text(13, color: GasPalette.ink2))),
          if (_guide.settings.contains(SetupSetting.phase))
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    _phase == 'three'
                        ? 'Three-phase supply'
                        : 'Single-phase supply',
                    style: _text(13, color: GasPalette.ink2))),
          if (_isGas && _result?.alreadyRegistered != true) ...[
            const Divider(height: 28),
            Text(
                '${_result?.gasConfig?.gasCapacityKg ?? _capacity.text.trim()} kg gas capacity',
                style: _text(14)),
            Text(
                '${_result?.gasConfig?.tareKg ?? _tare.text.trim()} kg empty cylinder',
                style: _text(14)),
          ],
        ]),
      );

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  bool _wide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= SetupFlowFrame.wideBreakpoint;

  Widget _tempField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        enabled: !_busy && !_draftLocked,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
        decoration: mobileInputDecoration(
            context,
            InputDecoration(
              labelText: label,
              filled: true,
              fillColor: GasPalette.panelAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
            )),
        validator: (value) {
          final text = value?.trim() ?? '';
          final other =
              controller == _min ? _max.text.trim() : _min.text.trim();
          if (text.isEmpty) {
            return other.isEmpty ? null : 'Enter both values.';
          }
          final number = _number(text);
          if (number == null || number < -60 || number > 60) {
            return 'Enter −60 to 60 °C.';
          }
          final lo = _number(_min.text), hi = _number(_max.text);
          if (controller == _max && lo != null && hi != null && hi <= lo) {
            return 'Must be above the lowest.';
          }
          return null;
        },
      );

  Widget _field(TextEditingController controller, String label,
          {String? helper, bool numeric = false, bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextFormField(
          controller: controller,
          enabled: !_busy,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged: numeric ? (_) => setState(() {}) : null,
          maxLength: numeric ? 8 : 120,
          decoration: mobileInputDecoration(
              context,
              InputDecoration(
                labelText: label,
                helperText: helper,
                counterText: '',
                filled: true,
                fillColor: GasPalette.panelAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
              )),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Enter $label.'
                  .replaceAll('Enter Gas', 'Enter the gas')
                  .replaceAll('Enter Empty', 'Enter the empty');
            }
            if (numeric) {
              final number = _number(value ?? '');
              if (number == null ||
                  !number.isFinite ||
                  number <= 0 ||
                  number > 1000) {
                return 'Enter a weight above 0 and up to 1,000 kg.';
              }
            }
            return null;
          },
        ),
      );

  Widget _note(IconData icon, String title, String text,
          {bool error = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: error ? Tone.bg(const Color(0xFFFFF1EE)) : GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: error ? Tone.bg(const Color(0xFFF4CCC4)) : GasPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon,
                size: 20,
                color: error ? GasPalette.critInk : GasPalette.series),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title, style: _text(14, weight: FontWeight.w700)))
          ]),
          const SizedBox(height: 8),
          Text(text, style: _text(13, color: GasPalette.ink2)),
        ]),
      );

  void _continue() {
    final invalid = _form.currentState?.validateGranularly();
    if (invalid == null) return;
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !field.mounted) return;
        Scrollable.ensureVisible(
          field.context,
          alignment: .15,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }
    _go(_step + 1);
  }

  Widget _footer() => SizedBox(
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: GasPalette.primary,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder()),
          onPressed: _busy
              ? null
              : _result != null
                  ? _done
                  : _step == 2
                      ? _save
                      : _continue,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_result != null
                  ? 'Open my workspace'
                  : _step == 2
                      ? _draftLocked
                          ? 'Retry setup'
                          : 'Link device'
                      : 'Continue'),
        ),
      );
}

/// One short animation per step: the illustration settles and the connection
/// trace draws towards the confirmation. No motion continues while typing.
class _SetupIllustration extends StatelessWidget {
  const _SetupIllustration(
      {required this.type, required this.step, this.complete = false});
  final String type;
  final int step;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
        child: Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$type-$step-$complete'),
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: Duration(milliseconds: reduce ? 0 : 850),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => SizedBox(
            height: step == 1 ? 124 : 164,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                  size: Size(280, step == 1 ? 114 : 154),
                  painter: _ConnectionPainter(progress, complete)),
              Transform.translate(
                  offset: Offset(0, (1 - progress) * 12),
                  child: DeviceIllustration(
                      type: type, size: step == 1 ? 108 : 140)),
              Positioned(
                  right: 8,
                  bottom: 18,
                  child: Transform.scale(
                    scale: .8 + .2 * progress,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: complete
                              ? GasPalette.goodSoft
                              : GasPalette.seriesSoft,
                          shape: BoxShape.circle),
                      child: Icon(
                          complete
                              ? Iconsax.tick_circle
                              : step == 0
                                  ? Iconsax.scan
                                  : step == 1 && type == 'gas_cylinder'
                                      ? Iconsax.weight
                                      : Iconsax.wifi,
                          size: 24,
                          color:
                              complete ? GasPalette.good : GasPalette.series),
                    ),
                  )),
            ])),
      ),
    ));
  }
}

class _ConnectionPainter extends CustomPainter {
  const _ConnectionPainter(this.progress, this.complete);
  final double progress;
  final bool complete;
  @override
  void paint(Canvas canvas, Size size) {
    final color = complete ? GasPalette.good : GasPalette.series;
    final paint = Paint()
      ..color = GasPalette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 230,
        height: size.height - 16);
    canvas.drawOval(rect, paint);
    paint
      ..color = color.withValues(alpha: .5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.7 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_ConnectionPainter old) =>
      old.progress != progress || old.complete != complete;
}
