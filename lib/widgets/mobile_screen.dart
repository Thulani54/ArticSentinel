import 'package:flutter/material.dart';

import '../gasmon/gas_theme.dart';

/// A compact page heading for the phone workspace. Actions stay reachable
/// without reserving space for a decorative banner.
class MobileScreenHeader extends StatelessWidget {
  const MobileScreenHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            color: GasPalette.ink,
                            fontSize: 24,
                            height: 1.2,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(description!,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      color: GasPalette.ink2,
                      fontSize: 13,
                      height: 1.4)),
            ],
            if (bottom != null) ...[
              const SizedBox(height: 12),
              bottom!,
            ],
          ],
        ),
      );
}
