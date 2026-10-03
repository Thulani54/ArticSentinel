import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_theme.dart';

enum AppEmptyStateKind { devices, readings, offline, results, alerts, records }

/// A visible, actionable state for an empty collection or unavailable request.
/// Intrinsic sizing allows use inside scroll views, cards and full-page views.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.kind = AppEmptyStateKind.records,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final AppEmptyStateKind kind;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  IconData get _icon =>
      icon ??
      switch (kind) {
        AppEmptyStateKind.devices => Iconsax.cpu,
        AppEmptyStateKind.readings => Iconsax.chart_2,
        AppEmptyStateKind.offline => Iconsax.wifi,
        AppEmptyStateKind.results => Iconsax.search_normal,
        AppEmptyStateKind.alerts => Iconsax.notification,
        AppEmptyStateKind.records => Iconsax.document_text,
      };

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24, vertical: compact ? 20 : 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ExcludeSemantics(
                  child: Stack(alignment: Alignment.bottomRight, children: [
                SvgPicture.asset(
                  kind == AppEmptyStateKind.offline
                      ? 'lib/assets/states/connection.svg'
                      : kind == AppEmptyStateKind.devices ||
                              kind == AppEmptyStateKind.readings
                          ? 'lib/assets/states/devices.svg'
                          : 'lib/assets/states/records.svg',
                  width: compact ? 112 : 160,
                  height: compact ? 80 : 114,
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: GasPalette.border)),
                  child: Icon(_icon, size: 18, color: GasPalette.primary),
                ),
              ])),
              SizedBox(height: compact ? 16 : 20),
              Semantics(
                  header: true,
                  child: Text(title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: compact ? 16 : 20,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: GasPalette.ink))),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.55,
                      color: GasPalette.ink2)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GasPalette.primary,
                    minimumSize: const Size(120, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    side: const BorderSide(color: GasPalette.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                  ),
                  child: Text(actionLabel!, textAlign: TextAlign.center),
                ),
              ],
            ]),
          ),
        ),
      );
}
