/// Create-account flow, in four short steps:
///   1. Company or personal account
///   2. Who you are (and the company name)
///   3. Password
///   4. Add purchased devices — optional, can be skipped
/// On finish it registers (api/signup/v2/), signs in, creates any devices
/// listed, and lands on the dashboard.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../services/auth_session.dart';
import '../widgets/mobile_forms.dart';

const _deviceTypes = <(String, String)>[
  ('device1', 'Refrigeration unit'),
  ('device2', 'Multi-zone temperature'),
  ('device3', 'Ice machine'),
  ('device4', 'Multi-compressor'),
  ('device5', 'Relay controller'),
  ('device6', 'Pressure monitor'),
  ('device7', 'Bottle vetting'),
  ('gas_cylinder', 'Gas cylinder'),
];

class _DeviceDraft {
  final id = TextEditingController();
  final name = TextEditingController();
  String type = 'device1';
  void dispose() {
    id.dispose();
    name.dispose();
  }
}

class SignUpFlowPage extends StatefulWidget {
  const SignUpFlowPage({super.key});

  @override
  State<SignUpFlowPage> createState() => _SignUpFlowPageState();
}

class _SignUpFlowPageState extends State<SignUpFlowPage> {
  int _step = 0;
  bool _busy = false;
  String _accountType = 'company';

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  final List<_DeviceDraft> _devices = [_DeviceDraft()];

  static const _titles = [
    ('Who is this account for?', 'You can add teammates later either way.'),
    ('Tell us about yourself', 'This is how your workspace will know you.'),
    ('Secure your account', 'Pick a password of at least 8 characters.'),
    ('Add your devices', 'Already purchased ArticSentinel devices? Add them now, or skip and do it later.'),
  ];

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _companyName, _password, _confirm]) {
      c.dispose();
    }
    for (final d in _devices) {
      d.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 20),
        [_stepType(), _stepDetails(), _stepSecurity(), _stepDevices()][_step],
        const SizedBox(height: 24),
        _actions(),
        const SizedBox(height: 16),
      ],
    );
    if (phone) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: content,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: GasPalette.page,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 520,
            padding: const EdgeInsets.fromLTRB(36, 28, 36, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GasPalette.border),
              boxShadow: const [
                BoxShadow(color: Color(0x14133648), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final (title, sub) = _titles[_step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _busy
                  ? null
                  : () {
                      if (_step == 0) {
                        context.canPop() ? context.pop() : context.go('/login');
                      } else {
                        setState(() => _step -= 1);
                      }
                    },
              icon: const Icon(Icons.arrow_back, color: GasPalette.ink),
            ),
            const Spacer(),
            Text('Step ${_step + 1} of 4',
                style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            minHeight: 6,
            backgroundColor: GasPalette.panelAlt,
            color: GasPalette.primary,
          ),
        ),
        const SizedBox(height: 22),
        Text('Create your account',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: GasPalette.series)),
        const SizedBox(height: 4),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: GasPalette.ink)),
        const SizedBox(height: 6),
        Text(sub, style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
      ],
    );
  }

  Widget _stepType() {
    Widget option(String value, IconData icon, String title, String sub) {
      final selected = _accountType == value;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _accountType = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? GasPalette.primary : GasPalette.border,
                width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? GasPalette.primary : GasPalette.panelAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: selected ? Colors.white : GasPalette.ink2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700, color: GasPalette.ink)),
                    const SizedBox(height: 2),
                    Text(sub, style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? GasPalette.primary : GasPalette.border),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        option('company', Icons.apartment, 'A company',
            'Monitoring for a business — restaurants, shops, facilities.'),
        const SizedBox(height: 12),
        option('personal', Icons.person_outline, 'Just me',
            'A personal workspace for my own equipment.'),
      ],
    );
  }

  Widget _stepDetails() {
    return Column(
      children: [
        if (_accountType == 'company') ...[
          _field(_companyName, 'Company name'),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(child: _field(_firstName, 'First name')),
            const SizedBox(width: 12),
            Expanded(child: _field(_lastName, 'Last name')),
          ],
        ),
        const SizedBox(height: 14),
        _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(_phone, 'Cellphone (optional)', keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _stepSecurity() {
    return Column(
      children: [
        _field(_password, 'Password',
            obscure: _hidePassword,
            suffix: IconButton(
              tooltip: _hidePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                  _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: GasPalette.ink2),
            )),
        const SizedBox(height: 14),
        _field(_confirm, 'Confirm password', obscure: true),
        const SizedBox(height: 14),
        Text(
          'By creating an account you accept our Terms of use and Privacy policy.',
          style: GoogleFonts.inter(fontSize: 12, color: GasPalette.muted),
        ),
      ],
    );
  }

  Widget _stepDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _devices.length; i++) _deviceCard(i),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => setState(() => _devices.add(_DeviceDraft())),
          style: OutlinedButton.styleFrom(
            foregroundColor: GasPalette.ink,
            side: const BorderSide(color: GasPalette.border),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add another device',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ),
        const SizedBox(height: 10),
        Text(
          'The Device ID is printed on the unit. Each device can also be added '
          'later in Device Management.',
          style: GoogleFonts.inter(fontSize: 12, color: GasPalette.muted),
        ),
      ],
    );
  }

  Widget _deviceCard(int i) {
    final d = _devices[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GasPalette.panelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GasPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Device ${i + 1}',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700, color: GasPalette.ink2)),
              const Spacer(),
              if (_devices.length > 1)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _devices.removeAt(i).dispose()),
                  icon: const Icon(Icons.close, size: 18, color: GasPalette.ink2),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: d.type,
            isExpanded: true,
            decoration: _decoration('Device type'),
            items: [
              for (final (value, label) in _deviceTypes)
                DropdownMenuItem(
                    value: value,
                    child: Text(label, style: GoogleFonts.inter(fontSize: 14))),
            ],
            onChanged: (v) => setState(() => d.type = v ?? d.type),
          ),
          const SizedBox(height: 12),
          _field(d.id, 'Device ID (on the unit)'),
          const SizedBox(height: 12),
          _field(d.name, 'Name it (e.g. Kitchen fridge)'),
        ],
      ),
    );
  }

  Widget _actions() {
    final last = _step == 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _busy ? null : _next,
          style: FilledButton.styleFrom(
            backgroundColor: GasPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text(_busy
              ? 'Working…'
              : last
                  ? 'Finish and open my dashboard'
                  : _step == 2
                      ? 'Create account'
                      : 'Continue'),
        ),
        if (last) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _finish(skipDevices: true),
            child: Text('Skip for now',
                style: GoogleFonts.inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: GasPalette.series)),
          ),
        ],
      ],
    );
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return mobileInputDecoration(
      context,
      InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: GasPalette.ink2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _field(TextEditingController controller, String label,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14.5, color: GasPalette.ink),
      decoration: _decoration(label, suffix: suffix),
    );
  }

  // ------------------------------------------------------------- actions

  void _toastError(String message) {
    MotionToast.error(
      description: Text(message, style: const TextStyle(color: Colors.white)),
      animationDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }

  bool get _emailLooksValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  void _next() {
    switch (_step) {
      case 0:
        setState(() => _step = 1);
      case 1:
        if (_accountType == 'company' && _companyName.text.trim().isEmpty) {
          return _toastError('Please enter the company name');
        }
        if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
          return _toastError('Please enter your first and last name');
        }
        if (!_emailLooksValid) return _toastError('Please enter a valid email');
        setState(() => _step = 2);
      case 2:
        if (_password.text.length < 8) {
          return _toastError('The password must be at least 8 characters');
        }
        if (_password.text != _confirm.text) {
          return _toastError("The passwords don't match");
        }
        setState(() => _step = 3);
      case 3:
        _finish(skipDevices: false);
    }
  }

  Future<void> _finish({required bool skipDevices}) async {
    final drafts = skipDevices
        ? <_DeviceDraft>[]
        : _devices
            .where((d) => d.id.text.trim().isNotEmpty || d.name.text.trim().isNotEmpty)
            .toList();
    for (final d in drafts) {
      if (d.id.text.trim().isEmpty || d.name.text.trim().isEmpty) {
        return _toastError('Each device needs both a Device ID and a name — or remove it.');
      }
    }

    setState(() => _busy = true);
    try {
      // 1. Register.
      final signup = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/signup/v2/'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_type': _accountType,
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'cellphone_number': _phone.text.trim(),
          if (_accountType == 'company') 'business_name': _companyName.text.trim(),
        }),
      );
      final signupBody = signup.body.isEmpty ? null : jsonDecode(signup.body);
      if (signup.statusCode != 201) {
        final error = (signupBody is Map ? signupBody['error'] : null)?.toString() ??
            'Could not create the account. Please try again.';
        if (error.toLowerCase().contains('email')) setState(() => _step = 1);
        _toastError(error);
        return;
      }

      // 2. Sign in with the new account.
      final login = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/login/'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'user_email': _email.text.trim(), 'password': _password.text}),
      );
      if (login.statusCode != 200) {
        _toastError('Account created — now sign in with your new details.');
        if (mounted) context.go('/login');
        return;
      }
      await AuthSession.applyLoginResponse(
          jsonDecode(login.body) as Map<String, dynamic>,
          password: _password.text);

      // 3. Add the purchased devices, if any.
      var added = 0;
      var failed = 0;
      for (final d in drafts) {
        try {
          final r = await http.post(
            Uri.parse('${Constants.articBaseUrl2}api/devices/create/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${Constants.authToken}',
            },
            body: jsonEncode({
              'business_id': Constants.business_uid,
              'device_id': d.id.text.trim(),
              'name': d.name.text.trim(),
              'device_type': d.type,
            }),
          );
          (r.statusCode == 200 || r.statusCode == 201) ? added++ : failed++;
        } catch (_) {
          failed++;
        }
      }

      if (!mounted) return;
      context.goNamed('dashboard');
      final summary = drafts.isEmpty
          ? 'Welcome to ArticSentinel!'
          : failed == 0
              ? 'Welcome! $added device${added == 1 ? '' : 's'} added.'
              : 'Welcome! $added added, $failed failed — retry in Device Management.';
      MotionToast.success(
        description: Text(summary, style: const TextStyle(color: Colors.white)),
        animationDuration: const Duration(milliseconds: 3000),
      ).show(context);
    } catch (e) {
      debugPrint('Signup failed: $e');
      _toastError('Could not create the account. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
