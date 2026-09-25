// DashboardDataView supplies today's hourly buckets and seven daily buckets.
const finite = value => value != null && value !== '' && Number.isFinite(Number(value)) ? Number(value) : null;
export function chartSeries(data, deviceId, range) {
  const key = range === 'today' ? 'hour_bucket' : 'day_bucket';
  return (data?.[range === 'today' ? 'hourly_aggregates' : 'daily_aggregates'] || [])
    .filter(row => String(row.device_id) === String(deviceId) && Number.isFinite(Date.parse(row[key])))
    .map(row => ({ ...Object.fromEntries(Object.entries(row).map(([key, value]) => [key, key.startsWith('avg_') || key === 'total_readings' || key === 'compressor_runtime_percentage' ? finite(value) : value])), at: Date.parse(row[key]) }))
    .sort((a, b) => a.at - b.at);
}
const temperatureFields = [
  ['avg_temp_air', 'Room'], ['avg_temp_coil', 'Coil'], ['avg_temp_drain', 'Drain'],
  ['avg_hs_temp', 'High side'], ['avg_ls_temp', 'Low side'], ['avg_ice_temp', 'Ice'], ['avg_air_temp', 'Air'],
  ...Array.from({ length: 8 }, (_, i) => [`avg_temp${i + 1}`, `Zone ${i + 1}`]),
];
export function temperatureSeries(rows) {
  const available = temperatureFields.filter(([key]) => rows.some(row => row[key] != null));
  return available.length ? available : rows.some(row => row.avg_temp != null) ? [['avg_temp', 'Temperature']] : [];
}
