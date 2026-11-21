import test from 'node:test';
import assert from 'node:assert/strict';
import {cleanView,readViews} from '../src/lib/admin/views.js';

test('saved and shared views preserve filters without credentials or unknown fields',()=>{
  const view=cleanView('tab=alerts&company=7&attention=unresolved&severity=critical&days=90&token=secret&password=secret&redirect=https://example.com');
  assert.equal(view.toString(),'tab=alerts&company=7&attention=unresolved&days=90&severity=critical');
  assert.equal(cleanView({q:'a'.repeat(500)}).get('q').length,120);
});

test('stored views tolerate invalid data and enforce the eight-view limit',()=>{
  const original=globalThis.localStorage;
  try{
    globalThis.localStorage={getItem:()=>'{broken'};
    assert.deepEqual(readViews('views'),[]);
    globalThis.localStorage.getItem=()=>JSON.stringify([null,{},...Array.from({length:10},(_,i)=>({name:`View ${i}`,query:'tab=devices'}))]);
    assert.equal(readViews('views').length,8);
    assert.equal(readViews('views')[0].name,'View 0');
    globalThis.localStorage.getItem=()=>'{"not":"an array"}';
    assert.deepEqual(readViews('views'),[]);
  }finally{globalThis.localStorage=original;}
});
