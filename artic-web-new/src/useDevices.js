// Shared device-list fetch with refresh, used by Dashboard and Devices.

import { useCallback, useEffect, useState } from 'react';
import { api } from './api';
import { useAuth } from './auth';

export function useDevices() {
  const { token, business } = useAuth();
  const [devices, setDevices] = useState(null); // null = loading
  const [error, setError] = useState(null);

  const refresh = useCallback(async () => {
    setError(null);
    try {
      setDevices(await api.devicesList(business.business_uid, token));
    } catch (e) {
      setError(e.message);
    }
  }, [token, business]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return { devices, error, refresh };
}
