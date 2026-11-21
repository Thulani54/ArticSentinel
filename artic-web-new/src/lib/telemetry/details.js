export function humanLabel(key) {
  const words=key.replace(/_analytics$/, '').replace(/([a-z])(\d)/g,'$1 $2').replaceAll('_',' ');
  const expanded=words.replace(/\bpct\b/g,'(%)').replace(/\bavg\b/g,'average').replace(/\bmin\b/g,'minimum').replace(/\bmax\b/g,'maximum');
  return expanded.charAt(0).toUpperCase()+expanded.slice(1);
}
export function dateWindow(days, end=new Date()) {
  const start=new Date(end);start.setDate(start.getDate()-days+1);
  const local=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
  return {start:local(start),end:local(end)};
}
export function readingCount(data) {
  if(!data)return null;
  for(const key of ['overall_statistics','zone_summary','ice_machine_summary','enhanced_temperature_analytics']) {
    if(typeof data[key]?.total_readings==='number')return data[key].total_readings;
  }
  const counts=data.daily_summary_analytics?.total_readings ?? data.compressor_analytics?.total_readings;
  return Array.isArray(counts)?counts.reduce((a,b)=>a+(Number(b)||0),0):null;
}
export function analyticsRows(value) {
  const fields=Object.keys(value).filter(k=>k!=='labels' && Array.isArray(value[k]) && value[k].some(v=>typeof v==='number'));
  return {fields,rows:(value.labels || []).map((label,i)=>({label,...Object.fromEntries(fields.map(k=>[k,typeof value[k][i]==='number'?value[k][i]:null]))}))};
}
