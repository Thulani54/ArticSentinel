import {useEffect,useRef,useState} from 'react';
import {useAuth} from '../auth';
import {api} from '../api';
import Modal from './Modal';
import {assignedClientId} from '../lib/deviceIdentity';
import {isFreshSetupReading} from '../lib/gas/scaleSetup';
import './scale-connect.css';

async function setupRequest(path,body,token){
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),15000);
  try{return await api.post(path,body,token,{signal:controller.signal});}
  catch(error){if(error.name==='AbortError')throw new Error('The connection check timed out. Check your internet connection and retry.');throw error;}
  finally{clearTimeout(timer);}
}

export default function ScaleConnectPanel({device,open,onOpen,onClose}) {
  return <>
    <section className="scale-connect-callout" aria-label="Scale setup"><div><strong>Connect your scale</strong><p>Choose your Wi-Fi in the phone app. This scale’s connection details are assigned automatically.</p></div><button className="btn" onClick={onOpen}>Connection guide</button></section>
    {open&&<Modal label="Connect your scale" onClose={onClose}><ScaleSetup key={device.id} device={device} onClose={onClose}/></Modal>}
  </>;
}

function ScaleSetup({device,onClose}) {
  const {business,token}=useAuth();
  const [step,setStep]=useState(0),[status,setStatus]=useState(null),[error,setError]=useState(''),[loading,setLoading]=useState(true),[retry,setRetry]=useState(0);
  const [watching,setWatching]=useState(false),[reading,setReading]=useState(null),[checking,setChecking]=useState(false),[timedOut,setTimedOut]=useState(false);
  const started=useRef(Date.now());
  const scope={business_id:business?.business_uid,device_id:device.id};
  useEffect(()=>{let active=true;setLoading(true);setError('');setupRequest('/gas/credentials/status/',scope,token).then(data=>{if(!active)return;if(data.mqtt_client_id!==assignedClientId(device.id))throw new Error('This scale’s connection ID could not be confirmed. Please retry.');setStatus(data);}).catch(e=>{if(active)setError(e.message);}).finally(()=>{if(active)setLoading(false);});return()=>{active=false;};},[device.id,business?.business_uid,token,retry]);
  useEffect(()=>{
    if(!watching)return;
    let active=true,timer;const deadline=Date.now()+180000;
    async function check(){
      if(!active)return;
      setChecking(true);
      try{
        const data=await setupRequest('/gas/readings/',{...scope,days:1},token);
        if(!active)return;
        setError('');
        if(isFreshSetupReading(data.latest,started.current,Date.now())){setReading(data.latest);setWatching(false);return;}
      }catch(e){if(active)setError(e.message);}
      finally{if(active)setChecking(false);}
      if(!active)return;
      if(Date.now()>=deadline){setTimedOut(true);setWatching(false);return;}
      timer=setTimeout(check,5000);
    }
    check();return()=>{active=false;clearTimeout(timer);};
  },[watching,device.id,business?.business_uid,token]);
  return <section className="scale-setup-modal">
    <header><div><span>{device.name} · {device.device_id}</span><h2>Connect your scale</h2></div><button className="btn" aria-label="Close scale setup" onClick={onClose}>Close</button></header>
    <ol className="scale-setup-steps" aria-label="Setup progress">{['Your scale','Wi-Fi','Live reading'].map((label,i)=><li key={label} aria-current={i===step?'step':undefined}><span>{i+1}</span>{label}</li>)}</ol>
    <div className="scale-setup-body">
      {error&&<div className="form-err" role="alert">{error}{step===0&&<button className="btn" onClick={()=>setRetry(x=>x+1)}>Retry connection check</button>}</div>}
      {step===0&&<>
        <svg className="scale-setup-art" viewBox="0 0 180 120" fill="none" aria-hidden="true"><rect x="30" y="90" width="120" height="18" rx="8" fill="var(--ink)"/><rect x="62" y="25" width="56" height="65" rx="20" fill="var(--panel)" stroke="#d76616" strokeWidth="3"/><path d="M72 25v-9h36v9M80 9h20" stroke="#d76616" strokeWidth="4" strokeLinecap="round"/><path d="m79 59 8 8 15-18" stroke="#158367" strokeWidth="4" strokeLinecap="round"/></svg>
        <h3>Your connection is assigned for you</h3><p>No client ID, topic or server password to type. Setup uses a separate login for this scale.</p>
        {loading?<p role="status">Checking your registered scale…</p>:status&&<p className="scale-setup-ready">✓ {device.device_id} is ready for setup</p>}
        <p className="ink2">Keep the scale powered on and put it in Bluetooth setup mode. Stay close to it.</p>
        <details><summary>Connection information</summary><dl><dt>Connection ID</dt><dd>{status?.mqtt_client_id||'Checking…'}</dd><dt>Reading topic</dt><dd>{status?.topic||'Checking…'}</dd></dl><p>The ID is a label, not a password. Device passwords stay separate and are sent by the phone app during setup.</p></details>
      </>}
      {step===1&&<>
        <h3>Choose Wi-Fi in the Artic Sentinel app</h3><p>Sign in to the same company on your Android phone or iPhone.</p>
        <ol className="scale-setup-instructions"><li>Open <strong>Equipment → {device.name} → Connect scale</strong>.</li><li>Find the nearby scale. Enter its setup code if the label has one.</li><li>Choose your <strong>2.4 GHz Wi-Fi</strong>, enter the Wi-Fi password and tap <strong>Connect scale</strong>.</li></ol>
        <p>The app sends Wi-Fi, the assigned ID, the reading topic and this scale’s private login together.</p>
        <div className="scale-setup-note">Bluetooth setup runs in the installed phone app. This website guides you and checks for the new reading; it does not send your Wi-Fi password.</div>
        <details><summary>Using an older scale?</summary><p>Firmware must accept and save the connection settings sent by the app. Older versions may need one update from your installer. You do not need different firmware or a manually entered client ID for each customer.</p></details>
      </>}
      {step===2&&<>
        <h3>{reading?'Your scale is reporting':'Check for a new reading'}</h3>
        {reading?<div className="scale-setup-ready" role="status"><strong>{Number(reading.gross_kg).toFixed(2)} kg</strong><p>New scale reading received at {new Date(reading.time).toLocaleTimeString()}.</p></div>:<>
          <p>Finish setup in the phone app, then check here. A reading from before you opened setup will not count.</p>
          {watching&&<p role="status">{checking?'Checking the scale…':'Waiting for a new reading…'} We check every five seconds for up to three minutes.</p>}
          {timedOut&&<p className="scale-setup-note">No new reading yet. Check power, Wi-Fi and the setup result in the phone app. If the scale cannot save automatic settings, contact your installer for a firmware update.</p>}
          <button className="btn primary" disabled={watching} onClick={()=>{setTimedOut(false);setError('');setWatching(true);}}>{watching?'Checking connection…':'Check live connection'}</button>
        </>}
      </>}
    </div>
    <footer>{step>0&&<button className="btn" onClick={()=>{setWatching(false);setStep(x=>x-1);}}>Back</button>}{step<2?<button className="btn primary" disabled={step===0&&(!status||loading||!!error)} onClick={()=>{if(step===0)started.current=Date.now();setError('');setStep(x=>x+1);}}>Continue</button>:<button className="btn" onClick={onClose}>{reading?'Done':'Close setup'}</button>}</footer>
  </section>;
}
