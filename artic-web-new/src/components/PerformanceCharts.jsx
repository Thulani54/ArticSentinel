// Building blocks for the Device Performance screen, shared by every device
// type so all charts look and line up the same: a trend chart (line or bar)
// with series toggles as its legend, a statistics table, and the monitor
// header card (production's "Ice Machine Monitor · Health" strip).

import { useMemo, useState } from 'react';
import {
  Bar, BarChart, CartesianGrid, Line, LineChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts';
import { Panel } from './bits';
import { INK, SERIES, tooltipStyle } from '../lib/palette';

// ---------------------------------------------------------- time labels
// Service labels look like "2026-09-19 14:00" (hourly) or "2026-09-19" (daily).
const parseLabel = (v) => {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}/.test(v)) return null;
  const d = new Date(v.length > 10 ? v.replace(' ', 'T') : `${v}T00:00`);
  return Number.isNaN(d.getTime()) ? null : d;
};
const dayFmt = { day: 'numeric', month: 'short' };
const timeFmt = { hour: '2-digit', minute: '2-digit' };

function makeTickFormatter(rows, axis) {
  const dates = rows.map((r) => parseLabel(r[axis])).filter(Boolean);
  if (!dates.length) return hourOrText;
  const spanDays = (dates[dates.length - 1] - dates[0]) / 86400000;
  return (v) => {
    const d = parseLabel(v);
    if (!d) return String(v ?? '');
    return spanDays > 2 ? d.toLocaleDateString([], dayFmt) : d.toLocaleTimeString([], timeFmt);
  };
}
// Hour-of-day buckets arrive as 0–23 (number or "7"); show them as 07:00.
const hourOrText = (v) => (/^\d{1,2}$/.test(String(v ?? '')) ? `${String(v).padStart(2, '0')}:00` : String(v ?? ''));
const tooltipLabel = (v) => {
  const d = parseLabel(v);
  if (!d) return hourOrText(v);
  return typeof v === 'string' && v.length > 10
    ? `${d.toLocaleDateString([], dayFmt)} ${d.toLocaleTimeString([], timeFmt)}`
    : d.toLocaleDateString([], { weekday: 'short', ...dayFmt });
};
const fmt = (v, d = 1) => (typeof v === 'number' && Number.isFinite(v) ? Number(v.toFixed(d)).toLocaleString() : '—');

/** Rows for recharts from a service series ({labels:[...], key:[...]}). */
export function seriesRows(series, keys) {
  if (!series?.labels) return [];
  return series.labels.map((label, i) => ({
    label,
    ...Object.fromEntries(keys.map((k) => [k, typeof series[k]?.[i] === 'number' ? series[k][i] : null])),
  }));
}

/** Sums hourly rows into one row per day (label "YYYY-MM-DD") for counts. */
export function dailyTotals(rows, keys) {
  const days = new Map();
  for (const r of rows) {
    const day = typeof r.label === 'string' ? r.label.slice(0, 10) : r.label;
    const acc = days.get(day) || { label: day, ...Object.fromEntries(keys.map((k) => [k, null])) };
    for (const k of keys) if (typeof r[k] === 'number') acc[k] = (acc[k] || 0) + r[k];
    days.set(day, acc);
  }
  return [...days.values()];
}

const spanDays = (rows) => {
  const d = rows.map((r) => parseLabel(r.label)).filter(Boolean);
  return d.length ? (d[d.length - 1] - d[0]) / 86400000 : 0;
};
export { spanDays };

/**
 * One chart card. `fields` is [{key, name}] in fixed colour order (slot n is
 * always the same entity). With 2+ series the legend doubles as toggles.
 */
export function TrendChart({ title, eyebrow, unit = '', rows, fields, axis = 'label', type = 'line', initialKeys, height = 260 }) {
  const available = useMemo(
    () => fields.filter((f) => rows.some((r) => typeof r[f.key] === 'number')),
    [fields, rows],
  );
  const [on, setOn] = useState(() => new Set(initialKeys || fields.map((f) => f.key)));
  const active = available.filter((f) => on.has(f.key));
  const colorOf = (key) => SERIES[fields.findIndex((f) => f.key === key) % SERIES.length];
  const tick = useMemo(() => makeTickFormatter(rows, axis), [rows, axis]);
  // Multi-day hourly series: one tick at the first reading of each day, so
  // the axis never repeats a date.
  const dayTicks = useMemo(() => {
    const dates = rows.map((r) => parseLabel(r[axis]));
    if (dates.some((d) => !d) || dates.length < 2 || (dates[dates.length - 1] - dates[0]) / 86400000 <= 2) return undefined;
    const seen = new Set();
    const ticks = rows.filter((r, i) => { const k = dates[i].toDateString(); if (seen.has(k)) return false; seen.add(k); return true; }).map((r) => r[axis]);
    // A partial first day (data starting late) would collide with the next tick.
    if (ticks.length > 2 && parseLabel(ticks[1]) - parseLabel(ticks[0]) < 12 * 3600000) ticks.shift();
    return ticks;
  }, [rows, axis]);
  // Short units ride on the ticks; longer ones (cycles, openings) stay in the
  // card header so the axis never clips.
  const suffix = unit === '°C' ? '°' : unit && unit.length <= 3 ? ` ${unit}` : '';
  const tipSuffix = unit === '°C' ? '°C' : unit ? ` ${unit}` : '';
  const toggle = (key) =>
    setOn((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });

  const Chart = type === 'bar' ? BarChart : LineChart;
  return (
    <Panel title={title} eyebrow={eyebrow || (unit ? `Unit: ${unit}` : 'Selected period')}>
      <div className="trend-legend" role="group" aria-label={`${title} series`}>
        {available.length > 1 && available.map((f) => (
          <button
            type="button"
            key={f.key}
            className={`trend-key${on.has(f.key) ? ' on' : ''}`}
            aria-pressed={on.has(f.key)}
            onClick={() => toggle(f.key)}
          >
            <i style={{ background: colorOf(f.key) }} />{f.name}
          </button>
        ))}
      </div>
      {!rows.length || !available.length ? (
        <div className="trend-empty" style={{ height }}><strong>No readings in this period</strong><span>Choose a longer range or another device.</span></div>
      ) : !active.length ? (
        <div className="trend-empty" style={{ height }}><strong>Nothing selected</strong><span>Turn on a series above to plot it.</span></div>
      ) : (
        <div style={{ height }} role="img" aria-label={`${title}: ${active.map((f) => f.name).join(', ')}, ${rows.length} points`}>
          <ResponsiveContainer width="100%" height="100%">
            <Chart data={rows} margin={{ top: 8, right: 10, left: 0, bottom: 0 }} barCategoryGap="20%">
              <CartesianGrid vertical={false} stroke={INK.grid} />
              <XAxis dataKey={axis} tickFormatter={tick} ticks={dayTicks} interval={dayTicks ? 0 : 'preserveStartEnd'} minTickGap={dayTicks ? 4 : 36} tick={{ fontSize: 10.5, fill: INK.muted }} tickLine={false} axisLine={{ stroke: INK.axis }} />
              <YAxis width={52} tick={{ fontSize: 10.5, fill: INK.muted }} tickLine={false} axisLine={false}
                allowDecimals={type !== 'bar'}
                domain={type === 'bar' ? [0, 'auto'] : ['auto', 'auto']} tickFormatter={(v) => `${fmt(v, 1)}${suffix}`} />
              <Tooltip {...tooltipStyle} labelFormatter={tooltipLabel} formatter={(v, name) => [`${fmt(v, 2)}${tipSuffix}`, name]} />
              {active.map((f) =>
                type === 'bar' ? (
                  <Bar key={f.key} dataKey={f.key} name={f.name} fill={colorOf(f.key)} radius={[4, 4, 0, 0]} maxBarSize={18} />
                ) : (
                  <Line key={f.key} dataKey={f.key} name={f.name} stroke={colorOf(f.key)} strokeWidth={2} dot={false}
                    activeDot={{ r: 4, strokeWidth: 0 }} connectNulls={false} isAnimationActive={false} />
                ),
              )}
            </Chart>
          </ResponsiveContainer>
        </div>
      )}
    </Panel>
  );
}

/** Min / average / max per measurement, with when the extremes happened. */
export function StatsTable({ title = 'Statistics summary', eyebrow = 'Selected period', rows }) {
  const shown = rows.filter((r) => [r.min, r.avg, r.max].some((v) => typeof v === 'number'));
  const when = (iso) => (iso ? new Date(iso).toLocaleString([], { ...dayFmt, ...timeFmt }) : '');
  return (
    <Panel title={title} eyebrow={eyebrow}>
      {!shown.length ? (
        <p className="hint">No statistics for this period.</p>
      ) : (
        <div className="table-wrap">
          <table className="stats-table">
            <thead><tr><th>Measurement</th><th>Minimum</th><th>Average</th><th>Maximum</th></tr></thead>
            <tbody>
              {shown.map((r) => (
                <tr key={r.name}>
                  <td>{r.color && <i className="stat-swatch" style={{ background: r.color }} />}{r.name}</td>
                  <td><span className="rt-min">{fmt(r.min)}{r.unit}</span>{r.minAt && <small>{when(r.minAt)}</small>}</td>
                  <td>{fmt(r.avg)}{r.unit}</td>
                  <td><span className="rt-max">{fmt(r.max)}{r.unit}</span>{r.maxAt && <small>{when(r.maxAt)}</small>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  );
}

/** Production's monitor strip: type title, reading count and a health badge. */
export function MonitorHeader({ title, subtitle, health }) {
  const score = typeof health?.score === 'number' ? health.score : null;
  const tone = score == null ? 'neutral' : score >= 80 ? 'good' : score >= 60 ? 'warning' : 'critical';
  return (
    <div className="monitor-header">
      <div>
        <h2>{title}</h2>
        <p>{subtitle}</p>
        {health?.note && <p className="monitor-note">{health.note}</p>}
      </div>
      <div className={`health-badge tone-${tone}`}>
        <span>Health</span>
        <strong>{score == null ? '—' : `${Math.round(score)}%`}</strong>
        <small>{health?.grade ? `Grade ${health.grade}` : score == null ? 'Unknown' : tone === 'good' ? 'Good' : tone === 'warning' ? 'Fair' : 'Poor'}</small>
      </div>
    </div>
  );
}
