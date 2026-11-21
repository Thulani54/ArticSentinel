// Chart colours. SERIES is a validated categorical palette (dataviz
// validate_palette.js: lightness, chroma, colour-blind separation and
// normal-vision checks all pass on a light surface). Assign slots in fixed
// order — slot n always means the same entity (zone n, sensor n) — and never
// cycle past 8. Slots 3–5 sit under 3:1 contrast on white, so every chart
// that uses them keeps visible labels or a data table.
export const SERIES = ['#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4', '#008300', '#4a3aa7', '#e34948'];

// Status colours are reserved for state (never a series) and always ship with
// a text label.
export const STATUS = { good: '#0ca30c', warning: '#fab219', serious: '#ec835a', critical: '#d03b3b' };

export const INK = { primary: '#173648', secondary: '#607686', muted: '#718694', grid: '#e4edf2', axis: '#c3d2db' };

// Shared tooltip styling for recharts.
export const tooltipStyle = {
  contentStyle: { background: '#173648', border: 'none', borderRadius: 10, color: '#f8fafc', fontSize: 12, padding: '8px 11px' },
  itemStyle: { color: '#f8fafc' },
  labelStyle: { color: '#b8c7d1', fontWeight: 600, marginBottom: 3 },
  cursor: { fill: 'rgba(23, 54, 72, 0.05)' },
};
