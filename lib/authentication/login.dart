/// Sign-in screen. Full-bleed on phones, a centred card on wide screens,
/// styled with the same tokens as the website. Email + password, Continue
/// with Google, and the door into the sign-up flow.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';

import '../constants/Constants.dart';
import '../gasmon/gas_theme.dart';
import '../services/auth_session.dart';
import '../services/google_auth.dart';
import '../widgets/mobile_forms.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    final form = _buildForm(phone);
    if (phone) {
      // Full width and height: the form IS the page.
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: form,
            ),
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
            width: 460,
            padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
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
            child: form,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool phone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: phone ? 28 : 0),
        Center(
          child: Image.asset('lib/assets/artic_logo.png',
              height: phone ? 88 : 104, width: phone ? 88 : 104),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Artic Sentinel.',
              style: GoogleFonts.lato(
                  fontSize: phone ? 26 : 30,
                  color: GasPalette.primary,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w300)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Sign in to your workspace',
              style: GoogleFonts.inter(fontSize: 13, color: GasPalette.ink2)),
        ),
        const SizedBox(height: 28),
        _field(
          controller: _email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 14),
        _field(
          controller: _password,
          label: 'Password',
          obscure: _hidePassword,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _signIn(),
          suffix: IconButton(
            tooltip: _hidePassword ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
            icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: GasPalette.ink2),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _signIn,
          style: FilledButton.styleFrom(
            backgroundColor: GasPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text(_busy ? 'Signing in…' : 'Sign in'),
        ),
        const SizedBox(height: 14),
        Row(children: [
          const Expanded(child: Divider(color: GasPalette.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or',
                style:
                    GoogleFonts.inter(fontSize: 12, color: GasPalette.muted)),
          ),
          const Expanded(child: Divider(color: GasPalette.border)),
        ]),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: GasPalette.ink,
            side: const BorderSide(color: GasPalette.border),
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            textStyle:
                GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          icon: const FaIcon(FontAwesomeIcons.google,
              size: 18, color: Color(0xFF4285F4)),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => context.push(Uri(
                    path: '/signup',
                    queryParameters:
                        GoRouterState.of(context).uri.queryParameters['type'] ==
                                null
                            ? null
                            : {
                                'type': GoRouterState.of(context)
                                    .uri
                                    .queryParameters['type']!
                              },
                  ).toString()),
          style: OutlinedButton.styleFrom(
            foregroundColor: GasPalette.ink,
            side: const BorderSide(color: GasPalette.border),
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            textStyle:
                GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          child: const Text('Create an account'),
        ),
        TextButton(
          onPressed: _busy ? null : () => context.push('/products'),
          child: const Text('Explore our products'),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'By signing in you accept our Terms of use and Privacy policy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: GasPalette.muted),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Artic Sentinel © ${DateTime.now().year}. All rights reserved',
            style: GoogleFonts.inter(fontSize: 11.5, color: GasPalette.muted),
          ),
        ),
        SizedBox(height: phone ? 20 : 0),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(fontSize: 14.5, color: GasPalette.ink),
      decoration: mobileInputDecoration(
        context,
        InputDecoration(
          labelText: label,
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
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
      ),
    );
  }

  // ---------------------------------------------------------------- actions

  void _toastError(String message) {
    MotionToast.error(
      description: Text(message, style: const TextStyle(color: Colors.white)),
      animationDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }

  Future<void> _finishSignIn(Map<String, dynamic> body,
      {String password = ''}) async {
    await AuthSession.applyLoginResponse(body, password: password);
    _email.clear();
    _password.clear();
    if (!mounted) return;
    final query = GoRouterState.of(context).uri.queryParameters;
    if (body['is_new_account'] == true || query['next'] == 'device-setup') {
      context.go(Uri(
              path: '/device-setup',
              queryParameters:
                  query['type'] == null ? null : {'type': query['type']!})
          .toString());
    } else {
      context.goNamed('dashboard');
    }
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    if (email.isEmpty) return _toastError('Please enter your email');
    if (_password.text.isEmpty) {
      return _toastError('Please enter your password');
    }
    setState(() => _busy = true);
    try {
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/login/'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'user_email': email, 'password': _password.text.trim()}),
      );
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['message'] == 'Login successful') {
        await _finishSignIn(body, password: _password.text.trim());
        return;
      }
      _toastError((body is Map ? body['message'] : null)?.toString() ??
          'Login failed. Please try again.');
    } catch (e) {
      debugPrint('Login failed: $e');
      _toastError('Could not sign in. Please try again later.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final result = await GoogleAuth.signIn();
      if (result.cancelled) return;
      if (result.body != null) {
        await _finishSignIn(result.body!);
        return;
      }
      _toastError(result.error ?? 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
