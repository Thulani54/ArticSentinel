import test from 'node:test';
import assert from 'node:assert/strict';
import {isFreshSetupReading} from '../src/lib/gas/scaleSetup.js';
import {assignedClientId} from '../src/lib/deviceIdentity.js';
test('setup requires a new measurement, preserves a real zero and rejects future time',()=>{
  const start=Date.parse('2026-11-15T12:00:00Z');
  const reading={time:'2026-11-15T12:00:05Z',gross_kg:0};
  assert.equal(isFreshSetupReading(reading,start,start+10000),true);
  assert.equal(isFreshSetupReading({...reading,time:'2026-11-15T11:59:59Z'},start),false);
  assert.equal(isFreshSetupReading({...reading,time:'2026-11-15T13:00:00Z'},start,start+10000),false);
  assert.equal(isFreshSetupReading({...reading,gross_kg:null},start),false);
  assert.equal(isFreshSetupReading({...reading,gross_kg:NaN},start),false);
  assert.equal(isFreshSetupReading(null,start),false);
});
test('web identity agrees with the mobile and server identity',()=>{
  assert.equal(assignedClientId(4),'AS_00000000000000000004');
  assert.equal(assignedClientId(255),'AS_000000000000000000FF');
  assert.equal(assignedClientId(0),null);
  assert.equal(assignedClientId(Number.MAX_SAFE_INTEGER+1),null);
});
