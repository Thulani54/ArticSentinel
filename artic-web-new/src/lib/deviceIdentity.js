// Same stable registered-device identity as platform_admin.policy.mqtt_client_id.
export function assignedClientId(deviceId) {
  if (typeof deviceId === 'number' && !Number.isSafeInteger(deviceId)) return null;
  if (!/^\d+$/.test(String(deviceId ?? ''))) return null;
  const id = BigInt(deviceId);
  if (id <= 0n || id >= 2n ** 80n) return null;
  return `AS_${id.toString(16).toUpperCase().padStart(20, '0')}`;
}
