/// Animated splash: the sonar logo sweeps in, then the app decides where to
/// go — dashboard when signed in, the welcome tour on first launch,
/// otherwise the sign-in screen.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gasmon/gas_theme.dart';
import '../services/shared_preferences.dart';

const String kSeenWelcomeKey = 'seen_welcome_v1';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Let the brand moment play while preferences load.
    final results = await Future.wait([
      Sharedprefs.getUserLoggedInSharedPreference(),
      SharedPreferences.getInstance(),
      Future.delayed(const Duration(milliseconds: 1700)),
    ]);
    if (!mounted) return;
    final loggedIn = results[0] as bool? ?? false;
    final prefs = results[1] as SharedPreferences;
    bool seenWelcome = false;
    try {
      seenWelcome = prefs.getBool(kSeenWelcomeKey) ?? false;
    } catch (_) {}
    if (loggedIn) {
      context.go('/dashboard');
    } else if (!seenWelcome) {
      context.go('/welcome');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_ctrl.value);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.85 + 0.15 * t,
                    child: Image.asset('lib/assets/artic_logo.png',
                        height: 120, width: 120),
                  ),
                  const SizedBox(height: 16),
                  Text('Artic Sentinel.',
                      style: GoogleFonts.lato(
                          fontSize: 30,
                          color: GasPalette.primary,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w300)),
                  const SizedBox(height: 6),
                  Text('Always in view',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: GasPalette.ink2,
                          letterSpacing: 0.4)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
