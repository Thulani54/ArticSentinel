export function parseRules(rows, metrics) {
  if (rows.length > 20) throw new Error('Use up to 20 conditions per device.');
  const unique = new Set();
  const result = rows.map((row, index) => {
    const metric = metrics.find(m => m.id === row.metric);
    if (!metric || !['lte', 'gte'].includes(row.comparison)) throw new Error(`Choose a reading and trigger for condition ${index + 1}.`);
    const pieces = metric.boolean ? [row.comparison === 'gte' ? '1' : '0'] : row.values.split(',').map(v => v.trim());
    if (!pieces.length || pieces.length > 20 || pieces.some(v => !v || !/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(v))) throw new Error(`Condition ${index + 1}: enter up to 20 numbers separated by commas.`);
    const thresholds = [...new Set(pieces.map(Number))];
    for (const value of thresholds) {
      if (!Number.isFinite(value) || (metric.minimum != null && value < metric.minimum) || (metric.maximum != null && value > metric.maximum)) throw new Error(`${metric.label}: use values between ${metric.minimum ?? '−∞'} and ${metric.maximum ?? '∞'} ${metric.unit || ''}.`);
      unique.add(`${metric.id}:${row.comparison}:${value}`);
    }
    return { metric: metric.id, comparison: row.comparison, thresholds };
  });
  if (unique.size > 50) throw new Error('Use up to 50 thresholds per device.');
  return result;
}
export const editRules = rules => rules.map(r => ({ metric: r.metric, comparison: r.comparison, values: r.thresholds.join(', ') }));
