import 'package:google_fonts/google_fonts.dart';
import '../../custom_widgets/customCard.dart';
import '../../gasmon/gas_widgets.dart';
import 'package:flutter/material.dart';
import '../../gasmon/gas_theme.dart';
import '../../widgets/mobile_forms.dart';

/// Keep the existing desktop styling; phone controls share the app tokens.
BoxDecoration accountSurface(BuildContext context, BoxDecoration original,
    {double radius = 14}) {
  if (!isPhoneLayout(context)) return original;
  return original.copyWith(
    color: GasPalette.panel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: GasPalette.border),
    boxShadow: const [
      BoxShadow(color: Color(0x05133648), blurRadius: 3, offset: Offset(0, 2))
    ],
  );
}

ButtonStyle accountButtonStyle(BuildContext context, ButtonStyle original,
    {bool primary = false}) {
  if (!isPhoneLayout(context)) return original;
  return original.copyWith(
    shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    backgroundColor: primary
        ? WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? GasPalette.primary.withValues(alpha: 0.38)
                : GasPalette.primary)
        : original.backgroundColor,
    foregroundColor: primary
        ? const WidgetStatePropertyAll(Colors.white)
        : original.foregroundColor,
    elevation: const WidgetStatePropertyAll(0),
  );
}

/// Keep metadata groups readable when a phone cannot fit them in one row.
class AccountFlow extends StatelessWidget {
  const AccountFlow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (!isPhoneLayout(context)) return Row(children: children);
    return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final child in children)
            if (child is! Spacer && child is! SizedBox) child,
        ]);
  }
}

/// Use the shared panel on phones while retaining the desktop card contract.
class AccountCard extends StatelessWidget {
  const AccountCard(
      {super.key,
      required this.child,
      required this.elevation,
      required this.color,
      this.surfaceTintColor,
      this.shape});
  final Widget child;
  final double elevation;
  final Color color;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  @override
  Widget build(BuildContext context) => isPhoneLayout(context)
      ? GPanel(padding: EdgeInsets.zero, child: child)
      : CustomCard(
          elevation: elevation,
          color: color,
          surfaceTintColor: surfaceTintColor,
          shape: shape,
          child: child);
}

TextStyle accountInter(BuildContext context,
    {TextStyle? textStyle,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle}) {
  final style = (textStyle ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle);
  if (!isPhoneLayout(context)) return GoogleFonts.inter(textStyle: style);
  final mobileColor = switch (style.color) {
    const Color(0xFF000000) ||
    const Color(0xFF1E293B) ||
    const Color(0xFF282828) =>
      GasPalette.ink,
    const Color(0xFF64748B) || const Color(0xFF6B7280) => GasPalette.ink2,
    const Color(0xFF9CA3AF) || const Color(0xFF94A3B8) => GasPalette.muted,
    _ => style.color,
  };
  return style.copyWith(fontFamily: 'Inter', color: mobileColor);
}

/// A phone-friendly reading surface for existing profile values.
class AccountDetailSection extends StatelessWidget {
  const AccountDetailSection({super.key, required this.title, required this.values});
  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) => GPanel(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: gasTitle(context).copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      const Padding(padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: GasPalette.border)),
      for (var index = 0; index < values.length; index++) ...[
        if (index > 0) const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: Text(values.keys.elementAt(index),
              style: gasSmall(context).copyWith(height: 1.5))),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: SelectableText(
            values.values.elementAt(index).trim().isEmpty
                ? 'Not provided' : values.values.elementAt(index),
            textAlign: TextAlign.end,
            style: gasBody(context).copyWith(
                color: values.values.elementAt(index).trim().isEmpty
                    ? GasPalette.muted : GasPalette.ink,
                height: 1.5),
          )),
        ]),
      ],
    ]),
  );
}
