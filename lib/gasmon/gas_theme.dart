/// Gas module look-and-feel tokens.
///
/// Same tokens as the ArticSentinel website, so the gas screens look alike in
/// the app and the browser. Flame orange is reserved for the gas subject
/// (level, usage); blue for money.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_tone.dart';
import '../widgets/mobile_forms.dart';

import 'gas_core.dart';

class GasPalette {
  GasPalette._();

  // Tokens shared with the website (artic-web-new/src/styles.css :root), so
  // the app and uat/articsentinel.com read as one product.

  // Text
  static Color get ink =>
      Tone.dark ? const Color(0xFFE6EEF3) : const Color(0xFF173648);
  static Color get ink2 =>
      Tone.dark ? const Color(0xFFA3B4C0) : const Color(0xFF607686);
  static Color get muted =>
      Tone.dark ? const Color(0xFF8A9DAA) : const Color(0xFF718694);

  // Surfaces
  static Color get page =>
      Tone.dark ? const Color(0xFF0B1319) : const Color(0xFFF2F6F9);
  static Color get panel =>
      Tone.dark ? const Color(0xFF131D25) : const Color(0xFFFFFFFF);
  static Color get panelAlt =>
      Tone.dark ? const Color(0xFF18242E) : const Color(0xFFF6F9FB);
  static Color get border =>
      Tone.dark ? const Color(0xFF26343F) : const Color(0xFFDCE6EC);

  // Brand + subject
  // The app-wide primary button colour (Constants.ctaColorLight).
  static Color get primary =>
      Tone.dark ? const Color(0xFF4A7FE0) : const Color(0xFF222B45);
  static Color get navy =>
      Tone.dark ? const Color(0xFF0E2A3A) : const Color(0xFF133648);
  static Color get flame =>
      Tone.dark ? const Color(0xFFE0703A) : const Color(0xFFBF521B);
  static Color get flameDeep =>
      Tone.dark ? const Color(0xFFF08A55) : const Color(0xFFA24313);
  static Color get flameSoft =>
      Tone.dark ? const Color(0xFF3A2416) : const Color(0xFFFFEDD5);
  static Color get series =>
      Tone.dark ? const Color(0xFF4C9BE8) : const Color(0xFF176BBA); // money series, primary buttons
  static Color get seriesSoft =>
      Tone.dark ? const Color(0xFF16293D) : const Color(0xFFDBEAFE);

  // Status (always paired with icon + label)
  static Color get good =>
      Tone.dark ? const Color(0xFF2DB38D) : const Color(0xFF158367);
  static Color get goodSoft =>
      Tone.dark ? const Color(0xFF0F2E25) : const Color(0xFFD1FAE5);
  static Color get goodInk =>
      Tone.dark ? const Color(0xFF5FD3AE) : const Color(0xFF047857);
  static Color get warn =>
      Tone.dark ? const Color(0xFFF5A524) : const Color(0xFFF59E0B);
  static Color get warnSoft =>
      Tone.dark ? const Color(0xFF35290F) : const Color(0xFFFEF3C7);
  static Color get warnInk =>
      Tone.dark ? const Color(0xFFF6C674) : const Color(0xFF92400E);
  static Color get warnLine =>
      Tone.dark ? const Color(0xFF5C4513) : const Color(0xFFFDE68A);
  static Color get crit =>
      Tone.dark ? const Color(0xFFF06060) : const Color(0xFFEF4444);
  static Color get critSoft =>
      Tone.dark ? const Color(0xFF3A1A1C) : const Color(0xFFFEE2E2);
  static Color get critInk =>
      Tone.dark ? const Color(0xFFF59A9A) : const Color(0xFFB91C1C);
  static Color get critLine =>
      Tone.dark ? const Color(0xFF5E2A2D) : const Color(0xFFFECACA);

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
