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
      this.padding = const EdgeInsets.all(16)});

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
      ),
      child: child,
    );
  }
}

/// Section label — small caps, muted.
class GEyebrow extends StatelessWidget {
  const GEyebrow(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: gasEyebrow(context))),
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
        Text(label.toUpperCase(),
            style: gasEyebrow(context).copyWith(fontSize: 10)),
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
