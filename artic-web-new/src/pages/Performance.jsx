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

const iso = (d) => d.toISOString().slice(0, 10);
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
  const { devices } = useDevices();
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

  useEffect(() => {
    if (!deviceId || isGas) {
      // Gas cylinders render their own panel; drop any temperature error/data left over.
      setError(null);
      setData(null);
      setLoading(false);
      return;
    }
    const device = devices?.find((d) => String(d.id) === deviceId);
    if (!device) return;
    if (device.is_active === false) {
      setData(null);
      setError('This device is retired. Reactivate it in Device Management to collect telemetry again.');
      return;
    }
    setLoading(true);
    setError(null);
    setData(null);
    const end = new Date();
    const start = new Date(end.getTime() - days * 86400000);
    api
      .get(
        `/device-metrics/?device_id=${encodeURIComponent(device.device_id)}&start_date=${iso(start)}&end_date=${iso(end)}&company_id=${business.business_uid}`,
        token,
      )
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [deviceId, days, devices, token, business, isGas]);

  const series = useMemo(() => {
    const ta = data?.temperature_analytics;
    if (!ta?.labels) return null;
    return ta.labels.map((l, i) => ({
      label: l,
      avg: ta.avg_temperature?.[i] ?? null,
      min: ta.min_temperature?.[i] ?? null,
      max: ta.max_temperature?.[i] ?? null,
    }));
  }, [data]);

  const stats = useMemo(() => {
    if (!series) return null;
    const vals = series.flatMap((p) => [p.avg, p.min, p.max]).filter((v) => v != null);
    if (!vals.length) return null;
    return {
      min: Math.min(...vals),
      max: Math.max(...vals),
      avg: vals.reduce((a, v) => a + v, 0) / vals.length,
    };
  }, [series]);

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Telemetry</div>
          <h1 className="page-title">Device Performance</h1>
          <p className="page-sub">
            {isGas ? 'Gas level and burn behaviour over time.' : 'Temperature behaviour per device over time.'}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
          <select style={{ width: 230 }} value={deviceId} onChange={(e) => setDeviceId(e.target.value)}>
            {(devices ?? []).map((d) => (
              <option key={d.id} value={String(d.id)}>
                {d.name} ({d.device_id})
              </option>
            ))}
          </select>
          <div className="seg">
            {RANGES.map((r) => (
              <button key={r.days} className={r.days === days ? 'on' : ''} onClick={() => setDays(r.days)}>
                {r.label}
              </button>
            ))}
          </div>
        </div>
      </div>

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

      {!loading && series && !error && (
        <>
          {stats && (
            <div className="tiles">
              <div className="tile">
                <div className="eyebrow">Average temp</div>
                <div className="v">{stats.avg.toFixed(1)}<span className="unit">°C</span></div>
              </div>
              <div className="tile">
                <div className="eyebrow">Minimum</div>
                <div className="v" style={{ color: 'var(--series)' }}>{stats.min.toFixed(1)}<span className="unit">°C</span></div>
              </div>
              <div className="tile">
                <div className="eyebrow">Maximum</div>
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
                  {series[0]?.min != null && <Line type="monotone" dataKey="min" name="Min" stroke="#94A3B8" strokeWidth={1.5} dot={false} strokeDasharray="4 3" />}
                  <Line type="monotone" dataKey="avg" name="Avg" stroke="#3B82F6" strokeWidth={2} dot={false} activeDot={{ r: 4, strokeWidth: 0 }} />
                  {series[0]?.max != null && <Line type="monotone" dataKey="max" name="Max" stroke="#EA580C" strokeWidth={1.5} dot={false} strokeDasharray="4 3" />}
                </LineChart>
              </ResponsiveContainer>
            </div>
            <p className="ink2" style={{ fontSize: 12, marginTop: 8 }}>
              Hour-of-day averages across {fmtDay(new Date())} window · min/avg/max per hour
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
