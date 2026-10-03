/// Dashboard summary for a selected gas cylinder, shown in place of the
/// fridge metrics (temperature/pressure/compressor), which a gas scale
/// doesn't have. Taps through to the full [GasCylinderDetailsDialog].
library;

import '../widgets/mobile_forms.dart';
import '../widgets/app_empty_state.dart';
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
  const GasDashboardCard({super.key, required this.device, this.loadData});

  final Device device;
  final Future<({GasDeviceData data, GasConfig config})> Function()? loadData;

  @override
  State<GasDashboardCard> createState() => _GasDashboardCardState();
}

class _GasDashboardCardState extends State<GasDashboardCard> {
  GasDeviceData? _data;
  String? _error;
  Timer? _refresh;
  int _loadGeneration = 0;

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
      setState(() {
        _data = null;
        _error = null;
      });
      _load();
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_loadGeneration;
    final id = widget.device.id;
    if (id == null && widget.loadData == null) return;
    try {
      final r = widget.loadData != null
          ? await widget.loadData!()
          : await GasApi.load(deviceId: id!, demoKey: widget.device.deviceId);
      if (mounted && request == _loadGeneration && id == widget.device.id) {
        setState(() {
          _data = r.data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && request == _loadGeneration && id == widget.device.id) {
        setState(() => _error = 'Check your connection and try again.');
      }
    }
  }

  Future<void> _openDetails() async {
    await showMobileDialog(
      context: context,
      builder: (_) => GasCylinderDetailsDialog(device: widget.device),
    );
    _load(); // setup may have changed
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null || !data.hasReadings) {
      final unsaved = widget.device.id == null && widget.loadData == null;
      if (data == null && _error == null && !unsaved) {
        return const GPanel(
            child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ));
      }
      return GPanel(
          child: AppEmptyState(
        compact: true,
        kind: _error != null
            ? AppEmptyStateKind.offline
            : AppEmptyStateKind.readings,
        title: _error != null
            ? 'Cylinder unavailable'
            : 'Waiting for the first reading',
        message: unsaved
            ? 'Add this device to connect a scale and view its gas level.'
            : _error ??
                'No weight has been reported for ${widget.device.name}. Connect your scale to start monitoring.',
        actionLabel: unsaved
            ? null
            : _error != null
                ? 'Retry'
                : 'Set up cylinder',
        onAction: unsaved
            ? null
            : _error != null
                ? _load
                : _openDetails,
      ));
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
    final readoutItems = [
      GReadout(label: 'Gas left', value: kg1(data.currentNetKg)),
      GReadout(
          label: 'On the scale',
          value: data.scaleGrossKg != null ? kg1(data.scaleGrossKg!) : '—',
          sub: 'cylinder + gas'),
      GReadout(label: 'Last reading', value: formatAgo(data.latest.at)),
      GReadout(
          label: 'Scale battery',
          value:
              data.batteryPct != null ? '${data.batteryPct!.round()}%' : '—'),
    ];
    final readouts = isPhoneLayout(context)
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final readout in readoutItems)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12), child: readout),
          ])
        : Column(children: [
            Row(children: [
              Expanded(child: readoutItems[0]),
              Expanded(child: readoutItems[1])
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: readoutItems[2]),
              Expanded(child: readoutItems[3])
            ]),
          ]);

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
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            GChip(
                data.isOffline || _error != null
                    ? 'LAST REPORTED'
                    : 'LIVE SCALE',
                tone: data.isOffline || _error != null
                    ? GChipTone.neutral
                    : GChipTone.good),
            GBandChip(band: band, levelPct: level),
          ]),
          if (_error != null || data.isOffline) ...[
            const SizedBox(height: 10),
            Text(
                _error != null
                    ? 'Could not refresh. Showing the last reported reading (${formatAgo(data.latest.at)}).'
                    : 'Scale offline. Showing the last reported reading (${formatAgo(data.latest.at)}).',
                style: gasSmall(context)),
            if (_error != null)
              Align(
                  alignment: Alignment.centerLeft,
                  child:
                      TextButton(onPressed: _load, child: const Text('Retry'))),
          ],
          if (data.live &&
              data.scaleGrossKg != null &&
              data.scaleGrossKg! < data.spec.tareKg) ...[
            const SizedBox(height: 10),
            Text(
              'The scale reads less than the empty cylinder weight '
              '(${kg1(data.spec.tareKg)}) — check the Cylinder setup.',
              style: gasSmall(context).copyWith(color: GasPalette.warnInk),
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
            style: FilledButton.styleFrom(
              backgroundColor: GasPalette.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
            ),
            onPressed: _openDetails,
            icon: const Icon(Icons.open_in_full, size: 18),
            label: const Text('Open cylinder'),
          ),
        ],
      ),
    );
  }
}
