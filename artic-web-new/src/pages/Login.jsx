import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import Brand from '../components/Brand';

function ColdRoom() {
  return <svg className="cold-room" viewBox="0 0 600 330" fill="none" role="img" aria-label="Illustration of connected cold-storage equipment">
    <path d="m48 246 268 71 240-110-268-62L48 246Z" fill="#C9E0EA"/>
    <path d="m106 98 235 49v137l-235-56V98Z" fill="#EDF5F8"/><path d="m341 147 163-77v137l-163 77V147Z" fill="#9CBFCF"/><path d="m106 98 166-68 232 40-163 77-235-49Z" fill="#FFFFFF"/>
    <path d="m130 116 77 17v117l-77-18V116Zm93 20 91 20v117l-91-21V136Z" fill="#D7E7EE" stroke="#ADCBD8" strokeWidth="2"/><path d="m151 133 38 8v91l-38-9v-90Z" fill="#C0D8E4"/><path d="m241 153 55 12v88l-55-13v-87Z" fill="#C0D8E4"/><path d="m197 186 0 18m108 6v18" stroke="#426C81" strokeWidth="4" strokeLinecap="round"/>
    <path d="m365 153 117-55v97l-117 58V153Z" fill="#81A9BE"/>{[0,1,2,3,4,5].map(i=><path key={i} d={`m377 ${161+i*12} 91-43`} stroke="#ACCBD9" strokeWidth="3"/>)}
    <path d="m264 54 74 13 39-18-73-12-40 17Z" fill="#DCEBF1"/><path d="m264 54 74 13v20l-74-15V54Z" fill="#92B7C9"/><path d="m338 67 39-18v20l-39 18V67Z" fill="#648FA6"/>
    <circle cx="327" cy="131" r="6" fill="#176BBA"/><circle cx="327" cy="131" r="13" stroke="#176BBA" strokeOpacity=".3" strokeWidth="2"/><path d="M327 118V94l78-38V25" stroke="#176BBA" strokeWidth="1.5" strokeDasharray="4 4"/><rect x="381" y="4" width="49" height="25" rx="7" fill="#176BBA"/><path d="m391 17 6-5 5 8 6-11 5 7h7" stroke="white" strokeWidth="1.5"/>
  </svg>;
}

export default function Login() {
  const { auth, login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  if (auth) return <Navigate to="/" replace />;
  async function onSubmit(event) {
    event.preventDefault(); setBusy(true); setError(null);
    try { await login(email.trim(), password); navigate('/', { replace: true }); }
    catch (err) { setError(err.message || 'Unable to sign in. Check your email and password.'); }
    finally { setBusy(false); }
  }
  return <main className="login-wrap">
    <section className="login-story"><Brand /><div className="login-story-body"><div className="story-tag"><span /> Cold-chain & gas monitoring</div><h1>A clear view of<br />what matters.</h1><p>Your equipment. Your temperatures. Your gas supply.<br />One workspace to keep operations in sight.</p><ColdRoom /><div className="story-features"><span>Temperature tracking</span><span>Gas monitoring</span><span>Equipment control</span></div></div><div className="story-footer">Built for the people who keep things running.</div></section>
    <section className="login-form-side"><div className="login-mobile-brand"><Brand /></div><form className="login-card" onSubmit={onSubmit} aria-busy={busy}><div className="login-entry-icon" aria-hidden="true">↗</div><h2 className="login-title">Welcome back</h2><p className="login-sub">Sign in to your monitoring workspace.</p>
      {error && <div className="form-err" role="alert">{error}</div>}
      <label htmlFor="email">Email address</label><input id="email" type="email" placeholder="you@company.com" value={email} autoComplete="username" onChange={e=>setEmail(e.target.value)} required />
      <label htmlFor="password">Password</label><div className="password-field"><input id="password" type={showPassword ? 'text' : 'password'} placeholder="Enter your password" value={password} autoComplete="current-password" onChange={e=>setPassword(e.target.value)} required /><button type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} aria-pressed={showPassword} onClick={()=>setShowPassword(v=>!v)}>{showPassword ? 'Hide' : 'Show'}</button></div>
      <button className="btn primary login-submit" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}<span aria-hidden="true">↗</span></button><p className="login-help">Need access? Contact your workspace administrator.</p>
    </form><footer className="login-foot">© {new Date().getFullYear()} ArticSentinel<span>Equipment intelligence, made clear.</span></footer></section>
  </main>;
}
