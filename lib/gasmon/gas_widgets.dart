/// Small shared widgets for the gas dashboard: panels, labels, readouts,
/// presence and severity chips.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'gas_core.dart';
import 'gas_theme.dart';

/// 'just now', '12m ago', '3h ago', '2d ago', else 'd MMM'.
String formatAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('d MMM').format(t);
}

/// Card surface on the white dialog.
class GPanel extends StatelessWidget {
  const GPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GasPalette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GasPalette.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05133648), blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Section label, muted (sentence case, as on the website).
class GEyebrow extends StatelessWidget {
  const GEyebrow(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: gasEyebrow(context))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Labeled numeric readout.
class GReadout extends StatelessWidget {
  const GReadout({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: gasEyebrow(context)),
        const SizedBox(height: 6),
        Text(value, style: gasData(context, size: 20, color: valueColor)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: gasSmall(context)),
        ],
      ],
    );
  }
}

/// Online/offline indicator with an honest timestamp.
class GPresenceChip extends StatelessWidget {
  const GPresenceChip({
    super.key,
    required this.online,
    this.lastSeen,
    this.light = false,
  });

  final bool online;
  final DateTime? lastSeen;
  final bool light; // for use on the dark header

  @override
  Widget build(BuildContext context) {
    final color = online ? GasPalette.good : GasPalette.warn;
    final fg = light ? Colors.white70 : GasPalette.ink2;
    final label = online
        ? 'Reporting now'
        : lastSeen == null
            ? 'No readings yet'
            : 'Last seen ${formatAgo(lastSeen!)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: gasSmall(context).copyWith(color: fg)),
      ],
    );
  }
}

/// Level band pill: icon + label, never color alone.
class GBandChip extends StatelessWidget {
  const GBandChip({super.key, required this.band, required this.levelPct});

  final GasBand band;
  final double levelPct;

  @override
  Widget build(BuildContext context) {
    final color = GasPalette.band(band);
    final (icon, label) = switch (band) {
      GasBand.healthy => (Icons.check_circle_outline, 'Healthy'),
      GasBand.warning => (Icons.error_outline, 'Warning'),
      GasBand.low => (Icons.warning_amber_rounded, 'Low gas'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label · ${levelPct.round()}%',
              style: gasSmall(context)
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Website-style panel: eyebrow, title and optional actions above the body.
class GSection extends StatelessWidget {
  const GSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.actions,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: gasEyebrow(context)),
        const SizedBox(height: 2),
        Text(title, style: gasTitle(context)),
      ],
    );
    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actions == null)
            head
          else
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [head, actions!],
            ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// A reading tile ("On the scale 12.5 kg / cylinder + gas combined").
class GTile extends StatelessWidget {
  const GTile(
      {super.key, required this.label, required this.value, this.sub, this.valueSize = 19});

  final String label;
  final String value;
  final String? sub;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GasPalette.panelAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: gasEyebrow(context)),
          const SizedBox(height: 4),
          Text(value,
              style: gasData(context, size: valueSize)
                  .copyWith(fontWeight: FontWeight.w800)),
          if (sub != null && sub!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub!, style: gasSmall(context)),
          ],
        ],
      ),
    );
  }
}

/// Lays tiles out in equal columns of at least [minWidth], like the
/// website's auto-fit grid.
class GTileGrid extends StatelessWidget {
  const GTileGrid({super.key, required this.children, this.minWidth = 150});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 12.0;
      final cols = ((c.maxWidth + gap) / (minWidth + gap)).floor().clamp(1, 8);
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in children) SizedBox(width: w, child: t)],
      );
    });
  }
}

enum GChipTone { good, warn, crit, demo, neutral }

/// Pill chip ("LIVE SCALE", "Online · just now").
class GChip extends StatelessWidget {
  const GChip(this.text, {super.key, required this.tone, this.dot = false});

  final String text;
  final GChipTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, line) = switch (tone) {
      GChipTone.good => (GasPalette.goodSoft, GasPalette.goodInk, null),
      GChipTone.warn => (GasPalette.warnSoft, GasPalette.warnInk, null),
      GChipTone.crit => (GasPalette.critSoft, GasPalette.critInk, null),
      GChipTone.demo => (GasPalette.flameSoft, GasPalette.flameDeep, GasPalette.flame),
      GChipTone.neutral => (GasPalette.panelAlt, GasPalette.ink2, GasPalette.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: line == null ? null : Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(text,
                style: gasSmall(context)
                    .copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Notice strip: bold lead, then the explanation.
class GBanner extends StatelessWidget {
  const GBanner({super.key, required this.lead, this.text, this.critical = false});

  final String lead;
  final String? text;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final fg = critical ? GasPalette.critInk : GasPalette.warnInk;
    final base = gasBody(context).copyWith(color: fg, fontWeight: FontWeight.w500);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: critical ? GasPalette.critSoft : GasPalette.warnSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: critical ? GasPalette.critLine : GasPalette.warnLine),
      ),
      child: Text.rich(TextSpan(style: base, children: [
        TextSpan(text: lead, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (text != null) TextSpan(text: ' $text'),
      ])),
    );
  }
}

/// Segmented range switch ("30d 60d 90d").
class GSegment<T> extends StatelessWidget {
  const GSegment(
      {super.key,
      required this.values,
      required this.selected,
      required this.label,
      required this.onChanged});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GasPalette.panelAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: GasPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values)
            Material(
              color: v == selected ? GasPalette.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => onChanged(v),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  child: Text(label(v),
                      style: gasBody(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: v == selected ? Colors.white : GasPalette.ink2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Website "Online · just now" / "Offline · 3d ago" chip.
class GStatusChip extends StatelessWidget {
  const GStatusChip({super.key, required this.online, this.lastSeen});

  final bool online;
  final DateTime? lastSeen;

  @override
  Widget build(BuildContext context) {
    final when = lastSeen == null ? 'no readings yet' : formatAgo(lastSeen!);
    return GChip('${online ? 'Online' : 'Offline'} · $when',
        tone: online ? GChipTone.good : GChipTone.crit, dot: true);
  }
}
