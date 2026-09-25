# Gas scale → ArticSentinel integration

How a gas-cylinder scale (ESP32 + load cell) gets its readings into ArticSentinel.
The same details, filled in for each device, are on the device page under
**Connect the scale** (e.g. https://uat.articsentinel.com/devices/30).

## 1. What the scale sends

The scale only measures **combined weight** — cylinder + gas. It never needs to
know the tank weight; the server subtracts it using the device's **Cylinder setup**.

| Setting    | Value                                        |
|------------|----------------------------------------------|
| Broker     | `api.articsentinel.com`                      |
| Port       | `8883` — **TLS required**; verify the server certificate (Let's Encrypt, any standard CA bundle) |
| Username   | the Device ID, e.g. `GAS-001`                |
| Password   | issued once per scale by an administrator (see below) |
| Topic      | `gas_cylinder/<DEVICE_ID>/data` — e.g. `gas_cylinder/GAS-001/data`. The topic identifies the scale; a body `device_id` that disagrees is rejected. |
| Client ID  | unique per scale, e.g. `gas-GAS-001`         |
| QoS        | 1                                            |
| Interval   | every 1–5 minutes                            |

Message body (JSON):

```json
{
  "device_id": "GAS-001",
  "weight_kg": 27.0,
  "ts": 1790162400,
  "battery": 87,
  "rssi": -61,
  "temp": 24.5,
  "fw": "1.0.0"
}
```

| Field       | Type            | Required | Meaning |
|-------------|-----------------|----------|---------|
| `device_id` | string          | no       | The Device ID registered in ArticSentinel. Optional (the topic already names the device); if sent, it must match. |
| `weight_kg` | number          | yes      | Combined weight on the scale, kg (cylinder + gas). Must be 0–200 or it is rejected. `gross_kg` is accepted as an alias. |
| `ts`        | number / string | no       | When the reading was taken: Unix seconds (or ms), or ISO-8601. Lets the scale upload readings it buffered while offline (accepted up to 7 days old). Leave out to use arrival time. |
| `battery`   | number          | no       | Battery %. |
| `rssi`      | integer         | no       | Wi-Fi signal, dBm. |
| `temp`      | number          | no       | Ambient °C. |
| `fw`        | string          | no       | Firmware version. |

Test from any machine:

```sh
mosquitto_pub -h api.articsentinel.com -p 8883 --capath /etc/ssl/certs \
  -u 'GAS-001' -P '<password>' -q 1 \
  -t 'gas_cylinder/GAS-001/data' -m '{"weight_kg":27.0}'
```

On the ESP32, use `WiFiClientSecure` with the ISRG Root X1 CA certificate (Let's Encrypt's root) so the scale verifies the server; don't use `setInsecure()` in production.

### Issuing scale logins (administrator, on the server)

```sh
cd ~/exvr
./mosquitto/gas_scale_credentials.sh add GAS-001      # issue or rotate; prints the password once
./mosquitto/gas_scale_credentials.sh revoke GAS-001   # cut a scale off
./mosquitto/gas_scale_credentials.sh list
```

Changes apply with a broker reload; connected devices stay connected.

## 2. What the server does with it

`mqtt/transfere_to_pg_gas.py` (container `exvr_mqtt_bridge_gas`):

1. Takes the Device ID from the topic, ignores it if no gas-cylinder device with that ID is registered, and looks up its Cylinder setup (empty weight + gas capacity).
2. `net_kg = max(0, weight_kg − tare_kg)`; `level_pct = net_kg / gas_capacity_kg × 100` (clamped 0–100).
3. Stores gross, tare, net, level and the optional fields in TimescaleDB table `gas_cylinder_data`
   (the tare in force is stored with each row, so changing cylinders later doesn't rewrite history; 400-day retention).
4. Marks the device online/active with `last_ping = now`.

Worked example (19 kg cylinder, empty weight 15.6 kg): scale reads 27.0 kg → 11.4 kg gas → 60%.

## 3. Cylinder setup (per device, in the web app)

Device page → **Cylinder setup**:

- **Empty cylinder weight** — the "TW" stamped on the cylinder collar.
- **Gas when full** — 9 / 14 / 19 / 48 kg or custom.
- Gas price per kg, low-level and warning thresholds.
- **Set empty weight from a full cylinder** — if the collar is unreadable: fit a full cylinder, wait for a reading, press the button (empty weight = scale reading − capacity).

API (token auth, all POST JSON; `device_id` = numeric id or the string Device ID):

| Endpoint | Body | Returns |
|---|---|---|
| `/api/gas/config/` | `business_id, device_id` | current setup (`is_default: true` if never saved) |
| `/api/gas/config/update/` | `business_id, device_id` + any of `gas_capacity_kg, tare_kg, price_per_kg, low_threshold_pct, warning_threshold_pct` | saved setup |
| `/api/gas/readings/` | `business_id, device_id, days` (1–400) | readings (5-min / 30-min / hourly buckets by range), latest raw reading, setup |

## 4. Wi-Fi setup over Bluetooth (mobile app)

The Android/iPhone app does this under the gas device → **Connect scale**. What the
scale firmware must provide:

| Item | Requirement |
|---|---|
| Protocol | ESP-IDF **unified provisioning** (`wifi_prov_mgr` / Arduino `WiFiProv`) over BLE |
| Security | **Security 1** (Curve25519 + AES-CTR). A proof-of-possession (PoP) code is optional; if used, print it on the scale label. Security 0 and 2 are rejected with a clear message. |
| Advertising | Name starting `PROV_`, or containing `GAS` / `SCALE`, or advertising the service UUID. Anything else is behind "Show all Bluetooth devices". |
| Endpoints | Found by their user-description (0x2901) names: `prov-session`, `prov-config`, `prov-scan`, `proto-ver`, and optionally `custom-data`. Falls back to service `021a9004-0382-4aea-bff4-6b3f1c5adfb4` with `ff50`–`ff54`. |
| `proto-ver` | Should report `"cap":["wifi_scan"]` so the app can list networks; otherwise the user types the network name. |
| Wi-Fi | 2.4 GHz. The app polls status for 45 s and shows wrong-password / network-not-found errors. |

Standard provisioning sends the Wi-Fi details as encrypted **protobuf** messages, not JSON.
The app uses `esp_provisioning_ble` for that.

**Optional: server login over `custom-data`.** If the scale registers a `custom-data`
endpoint, the app can send (encrypted, in the same session) before the Wi-Fi details:

```json
{"device_id":"GAS-001","mqtt_host":"api.articsentinel.com","mqtt_port":8883,
 "mqtt_user":"GAS-001","mqtt_pass":"<issued password>","topic":"gas_cylinder/GAS-001/data"}
```

The firmware should store it and reply with a short status such as `OK`; the app shows the
reply. Without this endpoint, the login has to be built into the firmware.

After Wi-Fi is up, the app waits (up to 3 minutes) for the scale's first reading to reach the
server and shows the weight, so a successful setup is confirmed end to end.

Test the scale's Bluetooth side with LightBlue (GATT table and 0x2901 names) or Espressif's
*ESP BLE Provisioning* app before using ours.

## 5. Broker security

| Port | Who | Login | Access |
|---|---|---|---|
| 1883, 9001 | field ESP32s (username `surprise`, never checked), existing bridges | anonymous or any username — unchanged | everything **except** `gas_cylinder/#` |
| 8883 (TLS) | gas scales | Device ID + password | publish `gas_cylinder/<own ID>/data` only |
| 1884 (Docker network only) | gas bridge (`gas-bridge`) | password in `.env` | read `gas_cylinder/#` |

Config: `mosquitto/config/mosquitto.conf` (`per_listener_settings true`), `acl_public`, `acl_gas`, `passwd`.
The TLS certificate is a copy of `/etc/letsencrypt/live/api.articsentinel.com/` in `mosquitto/certs/`; the certbot
deploy hook `/etc/letsencrypt/renewal-hooks/deploy/exvr-mosquitto-certs.sh` refreshes it and reloads the broker
(renewals don't need a restart).

Rollback: restore `mosquitto/config/mosquitto.conf.pre-listeners.20260923` and
`docker-compose.yml.pre-listeners.20260923`, then `docker compose up -d mosquitto mqtt_bridge_gas`.

History: a first attempt (23 Sep 2026, 11:35:44–11:40:30 UTC) put a password file on the shared port. That locked
out the `surprise` ESP32s, and device1/device2 data from that window is missing. It was replaced by the
per-listener setup above, rolled out 11:50 UTC with no rejected field devices.

## 6. Open items / risks

- **Ports 1883/9001 are still open to the internet without a checked login.** Internet scanners (`CENSYS`, `nmap`) connect regularly. Anyone can publish fake fridge readings or relay commands, or read all non-gas topics. Closing this needs the `surprise` password (or new firmware) so the ESP32s can move to authenticated access too.
- Pre-existing, not changed: `device7` is missing from the no-data watchdog's table map (`alerts/tasks.py`), so bottle-vetting devices are checked against the wrong table.
