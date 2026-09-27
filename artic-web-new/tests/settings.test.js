import test from 'node:test';
import assert from 'node:assert/strict';
import { parseRules, editRules } from '../src/lib/settings/rules.js';
const metrics = [{ id:'gas_level',label:'Gas remaining',minimum:0,maximum:100,unit:'%',boolean:false },{ id:'temp',label:'Temperature',minimum:-100,maximum:500,unit:'°C',boolean:false },{ id:'door',label:'Door',minimum:0,maximum:1,boolean:true }];
test('custom percentages retain true zero and deduplicate values',()=>assert.deepEqual(parseRules([{metric:'gas_level',comparison:'lte',values:'50, 30, 0, 30'}],metrics)[0].thresholds,[50,30,0]));
test('signed temperature and switch conditions use their native values',()=>assert.deepEqual(parseRules([{metric:'temp',comparison:'gte',values:'-20, -2.5'},{metric:'door',comparison:'gte',values:''}],metrics).map(r=>r.thresholds),[[-20,-2.5],[1]]));
test('invalid thresholds cannot silently become zero',()=>{for(const values of ['', '30,', 'NaN', 'Infinity', '101', '-1', '0x10'])assert.throws(()=>parseRules([{metric:'gas_level',comparison:'lte',values}],metrics));});
test('empty list disables rules and server payload round-trips',()=>{assert.deepEqual(parseRules([],metrics),[]);const rules=[{metric:'gas_level',comparison:'lte',thresholds:[75,40,15]}];assert.deepEqual(parseRules(editRules(rules),metrics),rules);});
test('unsupported metrics and excess conditions fail validation',()=>{assert.throws(()=>parseRules([{metric:'private',comparison:'lte',values:'1'}],metrics));assert.throws(()=>parseRules(Array(21).fill({metric:'gas_level',comparison:'lte',values:'10'}),metrics));});
