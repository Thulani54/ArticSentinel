/// Deterministic demo telemetry for gas cylinder devices.
///
/// The generator is a test fixture only. Production screens render only
/// server readings returned by GasApi; a missing series stays empty.
library;

import 'dart:math' as math;

import 'gas_core.dart';

/// Everything the gas dashboard needs for one device.
class GasDeviceData {
  const GasDeviceData({
    required this.spec,
    required this.readings,
    required this.alerts,
    required this.pricePerKg,
    this.live = false,
    this.scaleGrossKg,
    this.batteryPct,
    this.lowPct = kLowGasThresholdPct,
    this.warningPct = kWarningThresholdPct,
  });

  final GasSpec spec;
  final List<GasReading> readings; // ascending by time
  final List<GasAlert> alerts; // newest first
  final double pricePerKg;

  /// True when the readings come from the scale (api/gas/readings/), false
  /// for the generated demo series.
  final bool live;

  /// Latest combined weight exactly as the scale reported it (live only).
  final double? scaleGrossKg;
  final double? batteryPct;

  /// Alert levels from the device's Cylinder setup.
  final double lowPct;
  final double warningPct;

  /// A level is available only when at least one genuine reading exists.
  bool get hasReadings => live && readings.isNotEmpty;

  GasReading get latest => readings.last;

  bool get isOffline =>
      !hasReadings || DateTime.now().difference(latest.at) > kOfflineAfter;

  double get currentNetKg =>
      netGasKg(currentKg: latest.weightKg, tareKg: spec.tareKg);

  double get currentLevelPct => levelPercent(
      currentKg: latest.weightKg, tareKg: spec.tareKg, fullKg: spec.fullKg);
}

/// Generates a 90-day simulation: readings every 3 h, one refill, one
/// multi-day outage and realistic burn noise. Deterministic per [deviceKey],
/// so the same device always tells the same story.
GasDeviceData generateGasDemoData({required String deviceKey, DateTime? now}) {
  final at = now ?? DateTime.now();
  final rng = math.Random(deviceKey.hashCode);

  // Cylinder size, weighted toward commercial sizes.
  const sizes = [9, 14, 19, 48, 19, 48];
  final spec = GasSpec.forCapacity(sizes[rng.nextInt(sizes.length)]);
  final capacity = spec.capacityKg;

  final pricePerKg = 24.0 + rng.nextDouble() * 10.0;

  // Story beats: start 40–75% full, burn down to ~6–12% by the refill
  // (20–34 days ago), refill to full, then burn to an end level of 12–70%.
  final startPct = 0.40 + rng.nextDouble() * 0.35;
  final floorPct = 0.06 + rng.nextDouble() * 0.06;
  final endPct = 0.12 + rng.nextDouble() * 0.58;
  final refillDay = 56.0 + rng.nextDouble() * 14.0; // 90 − (34..20)
  final outageStart = 20.0 + rng.nextDouble() * 12.0; // days from start

  final burnBeforeRefill = capacity * (startPct - floorPct) / refillDay;
  final burnAfterRefill = capacity * (1 - endPct) / (90 - refillDay);

  final start = at.subtract(const Duration(days: 90));
  var netKg = capacity * startPct;
  final readings = <GasReading>[];
  const stepHours = 3;
  const stepsPerDay = 8;
  final totalSteps = 90 * stepsPerDay;

  for (var step = 0; step <= totalSteps; step++) {
    final dayIndex = step / stepsPerDay;
    final t = start.add(Duration(hours: stepHours * step));

    // Refill to full on the refill day.
    if (dayIndex >= refillDay && (step - 1) / stepsPerDay < refillDay) {
      netKg = capacity;
    }

    var perStep = (dayIndex < refillDay ? burnBeforeRefill : burnAfterRefill) /
        stepsPerDay *
        (0.85 + 0.3 * rng.nextDouble());
    // Keep the pre-refill trough from hitting absolute empty.
    if (dayIndex < refillDay) {
      final allowed = math.max(0.0, netKg - capacity * floorPct * 0.5);
      perStep = math.min(perStep, allowed);
    }
    netKg = math.max(0, netKg - perStep);

    // A 2–3 day outage mid-history: skip readings entirely.
    final inOutage = dayIndex >= outageStart && dayIndex < outageStart + 2.5;
    if (inOutage) continue;

    readings.add(GasReading(at: t, weightKg: spec.tareKg + netKg));
  }

  // Some devices are currently offline: drop the most recent readings so the
  // dashboard exercises its "last seen" / offline states.
  if (rng.nextDouble() < 0.35) {
    final drop = 8 + rng.nextInt(20); // 24–60 h stale
    if (readings.length > drop + 2) {
      readings.removeRange(readings.length - drop, readings.length);
    }
  }

  return GasDeviceData(
    spec: spec,
    readings: readings,
    alerts: deriveGasAlerts(readings, spec: spec),
    pricePerKg: pricePerKg,
  );
}
