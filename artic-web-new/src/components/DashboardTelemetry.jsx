import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { CartesianGrid, Line, LineChart, Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Legend } from 'recharts';
import { api, deviceTypeLabel } from '../api';
import GasDashboard from '../pages/GasDashboard';
import { useAuth } from '../auth';
import { Panel, Empty, Spinner } from './bits';
import { chartSeries, telemetryProfile, latestFields, displayReading } from '../lib/telemetry/dashboard';
import { isGasCylinderType } from '../lib/gas/gasCore';
import { SERIES as COLORS, tooltipStyle } from '../lib/palette';
import { DetailedMetrics, KeyMetrics, PerformanceOverview } from './DeviceOverview';
import DeviceBoard from './DeviceBoard';

const DETAILED_TYPES = new Set(['device1', 'device2', 'device3', 'device4', 'device5', 'device7']);

// Share of today's hours (so far) in which the device reported at least once.
// The API buckets hours by UTC day, so "today" is counted from UTC midnight.
function uptimeToday(data, deviceId, current) {
  if (typeof current?.uptimeToday === 'number') return current.uptimeToday;
  if (!data?.hourly_aggregates) return null;
  const now = new Date();
  const dayStart = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const hours = new Set(
    data.hourly_aggregates
      .filter((h) => h.device_id === deviceId && h.hour_bucket && new Date(h.hour_bucket).getTime() >= dayStart)
      .map((h) => new Date(h.hour_bucket).getUTCHours()),
  );
  return Math.min(100, (hours.size / (now.getUTCHours() + 1)) * 100);
}

export default function DashboardTelemetry({ devices, latestByDevice = {}, activeAlerts }) {
  const { token, business } = useAuth();
  const [selection, setSelection] = useState('');
  const [range, setRange] = useState('today');
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [revision, setRevision] = useState(0);
  const candidates = devices;
  const selected = candidates.find(d => d.device_id === selection) || candidates.find(d => d.is_online) || candidates[0];
  useEffect(() => {
    if (!business?.business_uid || !selected || isGasCylinderType(selected.device_type)) return;
    let cancelled = false;
    setData(null); setError(null);
    api.dashboard(business.business_uid, selected.device_id, token)
      .then(result => { if (!cancelled) setData({ ...result, requestedDeviceId: selected.device_id }); })
      .catch(err => { if (!cancelled) setError(err.message); });
    return () => { cancelled = true; };
  }, [business?.business_uid, selected?.device_id, token, revision]);
  const rows = useMemo(() => chartSeries(data, selected?.device_id, range), [data, selected?.device_id, range]);
  const profile = telemetryProfile(selected?.device_type, rows);
  const sensors = profile.fields.filter(([key]) => rows.some(row => row[key] != null));
  const gas = isGasCylinderType(selected?.device_type);
  const fields = latestFields(selected?.device_type);
  const readings = rows.reduce((sum, row) => sum + (row.total_readings ?? 0), 0);
  const tick = value => new Date(value).toLocaleString(undefined, range === 'today' ? { hour: '2-digit', minute: '2-digit' } : { day: 'numeric', month: 'short' });
  const current = data?.current_data?.find(row => row.device_id === selected?.device_id);
  const latest = latestByDevice[selected?.device_id] || current;
  const detailed = DETAILED_TYPES.has(selected?.device_type) && latest;
  if (!selected) return null;
  return <section className="telemetry-section" aria-label="Equipment telemetry">
    <div className="telemetry-heading"><div><h2>Inside your operation</h2><p>Readings and activity for every device type, including offline equipment.</p></div><Link className="btn sm" to={`/devices/${selected.id}`}>Equipment details</Link></div>
    <div className="telemetry-controls"><label className="device-select">Equipment<select aria-label="Chart equipment" value={selected.device_id} onChange={event => setSelection(event.target.value)}>{candidates.map(d => <option key={d.id} value={d.device_id}>{d.name} · {deviceTypeLabel(d.device_type)}{d.is_online ? ' · Online' : ' · Offline'}</option>)}</select></label>{!gas && <><div className="seg" aria-label="Chart time range">{[['today', 'Today'], ['week', '7 days']].map(([value, label]) => <button key={value} aria-pressed={range === value} className={range === value ? 'on' : ''} onClick={() => setRange(value)}>{label}</button>)}</div><button className="btn sm" onClick={() => setRevision(v => v + 1)}>Refresh graphs</button></>}</div>
    <DeviceBoard device={selected} latest={latest} />
    {gas ? <GasDashboard key={selected.id} device={selected} /> : error ? <div className="form-err" role="alert">Graphs could not load: {error}. Use Refresh graphs to try again.</div> : !data || data.requestedDeviceId !== selected.device_id ? <Spinner /> : <>
      <PerformanceOverview latest={latest} uptimePct={uptimeToday(data, selected.device_id, current)} activeAlerts={activeAlerts} />
      {detailed && <><KeyMetrics type={selected.device_type} latest={latest} /><h2 className="section-title">Detailed metrics · {deviceTypeLabel(selected.device_type)}</h2><DetailedMetrics type={selected.device_type} latest={latest} /><h2 className="section-title mt16">Trends</h2></>}
      {!detailed && fields.length > 0 && <Panel title="Latest device readings" eyebrow={current?.time ? `Last reported ${new Date(current.time).toLocaleString()}` : 'No readings received'}><div className="readouts">{fields.map(([key, label, unit]) => <div className="readout" key={key}><div className="eyebrow">{label}</div><div className="v">{displayReading(current?.[key], unit)}</div></div>)}</div><p className="hint">Last reported values may be historical when equipment is offline.</p></Panel>}
      <div className="chart-pair mt16">
        <Panel title={profile.title} eyebrow={range === 'today' ? 'Hourly averages · today' : 'Daily averages · last 7 days'} actions={<span className="chart-unit">{profile.unit}</span>}>
          {sensors.length ? <div className="chart-box telemetry-chart" role="img" aria-label={`${profile.title} for ${selected.name}, ${rows.length} time buckets`}><ResponsiveContainer width="100%" height="100%"><LineChart data={rows} margin={{ top: 12, right: 10, left: -15, bottom: 0 }} accessibilityLayer><CartesianGrid vertical={false} stroke="#e4edf2" strokeDasharray="3 4"/><XAxis dataKey="at" tickFormatter={tick} tick={{fontSize:10}} minTickGap={28} axisLine={false} tickLine={false}/><YAxis tick={{fontSize:10}} axisLine={false} tickLine={false} domain={['auto', 'auto']}/><Tooltip labelFormatter={tick} formatter={(value, name)=>[`${Number(value).toFixed(1)} ${profile.unit}`, name]} {...tooltipStyle}/><Legend wrapperStyle={{fontSize:11}}/>{sensors.map(([key, label], index)=><Line key={key} dataKey={key} name={label} stroke={COLORS[index % COLORS.length]} strokeWidth={2} dot={rows.length < 3} activeDot={{r:4}} connectNulls={false}/>)}</LineChart></ResponsiveContainer></div> : <Empty>No {profile.title.toLowerCase()} readings for this equipment in this period. Choose another device or time range.</Empty>}
        </Panel>
        <Panel title="Reporting activity" eyebrow={`${readings.toLocaleString()} readings in this period`} actions={<span className="chart-unit">Readings</span>}>
          {rows.some(row => row.total_readings != null) ? <div className="chart-box telemetry-chart" role="img" aria-label={`Reading counts for ${selected.name}`}><ResponsiveContainer width="100%" height="100%"><BarChart data={rows} margin={{top:12,right:10,left:-15,bottom:0}} accessibilityLayer><CartesianGrid vertical={false} stroke="#e4edf2" strokeDasharray="3 4"/><XAxis dataKey="at" tickFormatter={tick} tick={{fontSize:10}} minTickGap={28} axisLine={false} tickLine={false}/><YAxis allowDecimals={false} tick={{fontSize:10}} axisLine={false} tickLine={false}/><Tooltip labelFormatter={tick} {...tooltipStyle}/><Bar dataKey="total_readings" name="Readings" fill="#729db8" radius={[4,4,0,0]} maxBarSize={24}/></BarChart></ResponsiveContainer></div> : <Empty>No reporting activity in this period. Try the 7-day view for historical readings.</Empty>}
        </Panel>
      </div>
      <div className="telemetry-note"><span>{selected.name} · {selected.is_online ? 'Online' : 'Offline'}{current?.time ? ` · Last reading ${new Date(current.time).toLocaleString()}` : ''}</span><span>Times shown in your local timezone</span></div>
      {rows.length > 0 && <details className="telemetry-data"><summary>View chart data</summary><div className="table-wrap"><table><thead><tr><th>Time</th>{sensors.map(([key,label])=><th key={key}>{label} {profile.unit}</th>)}<th>Readings</th></tr></thead><tbody>{rows.map((row,index)=><tr key={`${row.at}-${index}`}><td>{tick(row.at)}</td>{sensors.map(([key])=><td key={key}>{row[key] ?? '—'}</td>)}<td>{row.total_readings ?? '—'}</td></tr>)}</tbody></table></div></details>}
    </>}
  </section>;
}
