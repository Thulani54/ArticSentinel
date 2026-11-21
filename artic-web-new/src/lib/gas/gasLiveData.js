import { OFFLINE_AFTER_MS, deriveGasAlerts, levelPercent, netGasKg } from './gasCore.js';

export function specFromConfig(config) {
  return {
    gasKg: config.gas_capacity_kg,
    tareKg: config.tare_kg,
    fullKg: config.tare_kg + config.gas_capacity_kg,
    capacityKg: config.gas_capacity_kg,
  };
}

export function thresholdsFromConfig(config) {
  return { low: config.low_threshold_pct, warning: config.warning_threshold_pct };
}

export function liveData(resp) {
  const { config } = resp;
  const spec = specFromConfig(config);
  // Readings are normalised onto the current tare via the stored net weight,
  // so a cylinder swapped for a different model still reads correctly.
  const toReading = (r) => ({ at: new Date(r.time), weightKg: r.net_kg + spec.tareKg });
  const readings = resp.readings.map(toReading).sort((a, b) => a.at - b.at);
  if (resp.latest) {
    const latestReading = toReading(resp.latest);
    const index = readings.findIndex((r) => r.at.getTime() === latestReading.at.getTime());
    if (index >= 0) readings[index] = latestReading;
    else if (!readings.length || latestReading.at > readings[readings.length - 1].at) readings.push(latestReading);
  }
  const latest = readings[readings.length - 1] ?? null;
  return {
    live: true,
    spec,
    readings,
    alerts: deriveGasAlerts(readings, spec, thresholdsFromConfig(config)),
    pricePerKg: config.price_per_kg,
    latest,
    latestRaw: resp.latest, // gross weight, battery, rssi, fw as the scale sent them
    isOffline: !latest || Date.now() - latest.at.getTime() > OFFLINE_AFTER_MS,
    currentNetKg: latest ? netGasKg(latest.weightKg, spec.tareKg) : null,
    currentLevelPct: latest ? levelPercent(latest.weightKg, spec.tareKg, spec.fullKg) : null,
  };
}

