import test from 'node:test';
import assert from 'node:assert/strict';
import { cylinderGeometry, cylinderFill, gasFraction } from '../src/lib/gas/cylinderGeometry.js';

const near = (a, b) => assert.ok(Math.abs(a - b) < 1e-8, `${a} != ${b}`);
for (const [capacity, width, top] of [[5,125,130.5],[9,165,96],[14,157.5,79.5],[19,152.5,66],[48,122.5,51]]) {
  test(`${capacity} kg matches the mobile tank proportions and half-full rail`, () => {
    const shape = cylinderGeometry(capacity);
    near(shape.width, width);
    near(shape.top, top);
    near(cylinderFill(shape, .5).y, (top + 270) / 2);
    near(cylinderFill(shape, .5).height, (270 - top) / 2);
    assert.ok(shape.top - 45 >= 0); // Carrying guard stays inside viewBox.
    assert.ok(shape.bottom + 14 < 300); // Foot ring stays inside viewBox.
  });
}

test('custom sizes interpolate and saved capacity rounding preserves shape', () => {
  near(cylinderGeometry(16.5).top, 72.75);
  near(cylinderGeometry((8.1 + 9) - 8.1).width, cylinderGeometry(9).width);
  assert.equal(cylinderGeometry(NaN).bodyPath, cylinderGeometry(19).bodyPath);
});

test('empty, full and invalid levels never draw outside the measured body', () => {
  const shape = cylinderGeometry(48);
  for (const [level, fraction] of [[-10,0],[0,0],[50,.5],[100,1],[150,1],[NaN,0]]) {
    assert.equal(gasFraction(level), fraction);
    const fill = cylinderFill(shape, gasFraction(level));
    near(fill.y + fill.height, shape.bottom);
    assert.ok(fill.y >= shape.top && fill.y <= shape.bottom);
  }
  assert.equal(cylinderFill(shape, 0).height, 0);
});
