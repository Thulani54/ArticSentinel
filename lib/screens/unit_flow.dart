import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../gasmon/gas_theme.dart';
import '../models/unit.dart';
import '../onboarding/device_setup_guide.dart';
import '../onboarding/setup_flow_frame.dart';
import '../widgets/mobile_forms.dart';

/// Sends the unit payload; returns normally on success. Throw a [String] to
/// show that message (e.g. the server's "Serial number already exists").
typedef UnitSaver = Future<void> Function(Map<String, dynamic> data);

/// Add or edit a refrigeration unit in three short steps, matching the
/// add-device flow: identify it from its rating plate, say where it is, then
/// its refrigeration details. Adding walks the steps in order; editing allows
/// Save from any step.
class UnitFlowScreen extends StatefulWidget {
  const UnitFlowScreen({super.key, this.unit, required this.onSave});

  /// null = add a new unit.
  final Unit? unit;
  final UnitSaver onSave;

  @override
  State<UnitFlowScreen> createState() => _UnitFlowScreenState();
}

class _Choice {
  const _Choice(this.value, this.label, [this.hint]);
  final String value;
  final String label;
  final String? hint;
}

const _refrigerants = [
  _Choice('r404a', 'R404A', 'Common in freezers and cold rooms'),
  _Choice('r134a', 'R134a', 'Common in fridges and chillers'),
  _Choice('r410a', 'R410A'),
  _Choice('r22', 'R22', 'Older systems'),
  _Choice('other', 'Other'),
];
const _compressors = [
  _Choice('scroll', 'Scroll'),
  _Choice('reciprocating', 'Reciprocating'),
  _Choice('harmonic', 'Harmonic'),
];
const _controls = [
  _Choice('electronic', 'Electronic'),
  _Choice('mechanical', 'Mechanical')
];
const _valves = [
  _Choice('internal', 'Internal'),
  _Choice('external', 'External')
];
const _dryers = [_Choice('flare', 'Flare'), _Choice('swage', 'Swage')];
const _fans = [
  _Choice('axial', 'Axial'),
  _Choice('centrifugal', 'Centrifugal'),
  _Choice('mixed_flow', 'Mixed flow'),
];
const _statuses = [
  _Choice('operational', 'Operational'),
  _Choice('maintenance', 'In maintenance'),
  _Choice('decommissioned', 'Decommissioned'),
];

class _UnitFlowScreenState extends State<UnitFlowScreen> {
  static const _steps = ['Identify', 'Location', 'Refrigeration'];

  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final Map<String, TextEditingController> _c;
  late final Map<String, String?> _pick;
  late final Map<String, DateTime?> _dates;
  int _step = 0;
  bool _saving = false;
  bool _moreSpecs = false;
  String? _error;

  bool get _editing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    final u = widget.unit;
    String n(double? v) =>
        v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');
    _c = {
      'name': u?.name ?? '',
      'model': u?.modelNumber ?? '',
      'serial': u?.serialNumber ?? '',
      'year': u == null ? '' : '${u.year}',
      'location': u?.location ?? '',
      'notes': u?.notes ?? '',
      'compressor_model': u?.compressorModel ?? '',
      'compressor_hp': n(u?.compressorHp),
      'compressor_amp_rating': n(u?.compressorAmpRating),
      'evaporator_model': u?.evaporatorModel ?? '',
      'evaporator_length': n(u?.evaporatorLength),
      'evaporator_width': n(u?.evaporatorWidth),
      'evaporator_height': n(u?.evaporatorHeight),
      'condenser_fan_count': u == null ? '' : '${u.condenserFanCount}',
      'condenser_fan_power': u?.condenserFanPower ?? '',
      'evaporator_fan_count': u == null ? '' : '${u.evaporatorFanCount}',
      'evaporator_fan_power': u?.evaporatorFanPower ?? '',
      'orifice_size': u?.orificeSize ?? '',
      'dryer_size': u?.dryerSize ?? '',
      'oil_separator': u?.oilSeparator ?? '',
      'liquid_receiver': u?.liquidReceiver ?? '',
      'accumulator_capacity': u?.accumulatorCapacity ?? '',
    }.map((k, v) => MapEntry(k, TextEditingController(text: v)));
    String? raw(String? v) => (v == null || v.isEmpty) ? null : v;
    _pick = {
      'status': raw(u?.statusValue) ?? 'operational',
      'refrigerant_type': raw(u?.refrigerantTypeValue),
      'compressor_type': raw(u?.compressorTypeValue),
      'control_type': raw(u?.controlTypeValue),
      'expansion_valve_type': raw(u?.expansionValveTypeValue),
      'dryer_type': raw(u?.dryerTypeValue),
      'condenser_fan_type': raw(u?.condenserFanTypeValue),
      'evaporator_fan_type': raw(u?.evaporatorFanTypeValue),
    };
    DateTime? d(String? v) => v == null ? null : DateTime.tryParse(v);
    _dates = {
      'last_maintenance_date': d(u?.lastMaintenanceDate),
      'last_repaired_date': d(u?.lastRepairedDate),
      'next_scheduled_maintenance': d(u?.nextScheduledMaintenance),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _t(String k) => _c[k]!.text.trim();

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  ({int step, String message})? _problem() {
    if (_t('name').isEmpty) return (step: 0, message: 'Give the unit a name.');
    if (_t('model').isEmpty)
      return (
        step: 0,
        message: 'Enter the model number from the rating plate.'
      );
    if (_t('serial').isEmpty)
      return (
        step: 0,
        message: 'Enter the serial number from the rating plate.'
      );
    final year = int.tryParse(_t('year'));
    if (_t('year').isNotEmpty &&
        (year == null || year < 1970 || year > DateTime.now().year + 1)) {
      return (
        step: 0,
        message:
            'Enter the year it was made or installed, e.g. ${DateTime.now().year}.'
      );
    }
    if (_pick['refrigerant_type'] == null) {
      return (
        step: 2,
        message: 'Choose the refrigerant. It’s printed on the rating plate.'
      );
    }
    for (final k in const [
      'compressor_hp',
      'compressor_amp_rating',
      'evaporator_length',
      'evaporator_width',
      'evaporator_height',
    ]) {
      if (_t(k).isNotEmpty &&
          (double.tryParse(_t(k).replaceAll(',', '.')) ?? -1) < 0) {
        return (
          step: 2,
          message: 'Specifications must be numbers, for example 2.5.'
        );
      }
    }
    return null;
  }

  /// Steps before the last only check their own fields when adding.
  bool _stepValid(int step) {
    final p = _problem();
    if (p != null && p.step == step) {
      setState(() => _error = p.message);
      _form.currentState?.validate();
      return false;
    }
    return true;
  }

  Map<String, dynamic> _payload() {
    String day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    double? num(String k) =>
        _t(k).isEmpty ? null : double.tryParse(_t(k).replaceAll(',', '.'));
    final data = <String, dynamic>{
      'name': _t('name'),
      'model_number': _t('model'),
      'serial_number': _t('serial'),
      'year': int.tryParse(_t('year')) ?? DateTime.now().year,
      'location': _t('location'),
      'notes': _t('notes'),
      'status': _pick['status'],
    };
    // Only what was chosen or typed: the server keeps its own defaults
    // for anything left as "not sure" when adding.
    _pick.forEach((k, v) {
      if (k != 'status' && v != null) data[k] = v;
    });
    for (final k in const [
      'compressor_model',
      'evaporator_model',
      'condenser_fan_power',
      'evaporator_fan_power',
      'orifice_size',
      'dryer_size',
      'oil_separator',
      'liquid_receiver',
      'accumulator_capacity'
    ]) {
      if (_t(k).isNotEmpty) data[k] = _t(k);
    }
    for (final k in const [
      'compressor_hp',
      'compressor_amp_rating',
      'evaporator_length',
      'evaporator_width',
      'evaporator_height'
    ]) {
      if (num(k) != null) data[k] = num(k);
    }
    for (final k in const ['condenser_fan_count', 'evaporator_fan_count']) {
      final v = int.tryParse(_t(k));
      if (v != null) data[k] = v;
    }
    _dates.forEach((k, v) => data[k] = v == null ? null : day(v));
    return data;
  }

  Future<void> _save() async {
    if (_saving) return;
    final p = _problem();
    if (p != null) {
      if (p.step != _step) _go(p.step);
      setState(() => _error = p.message);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _form.currentState?.validate());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_payload());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = e is String
          ? e
          : 'The unit could not be saved. Check your connection and try again — your entries are kept.';
      setState(() {
        _saving = false;
        _error = message;
        // Send the user to the field the server complained about.
        if (message.toLowerCase().contains('serial') ||
            message.toLowerCase().contains('name')) _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _steps.length - 1;
    return PopScope(
      canPop: !_saving,
      child: SetupFlowFrame(
        title: _editing ? 'Edit ${widget.unit!.name}' : 'Add a unit',
        deviceType: 'device1',
        deviceLabel: _editing
            ? '${widget.unit!.modelNumber} · ${widget.unit!.serialNumber}'
            : 'A refrigeration system your devices monitor',
        steps: _steps,
        step: _step,
        onStepTap: _editing && !_saving ? _go : null,
        busy: _saving,
        onBack: _step == 0
            ? () => Navigator.of(context).maybePop()
            : () => _go(_step - 1),
        closeLabel: 'Cancel',
        onClose: () => Navigator.of(context).maybePop(),
        scrollController: _scroll,
        footer: _footer(last),
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
                      0 => _identify(),
                      1 => _location(),
                      _ => _refrigeration(),
                    },
                    if (_error != null) ...[
                      const SizedBox(height: 12),
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

  Widget _primary(String label, VoidCallback onPressed, {Key? key}) =>
      FilledButton(
        key: key,
        style: FilledButton.styleFrom(
            backgroundColor: GasPalette.primary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder()),
        onPressed: _saving ? null : onPressed,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      );

  Widget _footer(bool last) {
    if (!_editing) {
      return last
          ? _primary('Add unit', _save, key: const ValueKey('unit-save'))
          : _primary('Continue', () {
              if (_stepValid(_step)) _go(_step + 1);
            });
    }
    final save =
        _primary('Save changes', _save, key: const ValueKey('unit-save'));
    if (last) return save;
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder()),
          onPressed: _saving ? null : () => _go(_step + 1),
          child: const Text('Next'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: save),
    ]);
  }

  // --- Steps -------------------------------------------------------------------

  Widget _heading(String title, String intro) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: SetupFlowFrame.text(26, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(intro, style: SetupFlowFrame.text(15, color: GasPalette.ink2)),
        ]),
      );

  List<Widget> _identify() {
    final year = DateTime.now().year;
    return [
      SetupScene(
          asset: DeviceSetupGuide.scene('rating-plate'), deviceType: 'device1'),
      _heading(_editing ? 'Identify the unit' : 'Find the rating plate',
          'The manufacturer’s plate on the condensing unit lists its model, serial number and refrigerant. Copy them exactly.'),
      if (!_editing) ...const [
        SetupInstructionTile(
            number: 1,
            icon: Iconsax.search_normal,
            title: 'Look on the condensing unit',
            text:
                'The plate is usually a metal or foil label on the outdoor or compressor unit.'),
        SetupInstructionTile(
            number: 2,
            icon: Iconsax.camera,
            title: 'Take a photo of it',
            text: 'Handy for your records and for technicians later.'),
      ],
      _field('name', 'Unit name',
          helper: 'What your team calls it, e.g. Cold room 1', required: true),
      _pair(_field('model', 'Model number', required: true),
          _field('serial', 'Serial number', required: true)),
      _label('Year made or installed'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final y in [year, year - 1, year - 2, year - 5])
          ChoiceChip(
            label: Text('$y'),
            selected: _t('year') == '$y',
            onSelected:
                _saving ? null : (_) => setState(() => _c['year']!.text = '$y'),
          ),
      ]),
      const SizedBox(height: 14),
      _field('year', 'Year',
          numeric: true, helper: 'Leave empty to use $year.'),
      if (_editing) ...[
        _label('Status'),
        _chips('status', _statuses, allowNone: false),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _location() => [
        SetupScene(
            asset: DeviceSetupGuide.scene('location'), deviceType: 'device1'),
        _heading('Where is it?',
            'A clear location gets technicians to the right unit first time, and names it in alerts.'),
        _field('location', 'Location',
            helper: 'Site, building and room, e.g. Main kitchen, back store'),
        _field('notes', 'Notes for technicians (optional)',
            helper: 'Access, keys, opening hours or anything unusual.',
            lines: 3),
        const SetupNote(
          icon: Iconsax.link,
          title: 'Link monitoring devices',
          text:
              'After saving, open a device in Equipment and choose this unit under “Connected unit”.',
        ),
      ];

  List<Widget> _refrigeration() => [
        SetupScene(
            asset: DeviceSetupGuide.scene('refrigerant'),
            deviceType: 'device1'),
        _heading('Refrigeration details',
            'The refrigerant matters most: it tells technicians what to bring. Leave the rest as “not sure” if you don’t know.'),
        _label('Refrigerant *'),
        _chips('refrigerant_type', _refrigerants, allowNone: false),
        const SizedBox(height: 18),
        _label('Compressor type'),
        _chips('compressor_type', _compressors),
        const SizedBox(height: 18),
        _pair(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Controls'),
            _chips('control_type', _controls),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Expansion valve'),
            _chips('expansion_valve_type', _valves),
          ]),
          stackBelow: 520,
        ),
        const SizedBox(height: 18),
        _field('compressor_model', 'Compressor model'),
        _pair(
            _field('compressor_hp', 'Compressor HP', numeric: true),
            _field('compressor_amp_rating', 'Rated current (A)',
                numeric: true)),
        _moreSpecsSection(),
        const SizedBox(height: 8),
        _label('Service history'),
        _pair(_date('last_maintenance_date', 'Last maintenance'),
            _date('last_repaired_date', 'Last repair'),
            stackBelow: 440),
        _date('next_scheduled_maintenance', 'Next maintenance'),
        if (!_editing) ...[
          const SizedBox(height: 4),
          _review(),
        ],
      ];

  Widget _moreSpecsSection() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GasPalette.border)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _moreSpecs,
            onExpansionChanged: (v) => _moreSpecs = v,
            shape: const RoundedRectangleBorder(),
            title: Text('More specifications',
                style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
            subtitle: Text('Fans, evaporator, dryer and receiver — optional',
                style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              _label('Dryer'),
              _chips('dryer_type', _dryers),
              const SizedBox(height: 14),
              _pair(_field('dryer_size', 'Dryer size'),
                  _field('orifice_size', 'Orifice size')),
              _pair(_field('oil_separator', 'Oil separator'),
                  _field('liquid_receiver', 'Liquid receiver')),
              _field('accumulator_capacity', 'Accumulator capacity'),
              _field('evaporator_model', 'Evaporator model'),
              _pair(_field('evaporator_length', 'Length (m)', numeric: true),
                  _field('evaporator_width', 'Width (m)', numeric: true)),
              _field('evaporator_height', 'Height (m)', numeric: true),
              _label('Condenser fans'),
              _chips('condenser_fan_type', _fans),
              const SizedBox(height: 14),
              _pair(_field('condenser_fan_count', 'How many', numeric: true),
                  _field('condenser_fan_power', 'Power each')),
              _label('Evaporator fans'),
              _chips('evaporator_fan_type', _fans),
              const SizedBox(height: 14),
              _pair(_field('evaporator_fan_count', 'How many', numeric: true),
                  _field('evaporator_fan_power', 'Power each')),
            ],
          ),
        ),
      );

  Widget _review() {
    final refrigerant = _refrigerants
        .where((c) => c.value == _pick['refrigerant_type'])
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: GasPalette.panelAlt, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t('name').isEmpty ? 'New unit' : _t('name'),
            style: SetupFlowFrame.text(18, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Model ${_t('model')} · Serial ${_t('serial')}',
            style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
        if (_t('location').isNotEmpty)
          Text(_t('location'),
              style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
        if (refrigerant != null)
          Text('Refrigerant ${refrigerant.label}',
              style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
      ]),
    );
  }

  // --- Building blocks -------------------------------------------------------

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child:
            Text(text, style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
      );

  Widget _chips(String key, List<_Choice> choices, {bool allowNone = true}) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in choices)
            Tooltip(
              message: c.hint ?? '',
              triggerMode: c.hint == null
                  ? TooltipTriggerMode.manual
                  : TooltipTriggerMode.longPress,
              child: ChoiceChip(
                label: Text(c.label),
                selected: _pick[key] == c.value,
                onSelected: _saving
                    ? null
                    : (on) => setState(() {
                          _pick[key] =
                              on ? c.value : (allowNone ? null : _pick[key]);
                          if (key == 'refrigerant_type') _error = null;
                        }),
              ),
            ),
          if (allowNone)
            ChoiceChip(
              label: const Text('Not sure'),
              selected: _pick[key] == null,
              onSelected:
                  _saving ? null : (_) => setState(() => _pick[key] = null),
            ),
        ],
      );

  Widget _pair(Widget a, Widget b, {double stackBelow = 300}) => LayoutBuilder(
        builder: (context, box) => box.maxWidth < stackBelow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [a, b])
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
          int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: _c[key],
          enabled: !_saving,
          minLines: lines,
          maxLines: lines,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : lines > 1
                  ? TextInputType.multiline
                  : TextInputType.text,
          textInputAction:
              lines > 1 ? TextInputAction.newline : TextInputAction.next,
          onChanged: key == 'year' ||
                  key == 'name' ||
                  key == 'model' ||
                  key == 'serial'
              ? (_) => setState(() {})
              : null,
          decoration: _decoration(label, helper: helper),
          validator: (value) {
            if (required && (value?.trim() ?? '').isEmpty) return 'Required.';
            final p = _problem();
            if (p != null &&
                p.step == _step &&
                key == 'year' &&
                p.message.contains('year')) return p.message;
            return null;
          },
        ),
      );

  Widget _date(String key, String label) {
    final value = _dates[key];
    final shown = value == null ? '' : DateFormat('d MMM yyyy').format(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        key: ValueKey('date-$key-$shown'),
        initialValue: shown,
        readOnly: true,
        enabled: !_saving,
        decoration: _decoration(label,
            suffix: value == null
                ? const Icon(Iconsax.calendar_1, size: 20)
                : Semantics(
                    button: true,
                    label: 'Clear $label',
                    child: InkResponse(
                      radius: 20,
                      onTap: _saving
                          ? null
                          : () => setState(() => _dates[key] = null),
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
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 30),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) setState(() => _dates[key] = picked);
        },
      ),
    );
  }
}
