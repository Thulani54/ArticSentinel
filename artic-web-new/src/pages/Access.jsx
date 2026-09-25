import Modal from '../components/Modal';
// Access Management — roles defined for the business
// (api/roles/, api/create_role/ — mirrors lib/screens/roles.dart).

import { useCallback, useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { Empty, Panel, Spinner } from '../components/bits';

function RoleForm({ onDone, onCancel }) {
  const { token } = useAuth();
  const [form, setForm] = useState({ name: '', description: '', category: 'custom' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function onSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post('/create_role/', form, token);
      onDone();
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  }

  return (
    <Modal onClose={onCancel} label="Create role">
      <div className="modal" style={{ maxWidth: 460 }}>
        <h3>Create role</h3>
        {error && <div className="form-err">{error}</div>}
        <form onSubmit={onSubmit}>
          <label htmlFor="access-field-1">Role name *</label>
          <input id="access-field-1" value={form.name} onChange={set('name')} required style={{ marginBottom: 13 }} />
          <label htmlFor="access-field-2">Description *</label>
          <input id="access-field-2" value={form.description} onChange={set('description')} required style={{ marginBottom: 13 }} />
          <label htmlFor="access-field-3">Category</label>
          <select id="access-field-3" value={form.category} onChange={set('category')} style={{ marginBottom: 4 }}>
            <option value="custom">Custom</option>
            <option value="executive">Executive</option>
            <option value="operations_management">Operations Management</option>
            <option value="technical_management">Technical Management</option>
            <option value="field_technician">Field Technician</option>
            <option value="monitoring_specialist">Monitoring Specialist</option>
            <option value="customer_user">Customer User</option>
            <option value="customer_admin">Customer Admin</option>
            <option value="system_admin">System Administrator</option>
          </select>
          <div className="foot">
            <button type="button" className="btn" onClick={onCancel}>Cancel</button>
            <button className="btn primary" disabled={busy}>{busy ? 'Creating…' : 'Create role'}</button>
          </div>
        </form>
      </div>
    </Modal>
  );
}

export default function Access() {
  const { token, business } = useAuth();
  const [roles, setRoles] = useState(null);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const refresh = useCallback(async () => {
    setError(null);
    try {
      const d = await api.get(`/roles/?business_id=${business.business_uid}`, token);
      setRoles(d.results ?? d ?? []);
    } catch (e) {
      setError(e.message);
    }
  }, [token, business]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Team</div>
          <h1 className="page-title">Access Management</h1>
          <p className="page-sub">Roles that shape what each team member can do.</p>
        </div>
        <button className="btn flame" onClick={() => setShowForm(true)}>+ Create role</button>
      </div>

      {error && <div className="form-err">{error}</div>}
      {!roles && !error && <Spinner />}

      {roles && (
        <Panel title={`Roles (${roles.length})`}>
          {roles.length === 0 ? (
            <Empty>No roles defined yet.</Empty>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Role</th>
                    <th>Category</th>
                    <th>Users</th>
                    <th>Permissions</th>
                    <th>Description</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {roles.map((r) => (
                    <tr key={r.role_id ?? r.id}>
                      <td style={{ fontWeight: 600 }}>{r.name}</td>
                      <td className="ink2">{r.category_display ?? r.category}</td>
                      <td className="ink2">{r.user_count ?? 0}</td>
                      <td className="ink2">{r.permission_count ?? 0}</td>
                      <td className="ink2">{r.description || '—'}</td>
                      <td>
                        <span className={`chip ${r.is_active === false ? 'neutral' : 'good'}`}>
                          {r.is_active === false ? 'inactive' : 'active'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
      )}

      {showForm && (
        <RoleForm
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
