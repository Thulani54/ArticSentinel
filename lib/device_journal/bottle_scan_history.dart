import '../widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';
import 'device_journal_api.dart';

class BottleScanHistoryPage extends StatefulWidget {
  const BottleScanHistoryPage(
      {super.key, required this.deviceId, required this.deviceName, this.api});
  final int deviceId;
  final String deviceName;
  final DeviceJournalApi? api;
  @override
  State<BottleScanHistoryPage> createState() => _BottleScanHistoryPageState();
}

class _BottleScanHistoryPageState extends State<BottleScanHistoryPage> {
  late final DeviceJournalApi _api = widget.api ?? DeviceJournalApi();
  final _search = TextEditingController();
  String _result = 'all';
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 6)),
      end: DateTime.now());
  List<dynamic> _rows = [];
  int? _next;
  bool _loading = true;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (!more) {
        _rows = [];
        _next = null;
      }
    });
    try {
      final result =
          await _api.request('devices/${widget.deviceId}/scans/', query: {
        'from': DateFormat('yyyy-MM-dd').format(_range.start),
        'to': DateFormat('yyyy-MM-dd').format(_range.end),
        'q': _search.text.trim(),
        'result': _result,
        'offset': more ? '${_next ?? 0}' : '0',
      });
      if (!mounted || generation != _generation) return;
      setState(() {
        _rows = [if (more) ..._rows, ...result['scans']];
        _next = result['next_offset'];
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = '$e');
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _dateRange() async {
    final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now().subtract(const Duration(days: 89)),
        lastDate: DateTime.now(),
        initialDateRange: _range);
    if (selected != null && mounted) {
      setState(() => _range = selected);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GasPalette.page,
        appBar: AppBar(title: const Text('Bottle scan history')),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Text(widget.deviceName, style: gasTitle(context)),
              const SizedBox(height: 8),
              Text(
                  'Review scan readings from the last 90 days. A code may appear again when the machine reports it more than once.',
                  style: gasBody(context)),
              const SizedBox(height: 20),
              TextField(
                  controller: _search,
                  maxLength: 512,
                  decoration: mobileInputDecoration(
                      context,
                      const InputDecoration(
                          labelText: 'Search bottle code', counterText: '')),
                  onSubmitted: (_) => _load()),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _load();
                        },
                  child: const Text('Search readings')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final choice in {
                  'all': 'All readings',
                  'verified': 'Verified',
                  'failed': 'Failed'
                }.entries)
                  ChoiceChip(
                      label: Text(choice.value),
                      selected: _result == choice.key,
                      onSelected: _loading
                          ? null
                          : (_) {
                              setState(() => _result = choice.key);
                              _load();
                            }),
              ]),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: _loading ? null : _dateRange,
                  child: Text(
                      '${DateFormat('d MMM').format(_range.start)} – ${DateFormat('d MMM yyyy').format(_range.end)}')),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator())),
              if (_error != null)
                AppEmptyState(
                    kind: AppEmptyStateKind.offline,
                    title: 'Scans unavailable',
                    message: _error!,
                    actionLabel: 'Retry',
                    onAction: _load),
              if (!_loading && _error == null && _rows.isEmpty)
                const AppEmptyState(
                    kind: AppEmptyStateKind.results,
                    title: 'No matching scans',
                    message:
                        'Try a different code, result or date range. Scans appear after the bottle machine reports them.'),
              for (final row in _rows)
                Padding(
                    padding: const EdgeInsets.only(top: 12), child: _scan(row)),
              if (!_loading && _next != null)
                TextButton(
                    onPressed: () => _load(more: true),
                    child: const Text('Load more scans')),
            ])),
      );
  Widget _scan(Map<String, dynamic> row) {
    final verified = row['verified'];
    final status = verified == true
        ? 'Verified'
        : verified == false
            ? 'Failed verification'
            : 'Not checked';
    final color = verified == true
        ? Tone.auto(const Color(0xFF087F69))
        : verified == false
            ? Tone.auto(const Color(0xFFB42318))
            : GasPalette.ink2;
    final time = DateTime.tryParse('${row['time']}')?.toLocal();
    return GPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(status, style: gasEyebrow(context).copyWith(color: color)),
      const SizedBox(height: 8),
      SelectableText('${row['code']}', style: gasTitle(context)),
      const SizedBox(height: 8),
      Text(
          time == null
              ? 'Time unavailable'
              : DateFormat('d MMM yyyy · HH:mm:ss').format(time),
          style: gasBody(context)),
      if (row['direction'] != null && '${row['direction']}'.isNotEmpty)
        Text('Direction: ${row['direction']}', style: gasBody(context)),
      if (row['manufacturer'] != null && '${row['manufacturer']}'.isNotEmpty)
        Text('Manufacturer: ${row['manufacturer']}', style: gasBody(context)),
      if (row['temperature'] != null)
        Text('Temperature: ${row['temperature']} °C', style: gasBody(context)),
      const SizedBox(height: 8),
      if (row['tray_kg'] is List)
        Wrap(spacing: 12, runSpacing: 6, children: [
          for (final entry in (row['tray_kg'] as List).asMap().entries)
            Text(
                'Tray ${entry.key + 1}: ${entry.value ?? '—'}${entry.value == null ? '' : ' kg'}',
                style: gasEyebrow(context)),
        ]),
    ]));
  }
}
