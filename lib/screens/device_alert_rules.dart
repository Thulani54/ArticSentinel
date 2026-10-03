import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_alert_rules.dart';
import '../widgets/mobile_forms.dart';

typedef AlertRulesLoader = Future<Map<String, dynamic>> Function();
typedef AlertRulesSaver = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> body);

class DeviceAlertRulesScreen extends StatefulWidget {
  const DeviceAlertRulesScreen(
      {super.key, required this.device, this.loadRules, this.saveRules});
  final Device device;
  final AlertRulesLoader? loadRules;
  final AlertRulesSaver? saveRules;
  @override
  State<DeviceAlertRulesScreen> createState() => _DeviceAlertRulesScreenState();
}

class _RuleDraft {
  _RuleDraft(this.metric, this.comparison, String values)
      : values = TextEditingController(text: values);
  String metric, comparison;
  final TextEditingController values;
}

class _DeviceAlertRulesScreenState extends State<DeviceAlertRulesScreen> {
  final _form = GlobalKey<FormState>();
  final List<_RuleDraft> _rules = [];
  List<Map<String, dynamic>> _metrics = [];
  int _revision = 0;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final rule in _rules) {
      rule.values.dispose();
    }
    super.dispose();
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
  void _accept(Map<String, dynamic> data) {
    for (final rule in _rules) {
      rule.values.dispose();
    }
    _rules.clear();
    _metrics = (data['metrics'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _revision = data['revision'] as int;
    for (final item in data['rules'] as List) {
      _rules.add(_RuleDraft(
          item['metric'],
          item['comparison'],
          (item['thresholds'] as List)
              .map((v) => '$v'.replaceFirst(RegExp(r'\.0$'), ''))
              .join(', ')));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await (widget.loadRules?.call() ??
          DeviceAlertRulesApi.request(widget.device.id!));
      if (!mounted) return;
      setState(() => _accept(data));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _spec(_RuleDraft r) =>
      _metrics.firstWhere((m) => m['id'] == r.metric);
  List<double>? _numbers(String text) {
    final parts = text.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty || parts.any((e) => e.isEmpty)) return null;
    final values = parts.map(double.tryParse).toList();
    if (values.any((e) => e == null || !e.isFinite)) return null;
    return values.cast<double>();
  }

  String? _validate(_RuleDraft r, String? text) {
    final values = _numbers(text ?? '');
    final spec = _spec(r);
    if (values == null)
      return 'Enter numbers separated by commas, e.g. 50, 30, 10';
    if (values.length > 20) return 'Use up to 20 thresholds per condition';
    for (final v in values) {
      if ((spec['minimum'] != null && v < (spec['minimum'] as num)) ||
          (spec['maximum'] != null && v > (spec['maximum'] as num)))
        return 'Use values from ${spec['minimum']} to ${spec['maximum']} ${spec['unit']}';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = {
        'revision': _revision,
        'rules': _rules
            .map((r) => {
                  'metric': r.metric,
                  'comparison': r.comparison,
                  'thresholds': _numbers(r.values.text)
                })
            .toList()
      };
      final data = await (widget.saveRules?.call(body) ??
          DeviceAlertRulesApi.request(widget.device.id!, body: body));
      if (!mounted) return;
      setState(() => _accept(data));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your device alert rules are saved.')));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, {String? helper}) =>
      mobileInputDecoration(
          context,
          InputDecoration(
              labelText: label, helperText: helper, helperMaxLines: 3));
  Widget _rule(_RuleDraft r, int index) {
    final spec = _spec(r);
    final boolean = spec['boolean'] == true;
    return Container(
        key: ObjectKey(r),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E5EA))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Text('Condition ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 17))),
            TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _rules.remove(r));
                        r.values.dispose();
                      },
                child: const Text('Remove'))
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              key: ValueKey('${identityHashCode(r)}-${r.metric}'),
              initialValue: r.metric,
              isExpanded: true,
              decoration: _decoration('Reading'),
              items: _metrics
                  .map((m) => DropdownMenuItem<String>(
                      value: m['id'],
                      child: Text(
                          '${m['label']}${m['unit'] == '' ? '' : ' (${m['unit']})'}',
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        r.metric = value;
                        final m = _spec(r);
                        r.comparison = m['boolean'] == true ? 'gte' : 'lte';
                        r.values.text = m['boolean'] == true ? '1' : '';
                      });
                    }),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
              key: ValueKey(
                  '${identityHashCode(r)}-${r.metric}-${r.comparison}'),
              initialValue: r.comparison,
              isExpanded: true,
              decoration: _decoration(boolean ? 'Alert when' : 'Trigger'),
              items: [
                DropdownMenuItem(
                    value: 'lte',
                    child:
                        Text(boolean ? 'Off / closed / false' : 'At or below')),
                DropdownMenuItem(
                    value: 'gte',
                    child: Text(boolean ? 'On / open / true' : 'At or above'))
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null)
                        setState(() {
                          r.comparison = value;
                          if (boolean)
                            r.values.text = value == 'gte' ? '1' : '0';
                        });
                    }),
          if (!boolean) ...[
            const SizedBox(height: 18),
            TextFormField(
                controller: r.values,
                enabled: !_saving,
                keyboardType: TextInputType.text,
                decoration: _decoration(
                    spec['unit'] == '%'
                        ? 'Percentages'
                        : 'Thresholds (${spec['unit']})',
                    helper:
                        'Separate values with commas. ${spec['unit'] == '%' ? 'Example: 50, 30, 10' : 'Use ${spec['unit']} for this reading.'}'),
                validator: (value) => _validate(r, value)),
            const SizedBox(height: 8),
            Text(
                'Re-arms after the reading recovers by ${spec['reset_margin']} ${spec['unit']}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF616B7A))),
          ],
        ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text('My device alerts'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF252C44)),
      body: SafeArea(
          child: Column(children: [
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _form,
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
                      Text(widget.device.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      const Text(
                          'Choose the readings and values that should notify you. These rules apply to your account only. A fresh reading already at a saved threshold can trigger an alert.'),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                        TextButton(
                            onPressed: _saving ? null : _load,
                            child: const Text('Reload saved rules')),
                        const SizedBox(height: 12)
                      ],
                      if (_metrics.isEmpty)
                        const Text(
                            'No supported readings are available for this device yet.'),
                      if (_metrics.isNotEmpty && _rules.isEmpty)
                        const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                                'No custom alerts. Saving an empty list turns off your threshold notifications for this device.')),
                      for (var i = 0; i < _rules.length; i++)
                        _rule(_rules[i], i),
                      if (_metrics.isNotEmpty)
                        OutlinedButton(
                            onPressed: _saving || _rules.length >= 20
                                ? null
                                : () {
                                    final m = _metrics.first;
                                    setState(() => _rules.add(_RuleDraft(
                                        m['id'],
                                        m['boolean'] == true ? 'gte' : 'lte',
                                        m['boolean'] == true ? '1' : '')));
                                  },
                            child: const Text('Add condition')),
                      const SizedBox(height: 16),
                      const Text(
                          'Alerts use recent device readings. Your phone must allow notifications. Removing a condition and saving cancels its queued alerts.'),
                    ]))),
        if (!_loading && _metrics.isNotEmpty)
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save my alerts')))),
      ])));
}
