import 'dart:math' as math;

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
import 'device_setup_service.dart';

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
      this.scaleSetupBuilder});
  final VoidCallback? onDone;
  final VoidCallback? onBrowseProducts;
  final String? initialDeviceType;
  final DeviceSetupService? service;
  final Widget Function(Device device)? scaleSetupBuilder;

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
  ProductDefinition? get _product =>
      _type == null ? null : ProductCatalog.byType(_type!);

  @override
  void initState() {
    super.initState();
    if (widget.initialDeviceType != null &&
        ProductCatalog.byType(widget.initialDeviceType!) != null) {
      _type = widget.initialDeviceType;
      _step = 0;
    }
  }

  @override
  void dispose() {
    for (final controller in [_id, _name, _location, _capacity, _tare]) {
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
            location: _location.text.trim()),
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
    for (final controller in [_id, _name, _location, _capacity, _tare]) {
      controller.clear();
    }
    setState(() {
      _result = null;
      _type = null;
      _draftLocked = false;
      _hasReading = false;
      _checked = false;
    });
    _go(-1);
  }

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
          child: Row(children: [
            IconButton(
                tooltip: 'Back',
                onPressed: _busy || _draftLocked || _step == -2
                    ? null
                    : () => _go(_step - 1),
                icon: const Icon(Iconsax.arrow_left)),
            Expanded(
                child: Text(
                    _step < 0 ? 'Set up your workspace' : _product!.title,
                    style: _text(15, weight: FontWeight.w600),
                    maxLines: 2)),
            TextButton(
                onPressed: _busy ? null : _done,
                child: Text(_result == null ? 'Set up later' : 'Done')),
          ])),
      if (_step >= 0)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step ${_step + 1} of 3',
                  style: _text(12, color: GasPalette.ink2)),
              const SizedBox(height: 8),
              Row(
                  children: List.generate(
                      3,
                      (i) => Expanded(
                              child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                            decoration: BoxDecoration(
                                color: i <= _step
                                    ? GasPalette.primary
                                    : GasPalette.border,
                                borderRadius: BorderRadius.circular(4)),
                          )))),
            ])),
      Expanded(
          child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
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
      )),
      if (_step >= 0) _footer(),
    ]);
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: phone ? Colors.white : GasPalette.page,
          body: SafeArea(
              child: Center(
                  child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            margin: phone ? EdgeInsets.zero : const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: phone ? null : BorderRadius.circular(20),
                border: phone ? null : Border.all(color: GasPalette.border)),
            child: content,
          ))),
        ));
  }

  TextStyle _text(double size,
          {FontWeight weight = FontWeight.w500,
          Color color = GasPalette.ink}) =>
      GoogleFonts.inter(
          fontSize: size, height: 1.45, fontWeight: weight, color: color);

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
        for (final product in ProductCatalog.products)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: GasPalette.border)),
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
                          const Icon(Iconsax.arrow_right_3,
                              size: 18, color: GasPalette.ink2),
                        ]))),
              )),
      ]);

  Widget _setupStep() {
    final registered = _result != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SetupIllustration(type: _type!, step: _step, complete: _hasReading),
      if (_step == 0) ...[
        _heading(
            _isGas
                ? 'Meet your gas scale'
                : _isBottle
                    ? 'Meet your bottle vetting machine'
                    : 'Identify your device',
            'Find the device ID on its label or setup screen. Use that exact ID so readings arrive in the right place.'),
        _field(_id, 'Device ID',
            helper: 'Use the hardware ID, not a name you make up.',
            required: true),
        _field(_name, _isGas ? 'Cylinder name' : 'Device name',
            helper: _isGas
                ? 'For example: Kitchen gas'
                : 'For example: Front counter',
            required: true),
        _field(_location, 'Location (optional)'),
      ] else if (_step == 1 && _isGas) ...[
        _heading('Set your cylinder size',
            'Your scale weighs the cylinder and the gas together. These two values let us show how much gas is left.'),
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
      ] else if (_step == 1) ...[
        _heading(
            'Give it power and a connection',
            _isBottle
                ? 'Power on the bottle vetting machine and use its own setup controls to connect it to your site’s network.'
                : 'Power on the device and follow its installation guide to connect it to your site’s network.'),
        _instruction(
            Iconsax.flash_1,
            'Power on',
            _isBottle
                ? 'Wait for the machine to finish starting. Keep the scanning area clear.'
                : 'Check the power indicator and make sure any sensors are connected.'),
        _instruction(Iconsax.wifi, 'Connect to your network',
            'Use the device’s network settings or your installer’s instructions. Keep this phone connected to the internet too.'),
        _instruction(
            Iconsax.scan,
            _isBottle ? 'Try a bottle scan' : 'Allow it to report',
            _isBottle
                ? 'Once the machine is ready, follow its usual bottle scanning process. Its scan and tray readings will appear after it reports.'
                : 'The dashboard will display readings once the device sends them.'),
        _note(Iconsax.info_circle, 'The device controls its connection',
            'This guide registers the device in your account. It does not change the machine’s network settings.'),
      ] else if (!registered) ...[
        _heading(
            'Ready to link',
            _isGas
                ? 'Save your cylinder, then we’ll help connect the scale to Wi-Fi using Bluetooth on your phone.'
                : 'Link this hardware ID to your workspace, then check for its first reading.'),
        _review(),
        const SizedBox(height: 20),
        _note(Iconsax.shield_tick, 'Your device, your readings',
            'Only this device’s measurements will appear in its dashboard. You can set your own alert levels after setup.'),
      ] else ...[
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

  Widget _instruction(IconData icon, String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 24, color: GasPalette.series),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: _text(16, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text, style: _text(14, color: GasPalette.ink2)),
              ])),
        ]),
      );

  Widget _note(IconData icon, String title, String text,
          {bool error = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: error ? const Color(0xFFFFF1EE) : GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: error ? const Color(0xFFF4CCC4) : GasPalette.border)),
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

  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: GasPalette.border))),
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
