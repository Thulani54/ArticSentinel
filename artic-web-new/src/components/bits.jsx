// Small shared UI pieces: panels, chips, tiles, formatters.

import { useEffect, useState } from 'react';

export function Panel({ title, eyebrow, actions, children, className = '' }) {
  return (
    <section className={`panel ${className}`}>
      {(title || actions) && (
        <div className="panel-head">
          <div>
            {eyebrow && <div className="eyebrow">{eyebrow}</div>}
            {title && <h3 className="panel-title">{title}</h3>}
          </div>
          {actions}
        </div>
      )}
      {children}
    </section>
  );
}

export function PresenceChip({ online, lastSeen }) {
  return (
    <span className={`chip ${online ? 'good' : 'crit'}`}>
      <span className="dot" />
      {online ? 'Online' : 'Offline'}
      {lastSeen != null && <span style={{ fontWeight: 500 }}>· {lastSeen}</span>}
    </span>
  );
}

export function BandChip({ band }) {
  const map = {
    healthy: { cls: 'good', label: 'Healthy' },
    warning: { cls: 'warn', label: 'Warning' },
    low: { cls: 'crit', label: 'Low gas' },
  };
  const { cls, label } = map[band] ?? { cls: 'neutral', label: 'Unknown' };
  return <span className={`chip ${cls}`}>{label}</span>;
}

export function Spinner() {
  return <div className="spinner" role="status" aria-label="Loading" />;
}

export function Empty({ children }) {
  return <div className="empty">{children}</div>;
}

// "3h ago" style stamps, mirroring formatAgo in gas_widgets.dart.
export function formatAgo(date, now = new Date()) {
  const s = Math.max(0, Math.floor((now - date) / 1000));
  if (s < 60) return 'just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return date.toLocaleDateString(undefined, { day: 'numeric', month: 'short' });
}

export const fmtDay = (d) => d.toLocaleDateString(undefined, { day: 'numeric', month: 'short' });

// Recharts tick formatter — compact axis dates.
export const compactTick = (ms) => {
  const d = new Date(ms);
  return `${d.getDate()}/${d.getMonth() + 1}`;
};

// Ticking clock so "x ago" strings stay honest on long-lived pages.
export function useNow(intervalMs = 60000) {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), intervalMs);
    return () => clearInterval(id);
  }, [intervalMs]);
  return now;
}
