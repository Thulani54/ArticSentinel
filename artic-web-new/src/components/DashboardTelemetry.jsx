import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { CartesianGrid, Line, LineChart, Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Legend } from 'recharts';
import { api } from '../api';
import { useAuth } from '../auth';
import { Panel, Empty, Spinner } from './bits';
import { chartSeries, temperatureSeries } from '../lib/telemetry/dashboard';
import { isGasCylinderType } from '../lib/gas/gasCore';
const COLORS = ['#176bba', '#bf521b', '#158367', '#7954a1', '#a77917', '#278791', '#a24873', '#667888'];

export default function DashboardTelemetry({ devices }) {
  const { token, business } = useAuth();
  const [selection, setSelection] = useState('');
  const [range, setRange] = useState('today');
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [revision, setRevision] = useState(0);
  const candidates = useMemo(() => devices.filter(d => !isGasCylinderType(d.device_type)), [devices]);
  const selected = candidates.find(d => d.device_id === selection) || candidates.find(d => d.is_online) || candidates[0];
  useEffect(() => {
    if (!business?.business_uid || !selected) return;
    let cancelled = false;
    setData(null); setError(null);
    api.dashboard(business.business_uid, selected.device_id, token)
      .then(result => { if (!cancelled) setData(result); })
      .catch(err => { if (!cancelled) setError(err.message); });
    return () => { cancelled = true; };
  }, [business?.business_uid, selected?.device_id, token, revision]);
  const rows = useMemo(() => chartSeries(data, selected?.device_id, range), [data, selected?.device_id, range]);
  const sensors = useMemo(() => temperatureSeries(rows), [rows]);
  const readings = rows.reduce((sum, row) => sum + (row.total_readings ?? 0), 0);
  const tick = value => new Date(value).toLocaleString(undefined, range === 'today' ? { hour: '2-digit', minute: '2-digit' } : { day: 'numeric', month: 'short' });
  const current = data?.current_data?.find(row => row.device_id === selected?.device_id);
  if (!selected) return null;
  return <section className="telemetry-section" aria-label="Equipment telemetry">
    <div className="telemetry-heading"><div><h2>Inside your operation</h2><p>Temperature and reporting activity from your connected equipment.</p></div><Link className="btn sm" to="/performance">Detailed performance</Link></div>
    <div className="telemetry-controls"><label className="device-select">Equipment<select aria-label="Chart equipment" value={selected.device_id} onChange={event => setSelection(event.target.value)}>{candidates.map(d => <option key={d.id} value={d.device_id}>{d.name}{d.is_online ? ' · Online' : ' · Offline'}</option>)}</select></label><div className="seg" aria-label="Chart time range">{[['today', 'Today'], ['week', '7 days']].map(([value, label]) => <button key={value} aria-pressed={range === value} className={range === value ? 'on' : ''} onClick={() => setRange(value)}>{label}</button>)}</div><button className="btn sm" onClick={() => setRevision(v => v + 1)}>Refresh graphs</button></div>
    {error ? <div className="form-err" role="alert">Graphs could not load: {error}. Use Refresh graphs to try again.</div> : !data ? <Spinner /> : <>
      <div className="chart-pair">
        <Panel title="Temperature trends" eyebrow={range === 'today' ? 'Hourly averages · today' : 'Daily averages · last 7 days'} actions={<span className="chart-unit">°C</span>}>
          {sensors.length ? <div className="chart-box telemetry-chart" role="img" aria-label={`Temperature history for ${selected.name}, ${rows.length} time buckets`}><ResponsiveContainer width="100%" height="100%"><LineChart data={rows} margin={{ top: 12, right: 10, left: -15, bottom: 0 }} accessibilityLayer><CartesianGrid vertical={false} stroke="#e4edf2" strokeDasharray="3 4"/><XAxis dataKey="at" tickFormatter={tick} tick={{fontSize:10}} minTickGap={28} axisLine={false} tickLine={false}/><YAxis tick={{fontSize:10}} axisLine={false} tickLine={false} domain={['auto', 'auto']}/><Tooltip labelFormatter={tick} formatter={(value, name)=>[`${Number(value).toFixed(1)} °C`, name]} contentStyle={{borderRadius:10, borderColor:'#dce6ec', fontSize:12}}/><Legend wrapperStyle={{fontSize:11}}/>{sensors.map(([key, label], index)=><Line key={key} dataKey={key} name={label} stroke={COLORS[index % COLORS.length]} strokeWidth={2} dot={rows.length < 3} activeDot={{r:4}} connectNulls={false}/>)}</LineChart></ResponsiveContainer></div> : <Empty>No temperature readings for this equipment in this period. Choose another device or time range.</Empty>}
        </Panel>
        <Panel title="Reporting activity" eyebrow={`${readings.toLocaleString()} readings in this period`} actions={<span className="chart-unit">Readings</span>}>
          {rows.some(row => row.total_readings != null) ? <div className="chart-box telemetry-chart" role="img" aria-label={`Reading counts for ${selected.name}`}><ResponsiveContainer width="100%" height="100%"><BarChart data={rows} margin={{top:12,right:10,left:-15,bottom:0}} accessibilityLayer><CartesianGrid vertical={false} stroke="#e4edf2" strokeDasharray="3 4"/><XAxis dataKey="at" tickFormatter={tick} tick={{fontSize:10}} minTickGap={28} axisLine={false} tickLine={false}/><YAxis allowDecimals={false} tick={{fontSize:10}} axisLine={false} tickLine={false}/><Tooltip labelFormatter={tick} contentStyle={{borderRadius:10,borderColor:'#dce6ec',fontSize:12}}/><Bar dataKey="total_readings" name="Readings" fill="#729db8" radius={[4,4,0,0]} maxBarSize={24}/></BarChart></ResponsiveContainer></div> : <Empty>No reporting activity in this period. Try the 7-day view for historical readings.</Empty>}
        </Panel>
      </div>
      <div className="telemetry-note"><span>{selected.name} · {selected.is_online ? 'Online' : 'Offline'}{current?.time ? ` · Last reading ${new Date(current.time).toLocaleString()}` : ''}</span><span>Times shown in your local timezone</span></div>
      {rows.length > 0 && <details className="telemetry-data"><summary>View chart data</summary><div className="table-wrap"><table><thead><tr><th>Time</th>{sensors.map(([key,label])=><th key={key}>{label} °C</th>)}<th>Readings</th></tr></thead><tbody>{rows.map((row,index)=><tr key={`${row.at}-${index}`}><td>{tick(row.at)}</td>{sensors.map(([key])=><td key={key}>{row[key] ?? '—'}</td>)}<td>{row.total_readings ?? '—'}</td></tr>)}</tbody></table></div></details>}
    </>}
  </section>;
}
