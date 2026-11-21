import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark switch for the native app.
///
/// Screens were written with literal light colours, so rather than thread a
/// theme through every widget they pass those colours through [Tone]. In light
/// mode [Tone] returns the colour untouched; in dark mode it maps it by the
/// role it plays (surface behind content, or ink drawn on top of it).
class AppAppearance {
  AppAppearance._();

  static const _modeKey = 'app_theme_mode';

  /// The user's choice. System follows the phone's dark mode setting.
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Load the saved choice before the first frame.
  static Future<void> load() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_modeKey);
      mode.value = ThemeMode.values.firstWhere((m) => m.name == saved,
          orElse: () => ThemeMode.system);
    } catch (_) {
      // Storage unavailable: keep following the system.
    }
    resolve();
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, value.name);
    } catch (_) {}
  }

  /// Recompute [Tone.dark] from the choice and the phone setting. Returns
  /// true when the effective brightness changed.
  static bool resolve() {
    final platformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final dark = !kIsWeb &&
        switch (mode.value) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system => platformDark,
        };
    final changed = dark != Tone.dark;
    Tone.dark = dark;
    SystemChrome.setSystemUIOverlayStyle(
        dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    return changed;
  }

  /// Colours are read while building, so a brightness change must rebuild
  /// every element, including const subtrees. State is kept.
  static void rebuildAll(BuildContext context) {
    void visit(Element element) {
      element.markNeedsBuild();
      // Painters compare their own fields, not the theme, so repaint too.
      if (element is RenderObjectElement) element.renderObject.markNeedsPaint();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }
}

class Tone {
  Tone._();

  static bool dark = false;

  /// A colour painted behind content: page, card, field, border, divider.
  /// Light colours become dark surfaces; dark ones are kept.
  static Color bg(Color? color) {
    final c = color ?? Colors.transparent;
    if (!dark) return c;
    final hsl = HSLColor.fromColor(c);
    if (hsl.lightness < 0.6) return c;
    if (hsl.saturation < 0.25 || hsl.lightness > 0.97) {
      // White is a card; near-whites sit a step above it; light greys are
      // borders and tracks.
      final l = hsl.lightness >= 0.995
          ? 0.115
          : 0.15 + (0.995 - hsl.lightness) * 0.45;
      // Cool slate, matching the palette's dark surfaces.
      return _hsl(c, 207, 0.3, l);
    }
    // Pastel status fills become dark tints of the same hue.
    return _hsl(c, hsl.hue, hsl.saturation.clamp(0.0, 0.5),
        0.15 + (1 - hsl.lightness) * 0.3);
  }

  /// A colour drawn on top of a surface: text, icon, progress, outline ink.
  /// Dark ink becomes light; light ink (e.g. white on a button) is kept.
  static Color fg(Color? color) {
    final c = color ?? Colors.transparent;
    if (!dark) return c;
    final hsl = HSLColor.fromColor(c);
    if (hsl.lightness > 0.5) return c;
    if (hsl.saturation < 0.2) {
      return _hsl(c, 207, 0.12, 0.95 - hsl.lightness * 0.75);
    }
    return _hsl(c, hsl.hue, hsl.saturation.clamp(0.0, 0.85),
        (1 - hsl.lightness * 0.8).clamp(0.62, 0.86));
  }

  /// Role unknown: light colours are treated as surfaces, dark as ink.
  static Color auto(Color? color) {
    final c = color ?? Colors.transparent;
    if (!dark) return c;
    final l = HSLColor.fromColor(c).lightness;
    if (l >= 0.6) return bg(c);
    if (l <= 0.45) return fg(c);
    return c;
  }

  static Color _hsl(Color source, double h, double s, double l) =>
      HSLColor.fromAHSL(source.a, h, s, l.clamp(0.0, 1.0)).toColor();
}

/// Rebuilds the app when the phone's appearance or the saved choice changes.
class AppearanceScope extends StatefulWidget {
  const AppearanceScope({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<AppearanceScope> createState() => _AppearanceScopeState();
}

class _AppearanceScopeState extends State<AppearanceScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppAppearance.mode.addListener(_update);
    AppAppearance.resolve();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppAppearance.mode.removeListener(_update);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _update();

  void _update() {
    if (!mounted || !AppAppearance.resolve()) return;
    setState(() {});
    AppAppearance.rebuildAll(context);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
