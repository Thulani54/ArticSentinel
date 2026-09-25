// Cylinder setup: the scale only reports combined weight (cylinder + gas), so
// the empty-cylinder weight (tare) and gas capacity set here are what turn a
// scale reading into kilograms of gas and a level percentage.

import { useEffect, useState } from 'react';
import { CYLINDER_SIZES } from '../lib/gas/gasCore';
import { Panel } from './bits';

const PRESETS = Object.entries(CYLINDER_SIZES).map(([gas, t]) => ({
  gas: Number(gas),
  tare: t.tare,
}));

function toForm(config) {
  return {
    gas_capacity_kg: String(config?.gas_capacity_kg ?? 19),
    tare_kg: String(config?.tare_kg ?? 15.6),
    price_per_kg: String(config?.price_per_kg ?? 28.5),
    low_threshold_pct: String(config?.low_threshold_pct ?? 20),
    warning_threshold_pct: String(config?.warning_threshold_pct ?? 50),
  };
}

export default function GasSetupPanel({ config, latestGrossKg, onSave }) {
  const [form, setForm] = useState(() => toForm(config));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const [saved, setSaved] = useState(false);

  // Reset only when the saved setup changes — not on every data refresh,
  // which would wipe what the user is typing.
  useEffect(() => {
    setForm(toForm(config));
  }, [config?.updated_at, config?.is_default]); // eslint-disable-line react-hooks/exhaustive-deps

  const set = (k) => (e) => {
    setSaved(false);
    setForm((f) => ({ ...f, [k]: e.target.value }));
  };

  const capacity = Number(form.gas_capacity_kg);
  const tare = Number(form.tare_kg);
  const preset = PRESETS.find((p) => p.gas === capacity && p.tare === tare);

  function applyPreset(e) {
    const p = PRESETS.find((x) => String(x.gas) === e.target.value);
    if (!p) return;
    setSaved(false);
    setForm((f) => ({ ...f, gas_capacity_kg: String(p.gas), tare_kg: String(p.tare) }));
  }

  // A freshly fitted full cylinder weighs tare + capacity, so the tare is
  // whatever the scale reads now minus the capacity.
  function tareFromFullCylinder() {
    if (latestGrossKg == null || !(capacity > 0)) return;
    const t = Math.round((latestGrossKg - capacity) * 10) / 10;
    if (t <= 0) {
      setError(`The scale reads ${latestGrossKg} kg — less than a full ${capacity} kg cylinder, so it can't be full.`);
      return;
    }
    setSaved(false);
    setError(null);
    setForm((f) => ({ ...f, tare_kg: String(t) }));
  }

  async function onSubmit(e) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setSaved(false);
    try {
      await onSave(Object.fromEntries(Object.entries(form).map(([k, v]) => [k, Number(v)])));
      setSaved(true);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  const full = capacity > 0 && tare > 0 ? capacity + tare : null;

  return (
    <Panel eyebrow="Setup" title="Cylinder setup">
      <form onSubmit={onSubmit}>
        <div className="form-grid">
          <div className="full">
            <label htmlFor="gassetuppanel-field-1">Cylinder size</label>
            <select id="gassetuppanel-field-1" value={preset ? String(preset.gas) : 'custom'} onChange={applyPreset}>
              {PRESETS.map((p) => (
                <option key={p.gas} value={String(p.gas)}>
                  {p.gas} kg cylinder (typical empty weight {p.tare} kg)
                </option>
              ))}
              <option value="custom">Custom — enter the weights below</option>
            </select>
          </div>
          <div>
            <label htmlFor="gassetuppanel-field-2">Empty cylinder weight (kg) *</label>
            <input id="gassetuppanel-field-2" type="number" step="0.1" min="0.1" value={form.tare_kg} onChange={set('tare_kg')} required />
            <div className="hint">The &ldquo;TW&rdquo; figure stamped on the cylinder collar.</div>
          </div>
          <div>
            <label htmlFor="gassetuppanel-field-3">Gas when full (kg) *</label>
            <input id="gassetuppanel-field-3" type="number" step="0.1" min="0.1" value={form.gas_capacity_kg} onChange={set('gas_capacity_kg')} required />
            <div className="hint">{full ? `A full cylinder weighs ${full.toFixed(1)} kg on the scale.` : ' '}</div>
          </div>
          <div>
            <label htmlFor="gassetuppanel-field-4">Gas price (R per kg)</label>
            <input id="gassetuppanel-field-4" type="number" step="0.01" min="0" value={form.price_per_kg} onChange={set('price_per_kg')} />
          </div>
          <div />
          <div>
            <label htmlFor="gassetuppanel-field-5">Low level alert (%)</label>
            <input id="gassetuppanel-field-5" type="number" step="1" min="1" max="98" value={form.low_threshold_pct} onChange={set('low_threshold_pct')} />
          </div>
          <div>
            <label htmlFor="gassetuppanel-field-6">Warning level (%)</label>
            <input id="gassetuppanel-field-6" type="number" step="1" min="2" max="99" value={form.warning_threshold_pct} onChange={set('warning_threshold_pct')} />
          </div>
        </div>

        {error && <div className="form-err" style={{ marginTop: 14 }}>{error}</div>}
        {saved && <div className="form-ok" style={{ marginTop: 14 }}>Setup saved — levels recalculated.</div>}

        <div style={{ display: 'flex', gap: 10, marginTop: 16, flexWrap: 'wrap', alignItems: 'center' }}>
          <button className="btn flame" disabled={busy}>{busy ? 'Saving…' : 'Save setup'}</button>
          {latestGrossKg != null && (
            <button type="button" className="btn" onClick={tareFromFullCylinder}>
              Set empty weight from a full cylinder
            </button>
          )}
        </div>
        {latestGrossKg != null && (
          <div className="hint" style={{ marginTop: 8 }}>
            Just fitted a full cylinder with no stamped weight? The scale reads {latestGrossKg} kg now — this works out the empty weight from that.
          </div>
        )}
      </form>
    </Panel>
  );
}
