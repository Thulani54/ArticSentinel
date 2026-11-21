export const DEFAULT_PREFERENCES = { density: 'comfortable', reduceMotion: false };
export const preferenceKey = user => `artic_preferences:${user?.id ?? user?.email ?? user?.username ?? 'session'}`;
export function readPreferences(key) {
  try { const p = JSON.parse(localStorage.getItem(key)); return { density: p?.density === 'compact' ? 'compact' : 'comfortable', reduceMotion: p?.reduceMotion === true }; }
  catch { return { ...DEFAULT_PREFERENCES }; }
}
export function applyPreferences(p) {
  document.documentElement.dataset.density = p.density;
  document.documentElement.dataset.reduceMotion = String(p.reduceMotion);
}
