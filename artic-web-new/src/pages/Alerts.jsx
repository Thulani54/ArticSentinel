// Notifications — live alerts from the backend with acknowledge/resolve
// actions. Endpoints mirror lib/screens/alert.dart.

import { useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, Panel, Spinner, formatAgo } from '../components/bits';
import { useNow } from '../components/bits';

const SEV = {
  critical: { cls: 'crit', label: 'Critical' },
  high: { cls: 'warn', label: 'High' },
  medium: { cls: 'neutral', label: 'Medium' },
  low: { cls: 'good', label: 'Low' },
};

const STATUS = {
  active: { cls: 'crit', label: 'Active' },
  acknowledged: { cls: 'warn', label: 'Acknowledged' },
  resolved: { cls: 'good', label: 'Resolved' },
  false_positive: { cls: 'neutral', label: 'False positive' },
};

const STATUS_FILTERS = ['', 'active', 'acknowledged', 'resolved', 'false_positive'];

export default function Alerts() {
  const { token, business } = useAuth();
  const now = useNow();
  const [stats, setStats] = useState(null);
  const [alerts, setAlerts] = useState(null);
  const [status, setStatus] = useState('');
  const [severity, setSeverity] = useState('');
  const [busyId, setBusyId] = useState(null);
  const [error, setError] = useState(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const [s, list] = await Promise.all([
        api.post('/alerts/statistics/', { business_id: business.business_uid }, token),
        api.post(
          '/alerts/list/',
          {
            business_id: business.business_uid,
            page: 1,
            page_size: 50,
            ...(status && { status }),
            ...(severity && { severity }),
          },
          token,
        ),
      ]);
      setStats(s);
      setAlerts(list.alerts ?? []);
    } catch (e) {
      setError(e.message);
    }
  }, [token, business, status, severity]);

  useEffect(() => {
    load();
  }, [load]);

  async function act(alert, action) {
    setBusyId(alert.id);
    try {
      await api.post(`/alerts/${action}/`, { business_id: business.business_uid, alert_id: alert.id }, token);
      await load();
    } catch (e) {
      window.alert(`Failed to ${action} alert: ${e.message}`);
    } finally {
      setBusyId(null);
    }
  }

  const tiles = useMemo(() => {
    if (!stats) return null;
    return [
      { label: 'Total', v: stats.total, cls: '' },
      { label: 'Active', v: stats.active, cls: 'accent-flame' },
      { label: 'Acknowledged', v: stats.acknowledged, cls: '' },
      { label: 'Resolved', v: stats.resolved, cls: '' },
      { label: 'Last 24h', v: stats.recent_24h, cls: '' },
    ];
  }, [stats]);

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Monitoring</div>
          <h1 className="page-title">Notifications</h1>
          <p className="page-sub">Temperature and equipment alerts across your fleet.</p>
        </div>
        <div className="seg" role="tablist" aria-label="Status filter">
          {STATUS_FILTERS.map((s) => (
            <button key={s || 'all'} className={s === status ? 'on' : ''} onClick={() => setStatus(s)}>
              {s || 'All'}
            </button>
          ))}
        </div>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!stats && !error && <Spinner />}

      {tiles && (
        <div className="tiles">
          {tiles.map((t) => (
            <div key={t.label} className={`tile ${t.cls}`}>
              <div className="eyebrow">{t.label}</div>
              <div className="v">{t.v}</div>
            </div>
          ))}
        </div>
      )}

      {stats && (
        <Panel
          title={`Alerts ${status ? `— ${status.replace('_', ' ')}` : ''}`}
          actions={
            <div className="seg" role="tablist" aria-label="Severity filter">
              {['', 'critical', 'high', 'medium', 'low'].map((s) => (
                <button key={s || 'all'} className={s === severity ? 'on' : ''} onClick={() => setSeverity(s)}>
                  {s || 'All sev'}
                </button>
              ))}
            </div>
          }
        >
          {!alerts && <Spinner />}
          {alerts && alerts.length === 0 && <Empty>No alerts match this filter.</Empty>}
          {alerts &&
            alerts.map((a) => {
              const sev = SEV[a.severity] ?? SEV.medium;
              const st = STATUS[a.status] ?? STATUS.active;
              return (
                <div className="alert-row" key={a.id}>
                  <div className={`ico chip ${sev.cls}`}>{a.severity === 'critical' ? '!' : '•'}</div>
                  <div style={{ minWidth: 0 }}>
                    <div className="t">{a.title}</div>
                    <div className="d">
                      {a.device_name} · triggered {formatAgo(new Date(a.triggered_at), now)}
                      {a.email_sent ? ' · email sent' : ''}
                    </div>
                  </div>
                  <div className="when" style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                    <span className={`chip ${sev.cls}`}>{sev.label}</span>
                    <span className={`chip ${st.cls}`}>{st.label}</span>
                    {a.status === 'active' && (
                      <>
                        <button className="btn sm" disabled={busyId === a.id} onClick={() => act(a, 'acknowledge')}>
                          Acknowledge
                        </button>
                        <button className="btn sm primary" disabled={busyId === a.id} onClick={() => act(a, 'resolve')}>
                          Resolve
                        </button>
                      </>
                    )}
                    {a.status === 'acknowledged' && (
                      <button className="btn sm primary" disabled={busyId === a.id} onClick={() => act(a, 'resolve')}>
                        Resolve
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
        </Panel>
      )}
    </>
  );
}
