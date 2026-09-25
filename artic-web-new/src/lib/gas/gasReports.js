// Report exports for the gas dashboard — CSV + PDF, mirroring
// lib/gasmon/gas_report.dart's behaviour (PDF for print/sharing, CSV raw).

import { levelPercent, netGasKg } from './gasCore';

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

const stamp = () => new Date().toISOString().slice(0, 10);

export function downloadGasCsv(device, data) {
  const rows = [['timestamp', 'weight_kg', 'net_kg', 'level_pct']];
  for (const r of data.readings) {
    rows.push([
      r.at.toISOString(),
      r.weightKg.toFixed(2),
      netGasKg(r.weightKg, data.spec.tareKg).toFixed(2),
      levelPercent(r.weightKg, data.spec.tareKg, data.spec.fullKg).toFixed(1),
    ]);
  }
  const csv = rows.map((r) => r.join(',')).join('\n');
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8' }), `gas-report-${device.device_id}-${stamp()}.csv`);
}

export async function downloadGasPdf(device, data, summary, rangeDays) {
  const { default: jsPDF } = await import('jspdf');
  const autoTable = (await import('jspdf-autotable')).default;

  const doc = new jsPDF({ unit: 'pt', format: 'a4' });
  const W = doc.internal.pageSize.getWidth();

  // Navy header band, matching the Flutter report's look.
  doc.setFillColor(34, 43, 69);
  doc.rect(0, 0, W, 92, 'F');
  doc.setTextColor(255, 255, 255);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(18);
  doc.text('Gas Cylinder Report', 40, 42);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(11);
  doc.setTextColor(203, 213, 225);
  doc.text(`${device.name} · ${device.device_id} · ${device.location || '—'}`, 40, 62);
  doc.text(`Generated ${new Date().toLocaleString()}`, 40, 78);

  // Summary block.
  doc.setTextColor(30, 41, 59);
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(12);
  doc.text(`Last ${rangeDays} days`, 40, 122);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(10);

  const fmtKg = (v) => `${v.toFixed(1)} kg`;
  const fmtR = (v) => `R${v.toFixed(2)}`;
  const lines = [
    `Gas remaining: ${fmtKg(data.currentNetKg)} (${Math.round(data.currentLevelPct)}% of capacity)`,
    `Consumption:   ${fmtKg(summary.totalKg)} total · ${fmtKg(summary.avgDailyKg)}/day avg`,
    `Cost:          ${fmtR(summary.totalCost)} total · ${fmtR(summary.avgDailyCost)}/day avg`,
    `Peak day:      ${summary.peak ? `${summary.peak.day.toLocaleDateString()} (${fmtKg(summary.peak.kg)})` : '—'}`,
    `Price assumed: ${fmtR(data.pricePerKg)}/kg`,
  ];
  lines.forEach((l, i) => doc.text(l, 40, 142 + i * 15));

  autoTable(doc, {
    startY: 232,
    head: [['Timestamp', 'Weight (kg)', 'Net gas (kg)', 'Level (%)']],
    body: data.readings.map((r) => [
      r.at.toLocaleString(),
      r.weightKg.toFixed(2),
      netGasKg(r.weightKg, data.spec.tareKg).toFixed(2),
      levelPercent(r.weightKg, data.spec.tareKg, data.spec.fullKg).toFixed(1),
    ]),
    styles: { fontSize: 8, cellPadding: 3 },
    headStyles: { fillColor: [34, 43, 69] },
    alternateRowStyles: { fillColor: [246, 248, 251] },
  });

  const pageCount = doc.getNumberOfPages();
  for (let p = 1; p <= pageCount; p++) {
    doc.setPage(p);
    doc.setFontSize(8);
    doc.setTextColor(148, 163, 184);
    doc.text(
      `ArticSentinel · ${data.live ? 'live scale data' : 'demo data'} · page ${p} of ${pageCount}`,
      W / 2,
      doc.internal.pageSize.getHeight() - 20,
      { align: 'center' },
    );
  }

  doc.save(`gas-report-${device.device_id}-${stamp()}.pdf`);
}
