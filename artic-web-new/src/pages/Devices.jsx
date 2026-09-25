import Modal from '../components/Modal';
// Device management: table of all devices with add / edit / delete. The form
// mirrors the backend serializer — note `floor` is NOT NULL in Postgres even
// though the API doesn't flag it, so the form requires it.

import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, DEVICE_TYPE_OPTIONS, deviceTypeLabel } from '../api';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { isGasCylinderType } from '../lib/gas/gasCore';
import { Empty, PresenceChip, Spinner } from '../components/bits';

const EMPTY_FORM = {
  name: '',
  device_id: '',
  location: '',
  building: '',
  floor: '',
  room: '',
  device_type: 'device1',
  capacity: '',
  manufacturer: '',
  model: '',
  serial_number: '',
  installation_date: '',
  is_active: true,
};

function DeviceForm({ initial, onDone, onCancel }) {
  const { token, business } = useAuth();
  const [form, setForm] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const editing = initial.id != null;
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function onSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const payload = {
      ...form,
      capacity: form.capacity === '' ? null : Number(form.capacity),
    };
    try {
      if (editing) {
        await api.updateDevice(business.business_uid, { ...payload, id: initial.id }, token);
      } else {
        await api.createDevice(business.business_uid, payload, token);
      }
      onDone();
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }

  return (
    <Modal onClose={onCancel} label="Device details">
      <div className="modal">
        <h3>{editing ? `Edit ${initial.name}` : 'Add device'}</h3>
        {error && <div className="form-err">{error}</div>}
        <form onSubmit={onSubmit}>
          <div className="form-grid">
            <div>
              <label htmlFor="devices-field-1">Name *</label>
              <input id="devices-field-1" value={form.name} onChange={set('name')} required />
            </div>
            <div>
              <label htmlFor="devices-field-2">Device ID *</label>
              <input id="devices-field-2"
                value={form.device_id}
                onChange={set('device_id')}
                required
                placeholder="e.g. GAS-002"
                disabled={editing}
              />
            </div>
            <div>
              <label htmlFor="devices-field-3">Device type *</label>
              <select id="devices-field-3" value={form.device_type} onChange={set('device_type')}>
                {DEVICE_TYPE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="devices-field-4">Capacity (kg)</label>
              <input id="devices-field-4" type="number" step="any" value={form.capacity ?? ''} onChange={set('capacity')} />
            </div>
            <div>
              <label htmlFor="devices-field-5">Location</label>
              <input id="devices-field-5" value={form.location} onChange={set('location')} placeholder="e.g. Main Kitchen" />
            </div>
            <div>
              <label htmlFor="devices-field-6">Building</label>
              <input id="devices-field-6" value={form.building} onChange={set('building')} />
            </div>
            <div>
              <label htmlFor="devices-field-7">Floor *</label>
              <input id="devices-field-7" value={form.floor} onChange={set('floor')} required placeholder="e.g. Ground" />
            </div>
            <div>
              <label htmlFor="devices-field-8">Room</label>
              <input id="devices-field-8" value={form.room} onChange={set('room')} />
            </div>
            <div>
              <label htmlFor="devices-field-9">Manufacturer</label>
              <input id="devices-field-9" value={form.manufacturer} onChange={set('manufacturer')} />
            </div>
            <div>
              <label htmlFor="devices-field-10">Model</label>
              <input id="devices-field-10" value={form.model} onChange={set('model')} />
            </div>
            <div>
              <label htmlFor="devices-field-11">Serial number</label>
              <input id="devices-field-11" value={form.serial_number} onChange={set('serial_number')} />
            </div>
            <div>
              <label htmlFor="devices-field-12">Installation date</label>
              <input id="devices-field-12" type="date" value={form.installation_date ?? ''} onChange={set('installation_date')} />
            </div>
            <div className="full">
              <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 0 }}>
                <input
                  type="checkbox"
                  style={{ width: 'auto' }}
                  checked={!!form.is_active}
                  onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))}
                />
                Device is active
              </label>
            </div>
          </div>
          <div className="foot">
            <button type="button" className="btn" onClick={onCancel}>
              Cancel
            </button>
            <button className="btn primary" disabled={busy}>
              {busy ? 'Saving…' : editing ? 'Save changes' : 'Add device'}
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
}

export default function Devices() {
  const { token, business } = useAuth();
  const { devices, error, refresh } = useDevices();
  const [modal, setModal] = useState(null); // {initial} for add/edit
  const [busyId, setBusyId] = useState(null);

  const sorted = useMemo(
    () => (devices ? [...devices].sort((a, b) => a.name.localeCompare(b.name)) : null),
    [devices],
  );

  async function onDelete(d) {
    if (!window.confirm(`Delete "${d.name}" (${d.device_id})? This cannot be undone.`)) return;
    setBusyId(d.id);
    try {
      await api.deleteDevice(business.business_uid, d.id, token);
      await refresh();
    } catch (e) {
      window.alert(`Delete failed: ${e.message}`);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Fleet</div>
          <h1 className="page-title">Devices</h1>
          <p className="page-sub">Add, edit and retire monitored equipment.</p>
        </div>
        <button className="btn flame" onClick={() => setModal({ initial: { ...EMPTY_FORM } })}>
          + Add device
        </button>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!sorted && !error && <Spinner />}

      {sorted && (
        <div className="panel">
          {sorted.length === 0 ? (
            <Empty>No devices yet — add your first device.</Empty>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Device ID</th>
                    <th>Type</th>
                    <th>Location</th>
                    <th>Status</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {sorted.map((d) => (
                    <tr key={d.id}>
                      <td style={{ fontWeight: 600 }}>
                        <Link to={`/devices/${d.id}`}>{d.name}</Link>
                      </td>
                      <td className="ink2">{d.device_id}</td>
                      <td>
                        <span className={`chip ${isGasCylinderType(d.device_type) ? 'gas-type' : 'type'}`}>
                          {deviceTypeLabel(d.device_type)}
                        </span>
                      </td>
                      <td className="ink2">
                        {[d.location, d.room].filter(Boolean).join(' · ') || '—'}
                      </td>
                      <td>
                        <PresenceChip online={!!d.is_online} />
                      </td>
                      <td>
                        <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
                          <button className="btn sm" onClick={() => setModal({ initial: { ...EMPTY_FORM, ...d } })}>
                            Edit
                          </button>
                          <button className="btn sm danger" disabled={busyId === d.id} onClick={() => onDelete(d)}>
                            {busyId === d.id ? '…' : 'Delete'}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {modal && (
        <DeviceForm
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
