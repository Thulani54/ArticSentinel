/// Team members: everyone in the business, plus "Add user" for the primary
/// contact, administrators and managers. Backed by api/team/members/.
/// A generated temporary password is shown once after adding, with a copy
/// button, so the admin can hand it over securely.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../services/shared_preferences.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/mobile_forms.dart';

const _userTypes = <(String, String)>[
  ('customer', 'Customer user'),
  ('technician', 'Technician'),
  ('manager', 'Manager'),
  ('administrator', 'Administrator'),
  ('support', 'Support staff'),
  ('service_provider', 'Service provider'),
];

String _userTypeLabel(String? value) => _userTypes
    .firstWhere((t) => t.$1 == value, orElse: () => (value ?? '', value ?? ''))
    .$2;

class TeamMembersTab extends StatefulWidget {
  const TeamMembersTab({super.key});

  @override
  State<TeamMembersTab> createState() => _TeamMembersTabState();
}

class _TeamMembersTabState extends State<TeamMembersTab> {
  List<Map<String, dynamic>> _members = [];
  bool _canManage = false;
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await Sharedprefs.getAuthTokenPreference();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await http.get(
          Uri.parse('${Constants.articBaseUrl2}api/team/members/'),
          headers: await _headers()).timeout(const Duration(seconds: 20));
      final body = jsonDecode(r.body);
      if (r.statusCode != 200) {
        throw Exception(body is Map
            ? (body['error'] ?? 'Request failed')
            : 'Request failed');
      }
      if (!mounted) return;
      setState(() {
        _members = (body['members'] as List).cast<Map<String, dynamic>>();
        _canManage = body['can_manage'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _members
        .where((m) =>
            '${m['firstname']} ${m['lastname']} ${m['email']} ${m['job_title']}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team members',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: GasPalette.ink)),
                    const SizedBox(height: 2),
                    Text(
                        '${_members.length} member${_members.length == 1 ? '' : 's'} in ${Constants.business_name}',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: GasPalette.ink2)),
                  ],
                ),
              ),
              if (_canManage)
                FilledButton.icon(
                  onPressed: _openAddUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: GasPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: Text('Add user',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: mobileInputDecoration(
              context,
              InputDecoration(
                hintText: 'Search by name, email or job title',
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: GasPalette.ink2),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: GasPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: GasPalette.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            _notice(_error!, retry: true)
          else if (shown.isEmpty)
            _notice(_query.isEmpty
                ? 'No team members yet.'
                : 'Nobody matches "$_query".')
          else
            ...shown.map(_memberCard),
          if (!_loading && !_canManage) ...[
            const SizedBox(height: 8),
            Text(
              'Only the primary contact, administrators and managers can add users.',
              style: GoogleFonts.inter(fontSize: 12, color: GasPalette.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _notice(String text, {bool retry = false}) {
    if (isPhoneLayout(context)) {
      return AppEmptyState(
        kind: retry
            ? AppEmptyStateKind.offline
            : _query.isNotEmpty
                ? AppEmptyStateKind.results
                : AppEmptyStateKind.records,
        icon: retry ? null : Icons.people_outline,
        title: retry
            ? 'Unable to load your team'
            : _query.isNotEmpty
                ? 'No matching team members'
                : 'No team members yet',
        message: retry
            ? text
            : _query.isNotEmpty
                ? 'Try another name, email or job title.'
                : 'People added to your business will appear here.',
        actionLabel: retry ? 'Retry' : null,
        onAction: retry ? _load : null,
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GasPalette.panelAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
          if (retry) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> m) {
    final name = '${m['firstname'] ?? ''} ${m['lastname'] ?? ''}'.trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();
    final active = m['is_active'] != false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GasPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: GasPalette.primary,
            child: Text(initials,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name.isEmpty ? m['email'] ?? '' : name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: GasPalette.ink)),
                    ),
                    if (m['is_primary_contact'] == true) ...[
                      const SizedBox(width: 6),
                      _chip(
                          'Owner', const Color(0xFFEFF6FF), GasPalette.series),
                    ],
                    if (!active) ...[
                      const SizedBox(width: 6),
                      _chip(
                          'Disabled', GasPalette.critSoft, GasPalette.critInk),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(m['email'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: GasPalette.ink2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(_userTypeLabel(m['user_type']), GasPalette.panelAlt,
                        GasPalette.ink2),
                    if ((m['job_title'] ?? '').toString().isNotEmpty)
                      _chip(
                          m['job_title'], GasPalette.panelAlt, GasPalette.ink2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Future<void> _openAddUser() async {
    final added = await showMobileDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddUserDialog(),
    );
    if (added == true) _load();
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _job = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'customer';
  bool _busy = false;
  String? _error;

  // Set once the user is created: the dialog switches to the hand-over view.
  String? _tempPassword;
  String? _createdEmail;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _job, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_first.text.trim().isEmpty ||
        _last.text.trim().isEmpty ||
        _email.text.trim().isEmpty) {
      setState(() => _error = 'First name, last name and email are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await Sharedprefs.getAuthTokenPreference();
      final r = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/team/members/add/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'first_name': _first.text.trim(),
          'last_name': _last.text.trim(),
          'email': _email.text.trim(),
          'user_type': _type,
          'job_title': _job.text.trim(),
          'cellphone_number': _phone.text.trim(),
        }),
      );
      final body = jsonDecode(r.body);
      if (r.statusCode == 201) {
        setState(() {
          _tempPassword = body['temporary_password'];
          _createdEmail = _email.text.trim();
        });
      } else {
        setState(() => _error =
            (body is Map ? body['error'] : null)?.toString() ??
                'Could not add the user.');
      }
    } catch (e) {
      setState(() => _error = 'Could not add the user. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileDialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _tempPassword == null ? _form() : _handOver(),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add a team member',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GasPalette.ink)),
        const SizedBox(height: 4),
        Text('They get access to this workspace and its devices.',
            style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _field(_first, 'First name')),
          const SizedBox(width: 10),
          Expanded(child: _field(_last, 'Last name')),
        ]),
        const SizedBox(height: 12),
        _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          decoration: _decoration('Role in the app'),
          items: [
            for (final (value, label) in _userTypes)
              DropdownMenuItem(
                  value: value,
                  child: Text(label, style: GoogleFonts.inter(fontSize: 14))),
          ],
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 12),
        _field(_job, 'Job title (optional)'),
        const SizedBox(height: 12),
        _field(_phone, 'Cellphone (optional)',
            keyboardType: TextInputType.phone),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: GasPalette.critInk,
                  fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _busy ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: GasPalette.border),
                  foregroundColor: GasPalette.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                ),
                child: Text(_busy ? 'Adding…' : 'Add user'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _handOver() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: GasPalette.good, size: 44),
        const SizedBox(height: 10),
        Text('User added',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GasPalette.ink)),
        const SizedBox(height: 6),
        Text(
          '$_createdEmail can sign in with this temporary password. '
          'It is shown only once — share it securely and ask them to change it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GasPalette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(_tempPassword!,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Copy password',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _tempPassword!));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Temporary password copied')));
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            backgroundColor: GasPalette.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return mobileInputDecoration(
      context,
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: GasPalette.ink2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GasPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GasPalette.primary),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14.5, color: GasPalette.ink),
      decoration: _decoration(label),
    );
  }
}
