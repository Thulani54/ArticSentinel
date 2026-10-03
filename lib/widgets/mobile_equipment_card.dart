import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../gasmon/gas_theme.dart';
import '../models/device.dart';
import 'device_illustration.dart';

class MobileEquipmentCard extends StatelessWidget {
  const MobileEquipmentCard({
    super.key,
    required this.device,
    required this.onOpen,
    required this.actions,
  });

  final Device device;
  final VoidCallback onOpen;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final statusColor = device.isActive
        ? (device.isOnline ? GasPalette.good : GasPalette.ink2)
        : GasPalette.critInk;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: GasPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GasPalette.page,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child:
                          DeviceIllustration(type: device.deviceType, size: 58),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name,
                            style: gasTitle(context).copyWith(fontSize: 15)),
                        const SizedBox(height: 5),
                        Text(
                            deviceIllustrationLabel(device.deviceType,
                                fallback: device.deviceTypeDisplay),
                            style: gasSmall(context)),
                        const SizedBox(height: 3),
                        Text(device.deviceId, style: gasSmall(context)),
                      ],
                    ),
                  ),
                  actions,
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: GasPalette.border),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: statusColor),
                        const SizedBox(width: 6),
                        Text(device.statusDisplay,
                            style: gasSmall(context).copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (device.location?.trim().isNotEmpty ?? false)
                    Text(device.location!, style: gasSmall(context)),
                ],
              ),
              if (device.connectedUnit != null) ...[
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Iconsax.link, size: 14, color: GasPalette.ink2),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          'Connected unit · ${device.connectedUnit!.name}',
                          style: gasSmall(context))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
