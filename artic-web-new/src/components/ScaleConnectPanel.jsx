// Scale connection details, laid out like LightBlue's characteristic list:
// each row is one value the scale firmware needs, with a copy button.
// Scales connect over TLS on 8883 with their Device ID as username and a
// password issued by mosquitto/gas_scale_credentials.sh; messages land in
// mqtt/transfere_to_pg_gas.py on the backend.

import { useState } from 'react';
import { Panel } from './bits';

export const MQTT_HOST = 'api.articsentinel.com';
export const MQTT_PORT = 8883;

function CopyButton({ text }) {
  const [done, setDone] = useState(false);
  async function copy() {
    try {
      await navigator.clipboard.writeText(text);
      setDone(true);
      setTimeout(() => setDone(false), 1400);
    } catch {
      window.prompt('Copy this value:', text);
    }
  }
  return (
    <button type="button" className="btn sm" onClick={copy} aria-label="Copy value">
      {done ? 'Copied' : 'Copy'}
    </button>
  );
}

export default function ScaleConnectPanel({ device, tareKg, capacityKg }) {
  const topic = `gas_cylinder/${device.device_id}/data`;
  // A worked example that is correct for this cylinder: 60% full.
  const exampleGross = tareKg != null && capacityKg != null
    ? Math.round((tareKg + capacityKg * 0.6) * 100) / 100
    : 27.0;
  const payload = JSON.stringify(
    { device_id: device.device_id, weight_kg: exampleGross, battery: 87, rssi: -61, fw: '1.0.0' },
    null,
    2,
  );
  const compact = JSON.stringify({ device_id: device.device_id, weight_kg: exampleGross });
  const testCmd =
    `mosquitto_pub -h ${MQTT_HOST} -p ${MQTT_PORT} --capath /etc/ssl/certs \\\n` +
    `  -u '${device.device_id}' -P '<password>' -q 1 \\\n` +
    `  -t '${topic}' -m '${compact}'`;

  // [label, sub-label, value, copyable]
  const rows = [
    ['Broker host', 'MQTT server', MQTT_HOST, true],
    ['Port', 'TLS required', String(MQTT_PORT), true],
    ['TLS', 'verify the server', 'Standard CA bundle (Let’s Encrypt certificate)', false],
    ['Username', 'the Device ID', device.device_id, true],
    ['Password', 'issued once per scale', 'Ask your ArticSentinel administrator', false],
    ['Topic', 'publish here only', topic, true],
    ['Client ID', 'must be unique per scale', `gas-${device.device_id}`, true],
    ['QoS', 'at least once', '1', true],
  ];

  return (
    <Panel eyebrow="Hardware" title="Connect the scale">
      <p className="ink2" style={{ fontSize: 13, marginBottom: 14 }}>
        The scale publishes its <strong>combined weight</strong> (cylinder + gas) over MQTT. The server subtracts the
        empty-cylinder weight from the setup above to get the gas left. Each scale logs in with its own password and
        can only publish to its own topic.
      </p>

      <div className="link-rows">
        {rows.map(([k, sub, v, copyable]) => (
          <div className="link-row" key={k}>
            <div className="k">
              {k}
              <small>{sub}</small>
            </div>
            <div className={copyable ? 'mono' : 'ink2'} style={copyable ? undefined : { fontSize: 12.5 }}>{v}</div>
            {copyable ? <CopyButton text={v} /> : <span />}
          </div>
        ))}
      </div>

      <div className="eyebrow" style={{ margin: '18px 0 8px' }}>Message body (JSON)</div>
      <div className="code-block">
        <CopyButton text={payload} />
        <pre>{payload}</pre>
      </div>
      {tareKg != null && capacityKg != null && (
        <div className="hint" style={{ marginTop: 6 }}>
          With this setup, {exampleGross} kg on the scale = {(exampleGross - tareKg).toFixed(1)} kg of gas = 60% full.
        </div>
      )}

      <div className="table-wrap" style={{ marginTop: 16 }}>
        <table className="fields-table">
          <thead>
            <tr>
              <th>Field</th>
              <th>Type</th>
              <th>Required</th>
              <th>Meaning</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>device_id</td>
              <td className="ink2">string</td>
              <td className="ink2">no</td>
              <td className="ink2">Optional — the topic already names the scale. If sent, it must be &ldquo;{device.device_id}&rdquo; or the reading is rejected.</td>
            </tr>
            <tr>
              <td>weight_kg</td>
              <td className="ink2">number</td>
              <td>yes</td>
              <td className="ink2">Combined weight on the scale in kg (cylinder + gas). 0–200; anything else is rejected.</td>
            </tr>
            <tr>
              <td>ts</td>
              <td className="ink2">number | string</td>
              <td className="ink2">no</td>
              <td className="ink2">When the reading was taken — Unix seconds or ISO-8601. Lets the scale upload readings buffered while offline (up to 7 days). Omit to use the arrival time.</td>
            </tr>
            <tr>
              <td>battery</td>
              <td className="ink2">number</td>
              <td className="ink2">no</td>
              <td className="ink2">Battery %.</td>
            </tr>
            <tr>
              <td>rssi</td>
              <td className="ink2">integer</td>
              <td className="ink2">no</td>
              <td className="ink2">Wi-Fi signal in dBm.</td>
            </tr>
            <tr>
              <td>temp</td>
              <td className="ink2">number</td>
              <td className="ink2">no</td>
              <td className="ink2">Ambient temperature, °C.</td>
            </tr>
            <tr>
              <td>fw</td>
              <td className="ink2">string</td>
              <td className="ink2">no</td>
              <td className="ink2">Firmware version.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div className="eyebrow" style={{ margin: '18px 0 8px' }}>Test from a terminal</div>
      <div className="code-block">
        <CopyButton text={testCmd} />
        <pre>{testCmd}</pre>
      </div>
      <div className="hint" style={{ marginTop: 6 }}>
        Send a reading every 1–5 minutes. The device shows online within seconds of the first message.
      </div>
    </Panel>
  );
}
