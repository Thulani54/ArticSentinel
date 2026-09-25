// DashboardDataView supplies today's hourly buckets and seven daily buckets.
const finite = value => value != null && value !== '' && Number.isFinite(Number(value)) ? Number(value) : null;
export function chartSeries(data, deviceId, range) {
  const key = range === 'today' ? 'hour_bucket' : 'day_bucket';
  return (data?.[range === 'today' ? 'hourly_aggregates' : 'daily_aggregates'] || [])
    .filter(row => String(row.device_id) === String(deviceId) && Number.isFinite(Date.parse(row[key])))
    .map(row => ({ ...Object.fromEntries(Object.entries(row).map(([key, value]) => [key, key.startsWith('avg_') || key.endsWith('_on_pct') || key === 'total_scans' || key === 'verified_scans' || key === 'total_readings' || key === 'compressor_runtime_percentage' ? finite(value) : value])), at: Date.parse(row[key]) }))
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

export function telemetryProfile(type, rows = []) {
  const numbered = (count, key, label) => Array.from({ length: count }, (_, i) => [key(i + 1), `${label} ${i + 1}`]);
  if (type === 'device4') return { title: 'Compressor current', unit: 'A', fields: Array.from({length:8}, (_,i) => Array.from({length:3}, (_,p) => [`avg_${i+1}comph${p+1}`, `C${i+1} phase ${p+1}`])).flat() };
  if (type === 'device5') return { title: 'Relay duty cycle', unit: '%', fields: numbered(16, i => `relay${i}_on_pct`, 'Relay') };
  if (type === 'device6') return { title: 'Pressure trends', unit: 'bar', fields: numbered(8, i => `avg_prs${i}`, 'Pressure') };
  if (type === 'device7') return { title: 'Bottle verification', unit: 'scans', fields: [['total_scans', 'Total scans'], ['verified_scans', 'Verified scans']] };
  return { title: 'Temperature trends', unit: '°C', fields: temperatureSeries(rows) };
}

export function latestFields(type) {
  if (type === 'device1') return [['temperatureAir','Room temperature','°C'],['temperatureCoil','Coil temperature','°C'],['temperatureDrain','Drain temperature','°C'],['compressorLow','Low-side pressure','psi'],['compressorHigh','High-side pressure','psi'],['comp','Compressor','state'],['door','Door open','state']];
  if (type === 'device4') return Array.from({length:8}, (_,i) => Array.from({length:3}, (_,p) => [`${i+1}comph${p+1}`, `Compressor ${i+1} · Phase ${p+1}`, 'A'])).flat();
  if (type === 'device5') return Array.from({length:16}, (_,i) => [`relay${i+1}`, `Relay ${i+1}`, 'state']);
  if (type === 'device6') return Array.from({length:8}, (_,i) => [`prs${i+1}`, `Pressure ${i+1}`, 'bar']);
  if (type === 'device7') return [['codeScan','Last scan','text'],['scanVerified','Scan verified','verified'], ...Array.from({length:4}, (_,i) => [`tray${i+1}wt`, `Tray ${i+1}`, 'kg']), ['bottleTemp','Temperature','°C'],['totalScansToday','Scans today',''],['verifiedScansToday','Verified today','']];
  return [];
}

export function displayReading(value, unit) {
  if (value == null || value === '') return '—';
  if (unit === 'text') return String(value);
  if (unit === 'state' || unit === 'verified') {
    if (![true, false, 1, 0].includes(value)) return '—';
    return unit === 'state' ? (value ? 'On' : 'Off') : (value ? 'Verified' : 'Not verified');
  }
  return Number.isFinite(Number(value)) ? `${Number(value).toLocaleString(undefined, {maximumFractionDigits:2})}${unit ? ` ${unit}` : ''}` : '—';
}
