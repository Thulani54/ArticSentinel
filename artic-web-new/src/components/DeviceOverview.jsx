// Per-device dashboard sections, following the production (Flutter) dashboard:
// System Performance Overview tiles, Key Metrics cards and a Detailed Metrics
// layout for each device type — reading tiles with today's min/max,
// comparison bars, zone tiles, and distribution / water-level donuts.
// Data: one row of api.latestDeviceData (latest reading + today's extremes).

import {
  Bar, BarChart, CartesianGrid, Cell, LabelList, Pie, PieChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis, ReferenceLine,
} from 'recharts';
import { Panel } from './bits';
import { INK, SERIES, STATUS, tooltipStyle } from '../lib/palette';

// ------------------------------------------------------------------ helpers
const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const deg = (v, d = 1) => (num(v) == null ? '—' : `${num(v).toFixed(d)}°C`);
const fixed = (v, unit = '', d = 1) => (num(v) == null ? '—' : `${num(v).toFixed(d)}${unit}`);
const hhmm = (iso) => (iso ? new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '');
const ago = (iso) => {
  if (!iso) return '—';
  const m = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (m < 1) return 'just now';
  if (m < 60) return `${m}m ago`;
  const h = Math.round(m / 60);
  return h < 48 ? `${h}h ago` : `${Math.round(h / 24)}d ago`;
};
const words = (s) => (s ? String(s).replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase()) : '—');
const label = (latest, key, fallback) => latest?.custom_labels?.[key] || fallback;

const STATUS_TONE = {
  running_normal: 'good',
  normal: 'good',
  temperature_alert: 'warning',
  warning: 'warning',
  maintenance_required: 'critical',
  critical: 'critical',
  offline: 'critical',
};

// ------------------------------------------------------------------- icons
const I = {
  gauge: <path d="M4 15a8 8 0 1 1 16 0M12 15l4-5" />,
  status: <><rect x="4" y="5" width="16" height="14" rx="3" /><path d="M8 12h2l1.5-3 2 6 1.5-3H16" /></>,
  clock: <><circle cx="12" cy="13" r="7" /><path d="M12 9v4l2.5 1.5M10 3h4" /></>,
  alert: <><path d="M12 4 3 19h18L12 4z" /><path d="M12 10v4M12 16.5v.5" /></>,
  therm: <><path d="M10 13.5V5a2 2 0 1 1 4 0v8.5a4 4 0 1 1-4 0z" /><path d="M12 10v6" /></>,
  snow: <path d="M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5 12 7l2.5-2.5M9.5 19.5 12 17l2.5 2.5" />,
  hot: <><path d="M10 13.5V5a2 2 0 1 1 4 0v8.5a4 4 0 1 1-4 0z" /><path d="M17.5 5.5 20 3M18 9h3" /></>,
  zones: <><path d="M4 20h16" /><path d="M5 20V10l4 3 4-6 3 4 3-2v11" /></>,
  gear: <><circle cx="12" cy="12" r="3" /><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M18.4 5.6l-2.1 2.1M7.7 16.3l-2.1 2.1" /></>,
  water: <path d="M3 9c2 0 2-1.5 4.5-1.5S9.5 9 12 9s2.5-1.5 4.5-1.5S19 9 21 9M3 14c2 0 2-1.5 4.5-1.5S9.5 14 12 14s2.5-1.5 4.5-1.5S19 14 21 14" />,
  bolt: <path d="M13 3 5 13.5h5.5L11 21l8-10.5h-5.5L13 3z" />,
  door: <><rect x="6" y="3" width="12" height="18" rx="1.5" /><circle cx="14.5" cy="12" r=".8" /></>,
  ice: <path d="M12 3 5 7v10l7 4 7-4V7l-7-4zM5 7l7 4 7-4M12 11v10" />,
  weight: <><path d="M6 8h12l2 12H4L6 8z" /><circle cx="12" cy="5" r="2" /></>,
  relay: <><rect x="3" y="8" width="18" height="8" rx="4" /><circle cx="16" cy="12" r="2.5" /></>,
};
function Icon({ name, size = 18 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {I[name]}
    </svg>
  );
}

// -------------------------------------------------- performance overview
export function PerformanceOverview({ latest, uptimePct, activeAlerts }) {
  const score = num(latest?.performanceScore);
  const status = latest?.systemStatus;
  const tone = STATUS_TONE[status] || 'neutral';
  const tiles = [
    { icon: 'gauge', value: score == null ? '—' : `${Math.round(score)}/100`, label: 'Performance score' },
    { icon: 'status', value: status ? words(status) : 'No data', label: 'System status', tone },
    { icon: 'clock', value: uptimePct == null ? '—' : `${uptimePct.toFixed(1)}%`, label: 'Uptime today' },
    { icon: 'alert', value: activeAlerts ?? '—', label: 'Active alerts', tone: activeAlerts > 0 ? 'warning' : undefined },
  ];
  return (
    <div className="perf-tiles">
      {tiles.map((t) => (
        <div className={`perf-tile${t.tone ? ` tone-${t.tone}` : ''}`} key={t.label}>
          <Icon name={t.icon} size={20} />
          <strong>{t.value}</strong>
          <span>{t.label}</span>
        </div>
      ))}
    </div>
  );
}

// ------------------------------------------------------------ key metrics
function MetricCard({ icon, tone, title, value, sub, note, noteTone }) {
  return (
    <div className="metric-card">
      <div className="metric-top">
        <span className={`metric-badge badge-${tone}`}><Icon name={icon} size={20} /></span>
        <div>
          <div className="metric-title">{title}</div>
          <div className="metric-value">{value}</div>
        </div>
      </div>
      <div className="metric-sub">{sub}</div>
      {note && <div className={`metric-note${noteTone ? ` note-${noteTone}` : ''}`}>{note}</div>}
    </div>
  );
}

function zoneTemps(latest) {
  return Array.from({ length: 8 }, (_, i) => ({
    n: i + 1,
    name: label(latest, `zone_${i + 1}`, `Zone ${i + 1}`),
    value: num(latest?.[`temp${i + 1}`]),
    min: num(latest?.[`temp${i + 1}_min`]),
    max: num(latest?.[`temp${i + 1}_max`]),
    minAt: latest?.[`temp${i + 1}_min_time`],
    maxAt: latest?.[`temp${i + 1}_max_time`],
  }));
}

export function KeyMetrics({ type, latest }) {
  if (!latest) return null;
  let cards = [];
  if (type === 'device2') {
    const zones = zoneTemps(latest).filter((z) => z.value != null);
    const min = zones.length ? zones.reduce((a, z) => (z.value < a.value ? z : a)) : null;
    const max = zones.length ? zones.reduce((a, z) => (z.value > a.value ? z : a)) : null;
    cards = [
      { icon: 'therm', tone: 'navy', title: 'Average temperature', value: deg(latest.avgTemp ?? latest.avgTemperature), sub: `Across ${zones.length} active zones` },
      { icon: 'snow', tone: 'blue', title: 'Min temperature', value: deg(min?.value), sub: 'Lowest zone reading', note: min ? min.name : null, noteTone: 'blue' },
      { icon: 'hot', tone: 'red', title: 'Max temperature', value: deg(max?.value), sub: 'Highest zone reading', note: max && max.value > 5 ? 'Above threshold' : max?.name, noteTone: max && max.value > 5 ? 'crit' : undefined },
      { icon: 'zones', tone: 'navy', title: 'Active zones', value: `${zones.length}/8`, sub: 'Temperature sensors online', note: zones.length === 8 ? 'All zones active' : `${8 - zones.length} not reporting` },
    ];
  } else if (type === 'device3') {
    cards = [
      { icon: 'ice', tone: 'red', title: 'Ice temperature', value: deg(latest.ice_temp), sub: 'Current ice bin temperature', note: num(latest.ice_temp) > 0 ? 'Check cooling' : 'Normal', noteTone: num(latest.ice_temp) > 0 ? 'crit' : undefined },
      { icon: 'therm', tone: 'navy', title: 'High side temp', value: deg(latest.hs_temp), sub: 'Compressor discharge' },
      { icon: 'snow', tone: 'blue', title: 'Low side temp', value: deg(latest.ls_temp), sub: 'Evaporator temperature' },
      { icon: 'gear', tone: 'navy', title: 'Harvest switch', value: latest.harvsw ? 'Active' : 'Inactive', sub: latest.harvsw ? 'Harvesting ice' : 'Ice forming', note: `${latest.harvest_count ?? 0} harvests today` },
      { icon: 'water', tone: 'amber', title: 'Water level', value: fixed(latest.wtrlvl, '%', 0), sub: 'Reservoir level' },
    ];
  } else if (type === 'device1') {
    cards = [
      { icon: 'therm', tone: 'navy', title: 'Air temperature', value: deg(latest.temperatureAir ?? latest.temperature), sub: 'Cabinet air' },
      { icon: 'snow', tone: 'blue', title: 'Coil temperature', value: deg(latest.temperatureCoil), sub: 'Evaporator coil' },
      { icon: 'water', tone: 'amber', title: 'Drain temperature', value: deg(latest.temperatureDrain), sub: 'Drain line' },
      { icon: 'bolt', tone: latest.comp ? 'green' : 'navy', title: 'Compressor', value: latest.compressorStatus || (latest.comp ? 'ON' : 'OFF'), sub: `Avg ${fixed(latest.avgCompAmp, ' A')}` },
      { icon: 'door', tone: latest.door ? 'red' : 'navy', title: 'Door', value: latest.door ? 'Open' : 'Closed', sub: latest.iceBuiltUp ? 'Ice build-up detected' : 'No ice build-up', noteTone: latest.iceBuiltUp ? 'crit' : undefined, note: latest.iceBuiltUp ? 'Defrost recommended' : null },
    ];
  } else if (type === 'device4') {
    const comps = Array.from({ length: 8 }, (_, i) => num(latest[`comp${i + 1}_avg`])).filter((v) => v != null && v > 0);
    const kw = Array.from({ length: 8 }, (_, i) => num(latest[`comp${i + 1}_power_kw`]) || 0).reduce((a, v) => a + v, 0);
    cards = [
      { icon: 'bolt', tone: 'navy', title: 'Compressors running', value: `${comps.length}/8`, sub: 'Drawing current' },
      { icon: 'gauge', tone: 'amber', title: 'Total power', value: fixed(kw, ' kW'), sub: 'All compressors' },
    ];
  } else if (type === 'device5') {
    cards = [
      { icon: 'relay', tone: 'green', title: 'Relays on', value: latest.relaysOnCount ?? '—', sub: 'Energised outputs' },
      { icon: 'relay', tone: 'navy', title: 'Relays off', value: latest.relaysOffCount ?? '—', sub: 'Idle outputs' },
    ];
  } else if (type === 'device7') {
    cards = [
      { icon: 'weight', tone: 'navy', title: 'Scans today', value: latest.totalScansToday ?? 0, sub: `${latest.verifiedScansToday ?? 0} verified` },
      { icon: 'therm', tone: 'blue', title: 'Bottle temperature', value: deg(latest.bottleTemp), sub: 'Fridge' },
      { icon: 'gauge', tone: 'amber', title: 'Verification rate', value: fixed(latest.verificationRate, '%', 0), sub: `${latest.failedScansToday ?? 0} failed` },
    ];
  }
  if (!cards.length) return null;
  return (
    <section className="metric-row" aria-label="Key metrics">
      {cards.map((c) => <MetricCard key={c.title} {...c} />)}
    </section>
  );
}

// ------------------------------------------------------- detailed metrics
export function ComparisonBars({ items, unit = '°C', height = 260 }) {
  const data = items.filter((i) => i.value != null);
  if (!data.length) return <p className="hint">No readings to compare yet.</p>;
  const hasNegative = data.some((d) => d.value < 0);
  const suffix = unit === '°C' ? '°' : unit.trim();
  return (
    <div style={{ height }} role="img" aria-label={data.map((d) => `${d.name} ${d.value.toFixed(1)}${unit}`).join(', ')}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 22, right: 8, left: -6, bottom: 0 }} barCategoryGap="30%">
          <CartesianGrid vertical={false} stroke={INK.grid} />
          <XAxis dataKey="name" tick={{ fontSize: 11, fill: INK.secondary }} tickLine={false} axisLine={{ stroke: INK.axis }} interval={0} />
          <YAxis tick={{ fontSize: 10, fill: INK.muted }} tickLine={false} axisLine={false} width={44} tickFormatter={(v) => `${v}${suffix}`} />
          {hasNegative && <ReferenceLine y={0} stroke={INK.axis} />}
          <Tooltip {...tooltipStyle} formatter={(v) => [`${Number(v).toFixed(1)}${unit}`, 'Reading']} />
          <Bar dataKey="value" maxBarSize={34} radius={[6, 6, 6, 6]}>
            {data.map((d) => <Cell key={d.name} fill={d.color} />)}
            <LabelList dataKey="value" position="top" formatter={(v) => `${Number(v).toFixed(1)}${suffix}`} style={{ fontSize: 10.5, fill: INK.secondary, fontWeight: 600 }} />
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

function Donut({ slices, center, sub, height = 200 }) {
  const data = slices.filter((s) => s.value > 0);
  return (
    <div className="donut-wrap">
      <div className="donut" style={{ height }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data.length ? data : [{ name: 'None', value: 1, color: INK.grid }]} dataKey="value" nameKey="name"
              innerRadius="62%" outerRadius="92%" paddingAngle={data.length > 1 ? 2 : 0} stroke="#fff" strokeWidth={data.length > 1 ? 2 : 0} isAnimationActive={false}>
              {(data.length ? data : [{ color: INK.grid }]).map((s, i) => <Cell key={i} fill={s.color} />)}
            </Pie>
            {data.length > 0 && <Tooltip {...tooltipStyle} />}
          </PieChart>
        </ResponsiveContainer>
        <div className="donut-center"><strong>{center}</strong>{sub && <span>{sub}</span>}</div>
      </div>
      <ul className="donut-legend">
        {slices.map((s) => (
          <li key={s.name}><i style={{ background: s.color }} />{s.name}<b>{s.value}</b></li>
        ))}
      </ul>
    </div>
  );
}

function ReadingTile({ icon, name, value, min, max, minAt, maxAt, tone }) {
  return (
    <div className={`reading-tile tone-${tone}`}>
      <Icon name={icon} size={20} />
      <span className="rt-name">{name}</span>
      <strong className="rt-value">{deg(value)}</strong>
      {(min != null || max != null) && (
        <div className="rt-range">
          <span className="rt-min">↓ {deg(min)} <small>{hhmm(minAt)}</small></span>
          <span className="rt-max">↑ {deg(max)} <small>{hhmm(maxAt)}</small></span>
        </div>
      )}
    </div>
  );
}

const zoneTone = (v) => (v == null ? 'neutral' : v > 5 ? 'hot' : v < -25 ? 'cold' : 'neutral');

export function DetailedMetrics({ type, latest }) {
  if (!latest) return null;

  if (type === 'device2') {
    const zones = zoneTemps(latest);
    const live = zones.filter((z) => z.value != null);
    const bands = [
      { name: 'Normal (−25 to 5°C)', value: live.filter((z) => zoneTone(z.value) === 'neutral').length, color: INK.primary },
      { name: 'Too low (< −25°C)', value: live.filter((z) => z.value < -25).length, color: SERIES[0] },
      { name: 'Too high (> 5°C)', value: live.filter((z) => z.value > 5).length, color: STATUS.critical },
    ];
    return (
      <>
        <div className="avg-banner">
          <div><span>Average temperature</span><strong>{deg(latest.avgTemp ?? latest.avgTemperature)}</strong></div>
          <small>Last reading {ago(latest.time)}</small>
        </div>
        <Panel title="Zone temperature comparison" eyebrow="Current reading per zone">
          <ComparisonBars items={zones.map((z, i) => ({ name: z.name.replace(/^Zone /, 'Z'), value: z.value, color: SERIES[i] }))} />
        </Panel>
        <Panel className="mt16" title="Zone temperatures" eyebrow="Now, with today's low and high">
          <div className="zone-grid">
            {zones.map((z) => (
              <div className={`zone-tile tone-${zoneTone(z.value)}`} key={z.n}>
                <span>{z.name}</span>
                <strong>{deg(z.value)}</strong>
                <div className="zone-range">
                  <div><small>Min</small><b className="rt-min">{deg(z.min)}</b><em>{hhmm(z.minAt)}</em></div>
                  <div><small>Max</small><b className="rt-max">{deg(z.max)}</b><em>{hhmm(z.maxAt)}</em></div>
                </div>
              </div>
            ))}
          </div>
        </Panel>
        <Panel className="mt16" title="Temperature distribution" eyebrow="Zones by temperature band">
          <Donut slices={bands} center={live.length} sub="zones" />
        </Panel>
      </>
    );
  }

  if (type === 'device3') {
    const sensors = [
      { key: 'hs_temp', name: 'High side', icon: 'hot', tone: 'amber' },
      { key: 'ls_temp', name: 'Low side', icon: 'therm', tone: 'blue' },
      { key: 'ice_temp', name: 'Ice', icon: 'ice', tone: 'aqua' },
      { key: 'air_temp', name: 'Air', icon: 'water', tone: 'neutral' },
    ];
    const water = num(latest.wtrlvl);
    return (
      <>
        <Panel title="Temperature readings" eyebrow={`Last reading ${ago(latest.time)}`}>
          <div className="reading-grid">
            {sensors.map((s) => (
              <ReadingTile key={s.key} icon={s.icon} tone={s.tone} name={`${s.name} temp`} value={latest[s.key]}
                min={num(latest[`${s.key}_min`])} max={num(latest[`${s.key}_max`])}
                minAt={latest[`${s.key}_min_time`]} maxAt={latest[`${s.key}_max_time`]} />
            ))}
          </div>
        </Panel>
        <div className="chart-pair mt16">
          <Panel title="Temperature comparison" eyebrow="Current reading per sensor">
            <ComparisonBars items={sensors.map((s, i) => ({ name: s.name, value: num(latest[s.key]), color: SERIES[i] }))} />
          </Panel>
          <Panel title="Water level" eyebrow={`Last empty ${ago(latest.wtrlvlLastEmpty)} · last full ${ago(latest.wtrlvlLastFull)}`}>
            <Donut
              slices={[
                { name: 'Water', value: water == null ? 0 : Math.round(water), color: SERIES[0] },
                { name: 'Empty', value: water == null ? 0 : Math.round(100 - water), color: INK.grid },
              ]}
              center={fixed(water, '%', 0)}
              sub={water == null ? 'no reading' : water >= 70 ? 'High' : water >= 30 ? 'Medium' : 'Low'}
            />
          </Panel>
        </div>
        <div className="status-strip mt16">
          <div><span>Harvest status</span><strong>{latest.harvsw ? 'Harvesting' : 'Idle'}</strong><small>Last {ago(latest.last_harvest_time)} · {latest.harvest_count ?? 0} today</small></div>
          <div><span>Energy (24 h)</span><strong>{fixed(latest.energy_consumed_24h, ' kWh')}</strong><small>{num(latest.energy_cost_24h) != null ? `R${latest.energy_cost_24h.toFixed(2)}` : 'No cost data'}</small></div>
          <div><span>Current draw</span><strong>{fixed(latest.amps, ' A')}</strong><small>{fixed(latest.power_kw, ' kW', 2)}</small></div>
        </div>
      </>
    );
  }

  if (type === 'device1') {
    const sensors = [
      { key: 'temperatureAir', name: 'Air', icon: 'therm', tone: 'neutral' },
      { key: 'temperatureCoil', name: 'Coil', icon: 'snow', tone: 'blue' },
      { key: 'temperatureDrain', name: 'Drain', icon: 'water', tone: 'aqua' },
    ];
    const phases = ['compAmpPh1', 'compAmpPh2', 'compAmpPh3'].map((k, i) => ({ name: `Phase ${i + 1}`, value: num(latest[k]), color: SERIES[i] }));
    return (
      <>
        <Panel title="Temperature readings" eyebrow={`Last reading ${ago(latest.time)}`}>
          <div className="reading-grid">
            {sensors.map((s) => <ReadingTile key={s.key} icon={s.icon} tone={s.tone} name={`${s.name} temp`} value={latest[s.key]} />)}
          </div>
        </Panel>
        <div className="chart-pair mt16">
          <Panel title="Temperature comparison" eyebrow="Current reading per sensor">
            <ComparisonBars items={sensors.map((s, i) => ({ name: s.name, value: num(latest[s.key]), color: SERIES[i] }))} />
          </Panel>
          <Panel title="Compressor current" eyebrow={`Imbalance ${fixed(latest.ampImbalance, '%')}`}>
            <ComparisonBars items={phases} unit=" A" />
          </Panel>
        </div>
      </>
    );
  }

  if (type === 'device4') {
    const comps = Array.from({ length: 8 }, (_, i) => ({ name: `C${i + 1}`, value: num(latest[`comp${i + 1}_avg`]), color: SERIES[i] }));
    return (
      <Panel title="Compressor current" eyebrow="Average amps per compressor">
        <ComparisonBars items={comps} unit=" A" />
      </Panel>
    );
  }

  if (type === 'device5') {
    return (
      <Panel title="Relay outputs" eyebrow={`Last reading ${ago(latest.time)}`}>
        <div className="relay-grid">
          {Array.from({ length: 16 }, (_, i) => {
            const on = !!latest[`relay${i + 1}`];
            return <div key={i} className={`relay-cell${on ? ' on' : ''}`}><span>{label(latest, `relay_${i + 1}`, `Relay ${i + 1}`)}</span><strong>{on ? 'On' : 'Off'}</strong></div>;
          })}
        </div>
      </Panel>
    );
  }

  if (type === 'device7') {
    const trays = [1, 2, 3, 4].map((n, i) => ({ name: `Tray ${n}`, value: num(latest[`tray${n}wt`]), color: SERIES[i] }));
    return (
      <Panel title="Tray weights" eyebrow={`Last scan ${ago(latest.time)}`}>
        <ComparisonBars items={trays} unit=" g" />
      </Panel>
    );
  }

  return null;
}
