import test from 'node:test';
import assert from 'node:assert/strict';
import {analyticsRows,dateWindow,readingCount} from '../src/lib/telemetry/details.js';
test('historical date window includes the latest reading day across month boundaries',()=>{
 assert.deepEqual(dateWindow(7,new Date(2026,7,5,21)),{start:'2026-07-30',end:'2026-08-05'});
 assert.deepEqual(dateWindow(1,new Date(2026,7,5,21)),{start:'2026-08-05',end:'2026-08-05'});
});
test('actual reading counts distinguish synthetic zero buckets from real telemetry',()=>{
 assert.equal(readingCount({enhanced_temperature_analytics:{total_readings:0},temperature_analytics:{labels:['00'],avg_temperature:[0]}}),0);
 assert.equal(readingCount({overall_statistics:{total_readings:18}}),18);
 assert.equal(readingCount({zone_summary:{total_readings:0}}),0);
 assert.equal(readingCount({ice_machine_summary:{total_readings:123}}),123);
 assert.equal(readingCount({}),null);
});
test('complete chart fields retain zero and negative readings while preserving gaps',()=>{
 const result=analyticsRows({labels:['a','b','c'],temp:[0,null,-12],count:[3,0]});
 assert.deepEqual(result.fields,['temp','count']);
 assert.deepEqual(result.rows,[{label:'a',temp:0,count:3},{label:'b',temp:null,count:0},{label:'c',temp:-12,count:null}]);
});
