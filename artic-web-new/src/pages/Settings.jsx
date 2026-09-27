import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import { api, deviceTypeLabel } from '../api';
import { useDevices } from '../useDevices';
import { Panel } from '../components/bits';
import { parseRules, editRules } from '../lib/settings/rules';
import { DEFAULT_PREFERENCES, preferenceKey, readPreferences, applyPreferences } from '../lib/settings/preferences';
import './settings.css';

function Details({ rows }) {
  return <dl className="settings-details">{rows.map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value == null || value === '' ? 'Not provided' : String(value).replaceAll('_', ' ')}</dd></div>)}</dl>;
}

function DeviceRules({ device, token, onDirty }) {
  const [data, setData] = useState(null);
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);
  const [reload, setReload] = useState(0);
  const dirty = data && JSON.stringify(rows) !== JSON.stringify(editRules(data.rules));
  useEffect(() => { onDirty(!!dirty); return () => onDirty(false); }, [dirty, onDirty]);
  useEffect(() => {
    if (!dirty) return;
    const warn = e => { e.preventDefault(); e.returnValue = ''; };
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);
  useEffect(() => {
    let cancelled = false;
    setData(null); setError(''); setMessage('');
    api.get(`/push/devices/${device.id}/rules/`, token).then(result => {
      if (!cancelled) { setData(result); setRows(editRules(result.rules)); }
    }).catch(e => { if (!cancelled) setError(e.message); });
    return () => { cancelled = true; };
  }, [device.id, token, reload]);
  function patch(index, values) { setRows(current => current.map((row, i) => i === index ? { ...row, ...values } : row)); setMessage(''); }
  async function save(e) {
    e.preventDefault(); if (!data || saving) return;
    setError(''); setMessage('');
    let rules;
    try { rules = parseRules(rows, data.metrics); } catch (e) { setError(e.message); return; }
    setSaving(true);
    try {
      const result = await api.request(`/push/devices/${device.id}/rules/`, 'PUT', { revision: data.revision, rules }, token);
      setData(result); setRows(editRules(result.rules));
      setMessage(rules.length ? 'Your alert rules are saved and available in the mobile app.' : 'Your threshold alerts are off for this device.');
    } catch (e) { setError(e.message); } finally { setSaving(false); }
  }
  return <div className="settings-rule-editor" aria-busy={saving}>
    <div className="settings-device-heading"><div><h3>{device.name || device.device_name || device.device_id}</h3><p>{deviceTypeLabel(device.device_type)} · {device.device_id}</p></div><Link className="btn sm" to={`/devices/${device.id}`}>Equipment details</Link></div>
    {error && <div className="settings-notice error" role="alert">{error} <button type="button" className="btn sm" disabled={saving} onClick={() => { if (!dirty || window.confirm('Discard unsaved changes and reload saved rules?')) setReload(v => v + 1); }}>Reload saved rules</button></div>}
    {!data && !error && <p role="status">Loading your rules…</p>}
    {data && <form onSubmit={save}>
      <p className="settings-help">{data.personalized ? 'Personal rules' : 'Default rules'} · Changes apply only to your account. Numeric readings use the units shown below.</p>
      <fieldset disabled={saving} className="settings-fieldset">
        {rows.map((row, index) => {
          const metric = data.metrics.find(m => m.id === row.metric);
          return <section className="settings-condition" key={index} aria-label={`Condition ${index + 1}`}>
            <div className="settings-condition-head"><strong>Condition {index + 1}</strong><button type="button" className="btn sm" onClick={() => setRows(current => current.filter((_, i) => i !== index))}>Remove<span className="sr-only"> condition {index + 1}</span></button></div>
            <div className="settings-fields"><label>Reading<select value={row.metric} onChange={e => patch(index, { metric: e.target.value, values: '', comparison: 'lte' })}>{data.metrics.map(m => <option key={m.id} value={m.id}>{m.label}{m.unit ? ` (${m.unit})` : ''}</option>)}</select></label>
            <label>Trigger<select value={row.comparison} onChange={e => patch(index, { comparison: e.target.value })}><option value="lte">{metric?.boolean ? 'Off / closed / false' : 'At or below'}</option><option value="gte">{metric?.boolean ? 'On / open / true' : 'At or above'}</option></select></label></div>
            {!metric?.boolean && <label>Thresholds{metric?.unit ? ` (${metric.unit})` : ''}<input value={row.values} onChange={e => patch(index, { values: e.target.value })} placeholder={metric?.unit === '%' ? '50, 30, 10' : 'Enter values, separated by commas'} autoComplete="off" aria-describedby={`rule-help-${index}`} /><small id={`rule-help-${index}`}>Separate values with commas. The reading must recover by {metric?.reset_margin} {metric?.unit} before the same alert can fire again.</small></label>}
          </section>;
        })}
        {!rows.length && <div className="settings-empty"><strong>No conditions</strong><p>Add a reading to monitor. Saving an empty list turns off your threshold alerts for this device.</p></div>}
        <div className="settings-actions"><button type="button" className="btn" disabled={!data.metrics.length || rows.length >= 20} onClick={() => setRows(current => [...current, { metric: data.metrics[0].id, comparison: 'lte', values: '' }])}>Add condition</button><span>{rows.length}/20 conditions</span></div>
        {!data.metrics.length && <p>No configurable readings are available for this device type.</p>}
        <div className="settings-save"><span>{dirty ? 'Unsaved changes' : 'Up to date'}</span><button className="btn primary" disabled={!dirty || !data.metrics.length}>{saving ? 'Saving…' : 'Save my alerts'}</button></div>
      </fieldset>
      {message && <p className="settings-notice success" role="status">{message}</p>}
    </form>}
  </div>;
}

export default function Settings() {
  const { user, business, token, logout } = useAuth();
  const navigate = useNavigate();
  const { devices, error, refresh } = useDevices();
  const [selected, setSelected] = useState('');
  const [dirty, setDirty] = useState(false);
  const [query, setQuery] = useState('');
  const key = preferenceKey(user);
  const [prefs, setPrefs] = useState(() => readPreferences(key));
  const [preferenceMessage, setPreferenceMessage] = useState('');
  useEffect(() => { setPrefs(readPreferences(key)); }, [key]);
  const selectedDevice = devices?.find(d => String(d.id) === selected);
  const matches = (devices || []).filter(d => `${d.name || d.device_name || ''} ${d.device_id}`.toLowerCase().includes(query.toLowerCase()));
  function savePreferences(next) {
    try { localStorage.setItem(key, JSON.stringify(next)); setPrefs(next); applyPreferences(next); window.dispatchEvent(new Event('artic-preferences')); setPreferenceMessage('Display preferences saved for this account in this browser.'); }
    catch { setPreferenceMessage('Browser storage is unavailable. Preferences could not be saved.'); }
  }
  return <>
    <div className="page-head"><div><div className="eyebrow">Your workspace</div><h1 className="page-title">Settings</h1><p className="page-sub">Make monitoring work for you. Manage personal alerts, display preferences and account details.</p></div><span className="chip neutral">{business?.business_name || 'Workspace'}</span></div>
    <div className="settings-layout">
      <nav className="settings-nav" aria-label="Settings sections"><a href="#phone-alerts">Device alerts<span>Readings & thresholds</span></a><a href="#display">Display<span>Comfort & accessibility</span></a><a href="#account">Account<span>Your signed-in identity</span></a><a href="#workspace">Workspace<span>Business & access</span></a></nav>
      <div className="settings-content">
        <section id="phone-alerts"><Panel title="Your device alerts" eyebrow="Personal notifications"><p className="settings-intro">Choose what matters on each device. Set percentage lists, temperature limits, pressure thresholds or switch states using the same rules as the mobile app.</p>
          <div className="settings-notice">Notifications arrive in the installed ArticSentinel mobile app with phone alerts enabled. This page configures rules; it does not enable browser push. Only fresh readings trigger alerts.</div>
          <div className="settings-fields"><label>Find equipment<input type="search" value={query} onChange={e => setQuery(e.target.value)} placeholder="Search by name or device ID" /></label><label>Device<select value={selected} onChange={e => { if (!dirty || window.confirm('Discard unsaved alert changes and switch devices?')) setSelected(e.target.value); }}><option value="">Choose a device</option>{(selectedDevice && !matches.includes(selectedDevice) ? [selectedDevice, ...matches] : matches).map(d => <option value={d.id} key={d.id}>{d.name || d.device_name || d.device_id} · {d.device_id}</option>)}</select></label></div>
          {error && <p role="alert">{error} <button className="btn sm" onClick={refresh}>Retry equipment</button></p>}
          {!devices && !error && <p role="status">Loading equipment…</p>}
          {devices && !matches.length && <p>No equipment matches your search.</p>}
          {selectedDevice ? <DeviceRules key={`${token}:${selectedDevice.id}`} device={selectedDevice} token={token} onDirty={setDirty} /> : <div className="settings-empty">Select equipment to view and configure your alert rules.</div>}
        </Panel></section>
        <section id="display"><Panel title="Display & accessibility" eyebrow="This browser"><p className="settings-intro">Preferences apply across this website, for your account on this browser.</p><div className="settings-fields"><label>Information density<select value={prefs.density} onChange={e => savePreferences({ ...prefs, density: e.target.value })}><option value="comfortable">Comfortable</option><option value="compact">Compact tables and panels</option></select></label><label className="settings-toggle"><input type="checkbox" checked={prefs.reduceMotion} onChange={e => savePreferences({ ...prefs, reduceMotion: e.target.checked })} /><span>Reduce interface motion<small>Limit transitions and scrolling animations.</small></span></label></div><div className="settings-actions"><button className="btn" onClick={() => savePreferences({ ...DEFAULT_PREFERENCES })}>Reset display preferences</button></div>{preferenceMessage && <p role="status" className="settings-help">{preferenceMessage}</p>}</Panel></section>
        <section id="account"><Panel title="Account details" eyebrow="Signed-in identity"><Details rows={[[ 'Name', [user?.firstname, user?.lastname].filter(Boolean).join(' ') ],['Email', user?.email],['Username', user?.username],['Role', user?.user_type],['Job title', user?.job_title],['Phone', user?.cellphone_number ?? user?.work_phone],['Timezone', user?.timezone]]} /><p className="settings-help">Account identity and access are managed by your workspace administrator.</p><div className="settings-save"><span>Sign out of this browser session.</span><button className="btn danger" onClick={() => { if (window.confirm(dirty ? 'Discard unsaved alert changes and sign out?' : 'Sign out of ArticSentinel in this browser?')) { logout(); navigate('/login'); } }}>Sign out</button></div></Panel></section>
        <section id="workspace"><Panel title="Business workspace" eyebrow="Organisation"><Details rows={[[ 'Business', business?.business_name ],['Workspace ID', business?.business_uid],['Contact person', business?.contact_person],['Address', [business?.address, business?.city, business?.province].filter(Boolean).join(', ')],['Phone', business?.phone],['Email', business?.email]]} /><div className="settings-shortcuts"><Link to="/access">Roles & access<span>Review workspace permissions</span></Link><Link to="/alerts">Alert centre<span>Review operational alerts</span></Link><Link to="/devices">Equipment<span>Manage connected devices</span></Link></div></Panel></section>
      </div>
    </div>
  </>;
}
