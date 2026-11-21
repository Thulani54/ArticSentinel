import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../gasmon/gas_theme.dart';
import '../models/device.dart';
import '../models/unit.dart';
import '../onboarding/device_setup_guide.dart';
import '../onboarding/setup_flow_frame.dart';
import '../products/product_catalog.dart';
import '../widgets/device_illustration.dart';
import '../widgets/mobile_forms.dart';

typedef DeviceSaver = Future<void> Function(Device device, String? unitId);

/// Edit a device in three short sections: name and place, how it runs, and
/// hardware and service details. Every section is optional, so Save is always
/// available; Next walks through them in order.
class DeviceEditorScreen extends StatefulWidget {
  const DeviceEditorScreen({
    super.key,
    required this.device,
    required this.onSave,
    this.availableUnits = const [],
    this.onOpenCylinderSetup,
  });

  final Device device;
  final DeviceSaver onSave;
  final List<Unit> availableUnits;

  /// Gas cylinders keep their size and alert levels on the cylinder screen.
  final VoidCallback? onOpenCylinderSetup;

  @override
  State<DeviceEditorScreen> createState() => _DeviceEditorScreenState();
}

class _DeviceEditorScreenState extends State<DeviceEditorScreen> {
  static const _sections = [
    'Name and place',
    'How it runs',
    'Hardware and service'
  ];

  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final Map<String, TextEditingController> _c;
  late bool _active;
  late String _phase;
  String? _unitId;
  int _step = 0;
  bool _saving = false;
  String? _error;

  Device get _d => widget.device;
  String? get _type => _d.deviceType;
  DeviceSetupGuide get _guide => DeviceSetupGuide.forType(_type);
  bool get _isGas => _type == 'gas_cylinder';
  bool get _hasRange =>
      _guide.settings.contains(SetupSetting.temperatureRange) ||
      _type == 'chiller' ||
      _type == 'freezer';
  bool get _hasPower => const {
        'device1',
        'device3',
        'device4',
        'chiller',
        'freezer'
      }.contains(_type);

  @override
  void initState() {
    super.initState();
    String fmt(double? v) => v == null
        ? ''
        : v == v.roundToDouble()
            ? v.toStringAsFixed(0)
            : '$v';
    _c = {
      'name': _d.name,
      'location': _d.location ?? '',
      'building': _d.building ?? '',
      'floor': _d.floor ?? '',
      'room': _d.room ?? '',
      'min': fmt(_d.targetTempMin),
      'max': fmt(_d.targetTempMax),
      'rate': fmt(_d.electricityRate),
      'manufacturer': _d.manufacturer ?? '',
      'model': _d.model ?? '',
      'serial': _d.serialNumber ?? '',
      'product': _d.productId ?? '',
      'capacity': _d.capacity ?? '',
      'installed': _d.installationDate ?? '',
      'warranty': _d.warrantyExpiry ?? '',
      'lastService': _d.lastServiceDate ?? '',
      'nextService': _d.nextServiceDate ?? '',
    }.map((k, v) => MapEntry(k, TextEditingController(text: v)));
    _active = _d.isActive;
    _phase = _d.phaseType == 'three' ? 'three' : 'single';
    _unitId = _d.connectedUnit?.id;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _t(String key) => _c[key]!.text.trim();
  String? _opt(String key) => _t(key).isEmpty ? null : _t(key);
  double? _num(String key) => double.tryParse(_t(key).replaceAll(',', '.'));

  void _go(int step) {
    // Keep entries; only the visible section's fields are validated here.
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Every section's rules, so a problem in a hidden section is still caught.
  ({int step, String message})? _problem() {
    if (_t('name').isEmpty) return (step: 0, message: 'Enter a device name.');
    if (_hasRange) {
      final lo = _num('min'), hi = _num('max');
      if ((_t('min').isEmpty) != (_t('max').isEmpty)) {
        return (
          step: 1,
          message: 'Enter both temperatures, or leave both empty.'
        );
      }
      if ((_t('min').isNotEmpty && lo == null) ||
          (_t('max').isNotEmpty && hi == null)) {
        return (step: 1, message: 'Temperatures must be numbers.');
      }
      if (lo != null && hi != null && hi <= lo) {
        return (
          step: 1,
          message: 'The highest temperature must be above the lowest.'
        );
      }
    }
    if (_t('rate').isNotEmpty && (_num('rate') == null || _num('rate')! < 0)) {
      return (step: 1, message: 'Enter a valid electricity rate.');
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    _form.currentState?.validate();
    final problem = _problem();
    if (problem != null) {
      if (problem.step != _step) _go(problem.step);
      setState(() => _error = problem.message);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _form.currentState?.validate());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final updated = Device(
      id: _d.id,
      companyName: _d.companyName,
      name: _t('name'),
      deviceId: _d.deviceId,
      deviceType: _d.deviceType,
      location: _opt('location'),
      building: _opt('building'),
      floor: _opt('floor'),
      room: _opt('room'),
      targetTempMin: _hasRange ? _num('min') : _d.targetTempMin,
      targetTempMax: _hasRange ? _num('max') : _d.targetTempMax,
      phaseType: _isGas ? _d.phaseType : _phase,
      electricityRate: _hasPower ? _num('rate') : _d.electricityRate,
      voltage: _d.voltage,
      manufacturer: _opt('manufacturer'),
      model: _opt('model'),
      serialNumber: _opt('serial'),
      productId: _opt('product'),
      capacity: _opt('capacity'),
      installationDate: _opt('installed'),
      warrantyExpiry: _opt('warranty'),
      lastServiceDate: _opt('lastService'),
      nextServiceDate: _opt('nextService'),
      isActive: _active,
      isOnline: _d.isOnline,
      lastPing: _d.lastPing,
      isInRepairMode: _d.isInRepairMode,
      repairModeStartedAt: _d.repairModeStartedAt,
      repairModeReason: _d.repairModeReason,
      createdAt: _d.createdAt,
      updatedAt: _d.updatedAt,
      // Cleared when "No unit" is chosen so the save really unlinks it.
      connectedUnit: _unitId == _d.connectedUnit?.id ? _d.connectedUnit : null,
    );
    try {
      await widget.onSave(updated, _unitId);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Your changes could not be saved. Check your connection and try again — nothing was lost.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ProductCatalog.byType(registryType(_type) ?? '');
    return PopScope(
      canPop: !_saving,
      child: SetupFlowFrame(
        title: 'Edit ${_d.name}',
        deviceType: _type,
        deviceLabel:
            '${product?.title ?? deviceIllustrationLabel(_type, fallback: 'Device')} · ${_d.deviceId}',
        steps: _sections,
        step: _step,
        onStepTap: _saving ? null : _go,
        busy: _saving,
        onBack: _step == 0
            ? () => Navigator.of(context).maybePop()
            : () => _go(_step - 1),
        closeLabel: 'Cancel',
        onClose: () => Navigator.of(context).maybePop(),
        scrollController: _scroll,
        footer: _footer(),
        body: Form(
          key: _form,
          child: AnimatedSwitcher(
            duration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ? 0 : 220),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...switch (_step) {
                      0 => _namePlace(),
                      1 => _howItRuns(),
                      _ => _hardware(),
                    },
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: SetupNote(
                            icon: Iconsax.info_circle,
                            title: 'Check this first',
                            text: _error!,
                            tone: SetupNoteTone.error),
                      ),
                    ],
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final last = _step == _sections.length - 1;
    final save = FilledButton(
      key: const ValueKey('editor-save'),
      style: FilledButton.styleFrom(
          backgroundColor: GasPalette.primary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder()),
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Save changes'),
    );
    if (last) return save;
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder()),
          onPressed: _saving ? null : () => _go(_step + 1),
          child: const Text('Next', maxLines: 1),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: save),
    ]);
  }

  // --- Sections --------------------------------------------------------------

  Widget _heading(String title, String intro) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: SetupFlowFrame.text(26, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(intro, style: SetupFlowFrame.text(15, color: GasPalette.ink2)),
        ]),
      );

  List<Widget> _namePlace() => [
        SetupScene(
            asset: DeviceSetupGuide.scene('location'), deviceType: _type),
        _heading('Name and place',
            'Use names your team recognises, so alerts say exactly which unit and where.'),
        _readOnlyId(),
        _field('name', _isGas ? 'Cylinder name' : 'Device name',
            helper: 'For example: Front counter fridge', required: true),
        _field('location', 'Site or area', helper: 'For example: Main kitchen'),
        _pair(_field('building', 'Building'), _field('floor', 'Floor')),
        _field('room', 'Room'),
      ];

  Widget _readOnlyId() => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GasPalette.border)),
        child: Row(children: [
          Icon(Iconsax.cpu, size: 20, color: GasPalette.series),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Device ID',
                  style: SetupFlowFrame.text(12, color: GasPalette.ink2)),
              SelectableText(_d.deviceId,
                  style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
              Text('Set by the hardware, so it can’t be changed here.',
                  style: SetupFlowFrame.text(12, color: GasPalette.ink2)),
            ]),
          ),
          IconButton(
            tooltip: 'Copy device ID',
            icon: const Icon(Iconsax.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _d.deviceId));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Device ID copied')));
            },
          ),
        ]),
      );

  List<Widget> _howItRuns() => [
        SetupScene(
            asset: DeviceSetupGuide.scene(_isGas
                ? 'cylinder-on-scale'
                : _hasRange
                    ? 'safe-range'
                    : _guide.fitScene),
            deviceType: _type),
        _heading(
            'How it runs',
            _isGas
                ? 'Whether this cylinder is in use, and where to change its size and gas alerts.'
                : _hasRange
                    ? 'The safe range flags readings that drift, and helps the AI assistant judge this unit.'
                    : 'Whether this device is in service, and how it is supplied.'),
        _serviceSwitch(),
        if (_hasRange) ..._rangeSettings(),
        if (!_isGas && _hasPower) ...[
          _label('Supply'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in const [
              ('single', 'Single phase'),
              ('three', 'Three phase')
            ])
              ChoiceChip(
                  label: Text(option.$2),
                  selected: _phase == option.$1,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _phase = option.$1)),
          ]),
          const SizedBox(height: 20),
          _field('rate', 'Electricity rate (per kWh)',
              helper: 'Used for energy cost estimates.', numeric: true),
        ],
        if (_isGas)
          SetupNote(
            icon: Iconsax.weight,
            title: 'Cylinder size and gas alerts',
            text:
                'Capacity, empty weight, price and alert levels live on the cylinder screen, next to the gas gauge.',
          ),
        if (_isGas && widget.onOpenCylinderSetup != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder()),
            onPressed: _saving ? null : widget.onOpenCylinderSetup,
            icon: const Icon(Iconsax.setting_4),
            label: const Text('Open cylinder setup'),
          ),
        ],
        if (_guide.safety != null && !_isGas) ...[
          const SizedBox(height: 16),
          SetupNote(
              icon: Iconsax.danger,
              title: 'Safety first',
              text: _guide.safety!,
              tone: SetupNoteTone.safety),
        ],
      ];

  Widget _serviceSwitch() => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Material(
          color: GasPalette.panelAlt,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: GasPalette.border)),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile.adaptive(
            value: _active,
            onChanged: _saving ? null : (v) => setState(() => _active = v),
            title: Text('In service',
                style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
            subtitle: Text(
                _active
                    ? 'Monitored and counted in your dashboard.'
                    : 'Paused: kept for its history, not counted as offline.',
                style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
          ),
        ),
      );

  List<Widget> _rangeSettings() {
    final presets = _guide.presets.isNotEmpty
        ? _guide.presets
        : const [
            RangePreset('Chiller', 0, 5),
            RangePreset('Freezer', -22, -18)
          ];
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
    return [
      _label('Safe temperature range'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in presets)
          ChoiceChip(
            label: Text('${p.label} ${fmt(p.min)} to ${fmt(p.max)} °C'),
            selected: _num('min') == p.min && _num('max') == p.max,
            onSelected: _saving
                ? null
                : (_) => setState(() {
                      _c['min']!.text = fmt(p.min);
                      _c['max']!.text = fmt(p.max);
                    }),
          ),
      ]),
      const SizedBox(height: 16),
      _pair(_field('min', 'Lowest (°C)', numeric: true, signed: true),
          _field('max', 'Highest (°C)', numeric: true, signed: true)),
    ];
  }

  List<Widget> _hardware() => [
        SetupScene(asset: DeviceSetupGuide.scene('details'), deviceType: _type),
        _heading('Hardware and service',
            'Model and service dates help your technicians and keep reminders accurate.'),
        _pair(_field('manufacturer', 'Manufacturer'), _field('model', 'Model')),
        _pair(
            _field('serial', 'Serial number'), _field('product', 'Product ID')),
        if (!_isGas)
          _field('capacity', 'Capacity', helper: 'For example: 500 L or 2 HP'),
        _label('Service dates'),
        _pair(
            _date('installed', 'Installed'), _date('warranty', 'Warranty ends'),
            stackBelow: 440),
        _pair(_date('lastService', 'Last service'),
            _date('nextService', 'Next service'),
            stackBelow: 440),
        if (widget.availableUnits.isNotEmpty) ...[
          _label('Connected unit'),
          DropdownButtonFormField<String?>(
            initialValue: widget.availableUnits.any((u) => u.id == _unitId)
                ? _unitId
                : null,
            isExpanded: true,
            style: SetupFlowFrame.text(15),
            decoration: _decoration('Unit this device monitors'),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('No unit')),
              for (final u in widget.availableUnits)
                DropdownMenuItem<String?>(
                    value: u.id,
                    child: Text(u.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _saving ? null : (v) => setState(() => _unitId = v),
          ),
          const SizedBox(height: 20),
        ],
      ];

  // --- Fields ----------------------------------------------------------------

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child:
            Text(text, style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
      );

  /// Two fields side by side when there's room, stacked on narrow phones.
  Widget _pair(Widget a, Widget b, {double stackBelow = 300}) => LayoutBuilder(
        builder: (context, box) => box.maxWidth < stackBelow
            ? Column(children: [a, b])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: a),
                const SizedBox(width: 12),
                Expanded(child: b),
              ]),
      );

  InputDecoration _decoration(String label, {String? helper, Widget? suffix}) {
    final base = mobileInputDecoration(
        context,
        InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          filled: true,
          fillColor: GasPalette.panelAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
        ));
    // Added after the shared phone styling, which turns field icons into
    // text actions; dates read better with a calendar / clear icon.
    return suffix == null
        ? base
        : base.copyWith(
            suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6), child: suffix));
  }

  Widget _field(String key, String label,
          {String? helper,
          bool required = false,
          bool numeric = false,
          bool signed = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: _c[key],
          enabled: !_saving,
          keyboardType: numeric
              ? TextInputType.numberWithOptions(decimal: true, signed: signed)
              : TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged:
              key == 'min' || key == 'max' ? (_) => setState(() {}) : null,
          decoration: _decoration(label, helper: helper),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) {
              return 'Enter ${label.toLowerCase()}.';
            }
            final problem = _problem();
            if (problem != null && problem.step == _step) {
              final mine =
                  (key == 'name' && problem.message.contains('name')) ||
                      ((key == 'min' || key == 'max') &&
                          problem.message.contains('emperature')) ||
                      (key == 'rate' && problem.message.contains('rate'));
              if (mine) return problem.message;
            }
            return null;
          },
        ),
      );

  Widget _date(String key, String label) {
    final controller = _c[key]!;
    DateTime? parsed() => DateTime.tryParse(controller.text.trim());
    final shown =
        parsed() == null ? '' : DateFormat('d MMM yyyy').format(parsed()!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        key: ValueKey('date-$key-$shown'),
        initialValue: shown,
        readOnly: true,
        enabled: !_saving,
        decoration: _decoration(label,
            suffix: controller.text.isEmpty
                ? const Icon(Iconsax.calendar_1, size: 20)
                : Semantics(
                    button: true,
                    label: 'Clear $label',
                    child: InkResponse(
                      radius: 20,
                      onTap: _saving
                          ? null
                          : () => setState(() => controller.clear()),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Iconsax.close_circle,
                            size: 20, color: GasPalette.ink2),
                      ),
                    ),
                  )),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: parsed() ?? now,
            firstDate: DateTime(now.year - 30),
            lastDate: DateTime(now.year + 30),
          );
          if (picked != null) {
            setState(() =>
                controller.text = DateFormat('yyyy-MM-dd').format(picked));
          }
        },
      ),
    );
  }
}

/// Product catalogue key for older device_type values.
String? registryType(String? type) =>
    const {'chiller': 'device1', 'freezer': 'device1'}[type] ?? type;
