import Modal from '../components/Modal';
// Maintenance — dashboard summary, records table and scheduling against the
// api/maintenance/* endpoints (mirrors lib/screens/maintanance.dart core).

import { useCallback, useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { Empty, Panel, Spinner, fmtDay } from '../components/bits';

const STATUS_CLS = {
  overdue: 'crit',
  pending: 'warn',
  scheduled: 'warn',
  in_progress: 'neutral',
  completed: 'good',
  cancelled: 'neutral',
};
const PRIORITIES = ['low', 'medium', 'high', 'critical'];
const STATUS_CHOICES = ['pending', 'scheduled', 'in_progress', 'completed', 'cancelled'];

function toLocalInput(d) {
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
}

function ScheduleForm({ devices, types, users, onDone, onCancel }) {
  const { token, business } = useAuth();
  const [form, setForm] = useState({
    device_id: devices[0] ? String(devices[0].id) : '',
    maintenance_type_id: types[0]?.id ?? '',
    scheduled_date: toLocalInput(new Date(Date.now() + 86400000)),
    work_description: '',
    status: 'pending',
    priority: 'medium',
    assigned_to_id: '',
    estimated_cost: '',
    estimated_duration_hours: '',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function onSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const payload = {
      device_id: Number(form.device_id),
      maintenance_type_id: form.maintenance_type_id,
      scheduled_date: new Date(form.scheduled_date).toISOString(),
      work_description: form.work_description,
      status: form.status,
      priority: form.priority,
      ...(form.assigned_to_id && { assigned_to_id: Number(form.assigned_to_id) }),
      ...(form.estimated_cost && { estimated_cost: Number(form.estimated_cost) }),
      ...(form.estimated_duration_hours && { estimated_duration_hours: Number(form.estimated_duration_hours) }),
    };
    try {
      await api.post('/maintenance/create/', payload, token);
      onDone();
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }

  return (
    <Modal onClose={onCancel} label="Schedule maintenance">
      <div className="modal">
        <h3>Schedule maintenance</h3>
        {error && <div className="form-err">{error}</div>}
        <form onSubmit={onSubmit}>
          <div className="form-grid">
            <div>
              <label htmlFor="maintenance-field-1">Device *</label>
              <select id="maintenance-field-1" value={form.device_id} onChange={set('device_id')} required>
                {devices.map((d) => (
                  <option key={d.id} value={String(d.id)}>{d.name} ({d.device_id})</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="maintenance-field-2">Maintenance type *</label>
              <select id="maintenance-field-2" value={form.maintenance_type_id} onChange={set('maintenance_type_id')} required>
                {types.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="maintenance-field-3">Scheduled date &amp; time *</label>
              <input id="maintenance-field-3" type="datetime-local" value={form.scheduled_date} onChange={set('scheduled_date')} required />
            </div>
            <div>
              <label htmlFor="maintenance-field-4">Assign to</label>
              <select id="maintenance-field-4" value={form.assigned_to_id} onChange={set('assigned_to_id')}>
                <option value="">— Unassigned —</option>
                {users.map((u) => (
                  <option key={u.id} value={String(u.id)}>{u.full_name || u.username}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="maintenance-field-5">Priority</label>
              <select id="maintenance-field-5" value={form.priority} onChange={set('priority')}>
                {PRIORITIES.map((p) => <option key={p} value={p}>{p[0].toUpperCase() + p.slice(1)}</option>)}
              </select>
            </div>
            <div>
              <label htmlFor="maintenance-field-6">Status</label>
              <select id="maintenance-field-6" value={form.status} onChange={set('status')}>
                {STATUS_CHOICES.map((s) => <option key={s} value={s}>{s.replace('_', ' ')}</option>)}
              </select>
            </div>
            <div>
              <label htmlFor="maintenance-field-7">Estimated cost (R)</label>
              <input id="maintenance-field-7" type="number" step="any" value={form.estimated_cost} onChange={set('estimated_cost')} />
            </div>
            <div>
              <label htmlFor="maintenance-field-8">Estimated hours</label>
              <input id="maintenance-field-8" type="number" step="any" value={form.estimated_duration_hours} onChange={set('estimated_duration_hours')} />
            </div>
            <div className="full">
              <label htmlFor="maintenance-field-9">Work description</label>
              <textarea id="maintenance-field-9"
                value={form.work_description}
                onChange={set('work_description')}
                rows={3}
                style={{ width: '100%', border: '1px solid var(--border)', borderRadius: 8, padding: '9px 12px', font: 'inherit' }}
              />
            </div>
          </div>
          <div className="foot">
            <button type="button" className="btn" onClick={onCancel}>Cancel</button>
            <button className="btn primary" disabled={busy}>{busy ? 'Scheduling…' : 'Schedule'}</button>
          </div>
        </form>
      </div>
    </Modal>
  );
}

export default function Maintenance() {
  const { token, business } = useAuth();
  const { devices } = useDevices();
  const [dash, setDash] = useState(null);
  const [records, setRecords] = useState(null);
  const [types, setTypes] = useState([]);
  const [users, setUsers] = useState([]);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const bid = business.business_uid;

  const refresh = useCallback(async () => {
    setError(null);
    try {
      const end = new Date();
      const start = new Date(end.getTime() - 30 * 86400000);
      const [d, list] = await Promise.all([
        api.post(
          '/maintenance/dashboard/',
          { business_id: bid, start_date: start.toISOString().slice(0, 10), end_date: end.toISOString().slice(0, 10) },
          token,
        ),
        api.post('/maintenance/list/', { business_id: bid }, token),
      ]);
      setDash(d.dashboard ?? null);
      setRecords(list.maintenance_records ?? []);
    } catch (e) {
      setError(e.message);
    }
  }, [token, bid]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  useEffect(() => {
    (async () => {
      try {
        const [t, u] = await Promise.all([
          api.get(`/maintenance/types/?business_id=${bid}`, token),
          api.get(`/maintenance/assignable-users/?business_id=${bid}`, token),
        ]);
        setTypes(t.maintenance_types ?? []);
        setUsers(u.users ?? []);
      } catch {
        /* form falls back to minimal options */
      }
    })();
  }, [token, bid]);

  const s = dash?.summary ?? {};

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Servicing</div>
          <h1 className="page-title">Maintenance</h1>
          <p className="page-sub">Planned servicing, repairs and their outcomes.</p>
        </div>
        <button className="btn flame" onClick={() => setShowForm(true)} disabled={!devices?.length || !types.length}>
          + Schedule maintenance
        </button>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!dash && !error && <Spinner />}

      {dash && (
        <>
          <div className="tiles">
            <div className="tile">
              <div className="eyebrow">Total (30d)</div>
              <div className="v">{s.total_maintenance ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Completed</div>
              <div className="v" style={{ color: 'var(--good)' }}>{s.completed_maintenance ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Pending</div>
              <div className="v" style={{ color: 'var(--warn)' }}>{s.pending_maintenance ?? 0}</div>
            </div>
            <div className="tile accent-flame">
              <div className="eyebrow">Overdue</div>
              <div className="v">{s.overdue_maintenance ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Completion rate</div>
              <div className="v">{s.completion_rate ?? 0}<span className="unit">%</span></div>
            </div>
          </div>

          <Panel title="Records">
            {!records && <Spinner />}
            {records && records.length === 0 && <Empty>No maintenance records yet — schedule the first service.</Empty>}
            {records && records.length > 0 && (
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Device</th>
                      <th>Type</th>
                      <th>Scheduled</th>
                      <th>Priority</th>
                      <th>Assigned</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {records.map((r) => (
                      <tr key={r.id}>
                        <td style={{ fontWeight: 600 }}>{r.device?.name ?? '—'}</td>
                        <td className="ink2">{r.maintenance_type?.name ?? '—'}</td>
                        <td className="ink2">{r.scheduled_date ? fmtDay(new Date(r.scheduled_date)) : '—'}</td>
                        <td className="ink2">{r.priority_display ?? r.priority}</td>
                        <td className="ink2">{r.assigned_to?.username || 'Unassigned'}</td>
                        <td>
                          <span className={`chip ${STATUS_CLS[r.status] ?? 'neutral'}`}>
                            {(r.status_display ?? r.status ?? '').toString().replace('_', ' ')}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Panel>
        </>
      )}

      {showForm && (
        <ScheduleForm
          devices={devices ?? []}
          types={types}
          users={users}
          onCancel={() => setShowForm(false)}
          onDone={() => {
            setShowForm(false);
            refresh();
          }}
        />
      )}
    </>
  );
}
