// Deterministic demo telemetry — JavaScript port of
// lib/gasmon/gas_demo_data.dart. The backend has no gas-weight endpoints yet,
// so the gas dashboard renders this series, labelled "DEMO DATA" in the UI.

import {
  OFFLINE_AFTER_MS,
  deriveGasAlerts,
  levelPercent,
  makeSpec,
  netGasKg,
} from './gasCore';

// Small deterministic PRNG so the same device always tells the same story.
function hashKey(str) {
  let h = 1779033703 ^ str.length;
  for (let i = 0; i < str.length; i++) {
    h = Math.imul(h ^ str.charCodeAt(i), 3432918353);
    h = (h << 13) | (h >>> 19);
  }
  return h >>> 0;
}

function mulberry32(seed) {
  let a = seed | 0;
  return function () {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function generateGasDemoData(deviceKey, now = new Date()) {
  const rng = mulberry32(hashKey(deviceKey));

  // Cylinder size, weighted toward commercial sizes.
  const sizes = [9, 14, 19, 48, 19, 48];
  const spec = makeSpec(sizes[Math.floor(rng() * sizes.length)]);
  const capacity = spec.capacityKg;

  const pricePerKg = 24 + rng() * 10;

  // Story beats: start 40–75% full, burn to ~6–12% by the refill (20–34 days
  // ago), refill to full, then burn to an end level of 12–70%.
  const startPct = 0.4 + rng() * 0.35;
  const floorPct = 0.06 + rng() * 0.06;
  const endPct = 0.12 + rng() * 0.58;
  const refillDay = 56 + rng() * 14; // 90 − (34..20)
  const outageStart = 20 + rng() * 12; // days from start

  const burnBeforeRefill = (capacity * (startPct - floorPct)) / refillDay;
  const burnAfterRefill = (capacity * (1 - endPct)) / (90 - refillDay);

  const start = new Date(now.getTime() - 90 * 86400000);
  let netKg = capacity * startPct;
  const readings = [];
  const stepHours = 3;
  const stepsPerDay = 8;
  const totalSteps = 90 * stepsPerDay;

  for (let step = 0; step <= totalSteps; step++) {
    const dayIndex = step / stepsPerDay;
    const t = new Date(start.getTime() + stepHours * 3600000 * step);

    // Refill to full on the refill day.
    if (dayIndex >= refillDay && (step - 1) / stepsPerDay < refillDay) {
      netKg = capacity;
    }

    let perStep =
      ((dayIndex < refillDay ? burnBeforeRefill : burnAfterRefill) / stepsPerDay) *
      (0.85 + 0.3 * rng());
    // Keep the pre-refill trough from hitting absolute empty.
    if (dayIndex < refillDay) {
      const allowed = Math.max(0, netKg - capacity * floorPct * 0.5);
      perStep = Math.min(perStep, allowed);
    }
    netKg = Math.max(0, netKg - perStep);

    // A 2–3 day outage mid-history: skip readings entirely.
    const inOutage = dayIndex >= outageStart && dayIndex < outageStart + 2.5;
    if (inOutage) continue;

    readings.push({ at: t, weightKg: spec.tareKg + netKg });
  }

  // Some devices are currently offline: drop the most recent readings.
  if (rng() < 0.35) {
    const drop = 8 + Math.floor(rng() * 20); // 24–60 h stale
    if (readings.length > drop + 2) {
      readings.splice(readings.length - drop, drop);
    }
  }

  const latest = readings[readings.length - 1];
  return {
    spec,
    readings, // ascending by time
    alerts: deriveGasAlerts(readings, spec), // newest first
    pricePerKg,
    latest,
    isOffline: Date.now() - latest.at.getTime() > OFFLINE_AFTER_MS,
    currentNetKg: netGasKg(latest.weightKg, spec.tareKg),
    currentLevelPct: levelPercent(latest.weightKg, spec.tareKg, spec.fullKg),
  };
}
