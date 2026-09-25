// Gas data for one cylinder: live scale readings from api/gas/readings/ when
// the scale has reported, otherwise the deterministic demo series. Both come
// back in the same shape, so screens don't care which one they got.

import { useCallback, useEffect, useState } from 'react';
import { api } from '../../api';
import { useAuth } from '../../auth';
import {
  OFFLINE_AFTER_MS,
  deriveGasAlerts,
  levelPercent,
  netGasKg,
} from './gasCore';
import { generateGasDemoData } from './gasDemoData';

const HISTORY_DAYS = 90;
const REFRESH_MS = 15000; // live scales report every few seconds

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

function liveData(resp) {
  const { config } = resp;
  const spec = specFromConfig(config);
  // Readings are normalised onto the current tare via the stored net weight,
  // so a cylinder swapped for a different model still reads correctly.
  const toReading = (r) => ({ at: new Date(r.time), weightKg: r.net_kg + spec.tareKg });
  const readings = resp.readings.map(toReading);
  const latest = resp.latest ? toReading(resp.latest) : readings[readings.length - 1];
  return {
    live: true,
    spec,
    readings,
    alerts: deriveGasAlerts(readings, spec, thresholdsFromConfig(config)),
    pricePerKg: config.price_per_kg,
    latest,
    latestRaw: resp.latest, // gross weight, battery, rssi, fw as the scale sent them
    isOffline: Date.now() - latest.at.getTime() > OFFLINE_AFTER_MS,
    currentNetKg: netGasKg(latest.weightKg, spec.tareKg),
    currentLevelPct: levelPercent(latest.weightKg, spec.tareKg, spec.fullKg),
  };
}

// Demo series re-expressed on the saved cylinder, so demo readouts match the
// setup panel: each reading keeps its fill fraction, scaled to the new
// capacity and shifted onto the new tare.
function demoData(device, config) {
  const demo = generateGasDemoData(device.device_id);
  if (!config || config.is_default) return { ...demo, live: false };
  const spec = specFromConfig(config);
  const readings = demo.readings.map((r) => ({
    at: r.at,
    weightKg: spec.tareKg + (netGasKg(r.weightKg, demo.spec.tareKg) / demo.spec.capacityKg) * spec.capacityKg,
  }));
  const latest = readings[readings.length - 1];
  return {
    ...demo,
    live: false,
    spec,
    readings,
    alerts: deriveGasAlerts(readings, spec, thresholdsFromConfig(config)),
    pricePerKg: config.price_per_kg,
    latest,
    currentNetKg: netGasKg(latest.weightKg, spec.tareKg),
    currentLevelPct: levelPercent(latest.weightKg, spec.tareKg, spec.fullKg),
  };
}

export function useGasData(device) {
  const { token, business } = useAuth();
  const [state, setState] = useState({ data: null, config: null, error: null });

  const load = useCallback(async () => {
    try {
      const resp = await api.post(
        '/gas/readings/',
        { business_id: business.business_uid, device_id: device.id, days: HISTORY_DAYS },
        token,
      );
      const data = resp.readings.length > 0 || resp.latest ? liveData(resp) : demoData(device, resp.config);
      setState({ data, config: resp.config, error: null });
    } catch (e) {
      // Backend unreachable: keep the screen useful with demo data.
      setState({
        data: demoData(device, null),
        config: null,
        error: e.message,
      });
    }
  }, [token, business, device.id, device.device_id]);

  useEffect(() => {
    load();
    const id = setInterval(() => {
      if (document.visibilityState === 'visible') load();
    }, REFRESH_MS);
    return () => clearInterval(id);
  }, [load]);

  const saveConfig = useCallback(
    async (values) => {
      const resp = await api.post(
        '/gas/config/update/',
        { business_id: business.business_uid, device_id: device.id, ...values },
        token,
      );
      await load(); // levels are recomputed against the new tare/capacity
      return resp.config;
    },
    [token, business, device.id, load],
  );

  return { ...state, reload: load, saveConfig };
}
