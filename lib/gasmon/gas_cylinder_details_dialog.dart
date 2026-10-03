/// Details dashboard for a gas cylinder device. Replaces the temperature-
/// oriented `DeviceDetailsDialog` for devices whose type is 'gas_cylinder'.
///
/// Shows live scale readings from api/gas/readings/ once the scale has
/// reported. Missing readings and failed requests are shown explicitly.
/// Also hosts the Cylinder setup and the Bluetooth "Connect scale" flow.
library;

import '../widgets/mobile_forms.dart';
import '../widgets/app_empty_state.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device.dart';
import 'gas_api.dart';
import 'gas_notification_card.dart';
import 'gas_charts.dart';
import 'gas_core.dart';
import 'gas_cylinder_gauge.dart';
import 'gas_demo_data.dart';
import 'gas_report.dart';
import 'gas_setup_card.dart';
import 'gas_theme.dart';
import 'gas_widgets.dart';
import 'scale_setup_screen.dart';

export 'gas_core.dart' show isGasCylinderType;

class GasCylinderDetailsDialog extends StatefulWidget {
  const GasCylinderDetailsDialog(
      {Key? key, required this.device, this.loadData})
      : super(key: key);

  final Device device;
  final Future<({GasDeviceData data, GasConfig config})> Function()? loadData;

  @override
  State<GasCylinderDetailsDialog> createState() =>
      _GasCylinderDetailsDialogState();
}

class _GasCylinderDetailsDialogState extends State<GasCylinderDetailsDialog>
    with SingleTickerProviderStateMixin {
  GasDeviceData? _loaded;
  GasConfig? _config;
  String? _loadError;
  Timer? _refresh;
  bool _loading = true;
  int _loadGeneration = 0;
  late final AnimationController _fillCtrl;
  int _rangeDays = 30;
  bool _exporting = false;

  GasDeviceData get _data => _loaded!;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _load();
    // Live scales report every few seconds; keep the dashboard current.
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _fillCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_loadGeneration;
    final id = widget.device.id;
    if (id == null && widget.loadData == null) {
      setState(() => _loading = false);
      return;
    }
    if (_loaded == null) setState(() => _loading = true);
    try {
      final result = widget.loadData != null
          ? await widget.loadData!()
          : await GasApi.load(deviceId: id!, demoKey: widget.device.deviceId);
      if (!mounted || request != _loadGeneration || id != widget.device.id) {
        return;
      }
      final firstReading =
          _loaded?.hasReadings != true && result.data.hasReadings;
      setState(() {
        _loaded = result.data;
        _config = result.config;
        _loadError = null;
        _loading = false;
      });
      if (firstReading) _fillCtrl.forward(from: 0);
    } catch (_) {
      if (!mounted || request != _loadGeneration || id != widget.device.id) {
        return;
      }
      setState(() {
        _loadError =
            'Could not refresh scale readings. Check your connection and retry.';
        _loading = false;
      });
    }
  }

  Future<void> _openCylinderSetup() async {
    final config = _config;
    if (config == null || widget.device.id == null) return;
    await showMobileDialog(
      context: context,
      builder: (_) => GasCylinderSetupDialog(
        config: config,
        scaleGrossKg:
            _loaded?.hasReadings == true ? _loaded!.scaleGrossKg : null,
        onSave: _saveConfig,
      ),
    );
  }

  Future<void> _saveConfig(GasConfig config) async {
    final id = widget.device.id;
    if (id == null) throw GasApiException('This device has no ID yet.');
    final saved = await GasApi.saveConfig(deviceId: id, config: config);
    if (!mounted) return;
    setState(() => _config = saved);
    await _load(); // levels are recomputed against the new tare/capacity
  }

  Future<void> _openScaleSetup() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScaleSetupScreen(device: widget.device),
    ));
    await _load();
  }

  List<GasReading> get _rangeReadings {
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    return _data.readings.where((r) => r.at.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _loaded == null) {
      return const MobileDialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading cylinder…'),
              ]),
        ),
      );
    }
    final phone = isPhoneLayout(context);
    final body = Container(
      color: GasPalette.page,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(phone ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child:
                _loaded?.hasReadings == true ? _buildPage() : _buildEmptyPage(),
          ),
        ),
      ),
    );
    if (phone) return MobileDialog(child: body);
    return MobileDialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.92,
          child: body,
        ),
      ),
    );
  }

  Widget _buildEmptyPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(true),
          const SizedBox(height: 20),
          AppEmptyState(
            kind: _loadError != null
                ? AppEmptyStateKind.offline
                : AppEmptyStateKind.readings,
            title: _loadError != null
                ? 'Readings unavailable'
                : 'Waiting for the first reading',
            message: widget.device.id == null && widget.loadData == null
                ? 'Add this device before connecting a scale or setting up its cylinder.'
                : _loadError ??
                    'Connect the scale to see the gas level, usage and alerts. No weight has been reported yet.',
            actionLabel: widget.device.id != null ? 'Retry' : null,
            onAction: widget.device.id != null ? _load : null,
          ),
        ],
      );

  /// Same sections, in the same order, as the website's gas page.
  Widget _buildPage() {
    final levelPct = _data.currentLevelPct;
    final band =
        bandFor(levelPct, lowPct: _data.lowPct, warningPct: _data.warningPct);
    final offline = _data.isOffline;
    final gross = _data.scaleGrossKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(offline),
        const SizedBox(height: 20),
        if (_loadError != null) ...[
          GBanner(
              lead: _loadError!,
              text:
                  'Showing the last reported reading from ${DateFormat("d MMM, HH:mm").format(_data.latest.at)}.'),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _load, child: const Text('Retry'))),
        ],
        if (_data.live && gross != null && gross < _data.spec.tareKg)
          GBanner(
              lead: 'The scale reads ${kg1(gross)} — less than the empty '
                  'cylinder weight (${kg1(_data.spec.tareKg)}).',
              text: 'Gas shows as 0 until the reading is above the empty '
                  "weight. Check the Cylinder setup below matches what's on "
                  'the scale.'),
        if (band == GasBand.low)
          GBanner(
              critical: true,
              lead:
                  '${offline || _loadError != null ? "Last reported low gas" : "Low gas"} — ${levelPct.round()}% remaining.',
              text: 'Schedule a refill.'),
        if (offline)
          GBanner(
              lead: 'Monitor offline.',
              text: 'Last reading ${formatAgo(_data.latest.at)} — usage since '
                  "then isn't measured."),
        _buildTopRow(levelPct, band),
        const SizedBox(height: 16),
        _buildPerformance(),
        const SizedBox(height: 16),
        _buildAlerts(),
        const SizedBox(height: 16),
        _buildReports(levelPct),
        const SizedBox(height: 16),
        if (isPhoneLayout(context)) ...[
          const SizedBox(height: 16),
          GasNotificationCard(device: widget.device),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _buildHeader(bool offline) {
    final phone = isPhoneLayout(context);
    final sub = [
      widget.device.deviceId,
      if ((widget.device.location ?? '').isNotEmpty) widget.device.location!,
    ].join(' · ');
    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GasPalette.flameSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.propane_tank_outlined,
              color: GasPalette.flame, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gas Cylinder',
                  style:
                      gasEyebrow(context).copyWith(color: GasPalette.series)),
              const SizedBox(height: 2),
              Text(widget.device.name,
                  style: gasData(context, size: phone ? 24 : 30)
                      .copyWith(letterSpacing: -0.3, height: 1.15)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sub, style: gasBody(context)),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: GasPalette.ink2),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        identity,
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_loaded?.hasReadings == true) ...[
              GChip(
                  offline || _loadError != null
                      ? 'LAST REPORTED'
                      : 'LIVE SCALE',
                  tone: offline || _loadError != null
                      ? GChipTone.neutral
                      : GChipTone.good),
              GStatusChip(
                  online: !offline && _loadError == null,
                  lastSeen: _data.latest.at),
            ] else
              GChip(_loadError != null ? 'Reading unavailable' : 'No readings yet',
                  tone: GChipTone.neutral),
            OutlinedButton(
              style: _secondaryButton(),
              onPressed: _config != null && widget.device.id != null
                  ? _openCylinderSetup
                  : null,
              child: const Text('Switch gas'),
            ),
            OutlinedButton.icon(
              style: _secondaryButton(),
              onPressed: widget.device.id == null ? null : _openScaleSetup,
              icon: const Icon(Icons.bluetooth, size: 16),
              label: const Text('Connect scale'),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _secondaryButton() => OutlinedButton.styleFrom(
        foregroundColor: GasPalette.ink,
        backgroundColor: GasPalette.panel,
        side: const BorderSide(color: GasPalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        minimumSize: const Size(0, 38),
      );

  ButtonStyle _primaryButton() => FilledButton.styleFrom(
        backgroundColor: GasPalette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        minimumSize: const Size(0, 38),
      );

  // -------------------------------------------------------------------------
  // Current level + readings
  // -------------------------------------------------------------------------

  Widget _buildTopRow(double levelPct, GasBand band) {
    return LayoutBuilder(builder: (context, c) {
      final gauge = _buildGaugeCard(levelPct, band);
      final readings = _buildReadings();
      if (c.maxWidth >= 900) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 300, child: gauge),
            const SizedBox(width: 16),
            Expanded(child: readings),
          ],
        );
      }
      return Column(children: [gauge, const SizedBox(height: 16), readings]);
    });
  }

  Widget _buildGaugeCard(double levelPct, GasBand band) {
    return GSection(
      eyebrow: 'Current level',
      title: 'Cylinder',
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedBuilder(
              animation: _fillCtrl,
              builder: (context, _) => GasCylinderGauge(
                fill: CurvedAnimation(
                        parent: _fillCtrl, curve: Curves.easeOutCubic)
                    .value,
                band: band,
                levelPct: levelPct,
                netKg: _data.currentNetKg,
                capacityKg: _data.spec.capacityKg,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GBandChip(band: band, levelPct: levelPct),
        ],
      ),
    );
  }

  Widget _buildReadings() {
    final now = DateTime.now();
    final today = todayUsage(_data.readings, pricePerKg: _data.pricePerKg);
    final burn = trailingBurnPerDay(_data.readings);
    final projection =
        daysRemaining(netKg: _data.currentNetKg, burnPerDay: burn, now: now);
    final gross = _data.scaleGrossKg;
    final lastAt = _data.latest.at;
    return GSection(
      eyebrow: 'Right now',
      title: 'Readings',
      child: GTileGrid(
          minWidth:
              isPhoneLayout(context) ? MediaQuery.sizeOf(context).width : 150,
          children: [
            if (_data.live && gross != null)
              GTile(
                  label: 'On the scale',
                  value: kg1(gross),
                  sub: 'cylinder + gas combined'),
            GTile(
                label: 'Net gas',
                value: kg1(_data.currentNetKg),
                sub: 'tare ${_trim(_data.spec.tareKg)} kg excluded'),
            GTile(
                label: 'Today so far',
                value: kg1(today.kg),
                sub: '${money(today.cost)} at ${money(_data.pricePerKg)}/kg'),
            GTile(
                label: 'Burn rate',
                value: '${kg1(burn)}/day',
                sub: '7-day rolling average'),
            GTile(
                label: 'Projection',
                value: _data.isOffline || projection.emptyBy == null
                    ? '—'
                    : DateFormat('d MMM').format(projection.emptyBy!),
                sub: 'empty by, at current burn'),
            GTile(
                label: 'Capacity',
                value: '${_data.spec.gasKg}kg class',
                sub: '${kg1(_data.spec.capacityKg)} usable when full'),
            GTile(
                label: 'Last reading',
                value: DateFormat('d MMM, HH:mm').format(lastAt),
                valueSize: 15,
                sub: [
                  '${kg1(gross ?? _data.latest.weightKg)} on the scale',
                  if (_data.batteryPct != null)
                    'battery ${_data.batteryPct!.round()}%',
                ].join(' · ')),
          ]),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  // -------------------------------------------------------------------------
  // Performance
  // -------------------------------------------------------------------------

  Widget _buildPerformance() {
    final daily = _rangeDays == 30;
    final points = daily
        ? dailySeries(_rangeReadings, pricePerKg: _data.pricePerKg)
        : weeklySeries(_rangeReadings, pricePerKg: _data.pricePerKg);
    final summary = summarize(
        dailySeries(_rangeReadings, pricePerKg: _data.pricePerKg),
        rangeDays: _rangeDays);
    final peak = daily
        ? summary.peak
        : (points.isEmpty
            ? null
            : points.reduce((a, b) => b.kg > a.kg ? b : a));
    final unit = daily ? 'daily' : 'weekly';

    Widget chart(String label, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: gasEyebrow(context)),
            const SizedBox(height: 8),
            child,
          ],
        );
    final burnChart = chart('Gas burned $unit (kg)',
        GasBurnBarChart(points: points, rodWidth: daily ? 9 : 20));
    final costChart =
        chart('Cost $unit ($kCurrency)', GasCostLineChart(points: points));

    return GSection(
      eyebrow: 'Performance',
      title: 'Usage — last $_rangeDays days',
      actions: GSegment<int>(
        values: const [30, 60, 90],
        selected: _rangeDays,
        label: (d) => '${d}d',
        onChanged: (d) => setState(() => _rangeDays = d),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTileGrid(
              minWidth: isPhoneLayout(context)
                  ? MediaQuery.sizeOf(context).width
                  : 140,
              children: [
                GTile(label: 'Consumed', value: kg1(summary.totalKg)),
                GTile(label: 'Cost', value: money(summary.totalCost)),
                GTile(
                    label: 'Avg / day',
                    value: money(summary.avgDailyCost),
                    sub: kg1(summary.avgDailyKg)),
                GTile(
                    label: 'Peak ${daily ? 'day' : 'week'}',
                    value: peak == null ? '—' : kg1(peak.kg),
                    sub: peak == null
                        ? null
                        : DateFormat('d MMM').format(peak.day)),
              ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: burnChart),
                  const SizedBox(width: 16),
                  Expanded(child: costChart),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [burnChart, const SizedBox(height: 20), costChart],
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Alerts
  // -------------------------------------------------------------------------

  Widget _buildAlerts() {
    final shown = _data.alerts.take(5).toList();
    return GSection(
      eyebrow: 'History',
      title: 'Alerts',
      child: shown.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                  color: GasPalette.panelAlt,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('No alerts in this period.',
                  textAlign: TextAlign.center, style: gasBody(context)),
            )
          : Column(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: i == shown.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: GasPalette.border)),
                    ),
                    child: _alertRow(shown[i]),
                  ),
              ],
            ),
    );
  }

  Widget _alertRow(GasAlert a) {
    final (bg, fg, glyph) = switch (a.severity) {
      GasSeverity.critical => (GasPalette.critSoft, GasPalette.critInk, '!'),
      GasSeverity.warning => (GasPalette.warnSoft, GasPalette.warnInk, '!'),
      GasSeverity.info => (GasPalette.goodSoft, GasPalette.goodInk, '↑'),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(glyph,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title,
                  style: gasBody(context).copyWith(
                      color: GasPalette.ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(a.detail, style: gasBody(context).copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(formatAgo(a.at),
            style: gasSmall(context).copyWith(color: GasPalette.muted)),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  Widget _buildReports(double levelPct) {
    return GSection(
      eyebrow: 'Reports',
      title: 'Export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                style: _primaryButton(),
                onPressed: _exporting
                    ? null
                    : () => _export(GasReportFormat.pdf, levelPct),
                child: Text(_exporting
                    ? 'Preparing…'
                    : 'Download PDF (last ${_rangeDays}d)'),
              ),
              OutlinedButton(
                style: _secondaryButton(),
                onPressed: _exporting
                    ? null
                    : () => _export(GasReportFormat.csv, levelPct),
                child: const Text('Download CSV'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'PDF summarises the selected $_rangeDays-day window; CSV contains '
            'the full reading series.',
            style: gasSmall(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _export(GasReportFormat format, double levelPct) async {
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await downloadGasReport(
        context: context,
        format: format,
        input: GasReportInput(
          deviceName: widget.device.name.isNotEmpty
              ? widget.device.name
              : 'Gas cylinder',
          deviceId: widget.device.deviceId.isNotEmpty
              ? widget.device.deviceId
              : 'unknown',
          spec: _data.spec,
          points: dailySeries(_rangeReadings, pricePerKg: _data.pricePerKg),
          rangeDays: _rangeDays,
          pricePerKg: _data.pricePerKg,
          levelPct: levelPct,
          netKg: _data.currentNetKg,
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(format == GasReportFormat.pdf
              ? 'PDF report generated'
              : 'CSV file downloaded'),
          backgroundColor: GasPalette.good,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: GasPalette.crit,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
