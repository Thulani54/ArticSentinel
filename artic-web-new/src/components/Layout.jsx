import { useEffect, useRef, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import Brand from './Brand';

function FlameMark() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M12 2.5c3.2 4.2 6.5 7.9 6.5 12.4a6.5 6.5 0 1 1-13 0C5.5 10.4 8.8 6.7 12 2.5z"
        fill="#EA580C"
      />
    </svg>
  );
}

function HamburgerIcon() {
  return (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M4 6.5h16M4 12h16M4 17.5h16" />
    </svg>
  );
}

function GaugeIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <rect x="8" y="7" width="8" height="14" rx="2.5" />
      <path d="M10 7V4.5h4V7" />
    </svg>
  );
}

function GridIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <rect x="3.5" y="3.5" width="7" height="7" rx="1.5" />
      <rect x="13.5" y="3.5" width="7" height="7" rx="1.5" />
      <rect x="3.5" y="13.5" width="7" height="7" rx="1.5" />
      <rect x="13.5" y="13.5" width="7" height="7" rx="1.5" />
    </svg>
  );
}

function ChartIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M4 20V10M10 20V4M16 20v-7M21 20H3.5" />
    </svg>
  );
}

function ChatIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 12a8 8 0 0 1-8 8H4.5L3 21l1-3.6A8 8 0 1 1 21 12z" />
      <path d="M8.5 10.5h7M8.5 14h4.5" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6" />
      <path d="M10 19a2.2 2.2 0 0 0 4 0" />
    </svg>
  );
}

function WrenchIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M14.7 6.3a4.5 4.5 0 0 0-6 5.6L3 17.6V21h3.4l5.7-5.7a4.5 4.5 0 0 0 5.6-6l-3 3-2.8-.7-.7-2.8 3.5-2.5z" />
    </svg>
  );
}

function DocIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M14 3H7a1.5 1.5 0 0 0-1.5 1.5v15A1.5 1.5 0 0 0 7 21h10a1.5 1.5 0 0 0 1.5-1.5V7.5L14 3z" />
      <path d="M14 3v4.5h4.5M9 13h6M9 17h6" />
    </svg>
  );
}

function BoltIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M13 3 5 13.5h5.5L11 21l8-10.5h-5.5L13 3z" />
    </svg>
  );
}

function PeopleIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3.5 20c.6-3.2 2.8-5 5.5-5s4.9 1.8 5.5 5" />
      <circle cx="16.8" cy="9" r="2.4" />
      <path d="M16.5 14.6c2.2.3 3.6 1.8 4 4.4" />
    </svg>
  );
}

function GearIcon() {
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <circle cx="12" cy="12" r="3.2" />
      <path d="M12 3.5v2.2M12 18.3v2.2M3.5 12h2.2M18.3 12h2.2M6 6l1.6 1.6M16.4 16.4 18 18M18 6l-1.6 1.6M7.6 16.4 6 18" />
    </svg>
  );
}

// Same order as the Flutter drawer (layouts/main_layout.dart).
const NAV_ITEMS = [
  { to: '/', end: true, icon: <GridIcon />, label: 'Dashboard' },
  { to: '/performance', icon: <ChartIcon />, label: 'Device Performance' },
  { to: '/units', icon: <GaugeIcon />, label: 'Unit Management' },
  { to: '/communication', icon: <ChatIcon />, label: 'Communications' },
  { to: '/devices', icon: <GaugeIcon />, label: 'Device Management' },
  { to: '/control', icon: <BoltIcon />, label: 'Control' },
  { to: '/reports', icon: <DocIcon />, label: 'Reports' },
  { to: '/alerts', icon: <BellIcon />, label: 'Notifications' },
  { to: '/maintenance', icon: <WrenchIcon />, label: 'Maintenance' },
  { to: '/access', icon: <PeopleIcon />, label: 'Access Management' },
  { to: '/settings', icon: <GearIcon />, label: 'Settings' },
];

export default function Layout() {
  const { business, user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [open, setOpen] = useState(false);
  const [mobile, setMobile] = useState(() => window.matchMedia('(max-width: 1050px)').matches);
  const drawer = useRef(null);
  const trigger = useRef(null);
  const current = NAV_ITEMS.find(item => item.to === location.pathname)?.label || 'Equipment details';
  useEffect(() => {
    const query = window.matchMedia('(max-width: 1050px)');
    const change = () => { setMobile(query.matches); setOpen(false); };
    query.addEventListener('change', change);
    return () => query.removeEventListener('change', change);
  }, []);
  useEffect(() => { setOpen(false); }, [location.pathname]);
  useEffect(() => { document.title = `${current} | ArticSentinel`; }, [current]);
  useEffect(() => {
    if (!open || !mobile) return;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    drawer.current.querySelector('button, a')?.focus();
    const onKey = (event) => {
      if (event.key === 'Escape') setOpen(false);
      if (event.key === 'Tab') {
        const controls = drawer.current.querySelectorAll('a, button');
        const first = controls[0], last = controls[controls.length - 1];
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
      }
    };
    window.addEventListener('keydown', onKey);
    return () => {
      document.body.style.overflow = previous;
      window.removeEventListener('keydown', onKey);
      trigger.current?.focus();
    };
  }, [open, mobile]);
  const identity = user?.firstname || user?.first_name || user?.username || user?.email || 'Account';
  return (
    <div className="shell">
      <a className="skip-link" href="#main-content">Skip to content</a>
      <header className="topbar">
        <button ref={trigger} className="hamburger" aria-label="Open menu" aria-expanded={open} aria-controls="workspace-navigation" onClick={() => setOpen(true)}><HamburgerIcon /></button>
        <div className="breadcrumb"><span>Workspace</span><span aria-hidden="true">/</span><strong>{current}</strong></div>
        <div className="tb-user"><span className="biz">{business?.business_name || 'Your workspace'}</span><NavLink to="/alerts" className="header-alert" aria-label="Notifications"><BellIcon /></NavLink><NavLink to="/settings" className="avatar" aria-label="Account settings">{identity.slice(0, 2).toUpperCase()}</NavLink></div>
      </header>
      <div className={`drawer-veil ${open ? 'open' : ''}`} onClick={() => setOpen(false)} aria-hidden="true" />
      <aside ref={drawer} id="workspace-navigation" className={`drawer ${open ? 'open' : ''}`} role={mobile ? 'dialog' : undefined} aria-modal={mobile && open ? true : undefined} aria-label="Workspace navigation" aria-hidden={mobile && !open} inert={mobile && !open ? '' : undefined}>
        <div className="brand"><Brand /><button className="drawer-close" aria-label="Close menu" onClick={() => setOpen(false)}>×</button></div>
        <div className="workspace-label"><span className="workspace-symbol">S</span><div><strong>{business?.business_name || 'Your workspace'}</strong><small>Monitoring workspace</small></div></div>
        <nav className="nav" aria-label="Main navigation">
          {NAV_ITEMS.map((item, index) => <div key={item.to}>
            {[0, 3, 9].includes(index) && <p className="nav-group">{index === 0 ? 'Monitor' : index === 3 ? 'Operations' : 'Workspace'}</p>}
            <NavLink to={item.to} end={item.end} className={({ isActive }) => isActive ? 'active' : ''}>{item.icon}<span>{item.label}</span></NavLink>
          </div>)}
        </nav>
        <div className="sidebar-foot"><div className="account-line"><span className="avatar">{identity.slice(0, 2).toUpperCase()}</span><div><div className="biz">{identity}</div><div className="usr">{user?.email || 'Workspace member'}</div></div></div><button className="signout" onClick={() => { logout(); navigate('/login'); }}>Sign out <span aria-hidden="true">↗</span></button></div>
      </aside>
      <main className="content" id="main-content" tabIndex={-1}><Outlet /><footer className="workspace-footer"><span>ArticSentinel</span><span>Cold-chain & gas monitoring</span></footer></main>
    </div>
  );
}
