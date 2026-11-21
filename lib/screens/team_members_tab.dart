/// Team members: everyone in the business, plus "Add user" for the primary
/// contact, administrators and managers. Backed by api/team/members/.
/// Adding opens the guided AddUserFlowScreen, which shows the one-time
/// temporary password with hand-over steps.
library;

import '../widgets/app_tone.dart';
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
import 'add_user_flow.dart';

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
  String? _roleFilter;

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
      final r = await http
          .get(Uri.parse('${Constants.articBaseUrl2}api/team/members/'),
              headers: await _headers())
          .timeout(const Duration(seconds: 20));
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
    final q = _query.toLowerCase();
    final shown = _members
        .where((m) =>
            _roleFilter == null ||
            (m['user_type'] ?? 'customer') == _roleFilter)
        .where((m) =>
            '${m['firstname']} ${m['lastname']} ${m['email']} ${m['job_title']}'
                .toLowerCase()
                .contains(q))
        .toList();
    final roles = {
      for (final m in _members) (m['user_type'] ?? 'customer').toString()
    };
    final managers = _members
        .where((m) =>
            m['is_primary_contact'] == true ||
            teamRole(m['user_type']).canAddUsers)
        .length;
    final technicians =
        _members.where((m) => m['user_type'] == 'technician').length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team members',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GasPalette.ink)),
                    const SizedBox(height: 2),
                    Text(
                        Constants.business_name.trim().isEmpty
                            ? 'People with access to your workspace'
                            : 'People with access to ${Constants.business_name}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: GasPalette.ink2)),
                  ]),
            ),
            if (_canManage)
              FilledButton.icon(
                onPressed: _openAddUser,
                style: FilledButton.styleFrom(
                  backgroundColor: GasPalette.primary,
                  foregroundColor: Tone.fg(Colors.white),
                  minimumSize: const Size(48, 44),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: Text('Add user',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
          ]),
          if (!_loading && _error == null && _members.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: [
              _stat(
                  '${_members.length}',
                  _members.length == 1 ? 'Member' : 'Members',
                  Icons.groups_2_outlined),
              const SizedBox(width: 10),
              _stat('$managers', 'Can add users',
                  Icons.admin_panel_settings_outlined),
              const SizedBox(width: 10),
              _stat(
                  '$technicians',
                  technicians == 1 ? 'Technician' : 'Technicians',
                  Icons.build_outlined),
            ]),
          ],
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: mobileInputDecoration(
              context,
              InputDecoration(
                hintText: 'Search by name, email or job title',
                prefixIcon:
                    Icon(Icons.search, size: 20, color: GasPalette.ink2),
                filled: true,
                fillColor: Tone.bg(Colors.white),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: GasPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: GasPalette.primary),
                ),
              ),
            ),
          ),
          if (roles.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip(null, 'Everyone'),
                for (final r in teamRoles.where((r) => roles.contains(r.value)))
                  _filterChip(r.value, r.label),
              ]),
            ),
          ],
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
            LayoutBuilder(builder: (context, box) {
              final columns = box.maxWidth >= 760 ? 2 : 1;
              final width = (box.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final m in shown)
                  SizedBox(width: width, child: _memberCard(m)),
              ]);
            }),
          if (!_loading && !_canManage) ...[
            const SizedBox(height: 12),
            Text(
                'Only the account owner, administrators and managers can add users.',
                style:
                    GoogleFonts.inter(fontSize: 12, color: GasPalette.muted)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Tone.bg(Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GasPalette.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: GasPalette.series),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GasPalette.ink)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, color: GasPalette.ink2)),
          ]),
        ),
      );

  Widget _filterChip(String? value, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _roleFilter == value,
          onSelected: (_) => setState(() => _roleFilter = value),
        ),
      );

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

  String _nameOf(Map<String, dynamic> m) =>
      '${m['firstname'] ?? ''} ${m['lastname'] ?? ''}'.trim();

  Widget _memberCard(Map<String, dynamic> m) {
    final name = _nameOf(m);
    final role = teamRole(m['user_type']);
    final active = m['is_active'] != false;
    final job = (m['job_title'] ?? '').toString();
    return Material(
      color: Tone.bg(Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GasPalette.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMember(m),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Opacity(
                opacity: active ? 1 : .45,
                child: teamAvatar(
                    name.isEmpty ? '${m['email']}' : name, role, 23)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(name.isEmpty ? m['email'] ?? '' : name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: GasPalette.ink)),
                      ),
                      if (m['is_primary_contact'] == true) ...[
                        const SizedBox(width: 6),
                        _chip(
                            'Owner', GasPalette.seriesSoft, GasPalette.series),
                      ],
                      if (!active) ...[
                        const SizedBox(width: 6),
                        _chip('Disabled', GasPalette.critSoft,
                            GasPalette.critInk),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(m['email'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: GasPalette.ink2)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _roleChip(role),
                      if (job.isNotEmpty)
                        _chip(job, GasPalette.panelAlt, GasPalette.ink2),
                    ]),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded, color: GasPalette.ink2),
          ]),
        ),
      ),
    );
  }

  Widget _roleChip(TeamRole role) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(role.icon, size: 12, color: GasPalette.series),
          const SizedBox(width: 4),
          Text(role.label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GasPalette.ink2)),
        ]),
      );

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

  /// Contact details with copy actions (the team API has no edit yet).
  Future<void> _showMember(Map<String, dynamic> m) {
    final name = _nameOf(m);
    final role = teamRole(m['user_type']);
    final rows = <(IconData, String, String)>[
      (Icons.mail_outline, 'Email', '${m['email'] ?? ''}'),
      if ('${m['cellphone_number'] ?? ''}'.isNotEmpty)
        (Icons.phone_outlined, 'Cellphone', '${m['cellphone_number']}'),
      if ('${m['job_title'] ?? ''}'.isNotEmpty)
        (Icons.badge_outlined, 'Job title', '${m['job_title']}'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Tone.bg(Colors.white),
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: teamAvatar(
                        name.isEmpty ? '${m['email']}' : name, role, 34)),
                const SizedBox(height: 12),
                Text(name.isEmpty ? '${m['email']}' : name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GasPalette.ink)),
                const SizedBox(height: 6),
                Center(child: _roleChip(role)),
                const SizedBox(height: 4),
                Text(role.forWhom,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: GasPalette.ink2)),
                const SizedBox(height: 16),
                for (final (icon, label, value) in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: GasPalette.series),
                    title: Text(label,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: GasPalette.ink2)),
                    subtitle: Text(value,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: GasPalette.ink)),
                    trailing: label == 'Job title'
                        ? null
                        : IconButton(
                            tooltip: 'Copy ${label.toLowerCase()}',
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: value));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$label copied')));
                            },
                          ),
                  ),
              ]),
        ),
      ),
    );
  }

  Future<void> _openAddUser() async {
    final added = await Navigator.of(context, rootNavigator: true).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AddUserFlowScreen(),
    ));
    if (added == true) _load();
  }
}
