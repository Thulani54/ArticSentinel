// Device Performance analytics for one device, laid out per device type the
// way the production (Flutter) screen does it: a monitor header with health,
// current readings, named trend charts and a statistics table. Every chart
// goes through TrendChart, so all device types look and align the same.

import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, deviceTypeLabel } from '../api';
import { useAuth } from '../auth';
import { Panel, Empty, Spinner } from './bits';
import { ComparisonBars, DetailedMetrics, KeyMetrics } from './DeviceOverview';
import { MonitorHeader, StatsTable, TrendChart, dailyTotals, seriesRows, spanDays } from './PerformanceCharts';
import { latestFields, displayReading } from '../lib/telemetry/dashboard';
import { readingCount, dateWindow, humanLabel } from '../lib/telemetry/details';
import { SERIES } from '../lib/palette';

const format = (v) => (v == null ? '—' : typeof v === 'boolean' ? (v ? 'On / Yes' : 'Off / No') : typeof v === 'number' ? v.toLocaleString(undefined, { maximumFractionDigits: 3 }) : String(v));
const f = (key, name) => ({ key, name });
const zoneName = (latest, n) => latest?.custom_labels?.[`zone_${n}`] || `Zone ${n}`;

function DataTable({ rows }) {
  if (!rows?.length) return null;
  const keys = [...new Set(rows.flatMap(Object.keys))];
  return <div className="table-wrap"><table><thead><tr>{keys.map((k) => <th key={k}>{humanLabel(k)}</th>)}</tr></thead><tbody>{rows.map((row, i) => <tr key={i}>{keys.map((k) => <td key={k}>{format(row[k])}</td>)}</tr>)}</tbody></table></div>;
}

// Chart over rows that already carry their x value in `axis`.
function Chart({ title, rows, fields, unit = '', axis = 'label', type = 'line', initialFields }) {
  return <TrendChart title={title} rows={rows} axis={axis} unit={unit} type={type}
    fields={fields.map((k) => (typeof k === 'string' ? f(k, humanLabel(k)) : k))}
    initialKeys={initialFields} />;
}

function StatTiles({ stats, skip = [] }) {
  const entries = Object.entries(stats || {}).filter(([k, v]) => !skip.includes(k) && (typeof v === 'number' || typeof v === 'string'));
  if (!entries.length) return null;
  return <div className="tiles">{entries.map(([k, v]) => <div className="tile" key={k}><div className="eyebrow">{humanLabel(k)}</div><div className="v stat-v">{format(v)}</div></div>)}</div>;
}

function EmptyPerformanceCharts({ type, dates }) {
  const numbered = (name, count) => Array.from({ length: count }, (_, i) => `${name} ${i + 1}`);
  const profiles = {
    device1: [['Temperature trends', '°C', ['Air', 'Coil', 'Drain']], ['Compressor current', 'A', ['Phase 1', 'Phase 2', 'Phase 3']]],
    device2: [['All zones temperature trends', '°C', numbered('Zone', 8)]],
    device3: [['Temperature trends', '°C', ['High side', 'Low side', 'Ice', 'Air']], ['Water level trends', '%', ['Water level']], ['Current draw', 'A', ['Current']], ['Harvest cycles', 'cycles', ['Harvests']]],
    device4: [['Compressor current', 'A', numbered('Compressor', 8)]],
    device5: [['Relay duty cycles', '%', numbered('Relay', 16)]],
    device6: [['Pressure trends', 'bar', numbered('Pressure sensor', 8)]],
    device7: [['Daily scan activity', 'scans', ['Scans', 'Verified']], ['Fridge temperature', '°C', ['Temperature']]],
  };
  return <div className="chart-pair">{(profiles[type] || [['Reading history', '', []]]).map(([title, unit, channels]) => <Panel key={title} title={title} eyebrow={unit ? `Unit: ${unit}` : 'Selected period'}>
    <div className="trend-legend">{channels.slice(0, 8).map((label, i) => <span className="trend-key" key={label}><i style={{ background: SERIES[i % SERIES.length] }} />{label}</span>)}</div>
    <div className="trend-empty" style={{ height: 260 }} role="img" aria-label={`${title}: no readings for ${dates.start} through ${dates.end}`}><strong>No readings in this period</strong><span>{dates.start} to {dates.end}. Waiting for recorded measurements.</span></div>
  </Panel>)}</div>;
}

// ---------------------------------------------------------- per-type layouts
function health(insights) {
  const h = insights?.device_health_score;
  if (h) return { score: h.overall_score, grade: h.health_grade, note: h.recommendation };
  if (typeof insights?.health_score === 'number') return { score: insights.health_score, note: insights.recommendations?.[0] };
  return null;
}

function IceMachine({ data, latest, count }) {
  const s = data.ice_machine_summary || {};
  const sensors = [f('hs_temp', 'High side'), f('ls_temp', 'Low side'), f('ice_temp', 'Ice'), f('air_temp', 'Air')];
  const hourlyHarvests = seriesRows(data.harvest_analytics, ['harvest_count']);
  const harvestDaily = spanDays(hourlyHarvests) > 2;
  const harvestRows = harvestDaily ? dailyTotals(hourlyHarvests, ['harvest_count']) : hourlyHarvests;
  return <>
    <MonitorHeader title="Ice machine monitor" subtitle={`${format(count)} readings · ${s.total_harvests ?? 0} harvests in this period`} health={health(data.real_time_insights)} />
    {latest && <><h3 className="section-title">Current readings</h3><KeyMetrics type="device3" latest={latest} /></>}
    <div className="chart-pair">
      <TrendChart title="Temperature trends" unit="°C" rows={seriesRows(data.temperature_analytics, sensors.map((x) => x.key))} fields={sensors} />
      <TrendChart title="Water level trends" unit="%" rows={seriesRows(data.water_analytics, ['water_level'])} fields={[f('water_level', 'Water level')]} />
      <TrendChart title="Harvest cycles" unit="cycles" type="bar" eyebrow={harvestDaily ? 'Harvests per day' : 'Harvests per hour'} rows={harvestRows} fields={[f('harvest_count', 'Harvests')]} />
      <TrendChart title="Current draw" unit="A" rows={seriesRows(data.amps_analytics, ['amps'])} fields={[f('amps', 'Current')]} />
    </div>
    <StatsTable rows={[
      { name: 'High side temperature', unit: '°C', color: SERIES[0], ...s.high_side_temp },
      { name: 'Low side temperature', unit: '°C', color: SERIES[1], ...s.low_side_temp },
      { name: 'Ice temperature', unit: '°C', color: SERIES[2], ...s.ice_temp },
      { name: 'Air temperature', unit: '°C', color: SERIES[3], ...s.air_temp },
      { name: 'Water level', unit: '%', ...s.water_level },
      { name: 'Current', unit: ' A', ...s.amps },
    ]} />
  </>;
}

function MultiZone({ data, latest, count }) {
  const zones = Array.from({ length: 8 }, (_, i) => f(`zone${i + 1}`, zoneName(latest, i + 1)));
  const summary = data.zone_summary?.zones || [];
  const avgBars = summary.map((z) => ({ name: zoneName(latest, z.zone), value: typeof z.avg === 'number' ? z.avg : null, color: SERIES[(z.zone - 1) % 8] }));
  return <>
    <MonitorHeader title="Multi-zone temperature monitor" subtitle={`Monitoring 8 temperature zones · ${format(count)} readings`} health={health(data.real_time_insights)} />
    {latest && <><h3 className="section-title">Current readings</h3><KeyMetrics type="device2" latest={latest} /></>}
    <TrendChart title="All zones temperature trends" unit="°C" height={300} rows={seriesRows(data.temperature_analytics, zones.map((z) => z.key))} fields={zones} />
    <Panel className="mt16" title="Zone temperature comparison" eyebrow="Average per zone over the period">
      <ComparisonBars items={avgBars} height={280} />
    </Panel>
    <div className="mt16">
      <TrendChart title="Coldest and warmest zone" eyebrow="Lowest and highest zone reading per hour" unit="°C"
        rows={seriesRows(data.temperature_analytics, ['min_temperature', 'max_temperature'])}
        fields={[f('min_temperature', 'Coldest zone'), f('max_temperature', 'Warmest zone')]} />
    </div>
    <StatsTable title="Zone statistics" rows={summary.map((z) => ({ name: zoneName(latest, z.zone), unit: '°C', color: SERIES[(z.zone - 1) % 8], min: z.min, avg: z.avg, max: z.max, minAt: z.min_time, maxAt: z.max_time }))} />
  </>;
}

function Refrigeration({ data, latest, count }) {
  const t = data.enhanced_temperature_analytics || {};
  const p = data.enhanced_pressure_analytics || {};
  const temps = [f('avg_air_temperature', 'Air'), f('avg_coil_temperature', 'Coil'), f('avg_drain_temperature', 'Drain')];
  const phases = [f('avg_amp_ph1', 'Phase 1'), f('avg_amp_ph2', 'Phase 2'), f('avg_amp_ph3', 'Phase 3')];
  return <>
    <MonitorHeader title="Refrigeration monitor" subtitle={`${format(count)} readings in this period`} health={health(data.real_time_insights)} />
    {latest && <><h3 className="section-title">Current readings</h3><KeyMetrics type="device1" latest={latest} /></>}
    <div className="chart-pair">
      <TrendChart title="Temperature trends" eyebrow="Average by hour of day · °C" unit="°C" rows={seriesRows(data.temperature_analytics, temps.map((x) => x.key))} fields={temps} />
      <TrendChart title="Compressor current" eyebrow="Average by hour of day · A" unit="A" rows={seriesRows(data.compressor_analytics, phases.map((x) => x.key))} fields={phases} />
      <TrendChart title="Pressure" eyebrow="Average by hour of day · psi" unit="psi" rows={seriesRows(data.pressure_analytics, ['avg_pressure_low', 'avg_pressure_high'])} fields={[f('avg_pressure_low', 'Low side'), f('avg_pressure_high', 'High side')]} />
      <TrendChart title="Door openings" unit="readings" type="bar" eyebrow="Readings with the door open" rows={seriesRows(data.door_analytics, ['door_open_count'])} fields={[f('door_open_count', 'Door open readings')]} />
      <TrendChart title="Compressor duty cycle" unit="%" rows={seriesRows(data.energy_efficiency_analytics, ['compressor_duty_cycle'])} fields={[f('compressor_duty_cycle', 'Duty cycle')]} />
      <TrendChart title="Phase imbalance" unit="%" rows={seriesRows(data.phase_balance_analytics, ['phase_imbalance_percentage'])} fields={[f('phase_imbalance_percentage', 'Imbalance')]} />
    </div>
    <StatsTable rows={[
      { name: 'Air temperature', unit: '°C', color: SERIES[0], min: t.min_air_temperature, avg: t.avg_air_temperature, max: t.max_air_temperature, minAt: t.min_air_temp_timestamp, maxAt: t.max_air_temp_timestamp },
      { name: 'Coil temperature', unit: '°C', color: SERIES[1], min: t.min_coil_temperature, avg: t.avg_coil_temperature, max: t.max_coil_temperature, minAt: t.min_coil_temp_timestamp, maxAt: t.max_coil_temp_timestamp },
      { name: 'Drain temperature', unit: '°C', color: SERIES[2], min: t.min_drain_temperature, avg: t.avg_drain_temperature, max: t.max_drain_temperature, minAt: t.min_drain_temp_timestamp, maxAt: t.max_drain_temp_timestamp },
      { name: 'Low-side pressure', unit: ' psi', min: p.min_pressure_low, avg: p.avg_pressure_low, max: p.max_pressure_low, minAt: p.min_pressure_low_timestamp, maxAt: p.max_pressure_low_timestamp },
      { name: 'High-side pressure', unit: ' psi', min: p.min_pressure_high, avg: p.avg_pressure_high, max: p.max_pressure_high, minAt: p.min_pressure_high_timestamp, maxAt: p.max_pressure_high_timestamp },
    ]} />
  </>;
}

// Compressor, relay and pressure monitors report overall statistics plus
// daily rows.
function StatisticsMonitor({ data, type, count }) {
  const daily = data.daily_data || [];
  const groups = type === 'device4'
    ? [['Daily compressor current', Array.from({ length: 8 }, (_, i) => f(`compressor${i + 1}_avg`, `Compressor ${i + 1}`)), 'A'],
       ['Daily compressor power', Array.from({ length: 8 }, (_, i) => f(`compressor${i + 1}_power_kw`, `Compressor ${i + 1}`)), 'kW']]
    : type === 'device5'
      ? [['Relay duty cycles · 1–8', Array.from({ length: 8 }, (_, i) => f(`relay${i + 1}_duty_cycle`, `Relay ${i + 1}`)), '%'],
         ['Relay duty cycles · 9–16', Array.from({ length: 8 }, (_, i) => f(`relay${i + 9}_duty_cycle`, `Relay ${i + 9}`)), '%']]
      : [['Daily pressure trends', Array.from({ length: 8 }, (_, i) => f(`sensor${i + 1}`, `Sensor ${i + 1}`)), 'bar']];
  return <>
    <MonitorHeader title={data.device_type_name || deviceTypeLabel(type)} subtitle={`${format(count)} readings in this period`} health={null} />
    <StatTiles stats={data.overall_statistics} skip={['total_readings']} />
    <div className="chart-pair">
      {groups.map(([title, fields, unit]) => <TrendChart key={title} title={title} unit={unit} rows={daily} axis="date" fields={fields} />)}
      {type === 'device5' && <TrendChart title="Hourly relay activity" unit="%" rows={data.hourly_relay_distribution || []} axis="hour"
        fields={Array.from({ length: 8 }, (_, i) => f(`relay${i + 1}_on_pct`, `Relay ${i + 1}`))} />}
    </div>
  </>;
}

function BottleAnalytics({ data, count }) {
  const stats = data.overall_statistics || {};
  const trays = Object.entries(stats.tray_weights || {}).map(([tray, values]) => ({ tray: humanLabel(tray), ...values }));
  return <>
    <MonitorHeader title="Bottle vetting monitor" subtitle={`${format(count)} readings in this period`} health={null} />
    <div className="tiles">{[['scans_in', 'Bottles scanned in'], ['scans_out', 'Bottles scanned out'], ['active_scans', 'Net scans in period'], ['total_bottles', 'Unique bottle codes'], ['verification_rate', 'Verification rate (%)'], ['total_scans', 'Total scans']].map(([key, label]) => <div className="tile" key={key}><div className="eyebrow">{label}</div><div className="v stat-v">{format(stats[key])}</div></div>)}</div>
    <p className="hint">Net scans are scans in minus scans out within this period, floored at zero.</p>
    <div className="chart-pair">
      <Chart title="Daily scan activity" rows={data.daily_data || []} axis="date" fields={[f('scans', 'Scans'), f('verified', 'Verified')]} unit="scans" type="bar" />
      <Chart title="Hourly scan activity" rows={data.hourly_activity || []} axis="hour" fields={[f('scans', 'Scans'), f('verified', 'Verified')]} unit="scans" type="bar" />
      <Chart title="Daily bottle movement" rows={data.daily_data || []} axis="date" fields={[f('scans_in', 'In'), f('scans_out', 'Out'), f('active', 'Net')]} unit="scans" type="bar" />
      <Chart title="Fridge temperature" rows={data.daily_data || []} axis="date" fields={[f('avg_temp', 'Average')]} unit="°C" />
      <Chart title="Average tray weights" rows={trays} axis="tray" fields={[f('avg', 'Average'), f('min', 'Minimum'), f('max', 'Maximum')]} unit="kg" type="bar" />
      <Chart title="Total weight history" rows={data.daily_data || []} axis="date" fields={[f('avg_total_weight', 'Total weight')]} unit="kg" />
    </div>
    {trays.length > 0 && <Panel title="Tray weights" eyebrow="kg · selected period"><DataTable rows={trays} /></Panel>}
  </>;
}

function Analytics({ data, type, latest, count }) {
  if (type === 'device3') return <IceMachine data={data} latest={latest} count={count} />;
  if (type === 'device2') return <MultiZone data={data} latest={latest} count={count} />;
  if (type === 'device1') return <Refrigeration data={data} latest={latest} count={count} />;
  if (type === 'device7') return <BottleAnalytics data={data} count={count} />;
  return <StatisticsMonitor data={data} type={type} count={count} />;
}

const PRESETS = [[1, 'Today'], [7, '7 days'], [30, '30 days'], [90, '90 days']];

export default function DetailedPerformance({ device }) {
  const { token, business } = useAuth();
  const [preset, setPreset] = useState(7);
  const [dates, setDates] = useState(() => dateWindow(7));
  const [draft, setDraft] = useState(dates);
  const [data, setData] = useState(null);
  const [latest, setLatest] = useState(null);
  const [latestError, setLatestError] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [revision, setRevision] = useState(0);

  // Latest reading with today's extremes (same source as the dashboard).
  useEffect(() => {
    let live = true;
    api.latestDeviceData(business.business_uid, token)
      .then((rows) => { if (live) setLatest((rows || []).find((d) => d.device_id === device.device_id) || {}); })
      .catch((e) => { if (live) setLatestError(e.message); });
    return () => { live = false; };
  }, [device.device_id, business.business_uid, token, revision]);

  useEffect(() => {
    let live = true;
    setLoading(true); setError(''); setData(null);
    const params = new URLSearchParams({
      device_id: device.device_id,
      company_id: business.business_uid,
      start_date: new Date(`${dates.start}T00:00:00`).toISOString(),
      end_date: new Date(`${dates.end}T23:59:59.999`).toISOString(),
    });
    api.get(`/device-metrics/?${params}`, token)
      .then((result) => { if (live) setData(result); })
      .catch((e) => { if (live) setError(e.message); })
      .finally(() => { if (live) setLoading(false); });
    return () => { live = false; };
  }, [device.device_id, business.business_uid, token, dates, revision]);

  const choose = (days) => { const next = dateWindow(days); setPreset(days); setDates(next); setDraft(next); };
  const applyCustom = (next) => { setPreset(null); setDates(next); setDraft(next); };
  const count = readingCount(data);
  const fields = latestFields(device.device_type);
  const hasLatest = latest && Object.keys(latest).length > 0;

  return <section className="performance-details">
    <div className="telemetry-heading"><div><h2>{device.name}</h2><p>{deviceTypeLabel(device.device_type)} · {device.is_online ? 'Online' : 'Offline'} · {device.device_id}</p></div><div className="heading-actions"><button type="button" className="btn sm" disabled={!latest?.time} onClick={() => applyCustom(dateWindow(7, new Date(latest.time)))}>Last reporting period</button><button type="button" className="btn sm" onClick={() => setRevision((n) => n + 1)}>Refresh</button><Link className="btn sm" to={`/devices/${device.id}`}>Equipment details</Link></div></div>

    <form className="filter-card" onSubmit={(e) => { e.preventDefault(); if (draft.start && draft.end && draft.start <= draft.end) applyCustom({ ...draft }); }}>
      <div className="filter-group">
        <span className="filter-label">Period</span>
        <div className="seg">{PRESETS.map(([days, label]) => <button type="button" key={days} className={preset === days ? 'on' : ''} aria-pressed={preset === days} onClick={() => choose(days)}>{label}</button>)}</div>
      </div>
      <label className="filter-group"><span className="filter-label">From</span><input aria-label="Analytics start date" type="date" required value={draft.start} max={draft.end} onChange={(e) => setDraft({ ...draft, start: e.target.value })} /></label>
      <label className="filter-group"><span className="filter-label">To</span><input aria-label="Analytics end date" type="date" required value={draft.end} min={draft.start} onChange={(e) => setDraft({ ...draft, end: e.target.value })} /></label>
      <button className="btn primary" type="submit">Apply dates</button>
    </form>
    <p className="hint">Showing {dates.start} to {dates.end}. Times on the charts are in the service's reporting timezone.</p>

    {latestError && <div className="form-err">Latest readings could not load: {latestError}</div>}
    {hasLatest && ['device4', 'device5', 'device7'].includes(device.device_type) && <><h3 className="section-title">Current readings{latest.time ? ` · last reported ${new Date(latest.time).toLocaleString()}` : ''}</h3><KeyMetrics type={device.device_type} latest={latest} /><div className="mt16"><DetailedMetrics type={device.device_type} latest={latest} /></div></>}
    {hasLatest && !['device1', 'device2', 'device3', 'device4', 'device5', 'device7'].includes(device.device_type) && fields.length > 0 && <Panel title="Latest device readings" eyebrow={latest.time ? `Last reported ${new Date(latest.time).toLocaleString()}` : 'No stored latest reading'}><div className="readouts">{fields.map(([key, label, unit]) => <div className="readout" key={key}><div className="eyebrow">{label}</div><div className="v">{displayReading(latest[key], unit)}</div></div>)}</div></Panel>}

    {loading ? <Spinner /> : error ? <div role="alert" className="form-err">Analytics could not load: {error}. Use Refresh to retry.</div>
      : data && count === 0 ? <><Panel title="No readings in this period"><Empty>{latest?.time ? 'Choose Last reporting period to see the most recent stored history.' : 'No stored readings for these dates. Try an earlier range.'}</Empty></Panel><EmptyPerformanceCharts type={device.device_type} dates={dates} /></>
      : data && <Analytics key={`${device.device_id}-${dates.start}-${dates.end}-${revision}`} data={data} type={device.device_type} latest={hasLatest ? latest : null} count={count} />}
  </section>;
}
