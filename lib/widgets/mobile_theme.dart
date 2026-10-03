import 'package:flutter/material.dart';

import '../gasmon/gas_theme.dart';

/// Native app defaults. Individual gas and authentication screens keep their
/// existing components; the web app retains its own theme.
ThemeData articMobileTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: GasPalette.primary,
    primary: GasPalette.primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: GasPalette.ink,
    outline: GasPalette.border,
  );
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(32));
  final primaryButton = ElevatedButton.styleFrom(
    backgroundColor: GasPalette.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(44, 48),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: pill,
    textStyle: const TextStyle(
        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
  );
  final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: GasPalette.page);
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: GasPalette.ink, displayColor: GasPalette.ink),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    filledButtonTheme: FilledButtonThemeData(style: primaryButton),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      foregroundColor: GasPalette.primary,
      minimumSize: const Size(44, 48),
      side: const BorderSide(color: GasPalette.border),
      shape: pill,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    )),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      foregroundColor: GasPalette.primary,
      shape: pill,
      minimumSize: const Size(44, 44),
    )),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
      foregroundColor: GasPalette.ink2,
      shape: pill,
    )),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: GasPalette.navy.withValues(alpha: 0.06),
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: GasPalette.border)),
    ),
    dividerTheme:
        const DividerThemeData(color: GasPalette.border, thickness: 1),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.white,
      foregroundColor: GasPalette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: GasPalette.ink),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: GasPalette.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: GasPalette.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: GasPalette.primary, width: 1.5)),
      labelStyle: const TextStyle(color: GasPalette.ink2),
    ),
  );
}
