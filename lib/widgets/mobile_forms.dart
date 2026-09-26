import 'package:flutter/material.dart';

/// Shared phone layout. Desktop/tablet widgets retain their original styling.
bool isPhoneLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

InputDecoration mobileInputDecoration(
    BuildContext context, InputDecoration original) {
  if (!isPhoneLayout(context)) return original;
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: color),
      );
  return original.copyWith(
    prefixIcon: const SizedBox.shrink(),
    prefixIconConstraints: const BoxConstraints.tightFor(width: 0, height: 0),
    suffixIcon: _fieldAction(original.suffixIcon),
    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    labelStyle: const TextStyle(color: Color(0xFF50586B), fontSize: 14),
    hintStyle: const TextStyle(color: Color(0xFF697386), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    border: border(const Color(0xFFD9DDE5)),
    enabledBorder: border(const Color(0xFFD9DDE5)),
    disabledBorder: border(const Color(0xFFE3E6ED)),
    focusedBorder: border(const Color(0xFF252C44)),
    errorBorder: border(const Color(0xFFB42318)),
    focusedErrorBorder: border(const Color(0xFFB42318)),
    errorMaxLines: 3,
    helperMaxLines: 3,
  );
}

Widget? _fieldAction(Widget? original) {
  if (original is IconButton) {
    return TextButton(
        onPressed: original.onPressed, child: Text(original.tooltip ?? 'Open'));
  }
  if (original is InkWell) {
    return TextButton(onPressed: original.onTap, child: const Text('Choose'));
  }
  return original == null ? null : const SizedBox.shrink();
}

BoxDecoration mobileFlatDecoration(
    BuildContext context, BoxDecoration original) {
  if (!isPhoneLayout(context) || original.gradient == null) return original;
  return BoxDecoration(
    color: original.gradient!.colors.first,
    image: original.image,
    border: original.border,
    borderRadius: original.borderRadius,
    shape: original.shape,
  );
}

/// Unwrap horizontal flex children when fields become a vertical stack.
class MobileFormRow extends StatelessWidget {
  const MobileFormRow(
      {super.key,
      required this.children,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.mainAxisSize = MainAxisSize.max,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.textDirection,
      this.verticalDirection = VerticalDirection.down,
      this.textBaseline});
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  @override
  Widget build(BuildContext context) {
    if (!isPhoneLayout(context))
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in children)
          if (child is Flexible)
            child.child
          else if (child is SizedBox &&
              child.width != null &&
              child.child == null)
            const SizedBox(height: 16)
          else
            child,
      ],
    );
  }
}

class MobileDialog extends StatelessWidget {
  const MobileDialog(
      {super.key,
      this.child,
      this.backgroundColor,
      this.elevation,
      this.shadowColor,
      this.surfaceTintColor,
      this.insetAnimationDuration = const Duration(milliseconds: 100),
      this.insetAnimationCurve = Curves.decelerate,
      this.insetPadding =
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      this.clipBehavior = Clip.none,
      this.shape,
      this.alignment});
  final Widget? child;
  final Color? backgroundColor, shadowColor, surfaceTintColor;
  final double? elevation;
  final Duration insetAnimationDuration;
  final Curve insetAnimationCurve;
  final EdgeInsets? insetPadding;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  @override
  Widget build(BuildContext context) {
    if (!isPhoneLayout(context))
      return Dialog(
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        insetAnimationDuration: insetAnimationDuration,
        insetAnimationCurve: insetAnimationCurve,
        insetPadding: insetPadding,
        clipBehavior: clipBehavior,
        shape: shape,
        alignment: alignment,
        child: child,
      );
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(child: SizedBox.expand(child: child)),
    );
  }
}

class MobileAlertDialog extends StatelessWidget {
  const MobileAlertDialog(
      {super.key,
      this.title,
      this.content,
      this.actions,
      this.titlePadding,
      this.contentPadding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
      this.actionsPadding = EdgeInsets.zero,
      this.backgroundColor,
      this.elevation,
      this.shape,
      this.scrollable = false,
      this.titleTextStyle,
      this.contentTextStyle,
      this.actionsAlignment,
      this.insetPadding =
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      this.semanticLabel,
      this.clipBehavior = Clip.none,
      this.buttonPadding,
      this.actionsOverflowDirection,
      this.actionsOverflowButtonSpacing});
  final Widget? title, content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? titlePadding, buttonPadding;
  final EdgeInsetsGeometry contentPadding, actionsPadding;
  final EdgeInsets insetPadding;
  final Color? backgroundColor;
  final double? elevation, actionsOverflowButtonSpacing;
  final ShapeBorder? shape;
  final bool scrollable;
  final TextStyle? titleTextStyle, contentTextStyle;
  final MainAxisAlignment? actionsAlignment;
  final VerticalDirection? actionsOverflowDirection;
  final String? semanticLabel;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) {
    if (!isPhoneLayout(context))
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        scrollable: scrollable,
        titleTextStyle: titleTextStyle,
        contentTextStyle: contentTextStyle,
        actionsAlignment: actionsAlignment,
        insetPadding: insetPadding,
        semanticLabel: semanticLabel,
        clipBehavior: clipBehavior,
        buttonPadding: buttonPadding,
        actionsOverflowDirection: actionsOverflowDirection,
        actionsOverflowButtonSpacing: actionsOverflowButtonSpacing,
      );
    return Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                child: Row(children: [
                  Expanded(
                      child: DefaultTextStyle(
                          style: const TextStyle(
                              color: Color(0xFF252C44),
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                          child: title ?? const SizedBox.shrink())),
                  IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close)),
                ])),
            const Divider(height: 1),
            Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: DefaultTextStyle(
                        style: const TextStyle(
                            color: Color(0xFF252C44),
                            fontSize: 15,
                            height: 1.4),
                        child: content ?? const SizedBox.shrink()))),
            if (actions != null)
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: actions!)),
          ]),
        ));
  }
}
