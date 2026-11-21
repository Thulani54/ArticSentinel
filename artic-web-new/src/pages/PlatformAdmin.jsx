import { useEffect, useState } from 'react';
import { Navigate, useSearchParams } from 'react-router-dom';
import { api, deviceTypeLabel, DEVICE_TYPE_OPTIONS } from '../api';
import { useAuth } from '../auth';
import Brand from '../components/Brand';
import Modal from '../components/Modal';
import './platform-admin.css';
import PlatformInsights from '../components/PlatformInsights';
import {cleanView,readViews} from '../lib/admin/views';

const ROOT = '/platform-admin/';
const SECTIONS = [
  ['overview','Overview','An operating view across Artic Sentinel.'],
  ['companies','Companies','Every customer workspace and its equipment.'],
  ['devices','Devices','Connection status, equipment identity and last readings.'],
  ['alerts','Alerts','Incidents and resolutions across every company.'],
  ['maintenance','Maintenance','Upcoming work, overdue jobs and completed services.'],
  ['reports','Reports','Find generated reports and inspect their contents.'],
  ['users','People','Account access and company membership.'],
  ['enquiries','Product enquiries','Requests received from prospective customers.'],
  ['health','Service health','The latest scheduled checks of the monitoring platform.'],
  ['activity','Access log','Administrator sign-ins, views and exports.'],
];
const COLUMNS = {
  companies: [['name','Company'],['device_count','Devices'],['online_count','Online'],['city','City'],['email','Contact'],['is_active','Status']],
  devices: [['name','Equipment'],['company__name','Company'],['device_type','Type'],['connection_status','Connection'],['last_ping','Last reading'],['mqtt_client_id','Assigned client ID']],
  alerts: [['title','Alert'],['company__name','Company'],['device__name','Equipment'],['severity','Severity'],['status','Status'],['triggered_at','Triggered']],
  maintenance: [['device__name','Equipment'],['device__company__name','Company'],['maintenance_type__name','Work'],['status','Status'],['priority','Priority'],['scheduled_date','Scheduled']],
  reports: [['report_name','Report'],['company_name','Company'],['report_type','Type'],['status','Status'],['generated_at','Created'],['generated_by','Created by']],
  users: [['user__email','Account'],['business__name','Company'],['user_type','Role'],['is_active','Status'],['user__last_login','Last sign-in']],
  enquiries: [['name','Name'],['company','Company'],['product_type','Product'],['email','Email'],['phone','Phone'],['created_at','Received']],
  health: [['name','Service'],['ok','Status'],['detail','Result'],['checked_at','Last check'],['consecutive_failures','Failures']],
  activity: [['user__username','Administrator'],['action','Action'],['resource','Section'],['created_at','Time']],
};
const STATUSES = {
  devices:['online','offline','never_reported','inactive'],companies:['active','inactive'],users:['active','inactive'],
  alerts:['active','acknowledged','resolved','false_positive'],maintenance:['scheduled','in_progress','overdue','completed','cancelled'],
  reports:['generating','completed','failed'],health:['healthy','failing','stale'],
};
const COMPANY_TABS = ['overview','companies','devices','alerts','maintenance','reports','users'];
const DATE_TABS = ['alerts','maintenance','reports','enquiries','activity'];
const nice = v => String(v ?? '').replaceAll('_',' ').replace(/\b\w/g,c=>c.toUpperCase());
const date = v => v ? new Date(v).toLocaleString([], { dateStyle:'medium',timeStyle:'short' }) : 'Not yet';
function Mark({type='grid'}) {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">{type==='signal'?<><path d="M4 17v3m5-8v8m5-13v13m5-18v18"/></>:type==='empty'?<><rect x="4" y="7" width="16" height="14" rx="3"/><path d="M8 7V3h8v4M8 12h8m-6 4h4"/></>:<><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></>}</svg>;
}
function Badge({value}) {
  const text = typeof value==='boolean' ? (value?'active':'inactive') : value;
  const tone = ['online','healthy','active','completed','resolved'].includes(text)?'good':['offline','failed','failing','critical','overdue'].includes(text)?'bad':['in_progress','acknowledged','high','medium','generating','stale'].includes(text)?'warn':'muted';
  return <span className={`pa-badge ${tone}`}><i/>{nice(text || 'Unknown')}</span>;
}
function Empty({title='No records found',text='Try a different search or clear your filters.'}) {
  return <div className="pa-empty"><Mark type="empty"/><h2>{title}</h2><p>{text}</p></div>;
}
function PasswordForm({onComplete}) {
  const {token,replaceToken}=useAuth();
  const [current,setCurrent]=useState(''),[next,setNext]=useState(''),[confirm,setConfirm]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState('');
  async function save(e){e.preventDefault();setError('');if(next!==confirm){setError('The new passwords do not match.');return;}setBusy(true);try{const data=await api.post(ROOT+'password/',{current_password:current,new_password:next},token);replaceToken(data.token);onComplete();}catch(e){setError(e.message);}finally{setBusy(false);}}
  return <form className="pa-password" onSubmit={save}><Mark/><h1>Make this account yours</h1><p>Replace your temporary password before opening the platform dashboard.</p>{error&&<p role="alert" className="pa-error">{error}</p>}<label>Temporary password<input autoComplete="current-password" type="password" required value={current} onChange={e=>setCurrent(e.target.value)}/></label><label>New password<input autoComplete="new-password" type="password" minLength={12} maxLength={128} required value={next} onChange={e=>setNext(e.target.value)}/></label><label>Confirm new password<input autoComplete="new-password" type="password" required value={confirm} onChange={e=>setConfirm(e.target.value)}/></label><p>Use at least 12 characters and a password you do not use elsewhere.</p><button className="btn primary" disabled={busy}>{busy?'Saving…':'Save password and continue'}</button></form>;
}
function DataTree({value}) {
  if(value==null)return <span>Not recorded</span>;
  if(typeof value!=='object')return <span>{String(value)}</span>;
  if(Array.isArray(value))return <div className="pa-report-list">{value.length?value.map((item,i)=><details key={i}><summary>Entry {i+1}</summary><DataTree value={item}/></details>):'No entries'}</div>;
  return <dl className="pa-detail-grid">{Object.entries(value).map(([key,val])=><div key={key}><dt>{nice(key)}</dt><dd><DataTree value={val}/></dd></div>)}</dl>;
}
export default function PlatformAdmin(){
  const {auth,token,user,logout}=useAuth();
  const [params,setParams]=useSearchParams();
  const section=SECTIONS.find(x=>x[0]===params.get('tab'))||SECTIONS[0];const tab=section[0];
  const [accessRetry,setAccessRetry]=useState(0);
  const [access,setAccess]=useState(null),[accessError,setAccessError]=useState(''),[companies,setCompanies]=useState([]);
  const company=params.get('company')||'', status=params.get('status')||'', from=params.get('from')||'', to=params.get('to')||'', type=params.get('type')||'', attention=params.get('attention')||'', sort=params.get('sort')||'', severity=params.get('severity')||'';
  const insightDays=[7,30,90].includes(Number(params.get('days')))?Number(params.get('days')):30;
  const page=Math.max(1,Number(params.get('page'))||1), search=params.get('q')||'';
  function updateFilters(changes){setParams(previous=>{const next=cleanView(previous);for(const [key,value] of Object.entries(changes)){if(value)next.set(key,String(value));else next.delete(key);}return next;});}
  const writeParam=(key,value)=>updateFilters({[key]:value,page:''});
  const setCompany=v=>writeParam('company',v),setStatus=v=>writeParam('status',v),setFrom=v=>writeParam('from',v),setTo=v=>writeParam('to',v),setSearch=v=>writeParam('q',v);
  const setPage=v=>updateFilters({page:typeof v==='function'?v(page):v});
  const [q,setQ]=useState(search);
  const [autoRefresh,setAutoRefresh]=useState(false),[viewName,setViewName]=useState('');
  const viewKey='artic-admin-views-'+(user?.id||user?.username||'anonymous');
  const [savedViews,setSavedViews]=useState(()=>readViews(viewKey));
  const [data,setData]=useState(null),[busy,setBusy]=useState(true),[error,setError]=useState(''),[reload,setReload]=useState(0),[exporting,setExporting]=useState(false),[notice,setNotice]=useState('');
  const [detail,setDetail]=useState(null),[detailError,setDetailError]=useState(''),[detailBusy,setDetailBusy]=useState(false);
  useEffect(()=>{let active=true;if(token)api.get(ROOT+'access/',token).then(x=>{if(active){setAccess(x);setAccessError('');}}).catch(e=>{if(active)setAccessError(e.status===403?'This account does not have platform administrator access.':e.message);});return()=>{active=false;};},[token,accessRetry]);
  useEffect(()=>{document.title=section[1]+' · Artic Sentinel administration';},[section]);
  useEffect(()=>{setQ(search);},[search]);
  useEffect(()=>{const id=setTimeout(()=>{if(q!==search)setSearch(q);},300);return()=>clearTimeout(id);},[q,search]);
  useEffect(()=>{if(!autoRefresh)return;const id=setInterval(()=>{if(document.visibilityState==='visible')setReload(x=>x+1);},60000);return()=>clearInterval(id);},[autoRefresh]);
  useEffect(()=>{let active=true;if(access&&!access.must_change_password)api.get(ROOT+'records/companies/?page_size=100',token).then(x=>{if(active)setCompanies(x.results);}).catch(()=>{});return()=>{active=false;};},[access,token]);
  const filters=new URLSearchParams();if(company&&COMPANY_TABS.includes(tab))filters.set('company',company);if(search)filters.set('q',search);if(status)filters.set('status',status);if(from&&DATE_TABS.includes(tab))filters.set('from',from);if(to&&DATE_TABS.includes(tab))filters.set('to',to);
  if(severity&&tab==='alerts')filters.set('severity',severity);if(type&&tab==='devices')filters.set('type',type);if(attention)filters.set('attention',attention);if(sort)filters.set('sort',sort);
  const filterKey=filters.toString();
  const queryKey=[tab,filterKey,page,company].join('::');
  useEffect(()=>{let active=true;if(!access||access.must_change_password)return;setBusy(true);setError('');const query=tab==='overview'?(company?'?company='+company:''):'?'+filterKey+'&page='+page;api.get(ROOT+(tab==='overview'?'overview/':'records/'+tab+'/')+query,token).then(x=>{if(active)setData({...x,_tab:tab,_query:queryKey});}).catch(e=>{if(active)setError(e.message);}).finally(()=>{if(active)setBusy(false);});return()=>{active=false;};},[tab,filterKey,page,reload,access?.must_change_password,!!access,token,company]);
  function select(next,options={}){const values={tab:next,company,...options};const nextParams=new URLSearchParams();for(const [key,value] of Object.entries(values))if(value)nextParams.set(key,String(value));setQ(options.q||'');setParams(nextParams);setNotice('');}
  function scope(id,next='devices'){select(next,{company:String(id)});}
  function saveView(){const name=viewName.trim().slice(0,40);if(!name){setNotice('Enter a name for this view.');return;}const next=[{name,query:cleanView(params).toString()},...savedViews.filter(x=>x.name!==name)].slice(0,8);try{localStorage.setItem(viewKey,JSON.stringify(next));setSavedViews(next);setViewName('');setNotice('View saved in this browser for your administrator account.');}catch{setNotice('This browser could not save the view.');}}
  function removeView(name){const next=savedViews.filter(x=>x.name!==name);setSavedViews(next);try{localStorage.setItem(viewKey,JSON.stringify(next));}catch{setNotice('Could not persist the change.');}}
  function loadView(query){const next=cleanView(query);setQ(next.get('q')||'');setParams(next);}
  async function copyView(){try{await navigator.clipboard.writeText(window.location.href);setNotice('View link copied. Administrator access is still required.');}catch{setNotice('Copy the page address to share this filtered view.');}}
  async function open(row){setDetail({summary:row,value:null});setDetailBusy(true);setDetailError('');try{const x=await api.get(ROOT+'records/'+tab+'/'+encodeURIComponent(row.id??row.name)+'/',token);setDetail(current=>current?{summary:row,value:x}:null);}catch(e){setDetailError(e.message);}finally{setDetailBusy(false);}}
  async function download(){setExporting(true);setNotice('');try{await api.download(ROOT+'export/'+tab+'/?'+filterKey,'GET',null,token,`artic-sentinel-${tab}.csv`);setNotice('CSV downloaded with your current filters.');}catch(e){setNotice(e.message);}finally{setExporting(false);}}
  function reportJson(){const blob=new Blob([JSON.stringify(detail.value,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`artic-report-${detail.value.report_id}.json`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
  if(!auth)return <Navigate to="/admin/login" replace/>;
  if(accessError)return <main className="pa-entry"><Brand/><Empty title="Administrator access required" text={accessError}/><button className="btn primary" onClick={logout}>Use another account</button><button className="btn" onClick={()=>setAccessRetry(x=>x+1)}>Retry</button></main>;
  if(!access)return <main className="pa-entry"><Brand/><p role="status">Checking administrator access…</p></main>;
  if(access.must_change_password)return <main className="pa-entry"><Brand/><PasswordForm onComplete={()=>setAccess(x=>({...x,must_change_password:false}))}/><button className="btn" onClick={logout}>Sign out</button></main>;
  const total=data?.counts?.devices||0;
  function cell(row,key){const v=row[key];if(['status','connection_status','severity','priority','is_active'].includes(key))return <Badge value={v}/>;if(key==='ok')return <Badge value={!v?'failing':row.stale?'stale':'healthy'}/>;if(['created_at','last_ping','triggered_at','scheduled_date','generated_at','checked_at','user__last_login'].includes(key))return date(v);if(key==='device_type')return deviceTypeLabel(v);return v==null||v===''?'—':String(v);}
  return <div className="pa-shell">
    <a className="skip-link" href="#pa-main">Skip to content</a>
    <aside className="pa-sidebar"><Brand/><div className="pa-workspace"><Mark/><div><strong>Platform administration</strong><span>All companies</span></div></div><nav aria-label="Administration">{SECTIONS.map(([key,label])=><button key={key} className={key===tab?'selected':''} aria-current={key===tab?'page':undefined} onClick={()=>select(key)}><Mark type={key==='health'?'signal':'grid'}/>{label}</button>)}</nav><div className="pa-admin-identity"><strong>{access.name||user?.username}</strong><span>Platform administrator</span><button onClick={logout}>Sign out</button></div></aside>
    <main id="pa-main" className="pa-main" tabIndex={-1}>
      <div className="pa-top"><span>Artic Sentinel / Administration</span><span>{access.username}</span></div>
      <header className="pa-heading"><div><h1>{section[1]}</h1><p>{section[2]}</p></div><div className="pa-header-actions"><button className="btn" onClick={()=>setReload(x=>x+1)} disabled={busy}>Refresh</button>{tab!=='overview'&&<button className="btn primary" onClick={download} disabled={busy||exporting||!data}>{exporting?'Exporting…':'Export CSV'}</button>}</div></header>
      <div className="pa-controls">{COMPANY_TABS.includes(tab)&&<label>Company<select value={company} onChange={e=>{setCompany(e.target.value);}}><option value="">All companies</option>{companies.map(c=><option value={c.id} key={c.id}>{c.name}</option>)}</select></label>}{tab!=='overview'&&<label className="pa-search">Search<input value={q} onChange={e=>setQ(e.target.value)} placeholder={`Search ${section[1].toLowerCase()}`}/></label>}{tab==='devices'&&<label>Equipment type<select value={type} onChange={e=>writeParam('type',e.target.value)}><option value="">All equipment types</option>{DEVICE_TYPE_OPTIONS.map(t=><option key={t.value} value={t.value}>{t.label}</option>)}</select></label>}{tab==='alerts'&&<label>Severity<select value={severity} onChange={e=>writeParam('severity',e.target.value)}><option value="">All severities</option>{['critical','high','medium','low','info'].map(s=><option value={s} key={s}>{nice(s)}</option>)}</select></label>}{STATUSES[tab]&&<label>Status<select value={status} onChange={e=>{setStatus(e.target.value);}}><option value="">All statuses</option>{STATUSES[tab].map(s=><option value={s} key={s}>{nice(s)}</option>)}</select></label>}{['devices','companies','alerts','maintenance','reports'].includes(tab)&&<label>Sort by<select value={sort} onChange={e=>writeParam('sort',e.target.value)}><option value="">Default order</option>{(tab==='devices'?[['name','Device name'],['oldest_reading','Oldest reading'],['newest','Newest device'],['company','Company']]:tab==='companies'?[['name','Company name'],['newest','Newest company']]:tab==='maintenance'?[['soonest','Earliest scheduled'],['latest','Latest scheduled']]:[['newest','Newest first'],['oldest','Oldest first']]).map(([key,label])=><option key={key} value={key}>{label}</option>)}</select></label>}{DATE_TABS.includes(tab)&&<><label>From<input type="date" value={from} onChange={e=>{setFrom(e.target.value);}}/></label><label>To<input type="date" min={from||undefined} value={to} onChange={e=>{setTo(e.target.value);}}/></label></>}{(company||q||status||from||to||type||attention||sort||severity)&&<button className="btn" onClick={()=>{select(tab,{company:''});}}>Clear filters</button>}</div>
      <div className="pa-view-tools"><label><input type="checkbox" checked={autoRefresh} onChange={e=>setAutoRefresh(e.target.checked)}/>Refresh every minute</label><button className="btn" onClick={copyView}>Copy view link</button>{tab==='overview'&&<button className="btn" onClick={()=>window.print()}>Print overview</button>}<input type="text" aria-label="Saved view name" placeholder="Name this view" maxLength={40} value={viewName} onChange={e=>setViewName(e.target.value)}/><button className="btn" onClick={saveView}>Save view</button></div>
      {savedViews.length>0&&<div className="pa-saved-views" aria-label="Saved views">{savedViews.map(view=><span key={view.name}><button onClick={()=>loadView(view.query)}>{view.name}</button><button aria-label={'Remove saved view '+view.name} onClick={()=>removeView(view.name)}>×</button></span>)}</div>}
      {['devices','alerts','maintenance'].includes(tab)&&<div className="pa-filter-chips" aria-label="Quick filters"><button className={!attention?'selected':''} onClick={()=>updateFilters({attention:'',status:'',page:''})}>All records</button>{(tab==='devices'?[['needs_attention','Not reporting']]:tab==='alerts'?[['unresolved','Unresolved alerts']]:[['overdue','Overdue jobs'],['due_soon','Due in 7 days']]).map(([key,label])=><button key={key} className={attention===key?'selected':''} onClick={()=>updateFilters({attention:key,status:'',page:''})}>{label}</button>)}</div>}
      {notice&&<p className="pa-notice" role="status">{notice}</p>}
      {error?<div className="pa-error" role="alert"><strong>Could not load this view</strong><p>{error}</p><button className="btn" onClick={()=>setReload(x=>x+1)}>Try again</button></div>:data?._query!==queryKey?<div className="pa-loading" role="status"><span/>Loading live platform records…</div>:data&&tab==='overview'?<>
        <section className="pa-fleet"><div><span>Fleet connection status</span><h2>{data.counts.online}<small> / {total} equipment online</small></h2><p>{data.counts.companies} companies · Updated {date(data.generated_at)}</p></div><div className="pa-fleet-breakdown"><div className="pa-status-track" aria-label="Equipment connection distribution">{[['online','good'],['offline','bad'],['never_reported','warn'],['inactive','muted']].map(([k,tone])=><span key={k} className={tone} style={{width:total?`${data.counts[k]/total*100}%`:'0%'}}/>)}</div><div className="pa-legend">{['online','offline','never_reported','inactive'].map(k=><span key={k}>{nice(k)} <strong>{data.counts[k]}</strong></span>)}</div></div></section>
        <div className="pa-operating-row">{[['companies','Companies',data.counts.companies],['alerts','Unresolved alerts',data.counts.active_alerts],['maintenance','Overdue maintenance',data.counts.overdue_maintenance],['reports','Saved reports',data.counts.reports]].map(([key,label,value])=><button key={key} onClick={()=>select(key,key==='alerts'?{attention:'unresolved'}:key==='maintenance'?{attention:'overdue'}:{})}><span>{label}</span><strong>{value}</strong><span>View {key}</span></button>)}</div>
        <PlatformInsights token={token} company={company} refresh={reload} onNavigate={select} days={insightDays} onDaysChange={value=>writeParam('days',value)}/><div className="pa-overview-grid"><section className="pa-panel"><div className="pa-section-title"><h2>Companies at a glance</h2><button onClick={()=>select('companies')}>View all</button></div>{data.companies.length?<div className="pa-company-list">{data.companies.map(c=><button key={c.id} onClick={()=>scope(c.id)}><span className="pa-company-initial">{c.name.slice(0,2).toUpperCase()}</span><span><strong>{c.name}</strong><small>{c.city||'Location not specified'}</small></span><span><strong>{c.online_count} / {c.device_count}</strong><small>online</small></span></button>)}</div>:<Empty title="No companies yet" text="Registered customer workspaces will appear here."/>}</section>
        <div className="pa-overview-side"><section className="pa-panel"><div className="pa-section-title"><h2>Equipment mix</h2><button onClick={()=>select('devices')}>View fleet</button></div>{data.device_types.length?data.device_types.map(x=><div className="pa-type-row" key={x.device_type}><div><span>{deviceTypeLabel(x.device_type)}</span><strong>{x.total}</strong></div><progress value={x.total} max={total}/></div>):<Empty title="No equipment connected" text="Devices appear when they are registered to a company."/>}</section><section className="pa-panel"><div className="pa-section-title"><h2>Platform services</h2><button onClick={()=>select('health')}>Inspect checks</button></div><div className="pa-service-summary"><Mark type="signal"/><strong>{data.health.filter(x=>x.ok&&!x.stale).length} / {data.health.length}</strong><span>healthy, recently checked</span></div>{data.health.some(x=>!x.ok||x.stale)&&<p className="pa-notice">Some checks are failing or have not run recently.</p>}</section></div></div>
        <section className="pa-panel"><div className="pa-section-title"><h2>Recent alerts</h2><button onClick={()=>select('alerts')}>View alerts</button></div>{data.recent_alerts.length?<div className="pa-recent-alerts">{data.recent_alerts.map(a=><div key={a.id}><Badge value={a.severity}/><span><strong>{a.title}</strong><small>{a.company__name} · {a.device__name}</small></span><time>{date(a.triggered_at)}</time></div>)}</div>:<Empty title="No alerts recorded" text="Equipment alerts will appear here as they are generated."/>}</section>
      </>:data&&<section className="pa-panel pa-records"><div className="pa-section-title"><h2>{data.count.toLocaleString()} {data.count===1?'record':'records'}</h2><span>Updated {date(data.generated_at)}</span></div>{data.results.length?<div className="pa-table-scroll"><table><thead><tr>{COLUMNS[tab].map(([k,label])=><th key={k}>{label}</th>)}<th><span className="pa-visually-hidden">Actions</span></th></tr></thead><tbody>{data.results.map(row=><tr key={row.id??row.name}>{COLUMNS[tab].map(([k],index)=><td key={k}>{index===0?<strong>{cell(row,k)}</strong>:cell(row,k)}</td>)}<td><button className="btn" aria-label={`View ${row.name||row.report_name||row.title||row.device__name||'record'}`} onClick={()=>open(row)}>Details</button>{tab==='companies'&&<button className="pa-text-btn" onClick={()=>scope(row.id)}>Devices</button>}</td></tr>)}</tbody></table></div>:<Empty/>}<div className="pa-pagination"><span>Page {page} of {Math.max(1,Math.ceil(data.count/data.page_size))}</span><div><button className="btn" disabled={page===1} onClick={()=>setPage(x=>x-1)}>Previous</button><button className="btn" disabled={page*data.page_size>=data.count} onClick={()=>setPage(x=>x+1)}>Next</button></div></div></section>}
      <footer className="pa-footer">Artic Sentinel <span>Platform-wide access · Activity is recorded</span></footer>
    </main>
    {detail&&<Modal label="Record details" onClose={()=>setDetail(null)}><section className="pa-modal"><header><h2>{detail.summary.name||detail.summary.report_name||detail.summary.title||'Record details'}</h2><button className="btn" aria-label="Close details" onClick={()=>setDetail(null)}>Close</button></header>{detailBusy?<p role="status">Loading details…</p>:detailError?<p role="alert" className="pa-error">{detailError}</p>:detail.value&&<>{tab==='devices'&&<div className="pa-connection"><h3>Device connection identity</h3><label>Assigned client ID<input readOnly value={detail.value.mqtt_client_id}/></label><button className="btn" onClick={async()=>{try{await navigator.clipboard.writeText(detail.value.mqtt_client_id);setNotice('Client ID copied.');}catch{setNotice('Select and copy the client ID from the field.');}}}>Copy client ID</button><p>{detail.value.identity_note}</p></div>}{tab==='reports'&&<button className="btn primary" onClick={reportJson}>Download report JSON</button>}<DataTree value={detail.value}/></>}</section></Modal>}
  </div>;
}
