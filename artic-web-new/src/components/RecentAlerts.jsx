// Latest active alerts for the dashboard (the production dashboard's
// "Recent Warnings"), newest first, linking through to Notifications.

import { Link } from 'react-router-dom';
import { Panel } from './bits';

const SEVERITY = {
  critical: { cls: 'crit', label: 'Critical' },
  high: { cls: 'crit', label: 'High' },
  medium: { cls: 'warn', label: 'Medium' },
  low: { cls: 'neutral', label: 'Low' },
};

const clean = (s) => (s || '').replace(/^AI:\s*/, '');

function ago(iso) {
  const m = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (m < 60) return `${Math.max(m, 1)}m ago`;
  const h = Math.round(m / 60);
  return h < 48 ? `${h}h ago` : `${Math.round(h / 24)}d ago`;
}

export default function RecentAlerts({ alerts, total, error }) {
  return (
    <Panel
      className="mt16"
      eyebrow={total != null ? `${total} active` : 'Latest'}
      title="Recent alerts"
      actions={<Link to="/alerts" className="btn sm">View all</Link>}
    >
      {error ? (
        <p className="form-err">Alerts could not load: {error}</p>
      ) : !alerts ? (
        <p className="hint">Loading alerts…</p>
      ) : alerts.length === 0 ? (
        <div className="alerts-clear">
          <strong>No active alerts</strong>
          <span>All systems operating normally.</span>
        </div>
      ) : (
        <ul className="recent-alerts">
          {alerts.map((a) => {
            const sev = SEVERITY[a.severity] || SEVERITY.low;
            return (
              <li key={a.id}>
                <span className={`chip ${sev.cls}`}>{sev.label}</span>
                <div className="ra-body">
                  <strong>{clean(a.title) || 'Alert'}</strong>
                  <span>{a.device_name || 'Device'}{a.message ? ` · ${a.message}` : ''}</span>
                </div>
                <time dateTime={a.triggered_at}>{a.triggered_at ? ago(a.triggered_at) : ''}</time>
              </li>
            );
          })}
        </ul>
      )}
    </Panel>
  );
}
