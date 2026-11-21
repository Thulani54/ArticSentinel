import test from 'node:test';
import assert from 'node:assert/strict';
import { assignedClientId } from '../src/lib/deviceIdentity.js';

test('registered devices get stable distinct MQTT IDs within 23 characters', () => {
  assert.equal(assignedClientId(37), 'AS_00000000000000000025');
  assert.equal(assignedClientId('37'), assignedClientId(37));
  assert.notEqual(assignedClientId(37), assignedClientId(38));
  assert.equal(assignedClientId(37).length, 23);
});
test('unsaved, malformed and imprecise device IDs do not fabricate an identity', () => {
  for (const value of [null,undefined,'',0,-1,'TestGas1',1.5,Number.MAX_SAFE_INTEGER+1]) {
    assert.equal(assignedClientId(value),null);
  }
});
