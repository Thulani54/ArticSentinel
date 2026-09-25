import test from 'node:test';
import assert from 'node:assert/strict';
import { chartSeries, temperatureSeries } from '../src/lib/telemetry/dashboard.js';

test('filters by equipment, sorts timestamps and preserves zero versus missing readings', () => {
  const rows = chartSeries({ hourly_aggregates: [
    { device_id: 'A', hour_bucket: '2026-09-25T10:00:00Z', avg_temp_air: null, total_readings: '8' },
    { device_id: 'B', hour_bucket: '2026-09-25T09:00:00Z', avg_temp_air: 44 },
    { device_id: 'A', hour_bucket: 'invalid', avg_temp_air: 77 },
    { device_id: 'A', hour_bucket: '2026-09-25T08:00:00Z', avg_temp_air: '0', avg_temp_coil: '', total_readings: 0 },
  ] }, 'A', 'today');
  assert.equal(rows.length, 2);
  assert.equal(rows[0].avg_temp_air, 0);
  assert.equal(rows[0].avg_temp_coil, null);
  assert.equal(rows[1].avg_temp_air, null);
  assert.equal(rows[1].total_readings, 8);
});
test('uses daily aggregates for seven-day charts', () => {
  assert.equal(chartSeries({ daily_aggregates: [{ device_id: 3, day_bucket: '2026-09-22', avg_temp: '-18.5' }] }, '3', 'week')[0].avg_temp, -18.5);
  assert.deepEqual(chartSeries(null, 'A', 'today'), []);
});
test('chooses available sensor channels without inventing zero readings or duplicate average', () => {
  assert.deepEqual(temperatureSeries([{ avg_hs_temp: 0, avg_air_temp: 5, avg_temp: 2 }]), [['avg_hs_temp', 'High side'], ['avg_air_temp', 'Air']]);
  assert.deepEqual(temperatureSeries([{ avg_temp1: -20, avg_temp8: 0 }]), [['avg_temp1', 'Zone 1'], ['avg_temp8', 'Zone 8']]);
  assert.deepEqual(temperatureSeries([{ avg_temp: 0 }]), [['avg_temp', 'Temperature']]);
  assert.deepEqual(temperatureSeries([{ avg_temp_air: null, total_readings: 0 }]), []);
});
