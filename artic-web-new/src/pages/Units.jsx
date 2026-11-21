import Modal from '../components/Modal';
// Unit Management — refrigeration units from the units/management endpoints
// (mirrors lib/screens/units.dart's core CRUD).

import { useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, Panel, Spinner } from '../components/bits';

const STATUSES = ['operational', 'maintenance', 'decommissioned'];
const STATUS_CLS = { operational: 'good', maintenance: 'warn', decommissioned: 'neutral' };
// Choice lists must match the Unit model (units/models.py) exactly — the
// server rejects anything else.
const REFRIGERANTS = [['r404a', 'R-404A'], ['r22', 'R-22'], ['r134a', 'R-134a'], ['r410a', 'R-410A'], ['other', 'Other']];
const COMPRESSOR_TYPES = [['scroll', 'Scroll'], ['reciprocating', 'Reciprocating'], ['harmonic', 'Harmonic']];
const EXPANSION_VALVES = [['internal', 'Internal'], ['external', 'External']];
const CONTROL_TYPES = [['electronic', 'Electronic'], ['mechanical', 'Thermostat']];
const DRYER_TYPES = [['flare', 'Flare'], ['swage', 'Swage']];

const EMPTY_FORM = {
  name: '',
  serial_number: '',
  model_number: '',
  year: new Date().getFullYear(),
  location: '',
  status: 'operational',
  refrigerant_type: 'r404a',
  compressor_type: 'scroll',
  expansion_valve_type: 'internal',
  control_type: 'electronic',
  dryer_type: 'flare',
  compressor_model: '',
};

// Older records may hold values outside the lists (e.g. "R134a"); map them
// onto a valid choice so editing doesn't fail.
function normalise(unit) {
  const pick = (list, v, fallback) => {
    const hit = list.find(([value, label]) => value === String(v ?? '').toLowerCase() || label.toLowerCase() === String(v ?? '').toLowerCase().replace(/^r(\d)/, 'r-$1'));
    return hit ? hit[0] : fallback;
  };
  const status = String(unit.status ?? '').toLowerCase();
  return {
    ...unit,
    status: status.includes('maint') ? 'maintenance' : status.includes('decom') ? 'decommissioned' : 'operational',
    refrigerant_type: pick(REFRIGERANTS, unit.refrigerant_type, 'other'),
    compressor_type: pick(COMPRESSOR_TYPES, unit.compressor_type, 'scroll'),
    expansion_valve_type: pick(EXPANSION_VALVES, unit.expansion_valve_type, 'internal'),
    control_type: pick(CONTROL_TYPES, unit.control_type, 'electronic'),
    dryer_type: pick(DRYER_TYPES, unit.dryer_type, 'flare'),
  };
}
const labelOf = (list, v) => list.find(([value]) => value === v)?.[1] || v || '—';
const Choice = ({ id, label, list, value, onChange }) => (
  <div>
    <label htmlFor={id}>{label} *</label>
    <select id={id} value={value} onChange={onChange} required>
      {list.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
    </select>
  </div>
);

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
              <label htmlFor="units-field-2">Serial number *</label>
              <input id="units-field-2" value={form.serial_number} onChange={set('serial_number')} required />
            </div>
            <div>
              <label htmlFor="units-field-3">Model number *</label>
              <input id="units-field-3" value={form.model_number} onChange={set('model_number')} required />
            </div>
            <div>
              <label htmlFor="units-field-4">Year installed *</label>
              <input id="units-field-4" type="number" min="1950" max={new Date().getFullYear()} value={form.year ?? ''} onChange={set('year')} required />
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
            <Choice id="units-field-7" label="Refrigerant" list={REFRIGERANTS} value={form.refrigerant_type} onChange={set('refrigerant_type')} />
            <Choice id="units-field-8" label="Compressor type" list={COMPRESSOR_TYPES} value={form.compressor_type} onChange={set('compressor_type')} />
            <Choice id="units-field-10" label="Expansion valve" list={EXPANSION_VALVES} value={form.expansion_valve_type} onChange={set('expansion_valve_type')} />
            <Choice id="units-field-11" label="Control type" list={CONTROL_TYPES} value={form.control_type} onChange={set('control_type')} />
            <Choice id="units-field-12" label="Dryer type" list={DRYER_TYPES} value={form.dryer_type} onChange={set('dryer_type')} />
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
      // The list returns the unit's id as `id`; edit/delete send it as unit_id.
      // Responses carry display labels ("Under Maintenance", "R-134a"); map
      // them back to stored values for the badges and the edit form.
      setData({ units: (d.units ?? []).map((u) => normalise({ ...u, unit_id: u.unit_id ?? u.id })), statistics: d.statistics ?? {} });
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
                        <td className="ink2">{labelOf(REFRIGERANTS, u.refrigerant_type)}</td>
                        <td>
                          <span className={`chip ${STATUS_CLS[u.status] ?? 'neutral'}`}>
                            {u.status || 'unknown'}
                          </span>
                        </td>
                        <td>
                          <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
                            <button className="btn sm" onClick={() => setModal({ initial: normalise({ ...EMPTY_FORM, ...u }) })}>
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
