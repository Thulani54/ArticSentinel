const number = value => value != null && value !== '' && Number.isFinite(Number(value)) ? Number(value) : null;
export function performanceSeries(data, type) {
  const analytics = data?.temperature_analytics;
  const definitions = type === 'device2'
    ? Array.from({length:8}, (_, i) => [`zone${i+1}`, `Zone ${i+1}`])
    : type === 'device3'
      ? [['hs_temp','High side'],['ls_temp','Low side'],['ice_temp','Ice'],['air_temp','Air']]
      : [['avg_air_temperature','Room'],['avg_coil_temperature','Coil'],['avg_drain_temperature','Drain'],['avg_temperature','Average']];
  let fields = definitions.filter(([key]) => Array.isArray(analytics?.[key]) && analytics[key].some(value => number(value) != null));
  if (fields.some(([key]) => key === 'avg_air_temperature')) fields = fields.filter(([key]) => key !== 'avg_temperature');
  const rows = (analytics?.labels || []).map((label, index) => ({label, ...Object.fromEntries(fields.map(([key]) => [key, number(analytics[key][index])]))}));
  return {fields, rows};
}
export function metricsQuery(deviceId, businessId, days, end = new Date()) {
  const start = new Date(end.getTime() - days * 86400000);
  return `/device-metrics/?${new URLSearchParams({device_id: deviceId, company_id: businessId, start_date:start.toISOString(), end_date:end.toISOString()})}`;
}
