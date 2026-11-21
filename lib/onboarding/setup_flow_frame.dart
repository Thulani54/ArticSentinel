import '../widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_theme.dart';
import '../widgets/device_illustration.dart';

/// Layout shared by the add-device wizard and the device editor.
///
/// Phones (iOS / Android, narrow web): one column, a step bar under the title
/// and a fixed action bar that stays above the keyboard.
/// Wide screens (web / desktop / tablet landscape): a centred card with a side
/// panel showing the device and every step by name, the form on the right.
class SetupFlowFrame extends StatelessWidget {
  const SetupFlowFrame({
    super.key,
    required this.title,
    required this.body,
    this.steps = const [],
    this.step,
    this.deviceType,
    this.deviceLabel,
    this.complete = false,
    this.onBack,
    this.closeLabel = 'Close',
    this.onClose,
    this.footer,
    this.sideNote,
    this.scrollController,
    this.busy = false,
    this.onStepTap,
    this.sideImage,
  });

  static const wideBreakpoint = 840.0;

  final String title;
  final Widget body;

  /// Step names; [step] is the current index, or null before the steps start.
  final List<String> steps;
  final int? step;
  final String? deviceType;
  final String? deviceLabel;
  final bool complete;
  final VoidCallback? onBack;
  final String closeLabel;
  final VoidCallback? onClose;
  final Widget? footer;
  final Widget? sideNote;
  final ScrollController? scrollController;
  final bool busy;

  /// When set, step names (side panel) and step segments (phone) jump to
  /// that step — used by the editor, where every step is optional.
  final ValueChanged<int>? onStepTap;

  /// Side-panel picture when the flow isn't about a device (e.g. people).
  final String? sideImage;

  static TextStyle text(double size,
          {FontWeight weight = FontWeight.w500,
          Color? color}) =>
      GoogleFonts.inter(
          fontSize: size, height: 1.45, fontWeight: weight, color: color ?? GasPalette.ink);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final main =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _TopBar(
          title: wide && step != null
              ? 'Step ${step! + 1} of ${steps.length}'
              : title,
          onBack: onBack,
          closeLabel: closeLabel,
          onClose: onClose,
          busy: busy),
      if (!wide && step != null)
        _StepBar(
            steps: steps, step: step!, complete: complete, onTap: onStepTap),
      Expanded(
          child: SingleChildScrollView(
              controller: scrollController,
              padding:
                  EdgeInsets.fromLTRB(wide ? 40 : 24, 12, wide ? 40 : 24, 24),
              child: body)),
      if (footer != null)
        Container(
          padding: EdgeInsets.fromLTRB(wide ? 40 : 24, 12, wide ? 40 : 24, 16),
          decoration: BoxDecoration(
              color: Tone.bg(Colors.white),
              border: Border(top: BorderSide(color: GasPalette.border))),
          child: footer,
        ),
    ]);

    return Scaffold(
      backgroundColor: wide ? GasPalette.page : Tone.bg(Colors.white),
      body: SafeArea(
        child: wide
            ? Center(
                child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 1040, maxHeight: 820),
                margin: const EdgeInsets.all(24),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: Tone.bg(Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: GasPalette.border),
                    boxShadow: [
                      BoxShadow(
                          color: GasPalette.ink.withValues(alpha: .06),
                          blurRadius: 30,
                          offset: const Offset(0, 12))
                    ]),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                          width: 320,
                          child: _SidePanel(
                              title: title,
                              steps: steps,
                              step: step,
                              deviceType: deviceType,
                              deviceLabel: deviceLabel,
                              complete: complete,
                              note: sideNote,
                              image: sideImage,
                              onTap: onStepTap)),
                      Expanded(child: main),
                    ]),
              ))
            : main,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar(
      {required this.title,
      required this.onBack,
      required this.closeLabel,
      required this.onClose,
      required this.busy});
  final String title;
  final VoidCallback? onBack;
  final String closeLabel;
  final VoidCallback? onClose;
  final bool busy;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
        child: Row(children: [
          IconButton(
              tooltip: 'Back',
              onPressed: busy ? null : onBack,
              icon: const Icon(Iconsax.arrow_left)),
          Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SetupFlowFrame.text(15, weight: FontWeight.w600))),
          if (onClose != null)
            TextButton(
                onPressed: busy ? null : onClose, child: Text(closeLabel)),
        ]),
      );
}

class _StepBar extends StatelessWidget {
  const _StepBar(
      {required this.steps,
      required this.step,
      required this.complete,
      this.onTap});
  final List<String> steps;
  final int step;
  final bool complete;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Step ${step + 1} of ${steps.length}',
                style: SetupFlowFrame.text(12, color: GasPalette.ink2)),
            Flexible(
              child: Text('  ·  ${steps[step]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SetupFlowFrame.text(12,
                      weight: FontWeight.w700, color: GasPalette.ink)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
              children: List.generate(
                  steps.length,
                  (i) => Expanded(
                        child: Semantics(
                          button: onTap != null,
                          label: onTap != null ? 'Go to ${steps[i]}' : null,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onTap == null ? null : () => onTap!(i),
                            child: Container(
                              // A taller target than the 4 px bar.
                              height: onTap == null ? 4 : 24,
                              alignment: Alignment.center,
                              margin: EdgeInsets.only(
                                  right: i == steps.length - 1 ? 0 : 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                height: 4,
                                decoration: BoxDecoration(
                                    color: complete
                                        ? GasPalette.good
                                        : (onTap == null
                                                ? i <= step
                                                : i == step)
                                            ? GasPalette.primary
                                            : GasPalette.border,
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ))),
        ]),
      );
}

class _SidePanel extends StatelessWidget {
  const _SidePanel(
      {required this.title,
      required this.steps,
      required this.step,
      required this.deviceType,
      required this.deviceLabel,
      required this.complete,
      required this.note,
      this.image,
      this.onTap});
  final String? image;
  final ValueChanged<int>? onTap;
  final String title;
  final List<String> steps;
  final int? step;
  final String? deviceType;
  final String? deviceLabel;
  final bool complete;
  final Widget? note;

  @override
  Widget build(BuildContext context) => Container(
        color: GasPalette.panelAlt,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Tone.bg(Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GasPalette.border)),
            child: image != null
                ? SvgPicture.asset(image!, height: 110)
                : deviceType == null
                    ? SvgPicture.asset('lib/assets/states/devices.svg',
                        height: 110)
                    : DeviceIllustration(type: deviceType, size: 112),
          ),
          const SizedBox(height: 20),
          Text(title, style: SetupFlowFrame.text(20, weight: FontWeight.w700)),
          if (deviceLabel != null) ...[
            const SizedBox(height: 4),
            Text(deviceLabel!,
                style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
          ],
          const SizedBox(height: 24),
          for (var i = 0; i < steps.length; i++) _sideStep(i),
          const Spacer(),
          if (note != null) note!,
        ]),
      );

  Widget _sideStep(int i) {
    // In the editor (onTap set) steps are sections, not progress: no ticks.
    final done = complete || (onTap == null && step != null && i < step!);
    final current = !complete && step == i;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? GasPalette.good
                  : current
                      ? GasPalette.primary
                      : Tone.bg(Colors.white),
              border: Border.all(
                  color: done || current
                      ? Colors.transparent
                      : GasPalette.border)),
          child: done
              ? Icon(Icons.check_rounded, size: 17, color: Tone.fg(Colors.white))
              : Text('${i + 1}',
                  style: SetupFlowFrame.text(13,
                      weight: FontWeight.w700,
                      color: current ? Tone.auto(Colors.white) : GasPalette.ink2)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(steps[i],
                style: SetupFlowFrame.text(14,
                    weight: current ? FontWeight.w700 : FontWeight.w500,
                    color:
                        current || done ? GasPalette.ink : GasPalette.ink2))),
      ]),
    );
    if (onTap == null) return row;
    return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap!(i),
        child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 4), child: row));
  }
}

/// A scene picture for a step: the step illustration with the device's own
/// illustration as a small badge, so every guide looks like its hardware.
class SetupScene extends StatelessWidget {
  const SetupScene(
      {super.key, required this.asset, this.deviceType, this.height = 132});
  final String asset;
  final String? deviceType;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(asset),
          tween: Tween(begin: reduce ? 1 : 0, end: 1),
          duration: Duration(milliseconds: reduce ? 0 : 420),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                  offset: Offset(0, (1 - t) * 10), child: child)),
          child: Container(
            height: height,
            decoration: BoxDecoration(
                color: GasPalette.panelAlt,
                borderRadius: BorderRadius.circular(20)),
            child: Stack(alignment: Alignment.center, children: [
              SvgPicture.asset(asset, height: height - 24),
              if (deviceType != null)
                Positioned(
                    right: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Tone.bg(Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(color: GasPalette.border)),
                      child: DeviceIllustration(type: deviceType, size: 34),
                    )),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Numbered instruction row used in every guide.
class SetupInstructionTile extends StatelessWidget {
  const SetupInstructionTile(
      {super.key,
      required this.number,
      required this.icon,
      required this.title,
      required this.text});
  final int number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: GasPalette.seriesSoft,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: GasPalette.series),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('$number. $title',
                    style: SetupFlowFrame.text(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text,
                    style: SetupFlowFrame.text(14, color: GasPalette.ink2)),
              ])),
        ]),
      );
}

/// Highlighted note (information, safety or error).
class SetupNote extends StatelessWidget {
  const SetupNote(
      {super.key,
      required this.icon,
      required this.title,
      required this.text,
      this.tone = SetupNoteTone.info});
  final IconData icon;
  final String title;
  final String text;
  final SetupNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, line, fg) = switch (tone) {
      SetupNoteTone.info => (
          GasPalette.panelAlt,
          GasPalette.border,
          GasPalette.series
        ),
      SetupNoteTone.safety => (
          GasPalette.warnSoft,
          GasPalette.warnLine,
          GasPalette.warnInk
        ),
      SetupNoteTone.error => (
          Tone.auto(const Color(0xFFFFF1EE)),
          Tone.auto(const Color(0xFFF4CCC4)),
          GasPalette.critInk
        ),
      SetupNoteTone.success => (
          GasPalette.goodSoft,
          Tone.auto(const Color(0xFFA7F3D0)),
          GasPalette.goodInk
        ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: SetupFlowFrame.text(14, weight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text(text, style: SetupFlowFrame.text(13, color: GasPalette.ink2)),
      ]),
    );
  }
}

enum SetupNoteTone { info, safety, error, success }
