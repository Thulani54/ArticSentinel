// Hero "board" for the selected device on the dashboard: its illustration on
// a lit stage, identity and status, and three headline readings for its type.

import { deviceTypeLabel } from '../api';
import { isGasCylinderType } from '../lib/gas/gasCore';
import DeviceIllustration from './DeviceIllustration';

const n = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const deg = (v) => (n(v) == null ? '—' : `${n(v).toFixed(1)}°C`);
const ago = (iso) => {
  if (!iso) return 'no readings yet';
  const m = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (m < 1) return 'just now';
  if (m < 60) return `${m} min ago`;
  const h = Math.round(m / 60);
  return h < 48 ? `${h} h ago` : `${Math.round(h / 24)} days ago`;
};

function highlights(type, l) {
  if (!l) return [];
  switch (type) {
    case 'device1': return [['Air', deg(l.temperatureAir ?? l.temperature)], ['Compressor', l.compressorStatus || (l.comp ? 'ON' : 'OFF')], ['Door', l.door ? 'Open' : 'Closed']];
    case 'device2': {
      const z = Array.from({ length: 8 }, (_, i) => n(l[`temp${i + 1}`])).filter((v) => v != null);
      return [['Average', deg(l.avgTemp ?? l.avgTemperature)], ['Coldest', deg(z.length ? Math.min(...z) : null)], ['Warmest', deg(z.length ? Math.max(...z) : null)]];
    }
    case 'device3': return [['Ice', deg(l.ice_temp)], ['Water', n(l.wtrlvl) == null ? '—' : `${Math.round(l.wtrlvl)}%`], ['Harvests today', l.harvest_count ?? 0]];
    case 'device4': {
      const kw = Array.from({ length: 8 }, (_, i) => n(l[`comp${i + 1}_power_kw`]) || 0).reduce((a, v) => a + v, 0);
      const running = Array.from({ length: 8 }, (_, i) => n(l[`comp${i + 1}_avg`])).filter((v) => v > 0).length;
      return [['Running', `${running}/8`], ['Power', `${kw.toFixed(1)} kW`]];
    }
    case 'device5': return [['Relays on', l.relaysOnCount ?? '—'], ['Relays off', l.relaysOffCount ?? '—']];
    case 'device7': return [['Scans today', l.totalScansToday ?? 0], ['Bottle temp', deg(l.bottleTemp)], ['Verified', l.verifiedScansToday ?? 0]];
    default: return [];
  }
}

export default function DeviceBoard({ device, latest }) {
  const gas = isGasCylinderType(device.device_type);
  const stats = highlights(device.device_type, latest);
  return (
    <section className={`device-board${gas ? ' gas' : ''}`} aria-label={`${device.name} overview`}>
      <div className="board-stage">
        <DeviceIllustration type={device.device_type} online={!!device.is_online} size={230} title={`${deviceTypeLabel(device.device_type)} illustration`} />
      </div>
      <div className="board-info">
        <span className="board-type">{gas ? 'Gas cylinder' : deviceTypeLabel(device.device_type)}</span>
        <h2>{device.name}</h2>
        <div className="board-meta">
          <span className={`board-status ${device.is_online ? 'on' : 'off'}`}><i />{device.is_online ? 'Online' : 'Offline'}</span>
          <span>{[device.location, device.building].filter(Boolean).join(' · ') || device.device_id}</span>
        </div>
        {stats.length > 0 && (
          <dl className="board-stats">
            {stats.map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}
          </dl>
        )}
        <p className="board-foot">Last reading {ago(latest?.time)}</p>
      </div>
    </section>
  );
}
