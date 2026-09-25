// Landing dashboard: fleet stats + device grid. Gas devices carry the flame
// accent and route to the gas dashboard; everything else to the detail view.

import { Link } from 'react-router-dom';
import DashboardTelemetry from '../components/DashboardTelemetry';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { api, deviceTypeLabel } from '../api';
import { deriveGasAlerts, isGasCylinderType } from '../lib/gas/gasCore';
import { generateGasDemoData } from '../lib/gas/gasDemoData';
import { specFromConfig, thresholdsFromConfig } from '../lib/gas/useGasData';

// Alerts over the last 30 days for one cylinder: from its scale readings when
// it has reported, otherwise from the labelled demo series.
async function gasAlertsFor(device, businessId, token) {
  const cutoff = Date.now() - 30 * 86400000;
  try {
    const resp = await api.post('/gas/readings/', { business_id: businessId, device_id: device.id, days: 30 }, token);
    if (resp.readings.length > 0) {
      const spec = specFromConfig(resp.config);
      const readings = resp.readings.map((r) => ({ at: new Date(r.time), weightKg: r.net_kg + spec.tareKg }));
      return deriveGasAlerts(readings, spec, thresholdsFromConfig(resp.config)).filter((a) => a.at.getTime() > cutoff).length;
    }
  } catch {
    /* fall through to demo */
  }
  return generateGasDemoData(device.device_id).alerts.filter((a) => a.at.getTime() > cutoff).length;
}
import { Empty, PresenceChip, Spinner } from '../components/bits';

export default function Dashboard() {
  const { user, token, business } = useAuth();
  const { devices, error } = useDevices();
  const [gasAlerts, setGasAlerts] = useState(null);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('All devices');
  const visibleDevices = (devices || []).filter(d => {
    const matches = [d.name, d.device_id, d.location, d.building].filter(Boolean).join(' ').toLowerCase().includes(search.toLowerCase());
    return matches && (filter === 'All devices' || (filter === 'Online' && d.is_online) || (filter === 'Offline' && !d.is_online) || (filter === 'Gas' && isGasCylinderType(d.device_type)));
  });

  // Count gas alerts raised in the last 30 days across the fleet's gas devices.
  useEffect(() => {
    if (!devices) return;
    const gas = devices.filter((d) => isGasCylinderType(d.device_type));
    let cancelled = false;
    Promise.all(gas.map((d) => gasAlertsFor(d, business.business_uid, token))).then((counts) => {
      if (!cancelled) setGasAlerts(counts.reduce((a, n) => a + n, 0));
    });
    return () => {
      cancelled = true;
    };
  }, [devices, business, token]);

  const stats = useMemo(() => {
    if (!devices) return null;
    return {
      total: devices.length,
      online: devices.filter((d) => d.is_online).length,
      gasCount: devices.filter((d) => isGasCylinderType(d.device_type)).length,
    };
  }, [devices]);

  const firstName = (user?.firstname || user?.first_name || user?.username || '').split(/[\s@.]/)[0];

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Overview</div>
          <h1 className="page-title">{firstName ? `Welcome back, ${firstName}` : 'Dashboard'}</h1>
          <p className="page-sub">Your equipment, connections and gas supply in one place.</p>
        </div>
        <a href="#equipment-list" className="btn sm">View all equipment ({devices?.length ?? '…'})</a><div className="dashboard-date">{new Date().toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'long' })}</div>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!devices && !error && <Spinner />}

      {stats && (
        <>
          <section className="fleet-summary" aria-label="Fleet connectivity">
            <div><h2>Every connection counts.</h2><p>{stats.total === 0 ? 'Add your first device to start monitoring your operation.' : `${stats.online} of ${stats.total} devices are online. ${stats.total - stats.online ? 'Review offline equipment to restore visibility.' : 'All registered devices are connected.'}`}</p></div>
            <div className="fleet-meter"><div className="fleet-meter-label"><span>Fleet connectivity</span><strong>{stats.total ? `${Math.round(stats.online / stats.total * 100)}%` : 'No devices'}</strong></div><div className="fleet-track"><span style={{ width: `${stats.total ? stats.online / stats.total * 100 : 0}%` }} /></div></div>
          </section>
          <div className="tiles">
            <div className="tile">
              <div className="eyebrow">Devices</div>
              <div className="v">{stats.total}</div>
              <div className="s">across all types</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Online now</div>
              <div className="v" style={{ color: 'var(--good)' }}>
                {stats.online}
              </div>
              <div className="s">reporting telemetry</div>
            </div>
            <div className="tile accent-flame">
              <div className="eyebrow">Gas cylinders</div>
              <div className="v">{stats.gasCount}</div>
              <div className="s">monitored cylinders</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Gas alerts · 30d</div>
              <div className="v">{gasAlerts ?? '…'}</div>
              <div className="s">includes simulated data when no readings</div>
            </div>
          </div>

          <DashboardTelemetry devices={devices} />
          <div className="panel" id="equipment-list">
            <div className="panel-head">
              <h2 className="panel-title">Your equipment <span className="muted">({devices.length})</span></h2>
              <Link to="/devices" className="btn sm">
                Manage all
              </Link>
            </div>
            <div className="fleet-toolbar"><input className="search-field" type="search" aria-label="Search equipment" placeholder="Search equipment or location…" value={search} onChange={e => setSearch(e.target.value)} /><div className="seg" aria-label="Filter equipment">{['All devices', 'Online', 'Offline', 'Gas'].map(value => <button key={value} className={filter === value ? 'on' : ''} aria-pressed={filter === value} onClick={() => setFilter(value)}>{value}</button>)}</div></div>
            {devices.length === 0 ? (
              <Empty>No devices yet — add your first device from the Devices page.</Empty>
            ) : visibleDevices.length === 0 ? <Empty>No equipment matches this search. Try another name or status.</Empty> : (
              <div className="grid">
                {visibleDevices.map((d) => {
                  const gas = isGasCylinderType(d.device_type);
                  return (
                    <Link
                      key={d.id}
                      to={`/devices/${d.id}`}
                      className={`dev-card${gas ? ' gas' : ''}`}
                    >
                      <div className="row">
                        <span className={`chip ${gas ? 'gas-type' : 'type'}`}>
                          {gas ? 'Gas Cylinder' : deviceTypeLabel(d.device_type)}
                        </span>
                        <PresenceChip online={!!d.is_online} />
                      </div>
                      <div>
                        <div className="name">{d.name}</div>
                        <div className="loc">
                          {[d.location, d.building].filter(Boolean).join(' · ') || d.device_id}
                        </div>
                      </div>
                      <div className="row device-bottom" style={{ fontSize: 12, color: 'var(--muted)' }}>
                        <span>{d.device_id}</span>
                        <span>View →</span>
                      </div>
                    </Link>
                  );
                })}
              </div>
            )}
          </div>
        </>
      )}
    </>
  );
}
