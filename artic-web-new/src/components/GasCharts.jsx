// Charts for the gas dashboard — daily burn bars (flame) and cost trend line
// (blue), per the dataviz rules: thin marks, recessive grid, one series per
// chart (titles name them, no legend), ink tooltips.

import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { CURRENCY, money } from '../lib/gas/gasCore';
import { compactTick, fmtDay } from './bits';

const inkTooltip = {
  contentStyle: {
    background: '#1E293B',
    border: 'none',
    borderRadius: 8,
    color: '#F8FAFC',
    fontSize: 12,
    padding: '8px 11px',
  },
  itemStyle: { color: '#F8FAFC' },
  labelStyle: { color: '#94A3B8', fontWeight: 600, marginBottom: 3 },
  cursor: { fill: 'rgba(30, 41, 59, 0.06)' },
};

export function GasBurnBarChart({ series }) {
  const data = series.map((p) => ({ ...p, ts: p.day.getTime(), label: fmtDay(p.day) }));
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} margin={{ top: 6, right: 6, left: -14, bottom: 0 }}>
        <CartesianGrid vertical={false} stroke="#E2E8F0" />
        <XAxis
          dataKey="ts"
          type="number"
          scale="time"
          domain={['dataMin', 'dataMax']}
          tickFormatter={compactTick}
          tick={{ fontSize: 11, fill: '#94A3B8' }}
          tickLine={false}
          axisLine={{ stroke: '#E2E8F0' }}
          minTickGap={28}
        />
        <YAxis
          tick={{ fontSize: 11, fill: '#94A3B8' }}
          tickLine={false}
          axisLine={false}
          width={44}
          tickFormatter={(v) => `${v}kg`}
        />
        <Tooltip {...inkTooltip} formatter={(v) => [`${v.toFixed(2)} kg`, 'Burned']} />
        <Bar dataKey="kg" fill="#EA580C" radius={[4, 4, 0, 0]} maxBarSize={14} />
      </BarChart>
    </ResponsiveContainer>
  );
}

export function GasCostLineChart({ series }) {
  const data = series.map((p) => ({ ...p, ts: p.day.getTime(), label: fmtDay(p.day) }));
  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data} margin={{ top: 6, right: 6, left: -6, bottom: 0 }}>
        <CartesianGrid vertical={false} stroke="#E2E8F0" />
        <XAxis
          dataKey="ts"
          type="number"
          scale="time"
          domain={['dataMin', 'dataMax']}
          tickFormatter={compactTick}
          tick={{ fontSize: 11, fill: '#94A3B8' }}
          tickLine={false}
          axisLine={{ stroke: '#E2E8F0' }}
          minTickGap={28}
        />
        <YAxis
          tick={{ fontSize: 11, fill: '#94A3B8' }}
          tickLine={false}
          axisLine={false}
          width={44}
          tickFormatter={(v) => `${CURRENCY}${v}`}
        />
        <Tooltip {...inkTooltip} formatter={(v) => [money(v), 'Cost']} />
        <Line
          type="monotone"
          dataKey="cost"
          stroke="#3B82F6"
          strokeWidth={2}
          dot={false}
          activeDot={{ r: 4, strokeWidth: 0 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
