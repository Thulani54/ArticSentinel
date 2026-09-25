// Gas cylinder dashboard — web port of GasCylinderDetailsDialog: gauge,
// readouts, performance (30/60/90 with daily/weekly aggregation), alerts and
// report exports, plus cylinder setup and scale connection details. Shows
// live scale data once the scale has reported; demo data (labelled) before.

import { useMemo, useState } from 'react';
import CylinderGauge from '../components/CylinderGauge';
import GasSetupPanel from '../components/GasSetupPanel';
import ScaleConnectPanel from '../components/ScaleConnectPanel';
import { GasBurnBarChart, GasCostLineChart } from '../components/GasCharts';
import {
  BandChip,
  Empty,
  Panel,
  PresenceChip,
  Spinner,
  formatAgo,
  fmtDay,
  useNow,
} from '../components/bits';
import {
  CURRENCY,
  bandFor,
  daysRemaining,
  dailySeries,
  kg1,
  money,
  summarize,
  todayUsage,
  trailingBurnPerDay,
  weeklySeries,
} from '../lib/gas/gasCore';
import { thresholdsFromConfig, useGasData } from '../lib/gas/useGasData';
import { downloadGasCsv, downloadGasPdf } from '../lib/gas/gasReports';

const RANGES = [30, 60, 90];

const SEVERITY = {
  critical: { cls: 'crit', label: 'Critical', icon: '!' },
  warning: { cls: 'warn', label: 'Warning', icon: '!' },
  info: { cls: 'good', label: 'Info', icon: '↑' },
};

export default function GasDashboard({ device }) {
  const { data, config, saveConfig } = useGasData(device);
  if (!data) return <Spinner />;
  return <GasDashboardBody device={device} data={data} config={config} saveConfig={saveConfig} />;
}

function GasDashboardBody({ device, data, config, saveConfig }) {
  const [range, setRange] = useState(30);
  const [exporting, setExporting] = useState(false);
  const now = useNow();

  const band = bandFor(data.currentLevelPct, config ? thresholdsFromConfig(config) : undefined);

  const perf = useMemo(() => {
    const series =
      range === 30 ? dailySeries(data.readings, data.pricePerKg) : weeklySeries(data.readings, data.pricePerKg);
    // Trim to the selected window (weekly buckets cover it).
    const cutoff = new Date(now.getTime() - range * 86400000);
    const trimmed = series.filter((p) => p.day.getTime() >= cutoff.getTime());
    return { series: trimmed, summary: summarize(trimmed, range) };
  }, [data, range, now]);

  const today = todayUsage(data.readings, data.pricePerKg, now);
  const burn = trailingBurnPerDay(data.readings, 7, now);
  const { emptyBy } = daysRemaining(data.currentNetKg, burn, now);

  async function exportPdf() {
    setExporting(true);
    try {
      await downloadGasPdf(device, data, perf.summary, range);
    } finally {
      setExporting(false);
    }
  }

  return (
    <>
      <div className="page-head">
        <div className="gas-hero">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <rect x="7" y="4.5" width="10" height="17" rx="3.2" fill="#EA580C" opacity="0.14" />
            <rect x="7" y="4.5" width="10" height="17" rx="3.2" stroke="#EA580C" strokeWidth="1.6" />
            <path d="M10 4.5V2.8h4v1.7" stroke="#EA580C" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
          <div>
            <div className="eyebrow">Gas Cylinder</div>
            <h1 className="page-title">{device.name}</h1>
            <p className="page-sub">
              {device.device_id}
              {device.location ? ` · ${device.location}` : ''}
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {data.live ? (
            <span className="chip good">LIVE SCALE</span>
          ) : (
            <span className="chip demo" title="The scale hasn't reported yet — showing simulated data">DEMO DATA</span>
          )}
          <PresenceChip online={!data.isOffline} lastSeen={formatAgo(data.latest.at, now)} />
        </div>
      </div>

      {!data.live && (
        <div className="banner warn">
          <strong>Showing demo data.</strong> Live readings replace it as soon as the scale sends its first
          weight — connection details are at the bottom of this page.
        </div>
      )}
      {data.live && data.latestRaw && data.latestRaw.gross_kg < data.spec.tareKg && (
        <div className="banner warn">
          <strong>
            The scale reads {kg1(data.latestRaw.gross_kg)} — less than the empty cylinder weight ({kg1(data.spec.tareKg)}).
          </strong>{' '}
          Gas shows as 0 until the reading is above the empty weight. Check the Cylinder setup below matches what&apos;s on
          the scale.
        </div>
      )}
      {band === 'low' && (
        <div className="banner crit">
          <strong>Low gas — {Math.round(data.currentLevelPct)}% remaining.</strong> Schedule a refill.
        </div>
      )}
      {data.isOffline && (
        <div className="banner warn">
          <strong>Monitor offline.</strong> Last reading {formatAgo(data.latest.at, now)} — usage since then
          isn&apos;t measured.
        </div>
      )}

      <div className="gas-grid">
        <Panel eyebrow="Current level" title="Cylinder">
          <CylinderGauge
            levelPct={data.currentLevelPct}
            netKg={data.currentNetKg}
            capacityKg={data.spec.capacityKg}
            band={band}
          />
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 10 }}>
            <BandChip band={band} />
          </div>
        </Panel>

        <Panel eyebrow="Right now" title="Readings">
          <div className="readouts">
            {data.live && data.latestRaw && (
              <div className="readout">
                <div className="eyebrow">On the scale</div>
                <div className="v">{kg1(data.latestRaw.gross_kg)}</div>
                <div className="s">cylinder + gas combined</div>
              </div>
            )}
            <div className="readout">
              <div className="eyebrow">Net gas</div>
              <div className="v">{kg1(data.currentNetKg)}</div>
              <div className="s">tare {data.spec.tareKg} kg excluded</div>
            </div>
            <div className="readout">
              <div className="eyebrow">Today so far</div>
              <div className="v">{kg1(today.kg)}</div>
              <div className="s">{money(today.cost)} at {money(data.pricePerKg)}/kg</div>
            </div>
            <div className="readout">
              <div className="eyebrow">Burn rate</div>
              <div className="v">{kg1(burn)}/day</div>
              <div className="s">7-day rolling average</div>
            </div>
            <div className="readout">
              <div className="eyebrow">Projection</div>
              <div className="v">{emptyBy ? fmtDay(emptyBy) : '—'}</div>
              <div className="s">empty by, at current burn</div>
            </div>
            <div className="readout">
              <div className="eyebrow">Capacity</div>
              <div className="v">
                {data.spec.gasKg}
                <span className="unit">kg class</span>
              </div>
              <div className="s">{kg1(data.spec.capacityKg)} usable when full</div>
            </div>
            <div className="readout">
              <div className="eyebrow">Last reading</div>
              <div className="v" style={{ fontSize: 15, paddingTop: 4 }}>
                {data.latest.at.toLocaleString(undefined, {
                  day: 'numeric',
                  month: 'short',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </div>
              <div className="s">
                {kg1(data.latestRaw?.gross_kg ?? data.latest.weightKg)} on the scale
                {data.latestRaw?.battery_pct != null ? ` · battery ${Math.round(data.latestRaw.battery_pct)}%` : ''}
              </div>
            </div>
          </div>
        </Panel>
      </div>

      <Panel
        className="mt16"
        eyebrow="Performance"
        title={`Usage — last ${range} days`}
        actions={
          <div className="seg" role="tablist" aria-label="Range">
            {RANGES.map((r) => (
              <button key={r} className={r === range ? 'on' : ''} onClick={() => setRange(r)}>
                {r}d
              </button>
            ))}
          </div>
        }
      >
        <div className="readouts" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', marginBottom: 16 }}>
          <div className="readout">
            <div className="eyebrow">Consumed</div>
            <div className="v">{kg1(perf.summary.totalKg)}</div>
          </div>
          <div className="readout">
            <div className="eyebrow">Cost</div>
            <div className="v">{money(perf.summary.totalCost)}</div>
          </div>
          <div className="readout">
            <div className="eyebrow">Avg / day</div>
            <div className="v">{money(perf.summary.avgDailyCost)}</div>
            <div className="s">{kg1(perf.summary.avgDailyKg)}</div>
          </div>
          <div className="readout">
            <div className="eyebrow">Peak {range === 30 ? 'day' : 'week'}</div>
            <div className="v">{perf.summary.peak ? kg1(perf.summary.peak.kg) : '—'}</div>
            <div className="s">{perf.summary.peak ? fmtDay(perf.summary.peak.day) : ''}</div>
          </div>
        </div>

        <div className="chart-pair">
          <div>
            <div className="eyebrow" style={{ marginBottom: 8 }}>
              Gas burned {range === 30 ? 'daily (kg)' : 'weekly (kg)'}
            </div>
            <div className="chart-box">
              <GasBurnBarChart series={perf.series} />
            </div>
          </div>
          <div>
            <div className="eyebrow" style={{ marginBottom: 8 }}>
              Cost {range === 30 ? 'daily' : 'weekly'} ({CURRENCY})
            </div>
            <div className="chart-box">
              <GasCostLineChart series={perf.series} />
            </div>
          </div>
        </div>
      </Panel>

      <Panel className="mt16" eyebrow="History" title="Alerts">
        {data.alerts.length === 0 ? (
          <Empty>No alerts in this period.</Empty>
        ) : (
          data.alerts.slice(0, 5).map((a, i) => {
            const s = SEVERITY[a.severity];
            return (
              <div className="alert-row" key={i}>
                <div className={`ico chip ${s.cls}`}>{s.icon}</div>
                <div>
                  <div className="t">{a.title}</div>
                  <div className="d">{a.detail}</div>
                </div>
                <div className="when">{formatAgo(a.at, now)}</div>
              </div>
            );
          })
        )}
      </Panel>

      <Panel className="mt16" eyebrow="Reports" title="Export">
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn primary" disabled={exporting} onClick={exportPdf}>
            {exporting ? 'Preparing…' : `Download PDF (last ${range}d)`}
          </button>
          <button className="btn" onClick={() => downloadGasCsv(device, data)}>
            Download CSV
          </button>
        </div>
        <p className="s ink2" style={{ fontSize: 12, marginTop: 10 }}>
          PDF summarises the selected {range}-day window; CSV contains the full reading series.
        </p>
      </Panel>

      <div className="mt16">
        <GasSetupPanel
          config={config}
          latestGrossKg={data.live ? data.latestRaw?.gross_kg ?? null : null}
          onSave={saveConfig}
        />
      </div>

      <div className="mt16">
        <ScaleConnectPanel
          device={device}
          tareKg={config?.tare_kg ?? null}
          capacityKg={config?.gas_capacity_kg ?? null}
        />
      </div>
    </>
  );
}
