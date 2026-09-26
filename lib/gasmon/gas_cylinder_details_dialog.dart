/// Details dashboard for a gas cylinder device. Replaces the temperature-
/// oriented `DeviceDetailsDialog` for devices whose type is 'gas_cylinder'.
///
/// Shows live scale readings from api/gas/readings/ once the scale has
/// reported (labelled "LIVE SCALE"), and demo data ("DEMO DATA") before that.
/// Also hosts the Cylinder setup and the Bluetooth "Connect scale" flow.
library;

import '../widgets/mobile_forms.dart';

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
  late final String _demoKey;
  late final AnimationController _fillCtrl;
  int _rangeDays = 30;
  bool _exporting = false;

  GasDeviceData get _data => _loaded!;

  @override
  void initState() {
    super.initState();
    final key = [
      widget.device.deviceId,
      widget.device.name,
      widget.device.id?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join('-');
    _demoKey = key.isEmpty ? 'gas' : key;
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
    final id = widget.device.id;
    GasDeviceData data;
    GasConfig? config = _config;
    if (widget.loadData != null) {
      final result = await widget.loadData!();
      data = result.data;
      config = result.config;
    } else if (id == null) {
      data = GasApi.demoForConfig(_demoKey, null);
    } else {
      try {
        final r = await GasApi.load(deviceId: id, demoKey: _demoKey);
        data = r.data;
        config = r.config;
        _loadError = null;
      } catch (e) {
        debugPrint('[gas] load failed: $e');
        if (mounted)
          setState(() => _loadError =
              'Could not refresh scale readings. Check your connection and retry.');
        if (_loaded != null) return; // keep showing what we have
        data = GasApi.demoForConfig(_demoKey, null);
      }
    }
    if (!mounted) return;
    final first = _loaded == null;
    setState(() {
      _loaded = data;
      _config = config;
    });
    if (first) _fillCtrl.forward();
  }

  Future<void> _saveConfig(GasConfig config) async {
    final id = widget.device.id;
    if (id == null) throw GasApiException('This device has no ID yet.');
    final saved = await GasApi.saveConfig(deviceId: id, config: config);
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
    if (_loaded == null) {
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
    final levelPct = _data.currentLevelPct;
    final band =
        bandFor(levelPct, lowPct: _data.lowPct, warningPct: _data.warningPct);
    final daily = dailySeries(_rangeReadings, pricePerKg: _data.pricePerKg);
    final summary = summarize(daily, rangeDays: _rangeDays);
    final chartPoints = _rangeDays <= 45
        ? daily
        : weeklySeries(_rangeReadings, pricePerKg: _data.pricePerKg);
    final burnPerDay = trailingBurnPerDay(_data.readings);
    final projection = daysRemaining(
        netKg: _data.currentNetKg, burnPerDay: burnPerDay, now: DateTime.now());
    final today = todayUsage(_data.readings, pricePerKg: _data.pricePerKg);
    final offline = _data.isOffline;

    return MobileDialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(offline),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: _buildBody(levelPct, band, today, summary,
                        chartPoints, projection, offline),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _buildHeader(bool offline) {
    if (isPhoneLayout(context)) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.device.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: GasPalette.navy)),
                      const SizedBox(height: 4),
                      Text('Gas cylinder · ${widget.device.deviceId}',
                          style: gasSmall(context)),
                    ])),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              Text(
                  _data.live
                      ? (offline
                          ? 'Offline · last reading ${formatAgo(_data.latest.at)}'
                          : 'Live scale connected')
                      : 'Waiting for the first scale reading',
                  style: gasBody(context)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _openScaleSetup,
                  child: const Text('Connect scale')),
            ],
          ));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: mobileFlatDecoration(
          context,
          BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GasPalette.navy,
                GasPalette.navy.withValues(alpha: 0.85)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          )),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.propane_tank, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gasTitle(context)
                      .copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gas Cylinder · '
                  '${widget.device.deviceId.isNotEmpty ? widget.device.deviceId : 'no ID'}',
                  style: gasSmall(context).copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _data.live ? _liveChip() : _demoChip(),
                    const SizedBox(width: 14),
                    GPresenceChip(
                      online: !offline,
                      lastSeen: _data.latest.at,
                      light: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _openScaleSetup,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Connect scale'),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GasPalette.good.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GasPalette.good.withValues(alpha: 0.7)),
      ),
      child: const Text(
        'LIVE SCALE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFFA7F3D0),
        ),
      ),
    );
  }

  Widget _demoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GasPalette.warn.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GasPalette.warn.withValues(alpha: 0.7)),
      ),
      child: const Text(
        'DEMO DATA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFFFFD8A8),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Body
  // -------------------------------------------------------------------------

  Widget _buildBody(
    double levelPct,
    GasBand band,
    ({double kg, double cost}) today,
    UsageSummary summary,
    List<DayPoint> chartPoints,
    ({double days, DateTime? emptyBy}) projection,
    bool offline,
  ) {
    if (isPhoneLayout(context) && !_data.live) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('No live reading yet', style: gasTitle(context)),
          const SizedBox(height: 10),
          Text(
              _loadError ??
                  'Connect the scale to Wi-Fi, then wait for its first weight reading. Gas level and usage charts will appear here when real readings arrive.',
              style: gasBody(context)),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: _load, child: const Text('Check for readings')),
        ])),
        const SizedBox(height: 20),
        GasSetupCard(config: _config, onSave: _saveConfig),
        const SizedBox(height: 20),
        GasNotificationCard(device: widget.device),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadError != null) ...[
          _noticeBanner(_loadError!),
          const SizedBox(height: 16)
        ],
        if (!_data.live) ...[
          _noticeBanner(
            'Showing demo data. Live readings replace it as soon as the scale '
            'sends its first weight — tap "Connect scale" to set one up.',
          ),
          const SizedBox(height: 16),
        ],
        if (_data.live &&
            _data.scaleGrossKg != null &&
            _data.scaleGrossKg! < _data.spec.tareKg) ...[
          _noticeBanner(
            'The scale reads ${kg1(_data.scaleGrossKg!)} — less than the empty '
            'cylinder weight (${kg1(_data.spec.tareKg)}). Gas shows as 0 until '
            'the reading is above it. Check the Cylinder setup below.',
          ),
          const SizedBox(height: 16),
        ],
        _buildTopRow(levelPct, band, today, projection, offline),
        if (band != GasBand.healthy) ...[
          const SizedBox(height: 16),
          _bandBanner(band, levelPct),
        ],
        if (offline) ...[
          const SizedBox(height: 12),
          _offlineBanner(),
        ],
        const SizedBox(height: 24),
        _buildPerformance(summary, chartPoints),
        const SizedBox(height: 24),
        _buildAlerts(),
        const SizedBox(height: 24),
        _buildReports(levelPct),
        const SizedBox(height: 24),
        if (isPhoneLayout(context)) ...[
          GasNotificationCard(device: widget.device),
          const SizedBox(height: 24)
        ],
        GasSetupCard(
          config: _config,
          scaleGrossKg: _data.live ? _data.scaleGrossKg : null,
          onSave: _saveConfig,
        ),
      ],
    );
  }

  Widget _noticeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: GasPalette.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GasPalette.warn.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: gasBody(context).copyWith(
              color: const Color(0xFF92400E), fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTopRow(
    double levelPct,
    GasBand band,
    ({double kg, double cost}) today,
    ({double days, DateTime? emptyBy}) projection,
    bool offline,
  ) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      final gauge = _buildGaugeCard(levelPct, band, offline);
      final side = _buildSideCards(today, projection, offline);
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: gauge),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: side),
          ],
        );
      }
      return Column(children: [gauge, const SizedBox(height: 16), side]);
    });
  }

  Widget _buildGaugeCard(double levelPct, GasBand band, bool offline) {
    return GPanel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: GEyebrow('Cylinder level')),
              GBandChip(band: band, levelPct: levelPct),
            ],
          ),
          const SizedBox(height: 8),
          Center(
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
          const SizedBox(height: 4),
          Text(
            '${_data.spec.gasKg} kg LPG cylinder · '
            'tare ${_data.spec.tareKg.toStringAsFixed(1)} kg',
            style: gasSmall(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSideCards(
    ({double kg, double cost}) today,
    ({double days, DateTime? emptyBy}) projection,
    bool offline,
  ) {
    final readouts = GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GEyebrow('Current state'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: GReadout(
                      label: 'Net gas', value: kg1(_data.currentNetKg))),
              Expanded(
                  child: GReadout(
                      label: 'Usable capacity',
                      value: kg1(_data.spec.capacityKg))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: GReadout(
                      label: 'Last reading',
                      value: formatAgo(_data.latest.at))),
              Expanded(
                  child: GReadout(
                      label: 'Price assumed',
                      value: '${money(_data.pricePerKg)}/kg')),
            ],
          ),
          if (_data.live && _data.scaleGrossKg != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: GReadout(
                        label: 'On the scale',
                        value: kg1(_data.scaleGrossKg!),
                        sub: 'cylinder + gas combined')),
                Expanded(
                    child: GReadout(
                        label: 'Scale battery',
                        value: _data.batteryPct != null
                            ? '${_data.batteryPct!.round()}%'
                            : '—')),
              ],
            ),
          ],
        ],
      ),
    );

    final hasToday = today.kg > 0;
    final todayCard = GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GEyebrow('Today so far'),
          const SizedBox(height: 12),
          Text(
            hasToday ? kg1(today.kg) : '—',
            style: gasData(context, size: 26, color: GasPalette.flameDeep),
          ),
          const SizedBox(height: 4),
          Text(
            hasToday
                ? 'burned · ${money(today.cost)}'
                : 'no measurable burn today',
            style: gasSmall(context),
          ),
        ],
      ),
    );

    final projCard = GPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GEyebrow('Est. runs out'),
          const SizedBox(height: 12),
          Text(
            offline
                ? '—'
                : (projection.emptyBy == null
                    ? '—'
                    : '~${projection.days.round()} days'),
            style: gasData(context, size: 26, color: GasPalette.navy),
          ),
          const SizedBox(height: 4),
          Text(
            offline
                ? 'paused — monitor offline'
                : (projection.emptyBy == null
                    ? 'no usable trend yet'
                    : 'around ${DateFormat('d MMM yyyy').format(projection.emptyBy!)}'),
            style: gasSmall(context),
          ),
        ],
      ),
    );

    return Column(
      children: [
        readouts,
        const SizedBox(height: 16),
        MobileFormRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: todayCard),
            const SizedBox(width: 16),
            Expanded(child: projCard),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Banners
  // -------------------------------------------------------------------------

  Widget _bandBanner(GasBand band, double levelPct) {
    final crit = band == GasBand.low;
    final color = crit ? GasPalette.crit : GasPalette.warn;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: crit ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: crit ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(crit ? Icons.error : Icons.warning_amber_rounded,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              crit
                  ? 'Low gas — ${levelPct.round()}% remaining. Schedule a refill now.'
                  : 'Gas at ${levelPct.round()}% — below the 50% comfort line. Plan a refill soon.',
              style: gasBody(context)
                  .copyWith(color: GasPalette.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: GasPalette.warn, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Monitor offline — last reading ${formatAgo(_data.latest.at)}. '
              'Estimates may be stale.',
              style: gasBody(context)
                  .copyWith(color: GasPalette.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Performance
  // -------------------------------------------------------------------------

  Widget _buildPerformance(UsageSummary summary, List<DayPoint> chartPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: GEyebrow('Performance')),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30d')),
                ButtonSegment(value: 60, label: Text('60d')),
                ButtonSegment(value: 90, label: Text('90d')),
              ],
              selected: {_rangeDays},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: GasPalette.navy,
                selectedForegroundColor: Colors.white,
                backgroundColor: GasPalette.panelAlt,
                foregroundColor: GasPalette.ink2,
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onSelectionChanged: (s) => setState(() => _rangeDays = s.first),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 720;
          final tiles = <(String, String)>[
            ('Total usage', kg1(summary.totalKg)),
            ('Total cost', money(summary.totalCost)),
            ('Avg per day', kg1(summary.avgDailyKg)),
            (
              'Peak day',
              summary.peak == null
                  ? '—'
                  : '${summary.peak!.kg.toStringAsFixed(1)} kg · '
                      '${DateFormat('d MMM').format(summary.peak!.day)}'
            ),
          ];
          final tileW = wide ? (c.maxWidth - 36) / 4 : (c.maxWidth - 12) / 2;

          final charts = LayoutBuilder(builder: (context, cc) {
            final wideCharts = cc.maxWidth >= 720;
            final burn = GPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gas burned per ${_rangeDays <= 45 ? 'day' : 'week'} (kg)',
                    style: gasBody(context).copyWith(
                        fontWeight: FontWeight.w700, color: GasPalette.ink),
                  ),
                  const SizedBox(height: 12),
                  GasBurnBarChart(
                      points: chartPoints, rodWidth: _rangeDays <= 45 ? 9 : 20),
                ],
              ),
            );
            final cost = GPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost trend ($kCurrency)',
                    style: gasBody(context).copyWith(
                        fontWeight: FontWeight.w700, color: GasPalette.ink),
                  ),
                  const SizedBox(height: 12),
                  GasCostLineChart(points: chartPoints),
                ],
              ),
            );
            if (wideCharts) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: burn),
                  const SizedBox(width: 16),
                  Expanded(child: cost),
                ],
              );
            }
            return Column(children: [burn, const SizedBox(height: 16), cost]);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (k, v) in tiles)
                    SizedBox(width: tileW, child: _summaryTile(k, v)),
                ],
              ),
              const SizedBox(height: 16),
              charts,
            ],
          );
        }),
      ],
    );
  }

  Widget _summaryTile(String label, String value) {
    return GPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: gasEyebrow(context).copyWith(fontSize: 9.5)),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gasData(context, size: 15)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Alerts
  // -------------------------------------------------------------------------

  Widget _buildAlerts() {
    final shown = _data.alerts.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GEyebrow('Recent alerts'),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          GPanel(
            child: Text('No alerts — levels have been steady.',
                style: gasBody(context)),
          )
        else
          GPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final a in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: GasPalette.severity(a.severity)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_severityIcon(a.severity),
                              size: 15, color: GasPalette.severity(a.severity)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: gasBody(context).copyWith(
                                      color: GasPalette.ink,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(a.detail, style: gasSmall(context)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(formatAgo(a.at),
                            style: gasSmall(context)
                                .copyWith(color: GasPalette.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _severityIcon(GasSeverity s) => switch (s) {
        GasSeverity.critical => Icons.error_rounded,
        GasSeverity.warning => Icons.warning_amber_rounded,
        GasSeverity.info => Icons.local_fire_department_rounded,
      };

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  Widget _buildReports(double levelPct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GEyebrow('Reports'),
        const SizedBox(height: 4),
        Text(
          'Last $_rangeDays days · demo data · price assumed '
          '${money(_data.pricePerKg)}/kg',
          style: gasSmall(context).copyWith(color: GasPalette.muted),
        ),
        const SizedBox(height: 10),
        MobileFormRow(
          children: [
            FilledButton.icon(
              onPressed: _exporting
                  ? null
                  : () => _export(GasReportFormat.pdf, levelPct),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Download PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: GasPalette.navy,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _exporting
                  ? null
                  : () => _export(GasReportFormat.csv, levelPct),
              icon: const Icon(Icons.table_view, size: 18),
              label: const Text('Download CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GasPalette.navy,
                side: const BorderSide(color: GasPalette.border),
              ),
            ),
          ],
        ),
      ],
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
