import '../widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../gasmon/gas_core.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';
import 'device_journal_api.dart';

class CylinderRefillHistoryPage extends StatefulWidget {
  const CylinderRefillHistoryPage(
      {super.key,
      required this.deviceId,
      required this.deviceName,
      this.readings = const [],
      this.capacityKg,
      this.tareKg,
      this.api});
  final int deviceId;
  final String deviceName;
  final List<GasReading> readings;
  final DeviceJournalApi? api;
  final double? capacityKg, tareKg;
  @override
  State<CylinderRefillHistoryPage> createState() =>
      _CylinderRefillHistoryPageState();
}

class _CylinderRefillHistoryPageState extends State<CylinderRefillHistoryPage> {
  late final DeviceJournalApi _api = widget.api ?? DeviceJournalApi();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await _api.request('devices/${widget.deviceId}/refills/', query: {
        'month': DateFormat('yyyy-MM').format(_month),
        if (more) 'offset': '${_data?['next_offset'] ?? 0}',
      });
      if (!mounted || generation != _generation) return;
      if (more) data['refills'] = [...?_data?['refills'], ...data['refills']];
      setState(() => _data = data);
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = '$e');
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _add() async {
    final saved = await showMobileDialog<bool>(
        context: context,
        builder: (_) => _RefillForm(
            deviceId: widget.deviceId,
            api: _api,
            capacityKg: widget.capacityKg,
            tareKg: widget.tareKg));
    if (saved == true && mounted) _load();
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _data = null;
    });
    _load();
  }

  double? get _usage {
    final rows = widget.readings
        .where((r) => r.at.year == _month.year && r.at.month == _month.month)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (rows.length < 2) return null;
    final series = dailySeries(rows, pricePerKg: 0);
    if (series.isEmpty) return null;
    final used = series.fold<double>(0, (sum, point) => sum + point.kg);
    return used;
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_data?['refills'] as List?) ?? [];
    return Scaffold(
      backgroundColor: GasPalette.page,
      appBar: AppBar(title: const Text('Refill history')),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Text(widget.deviceName, style: gasTitle(context)),
            const SizedBox(height: 8),
            Text(
                'Record purchases and cylinder changes. Your history does not change the scale or cylinder setup.',
                style: gasBody(context)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _loading ? null : _add,
                child: const Text('Log refill or cylinder change')),
            const SizedBox(height: 16),
            Row(children: [
              IconButton(
                  tooltip: 'Previous month',
                  onPressed: _loading ? null : () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                  child: Text(DateFormat('MMMM yyyy').format(_month),
                      textAlign: TextAlign.center, style: gasTitle(context))),
              IconButton(
                  tooltip: 'Next month',
                  onPressed: _loading ||
                          _month.month == DateTime.now().month &&
                              _month.year == DateTime.now().year
                      ? null
                      : () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right)),
            ]),
            const SizedBox(height: 12),
            if (_data != null)
              GPanel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text('Purchase spending', style: gasEyebrow(context)),
                    Text(
                        'R ${double.parse('${_data!['total_cost']}').toStringAsFixed(2)}',
                        style: gasData(context, size: 30)),
                    Text(
                        '${_data!['purchased_kg']} kg purchased · ${_data!['count']} ${_data!['count'] == 1 ? 'entry' : 'entries'}',
                        style: gasBody(context)),
                    const Divider(height: 28),
                    Text('Observed consumption', style: gasEyebrow(context)),
                    Text(
                        _usage == null
                            ? 'Not enough readings'
                            : '${_usage!.toStringAsFixed(2)} kg',
                        style: gasTitle(context)),
                    Text(
                        'Calculated from available scale readings for this month. Gaps and retention can leave usage unmeasured; purchases and consumption are different totals.',
                        style: gasBody(context)),
                  ])),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator())),
            if (_error != null)
              AppEmptyState(
                  kind: AppEmptyStateKind.offline,
                  title: 'History unavailable',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _load),
            if (!_loading && _error == null && rows.isEmpty)
              const AppEmptyState(
                  title: 'No entries this month',
                  message:
                      'Log a refill purchase or cylinder change to start tracking your history and gas spending.'),
            for (final row in rows)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GPanel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Text(
                            row['kind'] == 'cylinder_change'
                                ? 'Cylinder change'
                                : 'Refill purchase',
                            style: gasEyebrow(context)),
                        const SizedBox(height: 6),
                        Text(
                            DateFormat('d MMM yyyy')
                                .format(DateTime.parse(row['purchased_on'])),
                            style: gasTitle(context)),
                        const SizedBox(height: 8),
                        Text('${row['gas_kg']} kg · R ${row['cost']}',
                            style: gasData(context, size: 20)),
                        if (row['capacity_kg'] != null ||
                            row['tare_kg'] != null)
                          Text(
                              'Capacity ${row['capacity_kg'] ?? '—'} kg · Empty weight ${row['tare_kg'] ?? '—'} kg',
                              style: gasBody(context)),
                        if ((row['supplier'] as String).isNotEmpty)
                          Text(row['supplier'], style: gasBody(context)),
                        if ((row['notes'] as String).isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child:
                                  Text(row['notes'], style: gasBody(context))),
                      ]))),
            if (!_loading && _data?['next_offset'] != null)
              TextButton(
                  onPressed: () => _load(more: true),
                  child: const Text('Load more')),
          ])),
    );
  }
}

class _RefillForm extends StatefulWidget {
  const _RefillForm(
      {required this.deviceId,
      required this.api,
      this.capacityKg,
      this.tareKg});
  final int deviceId;
  final DeviceJournalApi api;
  final double? capacityKg, tareKg;
  @override
  State<_RefillForm> createState() => _RefillFormState();
}

class _RefillFormState extends State<_RefillForm> {
  final _form = GlobalKey<FormState>();
  final _kg = TextEditingController(),
      _cost = TextEditingController(),
      _supplier = TextEditingController(),
      _notes = TextEditingController();
  final _capacity = TextEditingController(), _tare = TextEditingController();
  String _kind = 'refill';
  @override
  void initState() {
    super.initState();
    _capacity.text = widget.capacityKg?.toStringAsFixed(2) ?? '';
    _tare.text = widget.tareKg?.toStringAsFixed(2) ?? '';
  }

  DateTime _date = DateTime.now();
  String _requestId = const Uuid().v4();
  String? _fingerprint, _error;
  bool _saving = false;
  @override
  void dispose() {
    for (final c in [_kg, _cost, _supplier, _notes, _capacity, _tare]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final body = {
      'purchased_on': DateFormat('yyyy-MM-dd').format(_date),
      'kind': _kind,
      if (_capacity.text.trim().isNotEmpty)
        'capacity_kg': _capacity.text.trim(),
      if (_tare.text.trim().isNotEmpty) 'tare_kg': _tare.text.trim(),
      'gas_kg': _kg.text.trim(),
      'cost': _cost.text.trim(),
      'supplier': _supplier.text.trim(),
      'notes': _notes.text.trim()
    };
    final fingerprint = body.toString();
    if (_fingerprint != null && _fingerprint != fingerprint) {
      _requestId = const Uuid().v4();
    }
    _fingerprint = fingerprint;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.request('devices/${widget.deviceId}/refills/',
          method: 'POST', body: {...body, 'request_id': _requestId});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => MobileDialog(
      child: SizedBox(
          width: 560,
          height: isPhoneLayout(context) ? null : 700,
          child: PopScope(
              canPop: !_saving,
              child: Scaffold(
                appBar: AppBar(
                    title: const Text('Cylinder history'),
                    leading: IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close))),
                body: Form(
                    key: _form,
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      Text('Record a purchase or change',
                          style: gasTitle(context)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                          initialValue: _kind,
                          isExpanded: true,
                          decoration: mobileInputDecoration(context,
                              const InputDecoration(labelText: 'Entry type')),
                          items: const [
                            DropdownMenuItem(
                                value: 'refill',
                                child: Text('Refill purchase')),
                            DropdownMenuItem(
                                value: 'cylinder_change',
                                child: Text('Cylinder change'))
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                    _kind = value!;
                                    if (_kind == 'cylinder_change') {
                                      if (_kg.text.isEmpty) _kg.text = '0';
                                      if (_cost.text.isEmpty) _cost.text = '0';
                                    }
                                  })),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _date,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now());
                                  if (picked != null && mounted) {
                                    setState(() => _date = picked);
                                  }
                                },
                          child: Text(
                              'Date · ${DateFormat('d MMM yyyy').format(_date)}')),
                      const SizedBox(height: 16),
                      _field(_kg, 'Gas purchased (kg)',
                          numeric: true,
                          validator: (v) => _number(
                              v, _kind == 'cylinder_change' ? 0 : .01, 200)),
                      _field(_cost, 'Total cost (ZAR)',
                          numeric: true,
                          validator: (v) => _number(v, 0, 99999999.99)),
                      if (_kind == 'cylinder_change') ...[
                        Text(
                            'Use 0 purchased kg and 0 cost if no gas was purchased. Apply a different cylinder size using Switch gas in the device view.',
                            style: gasBody(context)),
                        const SizedBox(height: 16),
                        _field(_capacity, 'Cylinder capacity (kg, optional)',
                            numeric: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? null
                                : _number(v, .01, 200)),
                        _field(_tare, 'Empty cylinder weight (kg, optional)',
                            numeric: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? null
                                : _number(v, .01, 200)),
                      ],
                      _field(_supplier, 'Supplier (optional)', max: 160),
                      _field(_notes, 'Notes (optional)', max: 1000, lines: 3),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!,
                                style: TextStyle(color: Tone.fg(Colors.red)))),
                      FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Saving…' : 'Save entry')),
                    ])),
              ))));
  String? _number(String? v, double min, double max) {
    final value = double.tryParse(v ?? '');
    if (value == null ||
        !value.isFinite ||
        value < min ||
        value > max ||
        !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v!.trim())) {
      return 'Enter $min–$max, with up to 2 decimal places.';
    }
    return null;
  }

  Widget _field(TextEditingController c, String label,
          {bool numeric = false,
          int? max,
          int lines = 1,
          String? Function(String?)? validator}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
              controller: c,
              enabled: !_saving,
              maxLength: max,
              maxLines: lines,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: mobileInputDecoration(
                  context, InputDecoration(labelText: label)),
              validator: validator));
}
