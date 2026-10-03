/// Gas cylinder domain logic: models, formulas and aggregations.
///
/// Pure Dart — no Flutter imports, fully unit-testable. Formulas per the
/// product brief:
///   net gas     = current weight − tare weight
///   level %     = net gas / (full weight − tare weight) × 100
///   daily usage = previous reading − current reading (refills count 0)
///   daily cost  = usage × price per kg
library;

import 'dart:math' as math;

/// Common LPG cylinder sizes: gas capacity (kg) → (tare weight, full weight).
const Map<int, (double, double)> kCylinderSizes = {
  9: (8.1, 17.1),
  14: (11.5, 25.5),
  19: (15.6, 34.6),
  48: (43.0, 91.0),
};

/// Demo price assumption (ZAR) until the backend supplies pricing.
const double kDefaultPricePerKg = 28.50;
const String kCurrency = 'R';

/// Low-gas thresholds, as percent of capacity.
const double kLowGasThresholdPct = 20;
const double kWarningThresholdPct = 50;

/// A cylinder monitor counts as offline once readings stop for this long.
const Duration kOfflineAfter = Duration(hours: 6);

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class GasReading {
  const GasReading({required this.at, required this.weightKg});

  final DateTime at;
  final double weightKg;
}

enum GasBand { healthy, warning, low }

enum GasSeverity { critical, warning, info }

class GasAlert {
  const GasAlert({
    required this.at,
    required this.severity,
    required this.title,
    required this.detail,
  });

  final DateTime at;
  final GasSeverity severity;
  final String title;
  final String detail;
}

/// Cylinder configuration for one device.
class GasSpec {
  const GasSpec({
    required this.gasKg,
    required this.tareKg,
    required this.fullKg,
  });

  /// Builds from a nominal gas capacity (e.g. 14 for a "14 kg" cylinder).
  factory GasSpec.forCapacity(int gasKg) {
    final t = kCylinderSizes[gasKg] ?? kCylinderSizes[19]!;
    return GasSpec(gasKg: gasKg, tareKg: t.$1, fullKg: t.$2);
  }

  final int gasKg;
  final double tareKg;
  final double fullKg;

  /// Total usable gas when full, in kg.
  double get capacityKg => fullKg - tareKg;
}

// ---------------------------------------------------------------------------
// Type detection
// ---------------------------------------------------------------------------

/// True when a device's `device_type` string denotes a gas cylinder monitor.
bool isGasCylinderType(String? deviceType) {
  final v = deviceType?.trim().toLowerCase();
  return v == 'gas_cylinder' ||
      v == 'gas cylinder' ||
      v == 'gas monitor' ||
      v == 'gas';
}

// ---------------------------------------------------------------------------
// Formulas
// ---------------------------------------------------------------------------

double netGasKg({required double currentKg, required double tareKg}) =>
    math.max(0, currentKg - tareKg);

double levelPercent({
  required double currentKg,
  required double tareKg,
  required double fullKg,
}) {
  final capacity = fullKg - tareKg;
  if (capacity <= 0) return 0;
  return ((currentKg - tareKg) / capacity * 100).clamp(0, 100).toDouble();
}

/// Consumption between two readings: weight drops as gas burns, so this is
/// previous − current. A refill (weight went up) contributes 0 rather than a
/// negative burn.
double consumptionKg({required double previousKg, required double currentKg}) =>
    math.max(0, previousKg - currentKg);

double costOf({required double consumptionKg, required double pricePerKg}) =>
    consumptionKg * pricePerKg;

GasBand bandFor(
  double levelPct, {
  double lowPct = kLowGasThresholdPct,
  double warningPct = kWarningThresholdPct,
}) {
  if (levelPct < lowPct) return GasBand.low;
  if (levelPct < warningPct) return GasBand.warning;
  return GasBand.healthy;
}

String money(double v) => '$kCurrency${v.toStringAsFixed(2)}';

String kg1(double v) => '${v.toStringAsFixed(1)} kg';

// ---------------------------------------------------------------------------
// Aggregations
// ---------------------------------------------------------------------------

class DayPoint {
  const DayPoint({required this.day, required this.kg, required this.cost});

  final DateTime day;
  final double kg;
  final double cost;
}

class UsageSummary {
  const UsageSummary({
    required this.totalKg,
    required this.totalCost,
    required this.avgDailyKg,
    required this.avgDailyCost,
    required this.peak,
    required this.daysCovered,
  });

  final double totalKg;
  final double totalCost;
  final double avgDailyKg;
  final double avgDailyCost;
  final DayPoint? peak;
  final int daysCovered;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Consumption as consecutive-reading differences, bucketed by day. Gaps over
/// 48 h (monitor offline) contribute nothing rather than reporting a whole
/// outage as one day's burn.
List<DayPoint> dailySeries(
  List<GasReading> readings, {
  required double pricePerKg,
}) {
  final sorted = [...readings]..sort((a, b) => a.at.compareTo(b.at));
  final kgByDay = <DateTime, double>{};
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1], cur = sorted[i];
    if (cur.at.difference(prev.at) > const Duration(hours: 48)) continue;
    final kg =
        consumptionKg(previousKg: prev.weightKg, currentKg: cur.weightKg);
    final day = _dayOf(cur.at);
    kgByDay[day] = (kgByDay[day] ?? 0) + kg;
  }
  final days = kgByDay.keys.toList()..sort();
  return [
    for (final d in days)
      DayPoint(
        day: d,
        kg: kgByDay[d]!,
        cost: costOf(consumptionKg: kgByDay[d]!, pricePerKg: pricePerKg),
      ),
  ];
}

/// Weekly buckets (starting Monday) — used for the 60/90-day views where 90
/// daily bars would be too dense.
List<DayPoint> weeklySeries(
  List<GasReading> readings, {
  required double pricePerKg,
}) {
  final daily = dailySeries(readings, pricePerKg: pricePerKg);
  final kg = <DateTime, double>{};
  for (final p in daily) {
    final weekStart = p.day.subtract(Duration(days: p.day.weekday - 1));
    kg[weekStart] = (kg[weekStart] ?? 0) + p.kg;
  }
  final starts = kg.keys.toList()..sort();
  return [
    for (final s in starts)
      DayPoint(
        day: s,
        kg: kg[s]!,
        cost: costOf(consumptionKg: kg[s]!, pricePerKg: pricePerKg),
      ),
  ];
}

/// Usage since local midnight: last reading before today vs the latest.
/// Returns 0 when there is no baseline yet.
({double kg, double cost}) todayUsage(
  List<GasReading> readings, {
  required double pricePerKg,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final sorted = [...readings]..sort((a, b) => a.at.compareTo(b.at));
  if (sorted.length < 2) return (kg: 0, cost: 0);
  final today = _dayOf(at);
  GasReading baseline = sorted.first;
  for (final r in sorted) {
    if (_dayOf(r.at).isBefore(today)) baseline = r;
  }
  final latest = sorted.last;
  if (identical(baseline, latest)) return (kg: 0, cost: 0);
  final kg =
      consumptionKg(previousKg: baseline.weightKg, currentKg: latest.weightKg);
  return (kg: kg, cost: costOf(consumptionKg: kg, pricePerKg: pricePerKg));
}

UsageSummary summarize(List<DayPoint> series, {required int rangeDays}) {
  final totalKg = series.fold<double>(0, (a, p) => a + p.kg);
  final totalCost = series.fold<double>(0, (a, p) => a + p.cost);
  DayPoint? peak;
  for (final p in series) {
    if (peak == null || p.kg > peak.kg) peak = p;
  }
  return UsageSummary(
    totalKg: totalKg,
    totalCost: totalCost,
    avgDailyKg: rangeDays > 0 ? totalKg / rangeDays : 0,
    avgDailyCost: rangeDays > 0 ? totalCost / rangeDays : 0,
    peak: peak,
    daysCovered: series.length,
  );
}

/// Rolling average daily burn over the trailing [days] — drives the
/// "runs out in ~N days" estimate.
double trailingBurnPerDay(
  List<GasReading> readings, {
  int days = 7,
  DateTime? now,
}) {
  final daily = dailySeries(readings, pricePerKg: 0);
  if (daily.isEmpty) return 0;
  final at = now ?? DateTime.now();
  final cutoff = at.subtract(Duration(days: days));
  final recent = daily.where((p) => p.day.isAfter(cutoff)).toList();
  if (recent.isEmpty) return 0;
  return recent.fold<double>(0, (a, p) => a + p.kg) / days;
}

/// Days of gas left at the current burn rate, and the calendar date that
/// implies. `days` is infinite when there is nothing to project on.
({double days, DateTime? emptyBy}) daysRemaining({
  required double netKg,
  required double burnPerDay,
  required DateTime now,
}) {
  if (burnPerDay <= 0 || netKg <= 0) {
    return (days: double.infinity, emptyBy: null);
  }
  final d = netKg / burnPerDay;
  return (
    days: d,
    emptyBy: now.add(Duration(milliseconds: (d * 86400000).round())),
  );
}

/// Derives alerts (refills, threshold crossings, offline gaps) from a reading
/// series — shared by the demo generator and any future live feed.
List<GasAlert> deriveGasAlerts(
  List<GasReading> readings, {
  required GasSpec spec,
  double lowPct = kLowGasThresholdPct,
  double warningPct = kWarningThresholdPct,
}) {
  final alerts = <GasAlert>[];
  final sorted = [...readings]..sort((a, b) => a.at.compareTo(b.at));
  double prevPct = 100;
  for (var i = 0; i < sorted.length; i++) {
    final r = sorted[i];
    final pct = levelPercent(
        currentKg: r.weightKg, tareKg: spec.tareKg, fullKg: spec.fullKg);
    if (i > 0) {
      final gap = r.at.difference(sorted[i - 1].at);
      if (gap > kOfflineAfter) {
        alerts.add(GasAlert(
          at: r.at,
          severity: GasSeverity.warning,
          title: 'Monitor back online',
          detail:
              'No readings for ${gap.inHours}h — usage for that period could not be measured.',
        ));
      }
      final delta = r.weightKg - sorted[i - 1].weightKg;
      if (delta > 1.5) {
        alerts.add(GasAlert(
          at: r.at,
          severity: GasSeverity.info,
          title: 'Cylinder refilled',
          detail:
              '+${delta.toStringAsFixed(1)} kg detected — now at ${pct.round()}%.',
        ));
      }
    }
    if (prevPct >= lowPct && pct < lowPct) {
      alerts.add(GasAlert(
        at: r.at,
        severity: GasSeverity.critical,
        title: 'Gas level below ${lowPct.round()}%',
        detail: 'About ${pct.round()}% remaining — schedule a refill.',
      ));
    } else if (prevPct >= warningPct && pct < warningPct) {
      alerts.add(GasAlert(
        at: r.at,
        severity: GasSeverity.warning,
        title: 'Gas level below ${warningPct.round()}%',
        detail: 'About ${pct.round()}% remaining.',
      ));
    }
    prevPct = pct;
  }
  return alerts.reversed.toList(); // newest first
}
