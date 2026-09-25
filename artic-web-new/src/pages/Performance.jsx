import { performanceSeries, metricsQuery } from '../lib/telemetry/performance';
import DashboardTelemetry from '../components/DashboardTelemetry';
// Device Performance — temperature analytics from the backend's
// device-metrics endpoint (same data source as lib/screens/
// device_perfomance_tracking.dart). Gas cylinders have no temperature
// telemetry; they get their level/burn series from the gas engine instead.

import { useEffect, useMemo, useState } from 'react';
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  Legend,
} from 'recharts';
import { api } from '../api';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { Empty, Panel, Spinner, fmtDay } from '../components/bits';
import {
  dailySeries,
  daysRemaining,
  isGasCylinderType,
  kg1,
  levelPercent,
  money,
  trailingBurnPerDay,
} from '../lib/gas/gasCore';
import { useGasData } from '../lib/gas/useGasData';

const RANGES = [
  { days: 1, label: '24h' },
  { days: 7, label: '7d' },
  { days: 30, label: '30d' },
];

const inkTooltip = {
  contentStyle: {
    background: '#1E293B', border: 'none', borderRadius: 8,
    color: '#F8FAFC', fontSize: 12, padding: '8px 11px',
  },
  itemStyle: { color: '#F8FAFC' },
  labelStyle: { color: '#94A3B8', fontWeight: 600, marginBottom: 3 },
};

export default function Performance() {
  const { token, business } = useAuth();
  const { devices, error: devicesError } = useDevices();
  const [deviceId, setDeviceId] = useState('');
  const [days, setDays] = useState(7);
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (devices && !deviceId && devices.length) setDeviceId(String(devices[0].id));
  }, [devices, deviceId]);

  const device = useMemo(
    () => devices?.find((d) => String(d.id) === deviceId) ?? null,
    [devices, deviceId],
  );
  const isGas = device ? isGasCylinderType(device.device_type) : false;
  const specialized = device?.is_active === false || ['device4', 'device5', 'device6', 'device7'].includes(device?.device_type);

  useEffect(() => {
    if (!deviceId || isGas || specialized) {
      // Gas cylinders render their own panel; drop any temperature error/data left over.
      setError(null);
      setData(null);
      setLoading(false);
      return;
    }
    const device = devices?.find((d) => String(d.id) === deviceId);
    if (!device) return;
    setLoading(true);
    setError(null);
    setData(null);
    let cancelled = false;
    api
      .get(
        metricsQuery(device.device_id, business.business_uid, days),
        token,
      )
      .then(result => { if (!cancelled) setData(result); })
      .catch(e => { if (!cancelled) setError(e.message); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [deviceId, days, devices, token, business, isGas, specialized]);

  const { rows: series, fields } = useMemo(() => performanceSeries(data, device?.device_type), [data, device?.device_type]);
  const stats = useMemo(() => {
    const vals = series.flatMap(row => fields.map(([key]) => row[key])).filter(value => value != null);
    return vals.length ? { min: Math.min(...vals), max: Math.max(...vals), avg: vals.reduce((a,b) => a+b,0)/vals.length } : null;
  }, [series, fields]);

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Telemetry</div>
          <h1 className="page-title">Device Performance</h1>
          <p className="page-sub">
            {specialized ? 'Device-specific readings and reporting activity.' : isGas ? 'Gas level and burn behaviour over time.' : 'Temperature behaviour per device over time.'}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
          <select aria-label="Performance equipment" style={{ width: 230 }} value={deviceId} onChange={(e) => setDeviceId(e.target.value)}>
            {(devices ?? []).map((d) => (
              <option key={d.id} value={String(d.id)}>
                {d.name} ({d.device_id})
              </option>
            ))}
          </select>
          {!specialized && <div className="seg">
            {RANGES.map((r) => (
              <button key={r.days} className={r.days === days ? 'on' : ''} onClick={() => setDays(r.days)}>
                {r.label}
              </button>
            ))}
          </div>}
        </div>
      </div>

      {devicesError && <div className="form-err" role="alert">{devicesError}</div>}
      {!devices && !devicesError && <Spinner />}
      {devices?.length === 0 && <Empty>No equipment is registered in this workspace.</Empty>}
      {device?.is_active === false && <div className="banner warn">This device is inactive. Available historical readings are shown below; no device settings have been changed.</div>}
      {specialized && !isGas && device && <DashboardTelemetry devices={[device]} />}
      {isGas && device && <GasPerformance device={device} days={days} />}

      {error && (
        <div className="panel">
          <Empty>
            No telemetry available for this device in the selected window
            {error ? ` — ${error}` : ''}.
          </Empty>
        </div>
      )}
      {loading && <Spinner />}

      {!specialized && !isGas && !loading && data && !error && !stats && <Empty>No sensor readings in this period. Choose another time range or device.</Empty>}
      {!specialized && !isGas && !loading && stats && !error && (
        <>
          {stats && (
            <div className="tiles">
              <div className="tile">
                <div className="eyebrow">Sensor average</div>
                <div className="v">{stats.avg.toFixed(1)}<span className="unit">°C</span></div>
              </div>
              <div className="tile">
                <div className="eyebrow">Lowest sensor average</div>
                <div className="v" style={{ color: 'var(--series)' }}>{stats.min.toFixed(1)}<span className="unit">°C</span></div>
              </div>
              <div className="tile">
                <div className="eyebrow">Highest sensor average</div>
                <div className="v" style={{ color: 'var(--flame)' }}>{stats.max.toFixed(1)}<span className="unit">°C</span></div>
              </div>
              <div className="tile">
                <div className="eyebrow">Window</div>
                <div className="v" style={{ fontSize: 16, paddingTop: 8 }}>
                  last {days === 1 ? '24 hours' : `${days} days`}
                </div>
              </div>
            </div>
          )}

          <Panel title="Temperature profile" eyebrow="Hourly averages">
            <div className="chart-box" style={{ height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={series} margin={{ top: 6, right: 8, left: -12, bottom: 0 }}>
                  <CartesianGrid vertical={false} stroke="#E2E8F0" />
                  <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#94A3B8' }} tickLine={false} axisLine={{ stroke: '#E2E8F0' }} minTickGap={16} />
                  <YAxis tick={{ fontSize: 11, fill: '#94A3B8' }} tickLine={false} axisLine={false} width={44} tickFormatter={(v) => `${v}°`} />
                  <Tooltip {...inkTooltip} formatter={(v, name) => [`${Number(v).toFixed(1)} °C`, name]} />
                  <Legend wrapperStyle={{fontSize:11}} />
                  {fields.map(([key, name], index) => <Line key={key} type="monotone" dataKey={key} name={name} stroke={['#176bba','#bf521b','#158367','#7954a1','#a77917','#278791','#a24873','#667888'][index % 8]} strokeWidth={2} dot={series.length < 3} connectNulls={false} />)}
                </LineChart>
              </ResponsiveContainer>
            </div>
            <p className="ink2" style={{ fontSize: 12, marginTop: 8 }}>
              Sensor averages over the selected {days === 1 ? '24 hours' : `${days} days`}
            </p>
          </Panel>
        </>
      )}
    </>
  );
}

// Gas cylinders: level-over-time and burn from the scale readings (or the
// labelled demo series until the scale reports) — same source as the gas dashboard.
function GasPerformance({ device, days }) {
  const { data, config } = useGasData(device);

  const gas = useMemo(() => {
    if (!data) return null;
    const now = new Date();
    const start = new Date(now.getTime() - days * 86400000);
    const windowReadings = data.readings.filter((r) => r.at >= start);
    const levelOf = (r) => levelPercent(r.weightKg, data.spec.tareKg, data.spec.fullKg);
    const hhmm = (d) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

    const points = [];
    if (days === 1) {
      for (const r of windowReadings) points.push({ label: hhmm(r.at), level: levelOf(r) });
    } else {
      const byDay = new Map(); // readings ascend, so the last per day wins
      for (const r of windowReadings) byDay.set(r.at.toDateString(), r);
      for (const r of byDay.values()) {
        points.push({ label: `${r.at.getDate()}/${r.at.getMonth() + 1}`, level: levelOf(r) });
      }
    }

    const burn = trailingBurnPerDay(data.readings, 7, now);
    const { emptyBy } = daysRemaining(data.currentNetKg, burn, now);
    const usage = dailySeries(data.readings, data.pricePerKg).filter(
      (p) => p.day.getTime() >= new Date(start).setHours(0, 0, 0, 0),
    );
    return {
      points,
      level: data.currentLevelPct,
      net: data.currentNetKg,
      usedKg: usage.reduce((a, p) => a + p.kg, 0),
      usedCost: usage.reduce((a, p) => a + p.cost, 0),
      daysLeft: Number.isFinite(emptyBy?.getTime?.()) ? emptyBy : null,
    };
  }, [data, days]);

  if (!gas) return <Spinner />;
  const low = config?.low_threshold_pct ?? 20;
  const warning = config?.warning_threshold_pct ?? 50;

  return (
    <>
      <div style={{ marginBottom: 16 }}>
        {data.live ? (
          <span className="chip good">LIVE SCALE</span>
        ) : (
          <>
            <span className="chip demo">DEMO DATA</span>
            <span className="ink2" style={{ fontSize: 12, marginLeft: 8 }}>
              Simulated telemetry until the scale sends its first reading.
            </span>
          </>
        )}
      </div>
      <div className="tiles">
        <div className="tile">
          <div className="eyebrow">Current level</div>
          <div className="v" style={{ color: gas.level < low ? 'var(--crit)' : gas.level < warning ? 'var(--warn)' : 'var(--good)' }}>
            {Math.round(gas.level)}<span className="unit">%</span>
          </div>
        </div>
        <div className="tile">
          <div className="eyebrow">Net gas</div>
          <div className="v">{kg1(gas.net)}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">Usage ({days === 1 ? '24h' : `${days}d`})</div>
          <div className="v">{kg1(gas.usedKg)}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">Usage cost</div>
          <div className="v">{money(gas.usedCost)}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">Est. empty by</div>
          <div className="v" style={{ fontSize: 16, paddingTop: 8 }}>
            {gas.daysLeft ? fmtDay(gas.daysLeft) : '—'}
          </div>
        </div>
      </div>

      <Panel title="Gas level profile" eyebrow={days === 1 ? (data.live ? 'Every 5 minutes' : 'Readings every 3 hours') : 'End-of-day level'}>
        <div className="chart-box" style={{ height: 300 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={gas.points} margin={{ top: 6, right: 8, left: -12, bottom: 0 }}>
              <CartesianGrid vertical={false} stroke="#E2E8F0" />
              <XAxis dataKey="label" tick={{ fontSize: 11, fill: '#94A3B8' }} tickLine={false} axisLine={{ stroke: '#E2E8F0' }} minTickGap={16} />
              <YAxis domain={[0, 100]} tick={{ fontSize: 11, fill: '#94A3B8' }} tickLine={false} axisLine={false} width={44} tickFormatter={(v) => `${v}%`} />
              <Tooltip {...inkTooltip} formatter={(v) => [`${Number(v).toFixed(1)} %`, 'Gas level']} />
              <Line type="monotone" dataKey="level" name="Gas level" stroke="#EA580C" strokeWidth={2} dot={false} activeDot={{ r: 4, strokeWidth: 0 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </Panel>
    </>
  );
}
