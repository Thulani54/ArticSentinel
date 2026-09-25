// Communications — the Flutter app's CommunicationDashboard (the "chat"
// section): messaging overview, providers, templates, logs, OTP and queues.

import { useCallback, useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, Panel, Spinner, formatAgo } from '../components/bits';

const TABS = ['Overview', 'Providers', 'Templates', 'Logs', 'OTP', 'Queues'];

const stripHtml = (s) =>
  (s ?? '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();

const STATUS_CLS = { sent: 'good', delivered: 'good', failed: 'crit', pending: 'warn', queued: 'warn' };

function statusChip(status, display) {
  return <span className={`chip ${STATUS_CLS[status] ?? 'neutral'}`}>{display ?? status}</span>;
}

export default function Communication() {
  const { token } = useAuth();
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [tab, setTab] = useState('Overview');

  const refresh = useCallback(async () => {
    setError(null);
    try {
      const [stats, providers, templates, logs, otp, queues] = await Promise.all([
        api.get('/communication/stats/', token),
        api.get('/communication/providers/', token),
        api.get('/communication/templates/', token),
        api.get('/communication/logs/?per_page=50', token),
        api.get('/communication/otp/?per_page=50', token),
        api.get('/communication/queues/', token),
      ]);
      setData({
        totals: stats.totals ?? {},
        providers: providers.providers ?? [],
        templates: templates.templates ?? [],
        logs: logs.logs ?? [],
        otp: otp.otp_codes ?? [],
        queues: queues.queues ?? [],
      });
    } catch (e) {
      setError(e.message);
    }
  }, [token]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Messaging</div>
          <h1 className="page-title">Communications</h1>
          <p className="page-sub">Monitor messaging systems and templates.</p>
        </div>
        <div className="seg">
          {TABS.map((t) => (
            <button key={t} className={t === tab ? 'on' : ''} onClick={() => setTab(t)}>
              {t}
            </button>
          ))}
        </div>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!data && !error && <Spinner />}

      {data && tab === 'Overview' && <Overview data={data} />}
      {data && tab === 'Providers' && <Providers data={data} />}
      {data && tab === 'Templates' && <Templates data={data} />}
      {data && tab === 'Logs' && <Logs data={data} />}
      {data && tab === 'OTP' && <Otp data={data} />}
      {data && tab === 'Queues' && <Queues data={data} />}
    </>
  );
}

function Overview({ data }) {
  const t = data.totals;
  return (
    <>
      <div className="tiles">
        <div className="tile">
          <div className="eyebrow">SMS sent</div>
          <div className="v">{t.sms_sent ?? 0}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">Emails sent</div>
          <div className="v">{t.email_sent ?? 0}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">OTP generated</div>
          <div className="v">{t.otp_generated ?? 0}</div>
        </div>
        <div className="tile">
          <div className="eyebrow">SMS failed</div>
          <div className="v" style={{ color: (t.sms_failed ?? 0) > 0 ? 'var(--crit)' : undefined }}>
            {t.sms_failed ?? 0}
          </div>
        </div>
      </div>

      <Panel title="Recent activity">
        {data.logs.length === 0 ? (
          <Empty>No recent activity — communication logs will appear here.</Empty>
        ) : (
          data.logs.slice(0, 5).map((log) => (
            <div className="alert-row" key={log.id}>
              <div className="ico" style={{ background: 'rgba(59,130,246,0.1)', color: 'var(--series)' }}>
                <ChatBubble />
              </div>
              <div style={{ minWidth: 0 }}>
                <div className="t">
                  {log.communication_type_display} — {statusChip(log.status, log.status_display)}
                </div>
                <div className="d" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {stripHtml(log.subject || log.message) || '—'}
                </div>
              </div>
              <div className="when">{log.created_at ? formatAgo(new Date(log.created_at)) : ''}</div>
            </div>
          ))
        )}
      </Panel>
    </>
  );
}

function ChatBubble() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <path d="M21 12a8 8 0 0 1-8 8H4.5L3 21l1-3.6A8 8 0 1 1 21 12z" />
    </svg>
  );
}

function Providers({ data }) {
  return (
    <Panel title={`Providers (${data.providers.length})`}>
      {data.providers.length === 0 ? (
        <Empty>No messaging providers configured.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Provider</th>
                <th>Type</th>
                <th>Sent</th>
                <th>Failed</th>
                <th>Success rate</th>
                <th>Cost / message</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {data.providers.map((p) => (
                <tr key={p.id ?? p.name}>
                  <td style={{ fontWeight: 600 }}>{p.name}</td>
                  <td className="ink2">{p.provider_type_display ?? p.provider_type}</td>
                  <td className="ink2">{p.total_sent ?? 0}</td>
                  <td className="ink2">{p.total_failed ?? 0}</td>
                  <td className="ink2">{p.success_rate ?? 0}%</td>
                  <td className="ink2">{p.cost_per_message != null ? `$${Number(p.cost_per_message).toFixed(4)}` : '—'}</td>
                  <td>
                    <span className={`chip ${p.is_active ? 'good' : 'crit'}`}>
                      {p.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  );
}

function Templates({ data }) {
  return (
    <Panel title={`Templates (${data.templates.length})`}>
      {data.templates.length === 0 ? (
        <Empty>No message templates defined.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Channel</th>
                <th>Subject</th>
                <th>Used</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {data.templates.map((tp) => (
                <tr key={tp.id}>
                  <td style={{ fontWeight: 600 }}>{tp.name}</td>
                  <td className="ink2">{tp.template_type_display ?? tp.template_type}</td>
                  <td className="ink2">{tp.communication_type_display ?? tp.communication_type}</td>
                  <td className="ink2" style={{ maxWidth: 260, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {tp.subject ? stripHtml(tp.subject) : '—'}
                  </td>
                  <td className="ink2">{tp.times_used ?? 0}×</td>
                  <td>{tp.is_default ? <span className="chip good">default</span> : null}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  );
}

function Logs({ data }) {
  return (
    <Panel title={`Message log (${data.logs.length})`}>
      {data.logs.length === 0 ? (
        <Empty>No messages sent yet.</Empty>
      ) : (
        data.logs.map((log) => (
          <div className="alert-row" key={log.id}>
            <div className="ico" style={{ background: 'rgba(59,130,246,0.1)', color: 'var(--series)' }}>
              <ChatBubble />
            </div>
            <div style={{ minWidth: 0 }}>
              <div className="t">
                {log.communication_type_display} · {statusChip(log.status, log.status_display)}
              </div>
              <div className="d">
                {log.subject ? <strong style={{ fontWeight: 600 }}>{stripHtml(log.subject)} — </strong> : null}
                {stripHtml(log.message).slice(0, 140) || '—'}
              </div>
              {log.error_message ? (
                <div className="d" style={{ color: 'var(--crit)' }}>Error: {log.error_message}</div>
              ) : null}
            </div>
            <div className="when">{log.created_at ? formatAgo(new Date(log.created_at)) : ''}</div>
          </div>
        ))
      )}
    </Panel>
  );
}

function Otp({ data }) {
  return (
    <Panel title={`OTP codes (${data.otp.length})`}>
      {data.otp.length === 0 ? (
        <Empty>No OTP codes generated recently.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Type</th>
                <th>Attempts</th>
                <th>Expires</th>
                <th>State</th>
              </tr>
            </thead>
            <tbody>
              {data.otp.map((o) => (
                <tr key={o.id}>
                  <td style={{ fontWeight: 600 }}>{o.user?.username ?? o.user?.email ?? '—'}</td>
                  <td className="ink2">{o.otp_type_display ?? o.otp_type}</td>
                  <td className="ink2">{o.attempts ?? 0}/{o.max_attempts ?? '—'}</td>
                  <td className="ink2">{o.expires_at ? new Date(o.expires_at).toLocaleString() : '—'}</td>
                  <td>
                    {o.is_used ? (
                      <span className="chip neutral">used</span>
                    ) : o.is_expired || o.is_valid === false ? (
                      <span className="chip crit">expired</span>
                    ) : (
                      <span className="chip good">valid</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  );
}

function Queues({ data }) {
  return (
    <Panel title={`Outbound queues (${data.queues.length})`}>
      {data.queues.length === 0 ? (
        <Empty>No queued messages.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Recipients</th>
                <th>Delivered</th>
                <th>Failed</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {data.queues.map((q) => (
                <tr key={q.id}>
                  <td style={{ fontWeight: 600 }}>{q.name}</td>
                  <td className="ink2">{q.total_recipients ?? 0}</td>
                  <td className="ink2">{q.successful_count ?? 0}</td>
                  <td className="ink2">{q.failed_count ?? 0}</td>
                  <td className="ink2">{q.priority_display ?? q.priority}</td>
                  <td>{statusChip(q.status, q.status_display)}</td>
                  <td className="ink2">{q.created_at ? new Date(q.created_at).toLocaleString() : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  );
}
