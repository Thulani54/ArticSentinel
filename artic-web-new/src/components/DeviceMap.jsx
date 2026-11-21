// "Device locations" map for the dashboard: every device with coordinates,
// marked green when online and grey when offline, on OpenStreetMap's
// standard tiles (free for light use with attribution; no API key).

import { useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { CircleMarker, MapContainer, Popup, TileLayer, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { deviceTypeLabel } from '../api';
import { isGasCylinderType } from '../lib/gas/gasCore';
import { Panel } from './bits';

// Fits the view to the devices once, and again only if the set of positions
// changes — not on every data refresh, so the user's pan/zoom sticks.
function FitBounds({ points }) {
  const map = useMap();
  const key = points.map((p) => p.join(',')).join(';');
  useEffect(() => {
    if (points.length === 1) map.setView(points[0], 14);
    else if (points.length > 1) map.fitBounds(points, { padding: [36, 36], maxZoom: 15 });
  }, [map, key]); // eslint-disable-line react-hooks/exhaustive-deps
  return null;
}

export default function DeviceMap({ devices }) {
  // The API sends coordinates as strings ("-26.1814"); convert before use.
  const placed = useMemo(
    () => (devices || [])
      .map((d) => ({ ...d, latitude: parseFloat(d.latitude), longitude: parseFloat(d.longitude) }))
      .filter((d) => Number.isFinite(d.latitude) && Number.isFinite(d.longitude)),
    [devices],
  );
  const points = useMemo(() => placed.map((d) => [d.latitude, d.longitude]), [placed]);
  const online = placed.filter((d) => d.is_online).length;

  return (
    <Panel
      className="mt16"
      eyebrow={`${placed.length} of ${devices?.length ?? 0} devices placed · ${online} online`}
      title="Device locations"
      actions={
        <div className="map-legend">
          <span><i className="dot-online" />Online</span>
          <span><i className="dot-offline" />Offline</span>
        </div>
      }
    >
      {placed.length === 0 ? (
        <p className="hint">No device has a location yet. Add latitude and longitude in Device Management.</p>
      ) : (
        <div className="device-map">
          <MapContainer center={points[0]} zoom={12} scrollWheelZoom={false} style={{ height: '100%', width: '100%' }}>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
              maxZoom={19}
            />
            <FitBounds points={points} />
            {placed.map((d) => (
              <CircleMarker
                key={d.id}
                center={[d.latitude, d.longitude]}
                radius={isGasCylinderType(d.device_type) ? 8 : 9}
                pathOptions={{
                  color: '#ffffff',
                  weight: 2,
                  fillColor: d.is_online ? '#0ca30c' : '#8a9aa5',
                  fillOpacity: 0.95,
                }}
              >
                <Popup>
                  <strong>{d.name}</strong>
                  <br />
                  {isGasCylinderType(d.device_type) ? 'Gas cylinder' : deviceTypeLabel(d.device_type)} · {d.is_online ? 'Online' : 'Offline'}
                  {d.location ? <><br />{d.location}</> : null}
                  <br />
                  <Link to={`/devices/${d.id}`}>Open device →</Link>
                </Popup>
              </CircleMarker>
            ))}
          </MapContainer>
        </div>
      )}
    </Panel>
  );
}
