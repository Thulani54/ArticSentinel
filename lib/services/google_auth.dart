/// "Continue with Google": native Google sign-in, then the backend exchanges
/// the Google ID token for an ArticSentinel session (POST api/auth/google/).
///
/// The client IDs below come from the Google Cloud console (APIs & Services →
/// Credentials) for the ArticSentinel OAuth app. While they are empty the
/// button explains that Google sign-in isn't configured yet.
library;

import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../constants/Constants.dart';

/// OAuth 2.0 client of type iOS (bundle id com.navario.articSentinel).
const String kGoogleIosClientId =
    '182447063043-brj8req3aq2oh9unrjk9dh55odsti8n7.apps.googleusercontent.com';

/// OAuth 2.0 client of type Web — the backend verifies tokens against this
/// audience too, and Android needs it as the serverClientId.
const String kGoogleWebClientId =
    '182447063043-qiaakjsqtefcdvckd8s5thp4ppls7pps.apps.googleusercontent.com';

class GoogleAuthResult {
  GoogleAuthResult.success(this.body)
      : cancelled = false,
        error = null;
  GoogleAuthResult.cancelled()
      : body = null,
        cancelled = true,
        error = null;
  GoogleAuthResult.failed(this.error)
      : body = null,
        cancelled = false;

  final Map<String, dynamic>? body; // the api/login/-shaped response
  final bool cancelled;
  final String? error;
}

class GoogleAuth {
  GoogleAuth._();

  static bool get isConfigured => kGoogleWebClientId.isNotEmpty;

  static Future<GoogleAuthResult> signIn() async {
    if (!isConfigured) {
      return GoogleAuthResult.failed(
          "Google sign-in isn't set up yet. Use your email and password.");
    }
    try {
      final google = GoogleSignIn(
        clientId: kGoogleIosClientId.isEmpty ? null : kGoogleIosClientId,
        serverClientId: kGoogleWebClientId,
        scopes: const ['email'],
      );
      final account = await google.signIn();
      if (account == null) return GoogleAuthResult.cancelled();
      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        return GoogleAuthResult.failed(
            "Google didn't return a sign-in token. Try again.");
      }
      final response = await http.post(
        Uri.parse('${Constants.articBaseUrl2}api/auth/google/'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return GoogleAuthResult.success(body);
      }
      final message = body is Map ? body['message'] : null;
      return GoogleAuthResult.failed(
          message?.toString() ?? 'Google sign-in failed. Try again.');
    } catch (e) {
      return GoogleAuthResult.failed(
          'Could not complete Google sign-in. Check your connection.');
    }
  }
}
