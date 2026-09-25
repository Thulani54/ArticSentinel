// Gas cylinder domain logic — JavaScript port of lib/gasmon/gas_core.dart.
// Pure functions, no React. Formulas per the product brief:
//   net gas     = current weight − tare weight
//   level %     = net gas / (full weight − tare weight) × 100
//   usage       = previous reading − current reading (refills count 0)
//   cost        = usage × price per kg

export const CYLINDER_SIZES = {
  9: { tare: 8.1, full: 17.1 },
  14: { tare: 11.5, full: 25.5 },
  19: { tare: 15.6, full: 34.6 },
  48: { tare: 43.0, full: 91.0 },
};

export const DEFAULT_PRICE_PER_KG = 28.5;
export const CURRENCY = 'R';
export const LOW_GAS_THRESHOLD_PCT = 20;
export const WARNING_THRESHOLD_PCT = 50;
export const OFFLINE_AFTER_MS = 6 * 3600 * 1000;

export function makeSpec(gasKg) {
  const t = CYLINDER_SIZES[gasKg] ?? CYLINDER_SIZES[19];
  return { gasKg, tareKg: t.tare, fullKg: t.full, capacityKg: t.full - t.tare };
}

export function isGasCylinderType(deviceType) {
  const v = (deviceType ?? '').trim().toLowerCase();
  return v === 'gas_cylinder' || v === 'gas cylinder' || v === 'gas monitor' || v === 'gas';
}

export function netGasKg(currentKg, tareKg) {
  return Math.max(0, currentKg - tareKg);
}

export function levelPercent(currentKg, tareKg, fullKg) {
  const capacity = fullKg - tareKg;
  if (capacity <= 0) return 0;
  return Math.min(100, Math.max(0, ((currentKg - tareKg) / capacity) * 100));
}

// Weight drops as gas burns, so consumption is previous − current. A refill
// (weight went up) contributes 0 rather than a negative burn.
export function consumptionKg(previousKg, currentKg) {
  return Math.max(0, previousKg - currentKg);
}

export const costOf = (kg, pricePerKg) => kg * pricePerKg;

export const DEFAULT_THRESHOLDS = { low: LOW_GAS_THRESHOLD_PCT, warning: WARNING_THRESHOLD_PCT };

export function bandFor(levelPct, thresholds = DEFAULT_THRESHOLDS) {
  if (levelPct < thresholds.low) return 'low';
  if (levelPct < thresholds.warning) return 'warning';
  return 'healthy';
}

export const money = (v) => `${CURRENCY}${v.toFixed(2)}`;
export const kg1 = (v) => `${v.toFixed(1)} kg`;

// ---------------------------------------------------------------- aggregations

const dayKey = (d) => `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
const dayOf = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const byTimeAsc = (a, b) => a.at - b.at;

// Consecutive-reading differences bucketed by day. Gaps over 48 h (monitor
// offline) contribute nothing rather than reporting an outage as one day's burn.
export function dailySeries(readings, pricePerKg) {
  const sorted = [...readings].sort(byTimeAsc);
  const kgByDay = new Map(); // dayKey -> { day, kg }
  for (let i = 1; i < sorted.length; i++) {
    const prev = sorted[i - 1];
    const cur = sorted[i];
    if (cur.at - prev.at > 48 * 3600 * 1000) continue;
    const kg = consumptionKg(prev.weightKg, cur.weightKg);
    const k = dayKey(cur.at);
    const entry = kgByDay.get(k) ?? { day: dayOf(cur.at), kg: 0 };
    entry.kg += kg;
    kgByDay.set(k, entry);
  }
  return [...kgByDay.values()]
    .sort((a, b) => a.day - b.day)
    .map((p) => ({ ...p, cost: costOf(p.kg, pricePerKg) }));
}

// Weekly buckets starting Monday — used for the 60/90-day views.
export function weeklySeries(readings, pricePerKg) {
  const kg = new Map(); // weekStartKey -> { day, kg }
  for (const p of dailySeries(readings, pricePerKg)) {
    const offset = (p.day.getDay() + 6) % 7; // Mon=0 .. Sun=6
    const weekStart = new Date(p.day);
    weekStart.setDate(weekStart.getDate() - offset);
    const k = dayKey(weekStart);
    const entry = kg.get(k) ?? { day: weekStart, kg: 0 };
    entry.kg += p.kg;
    kg.set(k, entry);
  }
  return [...kg.values()]
    .sort((a, b) => a.day - b.day)
    .map((p) => ({ ...p, cost: costOf(p.kg, pricePerKg) }));
}

// Usage since local midnight: last reading before today vs the latest.
export function todayUsage(readings, pricePerKg, now = new Date()) {
  const sorted = [...readings].sort(byTimeAsc);
  if (sorted.length < 2) return { kg: 0, cost: 0 };
  const today = dayKey(now);
  let baseline = sorted[0];
  for (const r of sorted) {
    if (dayKey(r.at) !== today) baseline = r;
  }
  const latest = sorted[sorted.length - 1];
  if (baseline === latest) return { kg: 0, cost: 0 };
  const kg = consumptionKg(baseline.weightKg, latest.weightKg);
  return { kg, cost: costOf(kg, pricePerKg) };
}

export function summarize(series, rangeDays) {
  let totalKg = 0;
  let totalCost = 0;
  let peak = null;
  for (const p of series) {
    totalKg += p.kg;
    totalCost += p.cost;
    if (!peak || p.kg > peak.kg) peak = p;
  }
  return {
    totalKg,
    totalCost,
    avgDailyKg: rangeDays > 0 ? totalKg / rangeDays : 0,
    avgDailyCost: rangeDays > 0 ? totalCost / rangeDays : 0,
    peak,
    daysCovered: series.length,
  };
}

// Rolling average daily burn over the trailing [days] — drives the
// "runs out in ~N days" estimate.
export function trailingBurnPerDay(readings, days = 7, now = new Date()) {
  const daily = dailySeries(readings, 0);
  if (daily.length === 0) return 0;
  const cutoff = now.getTime() - days * 86400000;
  const recent = daily.filter((p) => p.day.getTime() > cutoff);
  if (recent.length === 0) return 0;
  return recent.reduce((a, p) => a + p.kg, 0) / days;
}

export function daysRemaining(netKg, burnPerDay, now = new Date()) {
  if (burnPerDay <= 0 || netKg <= 0) return { days: Infinity, emptyBy: null };
  const d = netKg / burnPerDay;
  return { days: d, emptyBy: new Date(now.getTime() + Math.round(d * 86400000)) };
}

// Derives alerts (offline gaps, refills, threshold crossings) — newest first,
// mirroring deriveGasAlerts in gas_core.dart.
export function deriveGasAlerts(readings, spec, thresholds = DEFAULT_THRESHOLDS) {
  const { low, warning } = thresholds;
  const alerts = [];
  const sorted = [...readings].sort(byTimeAsc);
  let prevPct = 100;
  for (let i = 0; i < sorted.length; i++) {
    const r = sorted[i];
    const pct = levelPercent(r.weightKg, spec.tareKg, spec.fullKg);
    if (i > 0) {
      const gap = r.at - sorted[i - 1].at;
      if (gap > OFFLINE_AFTER_MS) {
        alerts.push({
          at: r.at,
          severity: 'warning',
          title: 'Monitor back online',
          detail: `No readings for ${Math.round(gap / 3600000)}h — usage for that period could not be measured.`,
        });
      }
      const delta = r.weightKg - sorted[i - 1].weightKg;
      if (delta > 1.5) {
        alerts.push({
          at: r.at,
          severity: 'info',
          title: 'Cylinder refilled',
          detail: `+${delta.toFixed(1)} kg detected — now at ${Math.round(pct)}%.`,
        });
      }
    }
    if (prevPct >= low && pct < low) {
      alerts.push({
        at: r.at,
        severity: 'critical',
        title: `Gas level below ${low}%`,
        detail: `About ${Math.round(pct)}% remaining — schedule a refill.`,
      });
    } else if (prevPct >= warning && pct < warning) {
      alerts.push({
        at: r.at,
        severity: 'warning',
        title: `Gas level below ${warning}%`,
        detail: `About ${Math.round(pct)}% remaining.`,
      });
    }
    prevPct = pct;
  }
  return alerts.reverse();
}
