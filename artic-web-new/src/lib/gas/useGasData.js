// Use reported telemetry only; failed requests retain explicitly marked last readings.
import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from '../../api';
import { useAuth } from '../../auth';
import { liveData } from './gasLiveData.js';
export { specFromConfig, thresholdsFromConfig } from './gasLiveData.js';

const HISTORY_DAYS = 90;
const REFRESH_MS = 15000;

export function useGasData(device) {
  const { token, business } = useAuth();
  const [state, setState] = useState({ data: null, config: null, error: null });

  const generation = useRef(0);
  const load = useCallback(async () => {
    const request = ++generation.current;
    try {
      const resp = await api.post(
        '/gas/readings/',
        { business_id: business.business_uid, device_id: device.id, days: HISTORY_DAYS },
        token,
      );
      const data = liveData(resp);
      if (request !== generation.current) return;
      setState({ data, config: resp.config, error: null });
    } catch (e) {
      if (request !== generation.current) return;
      setState((previous) => ({ ...previous, error: e.message }));
    }
  }, [token, business, device.id, device.device_id]);

  useEffect(() => {
    setState({ data: null, config: null, error: null });
    load();
    const id = setInterval(() => {
      if (document.visibilityState === 'visible') load();
    }, REFRESH_MS);
    return () => { clearInterval(id); generation.current++; };
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
