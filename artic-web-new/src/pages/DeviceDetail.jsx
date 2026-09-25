// Device detail router: gas cylinders open the gas dashboard; every other
// type gets the equipment/info view until live temperature telemetry is wired.

import { Link, useParams } from 'react-router-dom';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { deviceTypeLabel } from '../api';
import { isGasCylinderType } from '../lib/gas/gasCore';
import GasDashboard from './GasDashboard';
import DashboardTelemetry from '../components/DashboardTelemetry';
import { Empty, Panel, PresenceChip, Spinner, formatAgo } from '../components/bits';

export default function DeviceDetail() {
  const { id } = useParams();
  const { devices, error } = useDevices();

  if (!devices && !error) return <Spinner />;
  if (error) return <div className="form-err">{error}</div>;

  const device = devices.find((d) => String(d.id) === String(id));
  if (!device) {
    return (
      <Empty>
        Device not found. <Link to="/devices" style={{ textDecoration: 'underline' }}>Back to devices</Link>
      </Empty>
    );
  }

  if (isGasCylinderType(device.device_type)) {
    return <GasDashboard device={device} />;
  }

  const lastPing = device.last_ping ? new Date(device.last_ping) : null;
  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">{deviceTypeLabel(device.device_type)}</div>
          <h1 className="page-title">{device.name}</h1>
          <p className="page-sub">
            {device.device_id}
            {device.location ? ` · ${device.location}` : ''}
          </p>
        </div>
        <PresenceChip online={!!device.is_online} lastSeen={lastPing ? formatAgo(lastPing) : null} />
      </div>

      <Panel eyebrow="Equipment" title="Details">
        <dl className="kv">
          <dt>Device ID</dt>
          <dd>{device.device_id}</dd>
          <dt>Product</dt>
          <dd>{device.product_id || '—'}</dd>
          <dt>Manufacturer</dt>
          <dd>{device.manufacturer || '—'}</dd>
          <dt>Model</dt>
          <dd>{device.model || '—'}</dd>
          <dt>Serial</dt>
          <dd>{device.serial_number || '—'}</dd>
          <dt>Capacity</dt>
          <dd>{device.capacity != null ? `${device.capacity} kg` : '—'}</dd>
          <dt>Location</dt>
          <dd>
            {[device.building, device.floor ? `Floor ${device.floor}` : null, device.room].filter(Boolean).join(' · ') || '—'}
          </dd>
          <dt>Installed</dt>
          <dd>{device.installation_date || '—'}</dd>
          <dt>Warranty</dt>
          <dd>{device.warranty_expiry || '—'}</dd>
          <dt>Next service</dt>
          <dd>{device.next_service_date || '—'}</dd>
          <dt>Active</dt>
          <dd>{device.is_active ? 'Yes' : 'No'}</dd>
        </dl>
      </Panel>

      <DashboardTelemetry devices={[device]} />
    </>
  );
}
