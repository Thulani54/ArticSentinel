import '../widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../gasmon/gas_theme.dart';
import '../gasmon/gas_widgets.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';
import 'device_journal_api.dart';

/// Collaboration is authoritative on the server; a revision prevents one team
/// member from silently overwriting another member's assignment or resolution.
class AlertTeamPanel extends StatefulWidget {
  const AlertTeamPanel(
      {super.key,
      required this.alertId,
      this.api,
      this.onChanged,
      this.onResolved});
  final int alertId;
  final DeviceJournalApi? api;
  final VoidCallback? onChanged;
  final VoidCallback? onResolved;
  @override
  State<AlertTeamPanel> createState() => _AlertTeamPanelState();
}

class _AlertTeamPanelState extends State<AlertTeamPanel> {
  late final DeviceJournalApi _api = widget.api ?? DeviceJournalApi();
  final _note = TextEditingController();
  Map<String, dynamic>? _data;
  int? _assignee;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api.request('alerts/${widget.alertId}/team/');
      if (mounted) {
        setState(() {
          _data = data;
          _assignee = data['assigned_to'];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String action) async {
    if (action != 'assign' && _note.text.trim().length < 5) {
      setState(
          () => _error = 'Describe what was done using at least 5 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api
          .request('alerts/${widget.alertId}/team/', method: 'PATCH', body: {
        'revision': _data!['revision'],
        'action': action,
        'assigned_to': _assignee,
        'note': _note.text.trim(),
      });
      if (mounted) {
        setState(() {
          _data = data;
          _assignee = data['assigned_to'];
          _note.clear();
        });
        widget.onChanged?.call();
        if (action == 'resolve') widget.onResolved?.call();
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = (_data?['members'] as List?) ?? [];
    // Former/inactive team members retain attribution but cannot be assigned again.
    final selectable =
        _assignee == null || members.any((m) => m['id'] == _assignee);
    return GPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Team activity', style: gasTitle(context)),
      const SizedBox(height: 8),
      Text('Assign an owner and keep a shared record of the action taken.',
          style: gasBody(context)),
      if (_busy)
        const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator())),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: Tone.fg(Color(0xFFB42318)))),
        TextButton(
            onPressed: _busy ? null : _load,
            child: const Text('Reload team activity')),
      ],
      if (_data != null) ...[
        const SizedBox(height: 16),
        Text('Status: ${_data!['status']}', style: gasEyebrow(context)),
        if (!selectable)
          Text(
              'Previously assigned to ${_data!['assigned_name'] ?? 'a former team member'}',
              style: gasBody(context)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
            key: ValueKey('${_data!['revision']}-$_assignee'),
            initialValue: selectable ? _assignee : null,
            isExpanded: true,
            decoration: mobileInputDecoration(context,
                const InputDecoration(labelText: 'Responsible person')),
            items: [
              const DropdownMenuItem<int>(
                  value: null, child: Text('Unassigned')),
              for (final member in members)
                DropdownMenuItem<int>(
                    value: member['id'],
                    child:
                        Text(member['name'], overflow: TextOverflow.ellipsis))
            ],
            onChanged:
                _busy ? null : (value) => setState(() => _assignee = value)),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: _busy ? null : () => _save('assign'),
            child: const Text('Save assignment')),
        const SizedBox(height: 16),
        TextField(
            controller: _note,
            enabled: !_busy,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            decoration: mobileInputDecoration(
                context,
                const InputDecoration(
                    labelText: 'Action taken / handover note',
                    alignLabelWithHint: true))),
        OutlinedButton(
            onPressed: _busy ? null : () => _save('note'),
            child: const Text('Add note')),
        if (_data!['status'] != 'resolved') ...[
          const SizedBox(height: 8),
          FilledButton(
              onPressed: _busy ? null : () => _save('resolve'),
              child: const Text('Resolve with note')),
        ],
        const SizedBox(height: 20),
        if ((_data!['events'] as List).isEmpty)
          const AppEmptyState(
              compact: true,
              title: 'No team activity yet',
              message:
                  'Assign an owner or add the first note to keep your team informed.'),
        for (final event in _data!['events']) ...[
          const Divider(height: 20),
          Text(
              '${event['actor']} · ${event['action'] == 'assign' ? (event['assignee'] == '' ? 'Unassigned' : 'Assigned to ${event['assignee']}') : event['action'] == 'resolve' ? 'Resolved' : 'Note added'}',
              style: gasEyebrow(context)),
          const SizedBox(height: 4),
          if ('${event['note']}'.isNotEmpty)
            Text(event['note'], style: gasBody(context)),
          Text(
              DateFormat('d MMM yyyy · HH:mm')
                  .format(DateTime.parse(event['created_at']).toLocal()),
              style: gasEyebrow(context)),
        ],
      ],
    ]));
  }
}
