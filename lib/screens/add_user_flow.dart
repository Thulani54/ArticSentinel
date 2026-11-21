import '../widgets/app_tone.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../onboarding/device_setup_guide.dart';
import '../onboarding/setup_flow_frame.dart';
import '../services/shared_preferences.dart';
import '../widgets/mobile_forms.dart';

/// App roles, described by who they are for. Only "can add users" is
/// enforced by the server today (primary contact, administrators, managers).
class TeamRole {
  const TeamRole(this.value, this.label, this.forWhom, this.icon,
      {this.canAddUsers = false});
  final String value;
  final String label;
  final String forWhom;
  final IconData icon;
  final bool canAddUsers;
}

const teamRoles = [
  TeamRole('administrator', 'Administrator',
      'Runs the workspace for your business.', Iconsax.crown_1,
      canAddUsers: true),
  TeamRole('manager', 'Manager', 'Looks after sites, equipment and the team.',
      Iconsax.briefcase,
      canAddUsers: true),
  TeamRole('technician', 'Technician',
      'Services equipment and responds to alerts.', Iconsax.setting_2),
  TeamRole('customer', 'Team member',
      'Follows equipment and alerts day to day.', Iconsax.user),
  TeamRole('support', 'Support staff', 'Helps others use the workspace.',
      Iconsax.message_question),
  TeamRole('service_provider', 'Service provider',
      'An outside contractor who maintains your equipment.', Iconsax.truck),
];

TeamRole teamRole(String? value) =>
    teamRoles.firstWhere((r) => r.value == value, orElse: () => teamRoles[3]);

/// Adds the member; returns the one-time temporary password. Throw a String
/// to show the server's message.
typedef AddUserSubmit = Future<String> Function(Map<String, String> data);

Future<String> addTeamMember(Map<String, String> data) async {
  final token = await Sharedprefs.getAuthTokenPreference();
  final http.Response r;
  try {
    r = await http
        .post(Uri.parse('${Constants.articBaseUrl2}api/team/members/add/'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Token $token',
            },
            body: jsonEncode(data))
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    throw 'The user could not be added. Check your connection and try again.';
  }
  dynamic body;
  try {
    body = jsonDecode(r.body);
  } catch (_) {}
  if (r.statusCode == 201 &&
      body is Map &&
      body['temporary_password'] is String) {
    return body['temporary_password'] as String;
  }
  final message = body is Map ? body['error']?.toString() : null;
  throw (message != null && message.length <= 200)
      ? message
      : 'The user could not be added. Try again.';
}

/// Add a team member in three steps — who they are, their role, review —
/// then hand over the one-time temporary password.
class AddUserFlowScreen extends StatefulWidget {
  const AddUserFlowScreen({super.key, this.submit = addTeamMember});
  final AddUserSubmit submit;

  @override
  State<AddUserFlowScreen> createState() => _AddUserFlowScreenState();
}

class _AddUserFlowScreenState extends State<AddUserFlowScreen> {
  static const _steps = ['Who they are', 'Their role', 'Review and add'];
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _job = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'customer';
  int _step = 0;
  bool _busy = false;
  String? _error;
  String? _password;
  bool _copied = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _job, _phone]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String get _name => '${_first.text.trim()} ${_last.text.trim()}'.trim();

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _continue() {
    if (_step == 0 && !(_form.currentState?.validate() ?? false)) return;
    _go(_step + 1);
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final password = await widget.submit({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim(),
        'user_type': _role,
        'job_title': _job.text.trim(),
        'cellphone_number': _phone.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _password = password;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is String ? e : 'The user could not be added. Try again.';
        if (_error!.toLowerCase().contains('email')) _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _password != null;
    return PopScope(
      canPop: !_busy,
      child: SetupFlowFrame(
        title: done ? 'User added' : 'Add a team member',
        deviceLabel: done
            ? _email.text.trim()
            : Constants.business_name.trim().isEmpty
                ? 'Give someone access to your workspace'
                : 'Give someone access to ${Constants.business_name}',
        sideImage: DeviceSetupGuide.scene('person'),
        steps: _steps,
        step: done ? 2 : _step,
        complete: done,
        busy: _busy,
        onBack: done
            ? null
            : (_step == 0
                ? () => Navigator.of(context).maybePop()
                : () => _go(_step - 1)),
        closeLabel: done ? 'Done' : 'Cancel',
        onClose: () => Navigator.of(context).pop(done),
        scrollController: _scroll,
        sideNote: done
            ? null
            : const SetupNote(
                icon: Iconsax.shield_tick,
                title: 'Access',
                text:
                    'Everyone you add can see this workspace’s equipment and alerts.'),
        footer: FilledButton(
          key: const ValueKey('add-user-primary'),
          style: FilledButton.styleFrom(
              backgroundColor: GasPalette.primary,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder()),
          onPressed: _busy
              ? null
              : done
                  ? () => Navigator.of(context).pop(true)
                  : _step == 2
                      ? _add
                      : _continue,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(done
                  ? 'Done'
                  : (_step == 2
                      ? 'Add ${_first.text.trim().isEmpty ? 'user' : _first.text.trim()}'
                      : 'Continue')),
        ),
        body: Form(
          key: _form,
          child: AnimatedSwitcher(
            duration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ? 0 : 220),
            child: KeyedSubtree(
              key: ValueKey('$_step-$done'),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...done
                        ? _handOver()
                        : switch (_step) {
                            0 => _who(),
                            1 => _roleStep(),
                            _ => _review(),
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

  Widget _heading(String title, String intro) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: SetupFlowFrame.text(26, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(intro, style: SetupFlowFrame.text(15, color: GasPalette.ink2)),
        ]),
      );

  List<Widget> _who() => [
        SetupScene(asset: DeviceSetupGuide.scene('person')),
        _heading('Who are you adding?',
            'They sign in with this email address. Use one they check, so they can reset their password.'),
        _pair(_field(_first, 'First name', required: true),
            _field(_last, 'Last name', required: true)),
        _field(_email, 'Email',
            required: true, keyboard: TextInputType.emailAddress, email: true),
        _field(_job, 'Job title (optional)',
            helper: 'For example: Store manager'),
        _field(_phone, 'Cellphone (optional)', keyboard: TextInputType.phone),
      ];

  List<Widget> _roleStep() => [
        SetupScene(asset: DeviceSetupGuide.scene('roles')),
        _heading('Choose their role', 'Pick the closest fit for what they do.'),
        for (final r in teamRoles) _roleCard(r),
      ];

  Widget _roleCard(TeamRole r) {
    final selected = _role == r.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? GasPalette.seriesSoft : Tone.bg(Colors.white),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: selected ? GasPalette.series : GasPalette.border,
                  width: selected ? 1.5 : 1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _role = r.value),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: selected ? Tone.bg(Colors.white) : GasPalette.panelAlt,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(r.icon, size: 21, color: GasPalette.series),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.label,
                            style: SetupFlowFrame.text(15,
                                weight: FontWeight.w700)),
                        Text(r.forWhom,
                            style: SetupFlowFrame.text(13,
                                color: GasPalette.ink2)),
                        if (r.canAddUsers)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Can add users',
                                style: SetupFlowFrame.text(12,
                                    weight: FontWeight.w700,
                                    color: GasPalette.goodInk)),
                          ),
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
      ),
    );
  }

  List<Widget> _review() {
    final r = teamRole(_role);
    return [
      SetupScene(asset: DeviceSetupGuide.scene('invite')),
      _heading('Review and add',
          'We’ll create their account with a temporary password. You’ll see it once, on the next screen.'),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: GasPalette.panelAlt,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          _avatar(_name, r, 26),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name,
                  style: SetupFlowFrame.text(17, weight: FontWeight.w700)),
              Text(_email.text.trim(),
                  style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _pill(r.label),
                if (_job.text.trim().isNotEmpty) _pill(_job.text.trim()),
              ]),
            ]),
          ),
          IconButton(
              tooltip: 'Edit details',
              onPressed: () => _go(0),
              icon: const Icon(Iconsax.edit_2, size: 20)),
        ]),
      ),
    ];
  }

  List<Widget> _handOver() => [
        const SetupNote(
          icon: Iconsax.tick_circle,
          title: 'Account created',
          text:
              'Share these sign-in details privately — in person or a direct message, not a group chat.',
          tone: SetupNoteTone.success,
        ),
        const SizedBox(height: 20),
        Text('Temporary password',
            style: SetupFlowFrame.text(14, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          decoration: BoxDecoration(
              color: GasPalette.panelAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GasPalette.border)),
          child: Row(children: [
            Expanded(
              child: SelectableText(_password!,
                  style: SetupFlowFrame.text(18, weight: FontWeight.w700)
                      .copyWith(letterSpacing: 1)),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _password!));
                if (mounted) setState(() => _copied = true);
              },
              icon:
                  Icon(_copied ? Iconsax.tick_circle : Iconsax.copy, size: 18),
              label: Text(_copied ? 'Copied' : 'Copy'),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Copy it now — it can’t be shown again.',
            style: SetupFlowFrame.text(12, color: GasPalette.ink2)),
        const SizedBox(height: 24),
        Text('What ${_first.text.trim()} does next',
            style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        const SetupInstructionTile(
            number: 1,
            icon: Iconsax.mobile,
            title: 'Install or open Artic Sentinel',
            text: 'On iPhone, Android or at the web address your team uses.'),
        SetupInstructionTile(
            number: 2,
            icon: Iconsax.login,
            title: 'Sign in',
            text: 'With ${_email.text.trim()} and the temporary password.'),
        const SetupInstructionTile(
            number: 3,
            icon: Iconsax.lock_1,
            title: 'Keep it private',
            text:
                'The password opens their account, so it should only be shared with them.'),
      ];

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Tone.bg(Colors.white), borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            style: SetupFlowFrame.text(12,
                weight: FontWeight.w700, color: GasPalette.ink2)),
      );

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
        builder: (context, box) => box.maxWidth < 300
            ? Column(children: [a, b])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: a),
                const SizedBox(width: 12),
                Expanded(child: b),
              ]),
      );

  Widget _field(TextEditingController c, String label,
          {bool required = false,
          String? helper,
          TextInputType? keyboard,
          bool email = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: c,
          enabled: !_busy,
          keyboardType: keyboard,
          autocorrect: !email,
          textCapitalization: email || keyboard == TextInputType.phone
              ? TextCapitalization.none
              : TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: mobileInputDecoration(
              context,
              InputDecoration(
                labelText: label,
                helperText: helper,
                filled: true,
                fillColor: GasPalette.panelAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
              )),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (required && t.isEmpty) return 'Required.';
            if (email && t.isNotEmpty && !_emailPattern.hasMatch(t)) {
              return 'Enter a valid email address.';
            }
            return null;
          },
        ),
      );
}

/// Round initials avatar, tinted by role, shared with the team list.
Widget _avatar(String name, TeamRole role, double radius) =>
    teamAvatar(name, role, radius);

Widget teamAvatar(String name, TeamRole role, double radius) {
  final initials = name.trim().isEmpty
      ? '?'
      : name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((p) => p[0].toUpperCase())
          .join();
  final color = switch (role.value) {
    'administrator' => GasPalette.primary,
    'manager' => GasPalette.series,
    'technician' => GasPalette.good,
    'service_provider' => GasPalette.flame,
    _ => GasPalette.ink2,
  };
  return CircleAvatar(
    radius: radius,
    backgroundColor: color,
    child: Text(initials,
        style: SetupFlowFrame.text(radius * .62,
            weight: FontWeight.w700, color: Tone.auto(Colors.white))),
  );
}
