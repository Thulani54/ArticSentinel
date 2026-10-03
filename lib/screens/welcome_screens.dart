/// First-launch welcome tour: three pages on the brand navy, with the sonar
/// rings the logo is built from as the backdrop. Ends in "Create an account"
/// or "I already have an account".
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gasmon/gas_theme.dart';
import 'splash_screen.dart' show kSeenWelcomeKey;

class _Page {
  const _Page(this.icon, this.chips, this.title, this.body);
  final IconData icon;
  final List<(IconData, String)> chips;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.monitor_heart_outlined,
    [(Icons.ac_unit, '-18.2 °C'), (Icons.bolt, 'Compressor ON'), (Icons.wifi, 'Online')],
    'Your equipment,\nalways in view',
    'Fridges, freezers, ice machines and cold rooms report their readings '
        'around the clock, wherever you are.',
  ),
  _Page(
    Icons.propane_tank_outlined,
    [(Icons.scale, '12.5 kg on the scale'), (Icons.local_fire_department, '50% gas left'), (Icons.event, 'Refill ~22 Oct')],
    'Gas that never\nruns out on you',
    'Put a cylinder on a connected scale and watch the level, daily usage '
        'and the projected refill date.',
  ),
  _Page(
    Icons.notifications_active_outlined,
    [(Icons.warning_amber, 'Door left open'), (Icons.forum_outlined, 'Ask the assistant'), (Icons.group_outlined, 'Whole team alerted')],
    'Problems found\nbefore they cost you',
    'Alerts reach your team the moment something drifts, and the assistant '
        'answers questions about any device.',
  ),
];

class WelcomeScreens extends StatefulWidget {
  const WelcomeScreens({super.key});

  @override
  State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _done(String route) async {
    try {
      (await SharedPreferences.getInstance()).setBool(kSeenWelcomeKey, true);
    } catch (_) {}
    if (mounted) context.go(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: GasPalette.navy,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _SonarPainter())),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 12, 0),
                  child: Row(
                    children: [
                      Text('Artic Sentinel.',
                          style: GoogleFonts.lato(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w300)),
                      const Spacer(),
                      if (!last)
                        TextButton(
                          onPressed: () => _done('/login'),
                          child: Text('Skip',
                              style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _WelcomePage(page: _pages[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: () {
                          if (last) {
                            _done('/signup');
                          } else {
                            _controller.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: GasPalette.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          textStyle: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: Text(last ? 'Create an account' : 'Next'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _done('/login'),
                        child: Text('I already have an account',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 26),
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Icon(page.icon, size: 72, color: Colors.white),
                ),
                for (var i = 0; i < page.chips.length; i++)
                  Align(
                    alignment: [
                      Alignment.topRight,
                      Alignment.centerLeft,
                      Alignment.bottomRight
                    ][i],
                    child: _chip(page.chips[i].$1, page.chips[i].$2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(page.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 27,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text(page.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14.5, height: 1.55, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: GasPalette.flame),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GasPalette.ink)),
        ],
      ),
    );
  }
}

/// Concentric sonar arcs, echoing the ring logo.
class _SonarPainter extends CustomPainter {
  const _SonarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width * 0.5, size.height * 0.30);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 6; i++) {
      paint.color = Colors.white.withValues(alpha: 0.05 + 0.015 * (6 - i));
      canvas.drawArc(
          Rect.fromCircle(center: centre, radius: 70.0 * i),
          math.pi * (0.9 + i * 0.07),
          math.pi * 1.25,
          false,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonarPainter oldDelegate) => false;
}
