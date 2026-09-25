import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis, Legend } from 'recharts';
import { api, deviceTypeLabel } from '../api';
import { useAuth } from '../auth';
import { Panel, Empty, Spinner } from './bits';
import { latestFields, displayReading } from '../lib/telemetry/dashboard';
import { analyticsRows, readingCount, dateWindow, humanLabel } from '../lib/telemetry/details';

const colors = ['#176bba','#bf521b','#158367','#7954a1','#a77917','#278791','#a24873','#667888'];
const format = v => v == null ? '—' : typeof v === 'boolean' ? (v ? 'On / Yes' : 'Off / No') : typeof v === 'number' ? v.toLocaleString(undefined,{maximumFractionDigits:3}) : String(v);

function DataTable({rows}) {
  if (!rows?.length) return null;
  const keys = [...new Set(rows.flatMap(Object.keys))];
  return <div className="table-wrap"><table><thead><tr>{keys.map(k=><th key={k}>{humanLabel(k)}</th>)}</tr></thead><tbody>{rows.map((row,i)=><tr key={i}>{keys.map(k=><td key={k}>{format(row[k])}</td>)}</tr>)}</tbody></table></div>;
}
function Details({value}) {
  if (value == null) return <span>—</span>;
  if (Array.isArray(value)) return value.every(v=>v && typeof v==='object') ? <DataTable rows={value}/> : <p>{value.map(format).join(' · ') || 'No entries'}</p>;
  if (typeof value !== 'object') return <span>{format(value)}</span>;
  const entries=Object.entries(value);
  return <><dl className="performance-facts">{entries.filter(([,v])=>v==null || typeof v!=='object').map(([k,v])=><div key={k}><dt>{humanLabel(k)}</dt><dd>{format(v)}</dd></div>)}</dl>{entries.filter(([,v])=>v && typeof v==='object').map(([k,v])=><div className="performance-detail-group" key={k}><h3>{humanLabel(k)}</h3><Details value={v}/></div>)}</>;
}
function Chart({title, rows, fields, unit='', axis='label', initialFields}) {
  const [selected,setSelected]=useState(initialFields || fields.slice(0, Math.min(8,fields.length)));
  const available=fields.filter(k=>rows.some(row=>typeof row[k]==='number'));
  const active=selected.filter(k=>available.includes(k));
  return <Panel title={title} eyebrow={unit || 'Selected reporting period'}>
    {available.length>1 && <div className="performance-series">{available.map(k=><label key={k}><input type="checkbox" checked={active.includes(k)} onChange={e=>setSelected(old=>e.target.checked?[...old,k]:old.filter(x=>x!==k))}/>{humanLabel(k)}</label>)}</div>}
    {!rows.length ? <Empty>No readings in this period.</Empty> : !active.length ? <Empty>Select a measurement to plot.</Empty> : <div style={{height:280}} role="img" aria-label={`${title}, ${rows.length} data points`}><ResponsiveContainer width="100%" height="100%"><LineChart data={rows} margin={{top:10,right:15,left:0,bottom:0}} accessibilityLayer><CartesianGrid stroke="#e4edf2" vertical={false}/><XAxis dataKey={axis} tickFormatter={v=>typeof v==='string' && v.includes('T') ? v.replace('T',' ').slice(5,16) : v} minTickGap={35} tick={{fontSize:10}}/><YAxis tick={{fontSize:10}} domain={['auto','auto']}/><Tooltip formatter={(v,n)=>[`${format(v)}${unit ? ` ${unit}` : ''}`,n]}/><Legend wrapperStyle={{fontSize:11}}/>{active.map(k=><Line key={k} dataKey={k} name={humanLabel(k)} stroke={colors[available.indexOf(k)%8]} dot={rows.length<3} strokeWidth={2} connectNulls={false}/>)}</LineChart></ResponsiveContainer></div>}
    <details className="telemetry-data"><summary>View all chart values</summary><DataTable rows={rows}/></details>
  </Panel>;
}
function BottleAnalytics({data}) {
  const stats=data.overall_statistics;
  const trays=Object.entries(stats.tray_weights || {}).map(([tray,values])=>({tray:humanLabel(tray),...values}));
  return <>
    <div className="tiles">{[['scans_in','Bottles scanned in'],['scans_out','Bottles scanned out'],['active_scans','Net scans in period'],['total_bottles','Unique bottle codes'],['verification_rate','Verification rate (%)'],['total_scans','Total scans']].map(([key,label])=><div className="tile" key={key}><div className="eyebrow">{label}</div><div className="v">{format(stats[key])}</div></div>)}</div>
    <div className="chart-pair"><Panel title="Verification results"><Details value={{verified_scans:stats.verified_scans,failed_scans:stats.failed_scans,total_scans:stats.total_scans,verification_rate_pct:stats.verification_rate}}/></Panel><Panel title="Fridge temperature" eyebrow="°C · selected period"><Details value={stats.temperature}/></Panel></div>
    <Panel title="Tray weights" eyebrow="kg · selected period"><DataTable rows={trays}/><h3>Total weight (kg)</h3><Details value={stats.total_weight}/></Panel>
    <p className="hint">Net scans are scans in minus scans out within this period, floored at zero. Unique codes and scan counts are reported by the bottle-vetting service.</p>
    <div className="chart-pair"><Chart title="Daily scan activity" rows={data.daily_data || []} axis="date" fields={['scans','verified']} unit="scans"/><Chart title="Hourly scan activity" rows={data.hourly_activity || []} axis="hour" fields={['scans','verified']} unit="scans"/><Chart title="Daily bottle movement" rows={data.daily_data || []} axis="date" fields={['scans_in','scans_out','active']} unit="scans"/><Chart title="Fridge temperature history" rows={data.daily_data || []} axis="date" fields={['avg_temp']} unit="°C"/><Chart title="Average tray weights" rows={trays} axis="tray" fields={['avg','min','max']} unit="kg"/><Chart title="Total weight history" rows={data.daily_data || []} axis="date" fields={['avg_total_weight']} unit="kg"/></div>
  </>;
}
function Analytics({data,type}) {
  if(type==='device7') return <BottleAnalytics data={data}/>;
  const summaries=Object.entries(data).filter(([key,v])=>v && typeof v==='object' && !Array.isArray(v) && !Array.isArray(v.labels) && !['date_range','real_time_insights'].includes(key));
  const series=Object.entries(data).filter(([,v])=>v && Array.isArray(v.labels));
  const daily=data.daily_data || [];
  const groups=type==='device4' ? [ ['Daily compressor current',Array.from({length:8},(_,i)=>`compressor${i+1}_avg`),'A'], ['Daily compressor power',Array.from({length:8},(_,i)=>`compressor${i+1}_power_kw`),'kW'], ...Array.from({length:8},(_,i)=>[`Compressor ${i+1} phase detail`,[1,2,3].map(p=>`comp${i+1}_phase${p}`),'A']) ] : type==='device5' ? [ ['Relay duty cycles · 1–8',Array.from({length:8},(_,i)=>`relay${i+1}_duty_cycle`),'%'], ['Relay duty cycles · 9–16',Array.from({length:8},(_,i)=>`relay${i+9}_duty_cycle`),'%'] ] : type==='device6' ? [['Pressure history',Array.from({length:8},(_,i)=>`sensor${i+1}`),'bar']] : [];
  return <>
    {summaries.map(([key,value])=><Panel key={key} title={humanLabel(key)} eyebrow="Selected period · reported statistics"><Details value={value}/></Panel>)}
    <div className="chart-pair">{series.map(([key,value])=>{const {rows,fields}=analyticsRows(value);return <Chart key={key} title={humanLabel(key)} rows={rows} fields={fields} initialFields={key==='temperature_analytics' ? fields.filter(k=>!['min_temperature','max_temperature','avg_temperature'].includes(k)) : fields.slice(0,1)}/>;})}{groups.map(([title,fields,unit])=><Chart key={title} title={title} rows={daily} fields={fields} unit={unit} axis="date"/>)}{data.hourly_relay_distribution && <Chart title="Hourly relay activity" rows={data.hourly_relay_distribution} fields={Array.from({length:16},(_,i)=>`relay${i+1}_on_pct`)} unit="%" axis="hour"/>}</div>
    {data.real_time_insights && <Panel title="Service insights" eyebrow="Backend assessment"><p className="hint">These are service-provided assessments. Historical period results do not indicate that an offline device is currently operating.</p><Details value={data.real_time_insights}/></Panel>}
  </>;
}
export default function DetailedPerformance({device}) {
  const {token,business}=useAuth();
  const [dates,setDates]=useState(()=>dateWindow(7));
  const [draft,setDraft]=useState(dates);
  const [data,setData]=useState(null);
  const [latest,setLatest]=useState(null);
  const [latestError,setLatestError]=useState('');
  const [error,setError]=useState('');
  const [loading,setLoading]=useState(true);
  const [revision,setRevision]=useState(0);
  useEffect(()=>{let live=true; api.dashboard(business.business_uid,device.device_id,token).then(result=>{if(live)setLatest(result.current_data?.find(d=>d.device_id===device.device_id)||{});}).catch(e=>{if(live)setLatestError(e.message);});return()=>{live=false;};},[device.device_id,business.business_uid,token,revision]);
  useEffect(()=>{let live=true;setLoading(true);setError('');setData(null); const params=new URLSearchParams({device_id:device.device_id,company_id:business.business_uid,start_date:new Date(`${dates.start}T00:00:00`).toISOString(),end_date:new Date(`${dates.end}T23:59:59.999`).toISOString()});api.get(`/device-metrics/?${params}`,token).then(result=>{if(live)setData(result);}).catch(e=>{if(live)setError(e.message);}).finally(()=>{if(live)setLoading(false);});return()=>{live=false;};},[device.device_id,business.business_uid,token,dates,revision]);
  const changeDates=next=>{setDates(next);setDraft(next);};
  const count=readingCount(data);
  const fields=latestFields(device.device_type);
  return <section className="performance-details">
    <div className="telemetry-heading"><div><h2>{device.name}</h2><p>{deviceTypeLabel(device.device_type)} · {device.is_online?'Online':'Offline'} · {device.device_id}</p></div><Link className="btn sm" to={`/devices/${device.id}`}>Equipment details</Link></div>
    <div className="performance-toolbar"><div className="seg">{[1,7,30,90].map(days=><button key={days} onClick={()=>changeDates(dateWindow(days))}>{days===1?'Today':`${days} days`}</button>)}</div><button className="btn sm" disabled={!latest?.time} onClick={()=>changeDates(dateWindow(7,new Date(latest.time)))}>Last reporting period</button><button className="btn sm" onClick={()=>setRevision(n=>n+1)}>Refresh analytics</button></div>
    <form className="performance-toolbar" onSubmit={e=>{e.preventDefault();if(draft.start && draft.end && draft.start<=draft.end)changeDates({...draft});}}><label>From<input aria-label="Analytics start date" type="date" required value={draft.start} max={draft.end} onChange={e=>setDraft({...draft,start:e.target.value})}/></label><label>To<input aria-label="Analytics end date" type="date" required value={draft.end} min={draft.start} onChange={e=>setDraft({...draft,end:e.target.value})}/></label><button className="btn sm" type="submit">Apply dates</button></form>
    <p className="hint">Showing {dates.start} through {dates.end}. Date filters use your local timezone; chart bucket labels use the service’s reporting timezone.</p>
    {latestError && <div className="form-err">Latest snapshot could not load: {latestError}</div>}
    {latest && fields.length>0 && <Panel title="Latest device readings" eyebrow={latest.time?`Last reported ${new Date(latest.time).toLocaleString()}`:'No stored latest reading'}><div className="readouts">{fields.map(([key,label,unit])=><div className="readout" key={key}><div className="eyebrow">{label}</div><div className="v">{displayReading(latest[key],unit)}</div></div>)}</div><p className="hint">Latest reported snapshot; may fall outside the selected analytics dates.</p></Panel>}
    {loading ? <Spinner/> : error ? <div role="alert" className="form-err">Analytics could not load: {error}. Use Refresh analytics to retry.</div> : data && count===0 ? <Panel title="No readings in this period"><Empty>{latest?.time?'Choose Last reporting period to inspect the equipment’s stored history.':'No stored readings were found for the selected dates. Try an earlier date range.'}</Empty></Panel> : data && <><p className="hint">{count==null?'Available analytics':`${count.toLocaleString()} readings in selected period`}</p><Analytics key={`${device.device_id}-${dates.start}-${dates.end}-${revision}`} data={data} type={device.device_type}/></>}
  </section>;
}
