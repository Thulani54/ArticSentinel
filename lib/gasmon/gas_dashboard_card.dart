/// Dashboard summary for a selected gas cylinder, shown in place of the
/// fridge metrics (temperature/pressure/compressor), which a gas scale
/// doesn't have. Taps through to the full [GasCylinderDetailsDialog].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device.dart';
import 'gas_api.dart';
import 'gas_core.dart';
import 'gas_cylinder_details_dialog.dart';
import 'gas_cylinder_gauge.dart';
import 'gas_demo_data.dart';
import 'gas_theme.dart';
import 'gas_widgets.dart';

class GasDashboardCard extends StatefulWidget {
  const GasDashboardCard({super.key, required this.device});

  final Device device;

  @override
  State<GasDashboardCard> createState() => _GasDashboardCardState();
}

class _GasDashboardCardState extends State<GasDashboardCard> {
  GasDeviceData? _data;
  String? _error;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void didUpdateWidget(GasDashboardCard old) {
    super.didUpdateWidget(old);
    if (old.device.id != widget.device.id) {
      setState(() => _data = null);
      _load();
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.device.id;
    if (id == null) return;
    try {
      final r =
          await GasApi.load(deviceId: id, demoKey: widget.device.deviceId);
      if (mounted && id == widget.device.id) {
        setState(() {
          _data = r.data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _openDetails() async {
    await showDialog(
      context: context,
      builder: (_) => GasCylinderDetailsDialog(device: widget.device),
    );
    _load(); // setup may have changed
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return GPanel(
        child: SizedBox(
          height: 120,
          child: Center(
            child: _error != null
                ? Text("Couldn't load the cylinder: $_error",
                    style: gasSmall(context))
                : const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final level = data.currentLevelPct;
    final band =
        bandFor(level, lowPct: data.lowPct, warningPct: data.warningPct);
    final gauge = SizedBox(
      height: 190,
      child: FittedBox(
        child: GasCylinderGauge(
          fill: 1,
          band: band,
          levelPct: level,
          netKg: data.currentNetKg,
          capacityKg: data.spec.capacityKg,
        ),
      ),
    );
    final readouts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child:
                  GReadout(label: 'Gas left', value: kg1(data.currentNetKg))),
          Expanded(
            child: GReadout(
              label: 'On the scale',
              value: data.scaleGrossKg != null ? kg1(data.scaleGrossKg!) : '—',
              sub: data.live ? 'cylinder + gas' : null,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: GReadout(
                  label: 'Last reading', value: formatAgo(data.latest.at))),
          Expanded(
            child: GReadout(
              label: 'Scale battery',
              value: data.batteryPct != null
                  ? '${data.batteryPct!.round()}%'
                  : '—',
            ),
          ),
        ]),
      ],
    );

    return GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.propane_tank, color: GasPalette.flame, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.device.name,
                  style: gasTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            _chip(data.live ? 'LIVE SCALE' : 'DEMO DATA',
                data.live ? GasPalette.good : GasPalette.warn),
            const SizedBox(width: 8),
            GBandChip(band: band, levelPct: level),
          ]),
          if (data.live &&
              data.scaleGrossKg != null &&
              data.scaleGrossKg! < data.spec.tareKg) ...[
            const SizedBox(height: 10),
            Text(
              'The scale reads less than the empty cylinder weight '
              '(${kg1(data.spec.tareKg)}) — check the Cylinder setup.',
              style: gasSmall(context).copyWith(color: const Color(0xFF92400E)),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, box) {
            if (box.maxWidth < 480) {
              return Column(
                  children: [gauge, const SizedBox(height: 12), readouts]);
            }
            return Row(children: [
              SizedBox(width: 170, child: gauge),
              const SizedBox(width: 20),
              Expanded(child: readouts),
            ]);
          }),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: GasPalette.navy),
            onPressed: _openDetails,
            icon: const Icon(Icons.open_in_full, size: 18),
            label: const Text('Open cylinder'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: color)),
    );
  }
}
