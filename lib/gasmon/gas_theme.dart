/// Gas module look-and-feel tokens.
///
/// Matches the ArticSentinel light theme (slate scale + brand navy from
/// Constants.dart) so the dashboard reads as native. Flame orange is
/// reserved for the gas subject (level, usage); blue for money. The chart
/// pair (#EA580C, #3B82F6) passes CVD-separation and contrast checks on
/// white (ΔE 30.5 protan / 34.8 tritan).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mobile_forms.dart';

import 'gas_core.dart';

class GasPalette {
  GasPalette._();

  // Text (host slate scale)
  static const ink = Color(0xFF1E293B);
  static const ink2 = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);

  // Surfaces (host panel scale)
  static const panel = Color(0xFFF8FAFC);
  static const panelAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);

  // Brand + subject
  static const navy = Color(0xFF222B45); // host ctaColorLight
  static const flame = Color(0xFFEA580C);
  static const flameDeep = Color(0xFFC2410C);
  static const flameSoft = Color(0xFFFDBA74);
  static const series = Color(0xFF3B82F6); // money series

  // Status (host status colors — always paired with icon + label)
  static const good = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
  static const crit = Color(0xFFEF4444);

  static Color band(GasBand b) => switch (b) {
        GasBand.healthy => good,
        GasBand.warning => warn,
        GasBand.low => crit,
      };

  static Color severity(GasSeverity s) => switch (s) {
        GasSeverity.info => series,
        GasSeverity.warning => warn,
        GasSeverity.critical => crit,
      };
}

TextStyle gasEyebrow(BuildContext context) => _gasStyle(
      context,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: GasPalette.ink2,
    );

TextStyle gasTitle(BuildContext context) => _gasStyle(context,
    fontSize: 16, fontWeight: FontWeight.w700, color: GasPalette.ink);

TextStyle gasBody(BuildContext context) => _gasStyle(context,
    fontSize: 13, fontWeight: FontWeight.w500, color: GasPalette.ink2);

TextStyle gasSmall(BuildContext context) => _gasStyle(context,
    fontSize: 11.5, fontWeight: FontWeight.w500, color: GasPalette.ink2);

TextStyle gasData(BuildContext context, {double size = 22, Color? color}) =>
    _gasStyle(
      context,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? GasPalette.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _gasStyle(BuildContext context,
    {double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures}) {
  final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: fontFeatures);
  return isPhoneLayout(context) ? style : GoogleFonts.inter(textStyle: style);
}
