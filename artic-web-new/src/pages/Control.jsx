// Control — relay status, manual toggle and switch history per device
// (generic relay path from lib/screens/control.dart). The toggle actuates
// real equipment, so it asks for confirmation first.

import { useCallback, useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { Empty, Panel, Spinner } from '../components/bits';

export default function Control() {
  const { token, business } = useAuth();
  const { devices } = useDevices();
  const [deviceId, setDeviceId] = useState('');
  const [status, setStatus] = useState(null); // relay_status payload
  const [history, setHistory] = useState(null);
  const [error, setError] = useState(null);
  const [toggling, setToggling] = useState(false);

  useEffect(() => {
    if (devices && !deviceId && devices.length) setDeviceId(String(devices[0].id));
  }, [devices, deviceId]);

  const load = useCallback(async () => {
    if (!deviceId) return;
    setError(null);
    setStatus(null);
    setHistory(null);
    try {
      const [s, h] = await Promise.all([
        api.post('/devices/relay-status/', { business_id: business.business_uid, device_id: Number(deviceId) }, token),
        api.post(
          '/devices/relay-history/',
          { business_id: business.business_uid, device_id: Number(deviceId), limit: 20 },
          token,
        ),
      ]);
      setStatus(s.relay_status ?? null);
      setHistory(h.history ?? h.events ?? []);
    } catch (e) {
      setError(e.message);
    }
  }, [token, business, deviceId]);

  useEffect(() => {
    load();
  }, [load]);

  async function toggle() {
    const next = status ? !status.current_status : true;
    const what = next ? 'switch ON' : 'switch OFF';
    if (!window.confirm(`Really ${what} the relay for "${status?.device_name ?? 'this device'}"? This actuates real equipment.`)) {
      return;
    }
    setToggling(true);
    try {
      await api.post(
        '/devices/toggle-relay/',
        { business_id: business.business_uid, device_id: Number(deviceId), relay_status: next },
        token,
      );
      await load();
    } catch (e) {
      window.alert(`Toggle failed: ${e.message}`);
    } finally {
      setToggling(false);
    }
  }

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Equipment</div>
          <h1 className="page-title">Control</h1>
          <p className="page-sub">Relay state and manual switching for connected equipment.</p>
        </div>
        <select style={{ width: 250 }} value={deviceId} onChange={(e) => setDeviceId(e.target.value)}>
          {(devices ?? []).map((d) => (
            <option key={d.id} value={String(d.id)}>{d.name} ({d.device_id})</option>
          ))}
        </select>
      </div>

      {error && (
        <div className="panel">
          <Empty>Relay control isn&apos;t available for this device — {error}</Empty>
        </div>
      )}
      {!status && !error && <Spinner />}

      {status && (
        <div className="gas-grid">
          <Panel eyebrow="Relay" title="Current state">
            <div style={{ textAlign: 'center', padding: '18px 0' }}>
              <div
                className={`chip ${status.current_status ? 'good' : 'crit'}`}
                style={{ fontSize: 15, padding: '10px 20px' }}
              >
                <span className="dot" />
                {status.current_status ? 'ON — powered' : 'OFF — cut off'}
              </div>
              <div className="mt16">
                <button className="btn flame" onClick={toggle} disabled={toggling}>
                  {toggling ? 'Switching…' : status.current_status ? 'Switch OFF' : 'Switch ON'}
                </button>
              </div>
              <p className="ink2" style={{ fontSize: 12, marginTop: 12 }}>
                Asks for confirmation — this actuates real equipment.
              </p>
            </div>
          </Panel>

          <Panel eyebrow="Details" title="Switch info">
            <dl className="kv">
              <dt>Device</dt>
              <dd>{status.device_name ?? '—'}</dd>
              <dt>Last ON</dt>
              <dd>{status.last_on ? new Date(status.last_on).toLocaleString() : '—'}{status.last_on_by ? ` · ${status.last_on_by}` : ''}</dd>
              <dt>Last OFF</dt>
              <dd>{status.last_off ? new Date(status.last_off).toLocaleString() : '—'}{status.last_off_by ? ` · ${status.last_off_by}` : ''}</dd>
              <dt>Times off today</dt>
              <dd>{status.times_off_today ?? 0}</dd>
            </dl>
          </Panel>
        </div>
      )}

      {status && (
        <Panel className="mt16" title="Recent switch history">
          {!history && <Spinner />}
          {history && history.length === 0 && <Empty>No switch events recorded.</Empty>}
          {history && history.length > 0 && (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>When</th>
                    <th>Action</th>
                    <th>By</th>
                    <th>Source</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h, i) => (
                    <tr key={h.id ?? i}>
                      <td className="ink2">{h.timestamp || h.created_at ? new Date(h.timestamp ?? h.created_at).toLocaleString() : '—'}</td>
                      <td>
                        <span className={`chip ${(h.action ?? '').includes('off') ? 'crit' : 'good'}`}>
                          {(h.action ?? h.new_status ?? '').toString()}
                        </span>
                      </td>
                      <td className="ink2">{h.triggered_by_name ?? h.triggered_by ?? '—'}</td>
                      <td className="ink2">{h.source ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
      )}
    </>
  );
}
