import '../widgets/app_tone.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../models/device.dart';
import '../onboarding/device_setup_guide.dart';
import '../onboarding/setup_flow_frame.dart';
import '../services/shared_preferences.dart';
import '../services/unit_links.dart';
import '../widgets/device_illustration.dart';
import '../widgets/mobile_forms.dart';
import '../widgets/unit_link_sheets.dart';

class _MaintenanceKind {
  const _MaintenanceKind(this.id, this.name, this.category);
  final String id;
  final String name;
  final String category;
}

/// Schedule one maintenance job in three steps: choose the equipment (a unit
/// through one of its devices, or a device with no unit), say what and when,
/// then optional extras and a review.
///
/// Maintenance is recorded against a device; for a unit we use the device
/// that monitors it (asking which one when there are several).
class ScheduleMaintenanceScreen extends StatefulWidget {
  const ScheduleMaintenanceScreen({super.key, this.recurring = false});

  /// Create a repeating schedule instead of a single job.
  final bool recurring;

  @override
  State<ScheduleMaintenanceScreen> createState() =>
      _ScheduleMaintenanceScreenState();
}

class _ScheduleMaintenanceScreenState extends State<ScheduleMaintenanceScreen> {
  List<String> get _steps => widget.recurring
      ? const ['Equipment', 'Type and repeat', 'Review']
      : const ['Equipment', 'What and when', 'Review'];
  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('quarterly', 'Every 3 months'),
    ('semi_annual', 'Every 6 months'),
    ('annual', 'Yearly'),
    ('custom', 'Every … days'),
  ];
  String _frequency = 'monthly';
  final _customDays = TextEditingController();
  static const _priorities = [
    ('low', 'Low'),
    ('normal', 'Normal'),
    ('high', 'High'),
    ('critical', 'Critical')
  ];

  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController();
  final _cost = TextEditingController();
  final _contractor = TextEditingController();
  final _safety = TextEditingController();
  final _newItem = TextEditingController();

  List<Device> _devices = [];
  List<UnitSummary> _units = [];
  List<_MaintenanceKind> _kinds = [];
  List<(String, String)> _people = [];
  bool _loading = true;
  String? _loadError;

  int _step = 0;
  int? _deviceId;
  String? _kindId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _priority = 'normal';
  String? _assignee;
  final List<(String, bool)> _checklist = [];
  bool _descriptionEdited = false;
  bool _saving = false;
  String? _error;
  String? _requestFingerprint;
  String? _requestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _customDays,
      _search,
      _description,
      _duration,
      _cost,
      _contractor,
      _safety,
      _newItem
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
    };
  }

  String get _business => '${Constants.myBusiness.businessUid}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final headers = await _headers();
      final results = await Future.wait([
        http
            .post(Uri.parse('${Constants.articBaseUrl2}api/devices/list/'),
                headers: headers,
                body: jsonEncode(
                    {'business_id': _business, 'include_unit_details': true}))
            .timeout(const Duration(seconds: 20)),
        http
            .get(Uri.parse('${Constants.articBaseUrl2}api/maintenance/types/'),
                headers: headers)
            .timeout(const Duration(seconds: 20)),
        http
            .get(
                Uri.parse(
                    '${Constants.articBaseUrl2}api/maintenance/assignable-users/?business_id=$_business'),
                headers: headers)
            .timeout(const Duration(seconds: 20)),
      ]);
      if (results.any((r) => r.statusCode != 200)) throw StateError('setup');
      final devices = (jsonDecode(results[0].body)['devices'] as List)
          .map((d) => Device.fromJson(Map<String, dynamic>.from(d as Map)))
          .where((d) => d.id != null)
          .toList();
      final kinds = (jsonDecode(results[1].body)['maintenance_types'] as List)
          .map((t) => _MaintenanceKind('${t['id']}', '${t['name'] ?? ''}',
              '${t['category_display'] ?? t['category'] ?? ''}'))
          .toList();
      final people = (jsonDecode(results[2].body)['users'] as List)
          .map((u) => (
                '${u['id']}',
                '${u['full_name'] ?? u['username'] ?? 'Team member'}'
              ))
          .toList();
      // Units are optional extra context: devices already carry their unit.
      List<UnitSummary> units = [];
      try {
        units = await UnitLinks.units();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _kinds = kinds;
        _people = people;
        _units = units;
        _loading = false;
        if (_deviceId != null && !devices.any((d) => d.id == _deviceId))
          _deviceId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            'Unable to load maintenance setup. Check your connection and retry.';
      });
    }
  }

  Device? get _device => _devices.where((d) => d.id == _deviceId).firstOrNull;
  _MaintenanceKind? get _kind =>
      _kinds.where((k) => k.id == _kindId).firstOrNull;

  String _equipmentLabel(Device d) =>
      d.connectedUnit == null ? d.name : '${d.connectedUnit!.name} (${d.name})';

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _continue() {
    if (_step == 0 && _deviceId == null) {
      setState(() => _error = 'Choose the equipment that needs maintenance.');
      return;
    }
    if (_step == 1) {
      if (_kindId == null) {
        setState(() => _error = 'Choose the type of maintenance.');
        return;
      }
      if (!(_form.currentState?.validate() ?? false)) return;
    }
    _go(_step + 1);
  }

  void _suggestDescription() {
    if (_descriptionEdited) return;
    final kind = _kind, device = _device;
    if (kind != null && device != null)
      _description.text = '${kind.name} — ${_equipmentLabel(device)}';
  }

  Future<void> _submit() async {
    if (widget.recurring) return _submitSchedule();
    final device = _device, kind = _kind;
    if (device == null || kind == null || _description.text.trim().isEmpty) {
      _go(device == null ? 0 : 1);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final when =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    double? number(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final payload = <String, dynamic>{
      'device_id': device.id,
      'maintenance_type_id': kind.id,
      'scheduled_date': when.toUtc().toIso8601String(),
      'work_description': _description.text.trim(),
      'status': 'scheduled',
      'priority': _priority,
      if (_assignee != null)
        'assigned_to_id': int.tryParse(_assignee!) ?? _assignee,
      if (number(_cost) != null) 'estimated_cost': number(_cost),
      if (number(_duration) != null)
        'estimated_duration_hours': number(_duration),
      if (_contractor.text.trim().isNotEmpty)
        'external_contractor': _contractor.text.trim(),
      if (_safety.text.trim().isNotEmpty)
        'safety_precautions': _safety.text.trim(),
      if (_checklist.isNotEmpty)
        'checklist_items': [
          for (final (text, critical) in _checklist)
            {'description': text, 'is_critical': critical}
        ],
    };
    // Same entries retried after a lost response reuse one operation ID, so
    // the server never creates the job twice.
    final fingerprint = jsonEncode(payload);
    if (fingerprint != _requestFingerprint) {
      _requestFingerprint = fingerprint;
      _requestId = const Uuid().v4();
    }
    try {
      final r = await http
          .post(Uri.parse('${Constants.articBaseUrl2}api/maintenance/create/'),
              headers: await _headers(),
              body: jsonEncode({...payload, 'client_request_id': _requestId}))
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (r.statusCode == 201) {
        Navigator.of(context).pop(true);
        return;
      }
      throw StateError('create');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Unable to confirm the save. Your entries are kept. If the connection was interrupted, check Records before trying again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = _device;
    return PopScope(
      canPop: !_saving,
      child: SetupFlowFrame(
        title:
            widget.recurring ? 'Recurring maintenance' : 'Schedule maintenance',
        deviceType: device?.deviceType ?? 'device1',
        deviceLabel: device == null
            ? 'Plan a job for a unit or device'
            : _equipmentLabel(device),
        steps: _steps,
        step: _step,
        busy: _saving,
        onBack: _step == 0
            ? () => Navigator.of(context).maybePop()
            : () => _go(_step - 1),
        closeLabel: 'Cancel',
        onClose: () => Navigator.of(context).maybePop(),
        scrollController: _scroll,
        footer: _loading || _loadError != null || _devices.isEmpty
            ? null
            : FilledButton(
                key: const ValueKey('schedule-primary'),
                style: FilledButton.styleFrom(
                    backgroundColor: GasPalette.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder()),
                onPressed: _saving ? null : (_step == 2 ? _submit : _continue),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_step == 2
                        ? (widget.recurring
                            ? 'Create schedule'
                            : 'Schedule maintenance')
                        : 'Continue'),
              ),
        body: Form(
          key: _form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_loadError != null)
              _emptyOrError(Iconsax.wifi_square, 'Setup didn’t load',
                  _loadError!, 'Retry', _load)
            else if (_devices.isEmpty)
              _emptyOrError(
                  Iconsax.cpu,
                  'No equipment to maintain',
                  'Add a device in Equipment first. Maintenance is scheduled for the equipment it monitors.',
                  null,
                  null)
            else
              ...switch (_step) {
                0 => _equipmentStep(),
                1 => widget.recurring ? _repeatStep() : _whatWhenStep(),
                _ => widget.recurring ? _scheduleReview() : _reviewStep(),
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
    );
  }

  Widget _emptyOrError(IconData icon, String title, String text, String? action,
          VoidCallback? onAction) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icon, size: 40, color: GasPalette.series),
          const SizedBox(height: 12),
          Text(title, style: SetupFlowFrame.text(18, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
          if (action != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(action)),
          ],
        ]),
      );

  Widget _heading(String title, String intro) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: SetupFlowFrame.text(26, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(intro, style: SetupFlowFrame.text(15, color: GasPalette.ink2)),
        ]),
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text.toUpperCase(),
            style: SetupFlowFrame.text(12,
                    weight: FontWeight.w700, color: GasPalette.ink2)
                .copyWith(letterSpacing: .8)),
      );

  // --- Step 1: equipment ---------------------------------------------------

  List<Widget> _equipmentStep() {
    final q = _search.text.trim().toLowerCase();
    bool match(String s) => q.isEmpty || s.toLowerCase().contains(q);
    // Units: every known unit plus any unit a device points at.
    final unitNames = <String, String>{for (final u in _units) u.id: u.name};
    final unitPlaces = <String, String?>{
      for (final u in _units) u.id: u.location
    };
    for (final d in _devices) {
      final u = d.connectedUnit;
      if (u != null) unitNames.putIfAbsent(u.id, () => u.name);
    }
    final byUnit = <String, List<Device>>{
      for (final id in unitNames.keys) id: []
    };
    for (final d in _devices) {
      if (d.connectedUnit != null) byUnit[d.connectedUnit!.id]!.add(d);
    }
    final unitIds = unitNames.keys
        .where((id) =>
            match(unitNames[id]!) ||
            byUnit[id]!.any((d) => match('${d.name} ${d.deviceId}')))
        .toList()
      ..sort((a, b) =>
          unitNames[a]!.toLowerCase().compareTo(unitNames[b]!.toLowerCase()));
    final loose = _devices
        .where((d) =>
            d.connectedUnit == null &&
            match('${d.name} ${d.deviceId} ${d.location ?? ''}'))
        .toList();
    return [
      SetupScene(
          asset: DeviceSetupGuide.scene('details'),
          deviceType: _device?.deviceType),
      _heading('What needs maintenance?',
          'Pick a unit, or a device that isn’t part of a unit. Units list the devices that monitor them.'),
      if (_devices.length + unitNames.length > 6)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: mobileInputDecoration(
                context,
                InputDecoration(
                  hintText: 'Search units and devices',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: GasPalette.panelAlt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32)),
                )),
          ),
        ),
      if (unitIds.isNotEmpty) ...[
        _section('Units'),
        for (final id in unitIds)
          _unitCard(id, unitNames[id]!, unitPlaces[id], byUnit[id]!),
      ],
      if (loose.isNotEmpty) ...[
        _section(unitIds.isEmpty ? 'Devices' : 'Devices without a unit'),
        for (final d in loose)
          _deviceOption(d, d.name,
              '${deviceIllustrationLabel(d.deviceType, fallback: 'Device')} · ${d.deviceId}'),
      ],
      if (unitIds.isEmpty && loose.isEmpty)
        Text('Nothing matches “${_search.text.trim()}”.',
            style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
    ];
  }

  Widget _unitCard(
      String id, String name, String? place, List<Device> devices) {
    final selected = devices.any((d) => d.id == _deviceId);
    final header = Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(12)),
        child: Icon(Iconsax.box_1, color: GasPalette.series, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
          Text(
            [
              if (place != null && place.isNotEmpty) place,
              devices.isEmpty
                  ? 'No device linked'
                  : devices.length == 1
                      ? 'Monitored by ${devices.first.name}'
                      : '${devices.length} devices',
            ].join(' · '),
            style: SetupFlowFrame.text(12.5, color: GasPalette.ink2),
          ),
        ]),
      ),
      if (devices.length == 1)
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? GasPalette.series : GasPalette.ink2),
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? GasPalette.seriesSoft : Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? GasPalette.series : GasPalette.border,
                width: selected ? 1.5 : 1)),
        clipBehavior: Clip.antiAlias,
        child: devices.length == 1
            ? InkWell(
                onTap: () => setState(() {
                  _deviceId = devices.first.id;
                  _error = null;
                  _suggestDescription();
                }),
                child:
                    Padding(padding: const EdgeInsets.all(12), child: header),
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (devices.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              if (await showLinkDevicesToUnit(context,
                                  unitId: id, unitName: name)) _load();
                            },
                            icon: const Icon(Iconsax.link_2, size: 18),
                            label: const Text('Link a device to schedule'),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 6),
                        Text('Which device should the job be recorded against?',
                            style: SetupFlowFrame.text(12.5,
                                color: GasPalette.ink2)),
                        for (final d in devices) _deviceRow(d),
                      ],
                    ]),
              ),
      ),
    );
  }

  Widget _deviceRow(Device d) {
    final selected = _deviceId == d.id;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        _deviceId = d.id;
        _error = null;
        _suggestDescription();
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(children: [
          DeviceIllustration(type: d.deviceType, size: 32),
          const SizedBox(width: 10),
          Expanded(
              child: Text('${d.name} · ${d.deviceId}',
                  style: SetupFlowFrame.text(14))),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? GasPalette.series : GasPalette.ink2),
        ]),
      ),
    );
  }

  Widget _deviceOption(Device d, String title, String subtitle) {
    final selected = _deviceId == d.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? GasPalette.seriesSoft : Tone.bg(Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? GasPalette.series : GasPalette.border,
                width: selected ? 1.5 : 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() {
            _deviceId = d.id;
            _error = null;
            _suggestDescription();
          }),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              DeviceIllustration(type: d.deviceType, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style:
                              SetupFlowFrame.text(15, weight: FontWeight.w700)),
                      Text(subtitle,
                          style: SetupFlowFrame.text(12.5,
                              color: GasPalette.ink2)),
                    ]),
              ),
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? GasPalette.series : GasPalette.ink2),
            ]),
          ),
        ),
      ),
    );
  }

  // --- Step 2: what and when ----------------------------------------------

  List<Widget> _whatWhenStep() {
    final today = DateUtils.dateOnly(DateTime.now());
    final quick = [
      ('Today', today),
      ('Tomorrow', today.add(const Duration(days: 1))),
      ('In a week', today.add(const Duration(days: 7))),
    ];
    final isQuick = quick.any((q) => DateUtils.isSameDay(q.$2, _date));
    return [
      _heading('What and when',
          'Choose the type of job, then when it should happen.'),
      _section('Type of maintenance'),
      if (_kinds.isEmpty)
        Text('No maintenance types are set up yet.',
            style: SetupFlowFrame.text(14, color: GasPalette.ink2))
      else
        for (final category in {for (final k in _kinds) k.category}) ...[
          if (category.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(category,
                  style: SetupFlowFrame.text(13,
                      weight: FontWeight.w600, color: GasPalette.ink2)),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in _kinds.where((k) => k.category == category))
              ChoiceChip(
                label: Text(k.name),
                selected: _kindId == k.id,
                onSelected: (_) => setState(() {
                  _kindId = k.id;
                  _error = null;
                  _suggestDescription();
                }),
              ),
          ]),
          const SizedBox(height: 8),
        ],
      const SizedBox(height: 18),
      _section('Date and time'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (label, day) in quick)
          ChoiceChip(
            label: Text(label),
            selected: DateUtils.isSameDay(day, _date),
            onSelected: (_) => setState(() => _date = day),
          ),
        ActionChip(
          avatar: const Icon(Iconsax.calendar_1, size: 18),
          label: Text(
              isQuick ? 'Pick a date' : DateFormat('EEE d MMM').format(_date)),
          onPressed: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: today.subtract(const Duration(days: 30)),
                lastDate: today.add(const Duration(days: 730)));
            if (picked != null) setState(() => _date = picked);
          },
        ),
        ActionChip(
          avatar: const Icon(Iconsax.clock, size: 18),
          label: Text(_time.format(context)),
          onPressed: () async {
            final picked =
                await showTimePicker(context: context, initialTime: _time);
            if (picked != null) setState(() => _time = picked);
          },
        ),
      ]),
      const SizedBox(height: 18),
      _section('Priority'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (value, label) in _priorities)
          ChoiceChip(
              label: Text(label),
              selected: _priority == value,
              onSelected: (_) => setState(() => _priority = value)),
      ]),
      const SizedBox(height: 18),
      _section('Work to do'),
      TextFormField(
        key: const ValueKey('maintenance-work'),
        controller: _description,
        minLines: 2,
        maxLines: 4,
        onChanged: (_) => _descriptionEdited = true,
        decoration: _decoration('Description',
            helper: 'What the technician should do or check.'),
        validator: (v) =>
            (v?.trim() ?? '').isEmpty ? 'Describe the work.' : null,
      ),
      const SizedBox(height: 18),
      _section('Assign to'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: const Text('Unassigned'),
            selected: _assignee == null,
            onSelected: (_) => setState(() => _assignee = null)),
        for (final (id, name) in _people)
          ChoiceChip(
              label: Text(name),
              selected: _assignee == id,
              onSelected: (_) => setState(() => _assignee = id)),
      ]),
    ];
  }

  // --- Step 3: extras and review -------------------------------------------

  List<Widget> _reviewStep() {
    final device = _device!, kind = _kind!;
    final when =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final person = _people.where((p) => p.$1 == _assignee).firstOrNull?.$2;
    return [
      _heading('Review',
          'Add anything the technician should know, then schedule it.'),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DeviceIllustration(type: device.deviceType, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kind.name,
                  style: SetupFlowFrame.text(17, weight: FontWeight.w700)),
              Text(_equipmentLabel(device), style: SetupFlowFrame.text(14)),
              const SizedBox(height: 6),
              Text(
                  '${DateFormat('EEEE d MMMM, HH:mm').format(when)} · ${_priorities.firstWhere((p) => p.$1 == _priority).$2} priority',
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
              Text(person == null ? 'Unassigned' : 'Assigned to $person',
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
            ]),
          ),
          IconButton(
              tooltip: 'Change',
              onPressed: () => _go(1),
              icon: const Icon(Iconsax.edit_2, size: 20)),
        ]),
      ),
      const SizedBox(height: 20),
      _section('Optional details'),
      Row(children: [
        Expanded(child: _field(_duration, 'Hours', numeric: true)),
        const SizedBox(width: 12),
        Expanded(child: _field(_cost, 'Estimated cost', numeric: true)),
      ]),
      _field(_contractor, 'External contractor'),
      _field(_safety, 'Safety precautions', lines: 2),
      _section('Checklist'),
      for (var i = 0; i < _checklist.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_checklist[i].$2 ? Iconsax.danger : Iconsax.tick_square,
              color: _checklist[i].$2 ? GasPalette.critInk : GasPalette.series),
          title: Text(_checklist[i].$1, style: SetupFlowFrame.text(14)),
          subtitle: _checklist[i].$2
              ? Text('Critical',
                  style: SetupFlowFrame.text(12, color: GasPalette.critInk))
              : null,
          trailing: IconButton(
              tooltip: 'Remove',
              onPressed: () => setState(() => _checklist.removeAt(i)),
              icon: const Icon(Icons.close_rounded, size: 20)),
        ),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _newItem,
            onSubmitted: (_) => _addItem(false),
            decoration: _decoration('Add a checklist item'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
            tooltip: 'Add item',
            onPressed: () => _addItem(false),
            icon: const Icon(Icons.add)),
        IconButton(
            tooltip: 'Add as critical',
            onPressed: () => _addItem(true),
            icon: const Icon(Iconsax.danger)),
      ]),
    ];
  }

  void _addItem(bool critical) {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add((text, critical));
      _newItem.clear();
    });
  }

  InputDecoration _decoration(String label, {String? helper}) =>
      mobileInputDecoration(
          context,
          InputDecoration(
            labelText: label,
            helperText: helper,
            filled: true,
            fillColor: GasPalette.panelAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
          ));

  Widget _field(TextEditingController c, String label,
          {bool numeric = false, int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          decoration: _decoration(label),
        ),
      );

  // --- Recurring schedules -------------------------------------------------

  String get _repeatLabel => _frequency == 'custom'
      ? 'every ${_customDays.text.trim()} days'
      : switch (_frequency) {
          'daily' => 'every day',
          'weekly' => 'every week',
          'monthly' => 'every month (30 days)',
          'quarterly' => 'every 3 months',
          'semi_annual' => 'every 6 months',
          _ => 'every year',
        };

  List<Widget> _repeatStep() {
    final today = DateUtils.dateOnly(DateTime.now());
    final toMonday = (DateTime.monday - today.weekday + 7) % 7;
    final nextMonday = today.add(Duration(days: toMonday == 0 ? 7 : toMonday));
    final quick = [
      ('Today', today),
      ('Tomorrow', today.add(const Duration(days: 1))),
      ('Next Monday', nextMonday),
    ];
    return [
      _heading('Type and repeat',
          'What the job is, how often it repeats and when it starts.'),
      _section('Type of maintenance'),
      for (final category in {for (final k in _kinds) k.category}) ...[
        if (category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(category,
                style: SetupFlowFrame.text(13,
                    weight: FontWeight.w600, color: GasPalette.ink2)),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in _kinds.where((k) => k.category == category))
            ChoiceChip(
              label: Text(k.name),
              selected: _kindId == k.id,
              onSelected: (_) => setState(() {
                _kindId = k.id;
                _error = null;
              }),
            ),
        ]),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 10),
      _section('Repeats'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (value, label) in _frequencies)
          ChoiceChip(
              label: Text(label),
              selected: _frequency == value,
              onSelected: (_) => setState(() => _frequency = value)),
      ]),
      if (_frequency == 'custom') ...[
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('schedule-custom-days'),
          controller: _customDays,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: _decoration('Repeat every (days)'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            return n == null || n < 1 || n > 730
                ? 'Enter 1 to 730 days.'
                : null;
          },
        ),
      ],
      const SizedBox(height: 18),
      _section('First job'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (label, day) in quick)
          ChoiceChip(
              label: Text(label),
              selected: DateUtils.isSameDay(day, _date),
              onSelected: (_) => setState(() => _date = day)),
        ActionChip(
          avatar: const Icon(Iconsax.calendar_1, size: 18),
          label: Text(quick.any((q) => DateUtils.isSameDay(q.$2, _date))
              ? 'Pick a date'
              : DateFormat('EEE d MMM').format(_date)),
          onPressed: () async {
            final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: today,
                lastDate: today.add(const Duration(days: 730)));
            if (picked != null) setState(() => _date = picked);
          },
        ),
      ]),
      const SizedBox(height: 18),
      _section('Assign each job to'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
            label: const Text('Nobody yet'),
            selected: _assignee == null,
            onSelected: (_) => setState(() => _assignee = null)),
        for (final (id, name) in _people)
          ChoiceChip(
              label: Text(name),
              selected: _assignee == id,
              onSelected: (_) => setState(() => _assignee = id)),
      ]),
    ];
  }

  List<Widget> _scheduleReview() {
    final device = _device!, kind = _kind!;
    final person = _people.where((p) => p.$1 == _assignee).firstOrNull?.$2;
    return [
      _heading('Review', 'Check the schedule, then create it.'),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DeviceIllustration(type: device.deviceType, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kind.name,
                  style: SetupFlowFrame.text(17, weight: FontWeight.w700)),
              Text(_equipmentLabel(device), style: SetupFlowFrame.text(14)),
              const SizedBox(height: 6),
              Text(
                  'Repeats $_repeatLabel, starting ${DateFormat('EEEE d MMMM').format(_date)}',
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
              Text(
                  person == null
                      ? 'Jobs start unassigned'
                      : 'Each job assigned to $person',
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
            ]),
          ),
          IconButton(
              tooltip: 'Change',
              onPressed: () => _go(1),
              icon: const Icon(Iconsax.edit_2, size: 20)),
        ]),
      ),
      const SizedBox(height: 16),
      const SetupNote(
        icon: Iconsax.notification,
        title: 'Created and reminded automatically',
        text:
            'Each job is added 3 days before it’s due, at 09:00. Reminders go to the assignee, the account '
            'owner, administrators and managers 3 days, 2 days and 1 day before, 3 hours before, and if it runs late.',
      ),
    ];
  }

  Future<void> _submitSchedule() async {
    final device = _device, kind = _kind;
    if (device == null || kind == null) {
      _go(device == null ? 0 : 1);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'device_id': device.id,
      'maintenance_type_id': kind.id,
      'frequency': _frequency,
      'start_date': DateFormat('yyyy-MM-dd').format(_date),
      if (_frequency == 'custom')
        'custom_frequency_days': int.tryParse(_customDays.text.trim()),
      if (_assignee != null)
        'auto_assign_to_id': int.tryParse(_assignee!) ?? _assignee,
    };
    final fingerprint = jsonEncode(payload);
    if (fingerprint != _requestFingerprint) {
      _requestFingerprint = fingerprint;
      _requestId = const Uuid().v4();
    }
    try {
      final r = await http
          .post(
              Uri.parse(
                  '${Constants.articBaseUrl2}api/maintenance/schedule/create/'),
              headers: await _headers(),
              body: jsonEncode({...payload, 'client_request_id': _requestId}))
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (r.statusCode == 201) {
        Navigator.of(context).pop(true);
        return;
      }
      throw StateError('create');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Unable to save the schedule. Check your connection, or whether this equipment already has '
            'the same schedule, then retry.';
      });
    }
  }
}
