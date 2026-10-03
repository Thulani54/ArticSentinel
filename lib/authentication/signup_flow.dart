/// Three-step account creation, followed by authenticated guided device setup.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../services/auth_session.dart';
import '../widgets/mobile_forms.dart';

class SignUpFlowPage extends StatefulWidget {
  const SignUpFlowPage(
      {super.key, this.client, this.applySession, this.initialDeviceType});

  final http.Client? client;
  final Future<void> Function(Map<String, dynamic>, String)? applySession;
  final String? initialDeviceType;

  @override
  State<SignUpFlowPage> createState() => _SignUpFlowPageState();
}

class _SignUpFlowPageState extends State<SignUpFlowPage> {
  int _step = 0;
  bool _busy = false;
  bool _accountCreated = false;
  String? _error;
  late final http.Client _client = widget.client ?? http.Client();
  String _accountType = 'company';

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _companyName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;

  static const _titles = [
    ('Who is this account for?', 'You can add teammates later either way.'),
    ('Tell us about yourself', 'This is how your workspace will know you.'),
    ('Secure your account', 'Pick a password of at least 8 characters.'),
  ];

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _companyName,
      _password,
      _confirm
    ]) {
      c.dispose();
    }
    if (widget.client == null) _client.close();
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
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: [_stepType(), _stepDetails(), _stepSecurity()][_step],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Semantics(
              liveRegion: true,
              child: Text(_error!,
                  style:
                      const TextStyle(color: GasPalette.critInk, height: 1.5))),
        ],
        const SizedBox(height: 24),
        _actions(),
        const SizedBox(height: 16),
      ],
    );
    if (phone) {
      return PopScope(
          canPop: !_busy,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: content,
              ),
            ),
          ));
    }
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
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
                    BoxShadow(
                        color: Color(0x14133648),
                        blurRadius: 24,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: content,
              ),
            ),
          ),
        ));
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
                      if (_step == 0 || _accountCreated) {
                        context.canPop() ? context.pop() : context.go('/login');
                      } else {
                        setState(() {
                          _step -= 1;
                          _error = null;
                        });
                      }
                    },
              icon: const Icon(Icons.arrow_back, color: GasPalette.ink),
            ),
            const Spacer(),
            Text('Step ${_step + 1} of 3',
                style:
                    GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 6,
            backgroundColor: GasPalette.panelAlt,
            color: GasPalette.primary,
          ),
        ),
        const SizedBox(height: 22),
        Text('Create your account',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GasPalette.series)),
        const SizedBox(height: 4),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: GasPalette.ink)),
        const SizedBox(height: 6),
        Text(sub,
            style: GoogleFonts.inter(fontSize: 13.5, color: GasPalette.ink2)),
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
                child: Icon(icon,
                    color: selected ? Colors.white : GasPalette.ink2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: GasPalette.ink)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: GasPalette.ink2)),
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
        MobileFormRow(
          children: [
            Expanded(child: _field(_firstName, 'First name')),
            const SizedBox(width: 12),
            Expanded(child: _field(_lastName, 'Last name')),
          ],
        ),
        const SizedBox(height: 14),
        _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(_phone, 'Cellphone (optional)',
            keyboardType: TextInputType.phone),
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
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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

  Widget _actions() {
    final last = _step == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _busy ? null : _next,
          style: FilledButton.styleFrom(
            backgroundColor: GasPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text(_busy
              ? (_accountCreated ? 'Signing you in…' : 'Working…')
              : _accountCreated
                  ? 'Sign in and connect devices'
                  : last
                      ? 'Create account'
                      : 'Continue'),
        ),
        const SizedBox(height: 8),
        if (last) ...[
          Text('Next, we’ll help you connect your devices. You can skip setup.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: GasPalette.ink2)),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: _busy ? null : () => context.push('/products'),
          child: const Text('Explore our products'),
        ),
        if (_accountCreated || _error != null)
          TextButton(
            onPressed: _busy ? null : () => context.go('/login'),
            child: const Text('Go to sign in'),
          ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      enabled: !_busy && !_accountCreated,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14.5, color: GasPalette.ink),
      decoration: _decoration(label, suffix: suffix),
    );
  }

  // ------------------------------------------------------------- actions

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  bool get _emailLooksValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        setState(() => _step = 1);
      case 1:
        if (_accountType == 'company' && _companyName.text.trim().isEmpty) {
          return _showError('Please enter the company name.');
        }
        if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
          return _showError('Please enter your first and last name.');
        }
        if (!_emailLooksValid) return _showError('Please enter a valid email.');
        setState(() => _step = 2);
      case 2:
        if (_password.text.length < 8) {
          return _showError('The password must be at least 8 characters.');
        }
        if (_password.text != _confirm.text) {
          return _showError("The passwords don't match.");
        }
        _finish();
    }
  }

  Map<String, dynamic> _responseBody(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Remember a successful registration. A failed auto-login can be retried
      // without registering the account again or creating duplicate devices.
      if (!_accountCreated) {
        final signup = await _client
            .post(
              Uri.parse('${Constants.articBaseUrl2}api/signup/v2/'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'account_type': _accountType,
                'first_name': _firstName.text.trim(),
                'last_name': _lastName.text.trim(),
                'email': _email.text.trim(),
                'password': _password.text,
                'cellphone_number': _phone.text.trim(),
                if (_accountType == 'company')
                  'business_name': _companyName.text.trim(),
              }),
            )
            .timeout(const Duration(seconds: 25));
        if (!mounted) return;
        if (signup.statusCode != 201) {
          final responseError = _responseBody(signup)['error'];
          final error = responseError is String && responseError.length <= 220
              ? responseError
              : 'Could not create the account. Please try again.';
          if (error.toLowerCase().contains('email')) setState(() => _step = 1);
          _showError(error);
          return;
        }
        setState(() => _accountCreated = true);
      }
      final login = await _client
          .post(
            Uri.parse('${Constants.articBaseUrl2}api/login/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'user_email': _email.text.trim(), 'password': _password.text}),
          )
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      final body = _responseBody(login);
      if (login.statusCode != 200 ||
          body['token'] is! String ||
          (body['token'] as String).isEmpty ||
          body['user'] is! Map) {
        _showError('Your account was created. We could not sign you in yet. '
            'Try again below, or open the sign-in page.');
        return;
      }
      if (widget.applySession != null) {
        await widget.applySession!(body, _password.text);
      } else {
        await AuthSession.applyLoginResponse(body, password: _password.text);
      }
      if (!mounted) return;
      final type = widget.initialDeviceType;
      context.go(Uri(
              path: '/device-setup',
              queryParameters: type == null ? null : {'type': type})
          .toString());
    } catch (_) {
      _showError(_accountCreated
          ? 'Your account was created. Check your connection and try signing in again.'
          : 'We could not confirm account creation. Check your connection, or try signing in if the account was created.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
