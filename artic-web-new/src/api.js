// ArticSentinel API client — mirrors the endpoints the Flutter app uses
// (lib/screens/device_management.dart, ApiService). All device calls are
// POST + JSON with a DRF token header, same as the app.

const BASE = (import.meta.env.VITE_API_BASE || '') + '/api';

async function post(path, body, token) {
  const headers = { 'Content-Type': 'application/json; charset=UTF-8' };
  if (token) headers.Authorization = `Token ${token}`;

  const res = await fetch(BASE + path, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  let data = null;
  try {
    data = await res.json();
  } catch {
    /* non-JSON error body */
  }

  if (!res.ok) {
    const msg = describeError(res.status, data);
    const err = new Error(msg);
    err.status = res.status;
    throw err;
  }
  return data;
}

async function get(path, token, base = BASE) {
  const headers = {};
  if (token) headers.Authorization = `Token ${token}`;
  const res = await fetch(base + path, { headers });
  let data = null;
  try {
    data = await res.json();
  } catch {
    /* non-JSON */
  }
  if (!res.ok) {
    const err = new Error(describeError(res.status, data));
    err.status = res.status;
    throw err;
  }
  return data;
}

// DRF errors arrive as {error: "..."} or {error: {field: [..]}} — flatten.
function describeError(status, data) {
  if (data) {
    const e = data.error ?? data.detail ?? data.message;
    if (typeof e === 'string') return e;
    if (e && typeof e === 'object') {
      return Object.entries(e)
        .map(([f, v]) => `${f}: ${Array.isArray(v) ? v.join(', ') : v}`)
        .join(' · ');
    }
  }
  return `Request failed (${status})`;
}

export const api = {
  // Legacy telemetry routes live at the API origin root, outside /api/.
  dashboard: (businessId, deviceId, token) => get(
    `/dashboard-data/?business_uid=${encodeURIComponent(businessId)}&device_id=${encodeURIComponent(deviceId)}`,
    token, import.meta.env.VITE_TELEMETRY_BASE || 'https://api.articsentinel.com',
  ),
  // Generic calls for the section pages (alerts, maintenance, reports, …).
  post: (path, body, token) => post(path, body, token),
  get: (path, token) => get(path, token),

  async login(userEmail, password) {
    const data = await post('/login/', { user_email: userEmail, password });
    if (data.message !== 'Login successful' || !data.token) {
      throw new Error(data.message || 'Login failed');
    }
    return data; // { token, user, business, message }
  },

  async devicesList(businessId, token) {
    const data = await post(
      '/devices/list/',
      { business_id: businessId, include_unit_details: true },
      token,
    );
    const list = data.devices ?? data;
    return Array.isArray(list) ? list : [];
  },
  async createDevice(businessId, device, token) {
    const data = await post(
      '/devices/create/',
      { ...device, business_id: businessId },
      token,
    );
    return data.device ?? data;
  },

  async updateDevice(businessId, device, token) {
    const data = await post(
      '/devices/update/',
      { ...device, business_id: businessId, device_id: device.id },
      token,
    );
    return data.device ?? data;
  },

  async deleteDevice(businessId, deviceId, token) {
    return post('/devices/delete/', { business_id: businessId, device_id: deviceId }, token);
  },
};

// The backend's device_type choices (device/models.py DEVICE_TYPES).
export const DEVICE_TYPE_OPTIONS = [
  { value: 'device1', label: 'Device 1' },
  { value: 'device2', label: 'Device 2' },
  { value: 'device3', label: 'Device 3' },
  { value: 'device4', label: 'Device 4' },
  { value: 'device5', label: 'Device 5' },
  { value: 'device6', label: 'Device 6' },
  { value: 'device7', label: 'Device 7 — Bottle Vetting' },
  { value: 'gas_cylinder', label: 'Gas Cylinder' },
];

export function deviceTypeLabel(raw) {
  if (!raw) return 'Unknown';
  const hit = DEVICE_TYPE_OPTIONS.find((o) => o.value === raw);
  if (hit) return hit.label;
  return raw
    .split(/[_\s]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(' ');
}
