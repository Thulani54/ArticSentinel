import test from 'node:test';
import assert from 'node:assert/strict';
import { dailySeries, todayUsage, gasUsageForRange } from '../src/lib/gas/gasCore.js';

const r = (day, hour, weightKg) => ({ at: new Date(2026, 10, day, hour), weightKg });
const now = new Date(2026, 10, 8, 15);
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-9);

test('today and report agree when weight rises between drops', () => {
  const readings = [r(7, 23, 79.307), r(8, 6, 78.8), r(8, 9, 79.4279), r(8, 12, 79)];
  const report = dailySeries(readings, 39)[0];
  const today = todayUsage([...readings].reverse(), 39, now);
  near(today.kg, report.kg);
  near(today.cost, report.cost);
  near(today.kg, 0.307);
  assert.equal(today.kg.toFixed(2), '0.31');
  assert.equal(today.cost.toFixed(2), '11.97');
});

test('repeated scale fluctuations with no net loss produce zero consumption', () => {
  const readings = [r(7, 23, 30), r(8, 1, 29.8), r(8, 2, 30.1), r(8, 3, 29.9), r(8, 4, 30)];
  assert.equal(dailySeries(readings, 39)[0].kg, 0);
  assert.deepEqual(todayUsage(readings, 39, now), { kg: 0, cost: 0 });
});

test('November 8 hourly readings produce 0.335 kg, not 0.984 kg', () => {
  const weights = [36.354, 36.384, 36.386, 36.370, 36.390, 36.358,
    36.391, 36.376, 36.375, 36.371, 36.378, 36.369, 36.386, 36.127,
    36.579, 36.303, 36.388, 36.296, 36.277, 36.280, 36.087, 36.022];
  const readings = [r(7, 23, 36.357), ...weights.map((kg, hour) => r(8, hour, kg))];
  const report = dailySeries(readings, 39)[0];
  const today = todayUsage(readings, 39, new Date(2026, 10, 8, 22));
  near(report.kg, 0.335);
  near(today.kg, report.kg);
  near(today.cost, report.cost);
});

test('refill does not cancel usage before or after it', () => {
  const today = todayUsage([r(7, 23, 10), r(8, 6, 9), r(8, 9, 20), r(8, 12, 19.5)], 39, now);
  near(today.kg, 1.5);
  near(today.cost, 58.5);
});

test('offline gaps and future readings do not inflate today', () => {
  const today = todayUsage([r(4, 23, 40), r(8, 6, 30), r(8, 12, 29.5), r(8, 18, 27), r(9, 6, 25)], 39, now);
  near(today.kg, 0.5);
  near(today.cost, 19.5);
});

test('empty, singleton and historical readings return zero for today', () => {
  for (const readings of [[], [r(8, 6, 30)], [r(6, 6, 30), r(7, 6, 29)]]) {
    assert.deepEqual(todayUsage(readings, 39, now), { kg: 0, cost: 0 });
  }
});

test('range retains midnight baseline and excludes older and future days', () => {
  const readings = [r(5, 23, 35), r(6, 23, 30), r(7, 23, 29), r(8, 12, 28.5), r(8, 18, 27)];
  const usage = gasUsageForRange(readings, 39, 2, now);
  assert.deepEqual(usage.daily.map((p) => p.day.getDate()), [7, 8]);
  near(usage.summary.totalKg, 1.5);
  near(usage.daily.at(-1).kg, todayUsage(readings, 39, now).kg);
});

test('weekly chart and daily PDF retain identical totals at range boundaries', () => {
  const readings = Array.from({ length: 70 }, (_, i) => ({
    at: new Date(2026, 8, i + 1, 12), weightKg: 100 - i * 0.1,
  }));
  const usage = gasUsageForRange(readings, 39, 60, new Date(2026, 10, 9, 15));
  assert.equal(usage.daily.length, 60);
  near(usage.summary.totalKg, 6);
  near(usage.series.reduce((sum, p) => sum + p.kg, 0), usage.summary.totalKg);
  near(usage.series.reduce((sum, p) => sum + p.cost, 0), usage.summary.totalCost);
  near(usage.summary.peak.kg, 0.1); // Peak day, not peak week.
});
