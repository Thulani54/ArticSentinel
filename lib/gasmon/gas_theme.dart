/// Gas module look-and-feel tokens.
///
/// Same tokens as the ArticSentinel website, so the gas screens look alike in
/// the app and the browser. Flame orange is reserved for the gas subject
/// (level, usage); blue for money.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mobile_forms.dart';

import 'gas_core.dart';

class GasPalette {
  GasPalette._();

  // Tokens shared with the website (artic-web-new/src/styles.css :root), so
  // the app and uat/articsentinel.com read as one product.

  // Text
  static const ink = Color(0xFF173648);
  static const ink2 = Color(0xFF607686);
  static const muted = Color(0xFF718694);

  // Surfaces
  static const page = Color(0xFFF2F6F9);
  static const panel = Color(0xFFFFFFFF);
  static const panelAlt = Color(0xFFF6F9FB);
  static const border = Color(0xFFDCE6EC);

  // Brand + subject
  // The app-wide primary button colour (Constants.ctaColorLight).
  static const primary = Color(0xFF222B45);
  static const navy = Color(0xFF133648);
  static const flame = Color(0xFFBF521B);
  static const flameDeep = Color(0xFFA24313);
  static const flameSoft = Color(0xFFFFEDD5);
  static const series = Color(0xFF176BBA); // money series, primary buttons
  static const seriesSoft = Color(0xFFDBEAFE);

  // Status (always paired with icon + label)
  static const good = Color(0xFF158367);
  static const goodSoft = Color(0xFFD1FAE5);
  static const goodInk = Color(0xFF047857);
  static const warn = Color(0xFFF59E0B);
  static const warnSoft = Color(0xFFFEF3C7);
  static const warnInk = Color(0xFF92400E);
  static const warnLine = Color(0xFFFDE68A);
  static const crit = Color(0xFFEF4444);
  static const critSoft = Color(0xFFFEE2E2);
  static const critInk = Color(0xFFB91C1C);
  static const critLine = Color(0xFFFECACA);

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
      fontSize: 12,
      fontWeight: FontWeight.w700,
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
