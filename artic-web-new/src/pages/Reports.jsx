// Reports — alert summary for a window, report history from the backend, and
// a client-side PDF generator that registers each report via
// api/reports/generate/ (same contract as lib/screens/reports.dart).

import { useCallback, useEffect, useState } from 'react';
import { api } from '../api';
import { useAuth } from '../auth';
import { useDevices } from '../useDevices';
import { Empty, Panel, Spinner, fmtDay } from '../components/bits';

const iso = (d) => d.toISOString().slice(0, 10);

async function buildAndDownloadPdf(name, window_, alertSummary, devices, maintenance, generatedBy) {
  const { default: jsPDF } = await import('jspdf');
  const autoTable = (await import('jspdf-autotable')).default;

  const doc = new jsPDF({ unit: 'pt', format: 'a4' });
  const W = doc.internal.pageSize.getWidth();

  doc.setFillColor(34, 43, 69);
  doc.rect(0, 0, W, 84, 'F');
  doc.setTextColor(255, 255, 255);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(17);
  doc.text(name, 40, 40);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(10);
  doc.setTextColor(203, 213, 225);
  doc.text(`Period: ${window_.start} → ${window_.end} · Generated ${new Date().toLocaleString()} by ${generatedBy}`, 40, 62);

  doc.setTextColor(30, 41, 59);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(12);
  doc.text('Alert summary', 40, 116);
  const os = alertSummary?.overall_statistics ?? {};
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(10);
  [
    `Total alerts: ${os.total_alerts ?? 0} (active ${os.active_alerts ?? 0}, resolved ${os.resolved_alerts ?? 0})`,
    `High severity: ${os.high_count ?? 0} · Critical: ${os.critical_count ?? 0} · Affected devices: ${os.affected_devices ?? 0}`,
    `Average resolution time: ${os.avg_resolution_time_minutes ? Math.round(os.avg_resolution_time_minutes) + ' min' : '—'}`,
  ].forEach((l, i) => doc.text(l, 40, 136 + i * 15));

  autoTable(doc, {
    startY: 196,
    head: [['Device', 'Device ID', 'Type', 'Online', 'Location']],
    body: devices.map((d) => [d.name, d.device_id, d.device_type, d.is_online ? 'Yes' : 'No', d.location || '—']),
    styles: { fontSize: 8, cellPadding: 3 },
    headStyles: { fillColor: [34, 43, 69] },
    alternateRowStyles: { fillColor: [246, 248, 251] },
  });

  doc.save(`${name.toLowerCase().replace(/\s+/g, '-')}-${window_.start}.pdf`);
  return Math.max(1, doc.getNumberOfPages());
}

export default function Reports() {
  const { token, business, user } = useAuth();
  const { devices } = useDevices();
  const [history, setHistory] = useState(null);
  const [summary, setSummary] = useState(null);
  const [error, setError] = useState(null);
  const [days, setDays] = useState(30);
  const [generating, setGenerating] = useState(false);

  const bid = business.business_uid;

  const refresh = useCallback(async () => {
    setError(null);
    try {
      const end = new Date();
      const start = new Date(end.getTime() - days * 86400000);
      const [h, s] = await Promise.all([
        api.get(`/reports/history/${bid}/?limit=25`, token),
        api.get(`/alerts/summary/?business_id=${bid}&start_date=${iso(start)}&end_date=${iso(end)}`, token),
      ]);
      setHistory(h.reports ?? []);
      setSummary(s);
    } catch (e) {
      setError(e.message);
    }
  }, [token, bid, days]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function generate() {
    setGenerating(true);
    try {
      const end = new Date();
      const start = new Date(end.getTime() - days * 86400000);
      const window_ = { start: iso(start), end: iso(end) };
      const name = `Comprehensive Analytics Report — ${fmtDay(end)}`;
      const pages = await buildAndDownloadPdf(
        name,
        window_,
        summary,
        devices ?? [],
        null,
        user?.email || user?.username || 'ArticSentinel',
      );
      // Register the report so it appears in history, like the Flutter app.
      await api.post(
        '/reports/generate/',
        {
          report_type: 'comprehensive_analytics',
          report_name: name,
          business_id: bid,
          device_ids: (devices ?? []).map((d) => d.device_id),
          start_date: start.toISOString(),
          end_date: end.toISOString(),
          period: days === 1 ? 'Last 24 Hours' : `Last ${days} Days`,
          include_charts: true,
          include_raw_data: false,
          report_data: { alerts: summary?.overall_statistics ?? {} },
          generated_by: user?.email || user?.username || 'web',
          page_count: pages,
          file_size: '52KB',
        },
        token,
      );
      await refresh();
    } catch (e) {
      window.alert(`Report generation failed: ${e.message}`);
    } finally {
      setGenerating(false);
    }
  }

  const os = summary?.overall_statistics;

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Insights</div>
          <h1 className="page-title">Reports</h1>
          <p className="page-sub">Analytics summaries and generated report history.</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <div className="seg">
            {[7, 30, 90].map((d) => (
              <button key={d} className={d === days ? 'on' : ''} onClick={() => setDays(d)}>
                {d}d
              </button>
            ))}
          </div>
          <button className="btn flame" onClick={generate} disabled={generating || !devices}>
            {generating ? 'Generating…' : 'Generate PDF report'}
          </button>
        </div>
      </div>

      {error && <div className="form-err">{error}</div>}

      {os && (
        <div className="tiles">
          <div className="tile">
            <div className="eyebrow">Alerts ({days}d)</div>
            <div className="v">{os.total_alerts ?? 0}</div>
          </div>
          <div className="tile">
            <div className="eyebrow">Active</div>
            <div className="v" style={{ color: 'var(--flame)' }}>{os.active_alerts ?? 0}</div>
          </div>
          <div className="tile">
            <div className="eyebrow">High / critical</div>
            <div className="v">{(os.high_count ?? 0) + (os.critical_count ?? 0)}</div>
          </div>
          <div className="tile">
            <div className="eyebrow">Avg resolution</div>
            <div className="v">
              {os.avg_resolution_time_minutes ? Math.round(os.avg_resolution_time_minutes) : '—'}
              {os.avg_resolution_time_minutes ? <span className="unit">min</span> : ''}
            </div>
          </div>
        </div>
      )}

      <Panel title="Report history">
        {!history && <Spinner />}
        {history && history.length === 0 && <Empty>No reports generated yet.</Empty>}
        {history && history.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Type</th>
                  <th>Period</th>
                  <th>Devices</th>
                  <th>Generated</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {history.map((r) => (
                  <tr key={r.id}>
                    <td style={{ fontWeight: 600 }}>{r.report_name}</td>
                    <td className="ink2">{(r.report_type ?? '').replace(/_/g, ' ')}</td>
                    <td className="ink2">{r.period}</td>
                    <td className="ink2">{(r.device_ids ?? []).length}</td>
                    <td className="ink2">{r.created_at ? new Date(r.created_at).toLocaleString() : '—'}</td>
                    <td>
                      <span className={`chip ${r.status === 'completed' ? 'good' : 'warn'}`}>{r.status}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </>
  );
}
