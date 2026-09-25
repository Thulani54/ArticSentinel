import Modal from '../components/Modal';
// Unit Management — refrigeration units from the units/management endpoints
// (mirrors lib/screens/units.dart's core CRUD).

import { useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, Panel, Spinner } from '../components/bits';

const STATUSES = ['operational', 'maintenance', 'decommissioned'];
const STATUS_CLS = { operational: 'good', maintenance: 'warn', decommissioned: 'neutral' };
const REFRIGERANTS = ['R134a', 'R404A', 'R290', 'R448A', 'R449A', 'R600a', 'Other'];

const EMPTY_FORM = {
  name: '',
  serial_number: '',
  model_number: '',
  year: new Date().getFullYear(),
  location: '',
  status: 'operational',
  refrigerant_type: 'R134a',
  compressor_type: '',
  compressor_model: '',
};

function UnitForm({ initial, onDone, onCancel }) {
  const { token, business } = useAuth();
  const [form, setForm] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const editing = initial.unit_id != null && initial.unit_id !== '';
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function onSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const payload = { ...form, year: Number(form.year) || new Date().getFullYear() };
    try {
      if (editing) {
        await api.post(
          '/units/management/update/',
          { ...payload, business_id: business.business_uid, unit_id: initial.unit_id },
          token,
        );
      } else {
        await api.post('/units/management/create/', { ...payload, business_id: business.business_uid }, token);
      }
      onDone();
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }

  return (
    <Modal onClose={onCancel} label="Unit details">
      <div className="modal">
        <h3>{editing ? `Edit ${initial.name}` : 'Add unit'}</h3>
        {error && <div className="form-err">{error}</div>}
        <form onSubmit={onSubmit}>
          <div className="form-grid">
            <div>
              <label htmlFor="units-field-1">Name *</label>
              <input id="units-field-1" value={form.name} onChange={set('name')} required />
            </div>
            <div>
              <label htmlFor="units-field-2">Serial number</label>
              <input id="units-field-2" value={form.serial_number} onChange={set('serial_number')} />
            </div>
            <div>
              <label htmlFor="units-field-3">Model number</label>
              <input id="units-field-3" value={form.model_number} onChange={set('model_number')} />
            </div>
            <div>
              <label htmlFor="units-field-4">Year</label>
              <input id="units-field-4" type="number" value={form.year ?? ''} onChange={set('year')} />
            </div>
            <div>
              <label htmlFor="units-field-5">Location</label>
              <input id="units-field-5" value={form.location} onChange={set('location')} />
            </div>
            <div>
              <label htmlFor="units-field-6">Status</label>
              <select id="units-field-6" value={form.status} onChange={set('status')}>
                {STATUSES.map((s) => (
                  <option key={s} value={s}>{s[0].toUpperCase() + s.slice(1)}</option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="units-field-7">Refrigerant type</label>
              <select id="units-field-7" value={form.refrigerant_type} onChange={set('refrigerant_type')}>
                {REFRIGERANTS.map((r) => <option key={r} value={r}>{r}</option>)}
              </select>
            </div>
            <div>
              <label htmlFor="units-field-8">Compressor type</label>
              <input id="units-field-8" value={form.compressor_type} onChange={set('compressor_type')} />
            </div>
            <div>
              <label htmlFor="units-field-9">Compressor model</label>
              <input id="units-field-9" value={form.compressor_model} onChange={set('compressor_model')} />
            </div>
          </div>
          <div className="foot">
            <button type="button" className="btn" onClick={onCancel}>Cancel</button>
            <button className="btn primary" disabled={busy}>{busy ? 'Saving…' : editing ? 'Save changes' : 'Add unit'}</button>
          </div>
        </form>
      </div>
    </Modal>
  );
}

export default function Units() {
  const { token, business } = useAuth();
  const [data, setData] = useState(null); // { units, statistics }
  const [error, setError] = useState(null);
  const [modal, setModal] = useState(null);
  const [busyId, setBusyId] = useState(null);

  async function refresh() {
    setError(null);
    try {
      const d = await api.post('/units/management/list/', { business_id: business.business_uid }, token);
      setData({ units: d.units ?? [], statistics: d.statistics ?? {} });
    } catch (e) {
      setError(e.message);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function onDelete(u) {
    if (!window.confirm(`Delete unit "${u.name}"? This cannot be undone.`)) return;
    setBusyId(u.unit_id);
    try {
      await api.post('/units/management/delete/', { business_id: business.business_uid, unit_id: u.unit_id }, token);
      await refresh();
    } catch (e) {
      window.alert(`Delete failed: ${e.message}`);
    } finally {
      setBusyId(null);
    }
  }

  const st = data?.statistics ?? {};

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Refrigeration</div>
          <h1 className="page-title">Unit Management</h1>
          <p className="page-sub">Fridge and freezer units, their specs and lifecycle status.</p>
        </div>
        <button className="btn flame" onClick={() => setModal({ initial: { ...EMPTY_FORM } })}>
          + Add unit
        </button>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!data && !error && <Spinner />}

      {data && (
        <>
          <div className="tiles">
            <div className="tile">
              <div className="eyebrow">Total units</div>
              <div className="v">{st.total_units ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Operational</div>
              <div className="v" style={{ color: 'var(--good)' }}>{st.operational_units ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">In maintenance</div>
              <div className="v" style={{ color: 'var(--warn)' }}>{st.maintenance_units ?? 0}</div>
            </div>
            <div className="tile">
              <div className="eyebrow">Decommissioned</div>
              <div className="v">{st.decommissioned_units ?? 0}</div>
            </div>
          </div>

          <Panel title="Units">
            {data.units.length === 0 ? (
              <Empty>No units registered yet — add your first unit.</Empty>
            ) : (
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Serial</th>
                      <th>Model</th>
                      <th>Location</th>
                      <th>Refrigerant</th>
                      <th>Status</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.units.map((u) => (
                      <tr key={u.unit_id}>
                        <td style={{ fontWeight: 600 }}>{u.name}</td>
                        <td className="ink2">{u.serial_number || '—'}</td>
                        <td className="ink2">{u.model_number || '—'}</td>
                        <td className="ink2">{u.location || '—'}</td>
                        <td className="ink2">{u.refrigerant_type || '—'}</td>
                        <td>
                          <span className={`chip ${STATUS_CLS[u.status] ?? 'neutral'}`}>
                            {u.status || 'unknown'}
                          </span>
                        </td>
                        <td>
                          <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
                            <button className="btn sm" onClick={() => setModal({ initial: { ...EMPTY_FORM, ...u } })}>
                              Edit
                            </button>
                            <button className="btn sm danger" disabled={busyId === u.unit_id} onClick={() => onDelete(u)}>
                              {busyId === u.unit_id ? '…' : 'Delete'}
                            </button>
                          </div>
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

      {modal && (
        <UnitForm
          initial={modal.initial}
          onCancel={() => setModal(null)}
          onDone={() => {
            setModal(null);
            refresh();
          }}
        />
      )}
    </>
  );
}
