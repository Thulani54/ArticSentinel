export const VIEW_KEYS=['tab','company','q','status','from','to','type','attention','sort','page','days','severity'];
export function cleanView(query){
  const input=new URLSearchParams(query),result=new URLSearchParams();
  for(const key of VIEW_KEYS){const value=input.get(key);if(value)result.set(key,value.slice(0,120));}
  return result;
}
export function readViews(key){
  try{const value=JSON.parse(localStorage.getItem(key)||'[]');return Array.isArray(value)?value.filter(x=>x&&typeof x.name==='string'&&typeof x.query==='string').slice(0,8):[];}catch{return [];}
}
