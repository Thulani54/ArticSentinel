/// Dashboard panel listing every gas cylinder with its level and status, so
/// cylinders are visible without picking them in the device dropdown (the
/// website shows them as equipment cards the same way).
library;

import '../widgets/mobile_forms.dart';
import 'package:flutter/material.dart';

import '../models/device.dart';
import 'gas_api.dart';
import 'gas_core.dart';
import 'gas_cylinder_details_dialog.dart';
import 'gas_demo_data.dart';
import 'gas_theme.dart';
import 'gas_widgets.dart';

class GasCylindersPanel extends StatelessWidget {
  const GasCylindersPanel({super.key, required this.devices, this.onOpened});

  final List<Device> devices;

  /// Called after a cylinder's details close (setup may have changed).
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    return GSection(
      eyebrow: 'Gas supply',
      title: 'Gas cylinders (${devices.length})',
      child: GTileGrid(
        minWidth: 260,
        children: [
          for (final d in devices)
            _CylinderCard(key: ValueKey(d.id), device: d, onOpened: onOpened),
        ],
      ),
    );
  }
}

class _CylinderCard extends StatefulWidget {
  const _CylinderCard({super.key, required this.device, this.onOpened});

  final Device device;
  final VoidCallback? onOpened;

  @override
  State<_CylinderCard> createState() => _CylinderCardState();
}

class _CylinderCardState extends State<_CylinderCard> {
  GasDeviceData? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.device.id;
    if (id == null) return;
    try {
      final r = await GasApi.load(deviceId: id, demoKey: widget.device.deviceId);
      if (mounted) {
        setState(() {
          _data = r.data;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open() async {
    await showMobileDialog(
      context: context,
      builder: (_) => GasCylinderDetailsDialog(device: widget.device),
    );
    _load();
    widget.onOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final data = _data;
    final sub = [
      if ((d.location ?? '').isNotEmpty) d.location!,
      d.deviceId,
    ].join(' · ');
    final online = data != null && data.live ? !data.isOffline : d.isOnline == true;

    Widget level;
    if (data == null) {
      level = Text(_failed ? 'Level unavailable' : 'Loading level…',
          style: gasSmall(context));
    } else if (!data.live) {
      level = const GChip('Waiting for first reading', tone: GChipTone.demo);
    } else {
      final band = bandFor(data.currentLevelPct,
          lowPct: data.lowPct, warningPct: data.warningPct);
      level = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data.currentLevelPct.round()}%',
                  style: gasData(context,
                      size: 26,
                      color: band == GasBand.low
                          ? GasPalette.critInk
                          : GasPalette.ink)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    '${kg1(data.currentNetKg)} of ${kg1(data.spec.capacityKg)}',
                    style: gasSmall(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (data.currentLevelPct / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: GasPalette.panelAlt,
              color: band == GasBand.low
                  ? GasPalette.crit
                  : band == GasBand.warning
                      ? GasPalette.warn
                      : GasPalette.flame,
            ),
          ),
        ],
      );
    }

    return Material(
      color: GasPalette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: GasPalette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const GChip('Gas Cylinder', tone: GChipTone.demo),
                const Spacer(),
                GChip(online ? 'Online' : 'Offline',
                    tone: online ? GChipTone.good : GChipTone.crit, dot: true),
              ]),
              const SizedBox(height: 12),
              Text(d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gasTitle(context)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gasSmall(context)),
              ],
              const SizedBox(height: 12),
              level,
              const SizedBox(height: 10),
              Text('View →',
                  style: gasBody(context).copyWith(
                      color: GasPalette.series, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
