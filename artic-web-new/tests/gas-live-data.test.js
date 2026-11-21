import test from 'node:test';
import assert from 'node:assert/strict';
import { liveData } from '../src/lib/gas/gasLiveData.js';
import { todayUsage } from '../src/lib/gas/gasCore.js';

const config = { gas_capacity_kg: 48, tare_kg: 43, price_per_kg: 39, low_threshold_pct: 20, warning_threshold_pct: 50 };
const row = (hour, net_kg) => ({ time: `2026-11-15T${hour}:00:00+02:00`, net_kg, gross_kg: net_kg + 43 });

test('latest telemetry contributes to usage just as it does to the gas level', () => {
  const data = liveData({ config, readings: [row('00', 36.307), row('01', 36.2)], latest: row('02', 36) });
  assert.equal(data.readings.length, 3);
  assert.equal(data.currentNetKg, 36);
  const usage = todayUsage(data.readings, 39, new Date('2026-11-15T03:00:00+02:00'));
  assert.equal(usage.kg.toFixed(2), '0.31');
  assert.equal(usage.cost.toFixed(2), '11.97');
});

test('same-timestamp latest reading replaces the bucket without a duplicate', () => {
  const data = liveData({ config, readings: [row('00', 36.307), row('01', 36.2)], latest: row('01', 36) });
  assert.equal(data.readings.length, 2);
  assert.equal(data.readings.at(-1).weightKg, 79);
});

test('no telemetry remains empty; a latest-only response remains usable', () => {
  const empty = liveData({ config, readings: [], latest: null });
  assert.deepEqual(empty.readings, []);
  assert.equal(empty.latest, null);
  assert.equal(empty.currentNetKg, null);
  const latestOnly = liveData({ config, readings: [], latest: row('01', 36) });
  assert.equal(latestOnly.readings.length, 1);
  assert.equal(latestOnly.currentNetKg, 36);
});
