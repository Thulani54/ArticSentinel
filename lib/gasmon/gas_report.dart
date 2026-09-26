/// PDF/CSV export for the gas dashboard. Delivery mirrors the app's own
/// reports screen: browser download on web (universal_html anchor), share
/// sheet via `printing` for PDF on mobile, saved file + snackbar for CSV.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import 'gas_core.dart';
import 'gas_theme.dart';

enum GasReportFormat { pdf, csv }

class GasReportInput {
  const GasReportInput({
    required this.deviceName,
    required this.deviceId,
    required this.spec,
    required this.points,
    required this.rangeDays,
    required this.pricePerKg,
    required this.levelPct,
    required this.netKg,
  });

  final String deviceName;
  final String deviceId;
  final GasSpec spec;

  /// Daily points for the chosen range.
  final List<DayPoint> points;
  final int rangeDays;
  final double pricePerKg;
  final double levelPct;
  final double netKg;
}

/// Builds and delivers the report. [context] is only used for the mobile
/// "saved to …" snackbar; safe to omit on web.
Future<void> downloadGasReport({
  required GasReportInput input,
  required GasReportFormat format,
  BuildContext? context,
}) async {
  final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
  final safeId = input.deviceId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final name =
      'gas-report-$safeId-$stamp.${format == GasReportFormat.pdf ? 'pdf' : 'csv'}';

  if (format == GasReportFormat.pdf) {
    final bytes = await _buildPdf(input);
    if (kIsWeb) {
      _downloadBytes(bytes, name, 'application/pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: name);
    }
    return;
  }

  final csv = _buildCsv(input);
  if (kIsWeb) {
    _downloadBytes(utf8.encode(csv), name, 'text/csv');
    return;
  }

  // Mobile/desktop: save to the user's downloads (or documents) and tell
  // them where it went.
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    dir = await getDownloadsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsString(csv);
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV saved to ${file.path}'),
        backgroundColor: GasPalette.good,
      ),
    );
  }
}

void _downloadBytes(List<int> bytes, String name, String mime) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

String _buildCsv(GasReportInput input) {
  final df = DateFormat('yyyy-MM-dd');
  final rows = <List<dynamic>>[
    ['Gas Cylinder Report', input.deviceName, input.deviceId],
    [
      'Range',
      '${input.rangeDays} days',
      'Price/kg',
      money(input.pricePerKg),
    ],
    [
      'Level now',
      '${input.levelPct.toStringAsFixed(0)}%',
      'Gas now',
      kg1(input.netKg),
    ],
    [],
    ['Date', 'Usage (kg)', 'Cost ($kCurrency)'],
    for (final p in input.points)
      [df.format(p.day), p.kg.toStringAsFixed(2), p.cost.toStringAsFixed(2)],
  ];
  return const ListToCsvConverter().convert(rows);
}

Future<Uint8List> _buildPdf(GasReportInput input) async {
  final doc = pw.Document();
  final totalKg = input.points.fold<double>(0, (a, p) => a + p.kg);
  final totalCost = input.points.fold<double>(0, (a, p) => a + p.cost);
  final summary = <(String, String)>[
    ('Device', '${input.deviceName} (${input.deviceId})'),
    ('Cylinder', '${input.spec.gasKg} kg LPG'),
    (
      'Level now',
      '${input.levelPct.toStringAsFixed(0)}% · ${kg1(input.netKg)}'
    ),
    ('Range', 'Last ${input.rangeDays} days'),
    ('Price assumed', '${money(input.pricePerKg)} / kg'),
  ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
    footer: (ctx) => pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Generated ${DateFormat('d MMM yyyy').format(DateTime.now())}'
        ' · ArticSentinel Gas Monitoring · demo data',
        style: const pw.TextStyle(
            fontSize: 8, color: PdfColor.fromInt(0xFF64748B)),
      ),
    ),
    build: (ctx) => [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF222B45)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('GAS CYLINDER REPORT',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFFFFFFFF))),
            pw.SizedBox(height: 4),
            pw.Text('${input.deviceName} · ${input.deviceId}',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColor.fromInt(0xFFCBD5E1))),
          ],
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          for (final (k, v) in summary)
            pw.SizedBox(
              width: 150,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(k.toUpperCase(),
                      style: const pw.TextStyle(
                          fontSize: 7.5, color: PdfColor.fromInt(0xFF64748B))),
                  pw.SizedBox(height: 2),
                  pw.Text(v,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1E293B))),
                ],
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Total usage ${totalKg.toStringAsFixed(1)} kg'
        ' · Total cost ${money(totalCost)}',
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFFC2410C)),
      ),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Usage (kg)', 'Cost ($kCurrency)'],
        data: [
          for (final p in input.points)
            [
              DateFormat('yyyy-MM-dd').format(p.day),
              p.kg.toStringAsFixed(2),
              p.cost.toStringAsFixed(2),
            ],
        ],
        headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFFFFFFFF)),
        headerDecoration:
            const pw.BoxDecoration(color: PdfColor.fromInt(0xFF222B45)),
        cellStyle: const pw.TextStyle(
            fontSize: 9, color: PdfColor.fromInt(0xFF334155)),
        cellAlignment: pw.Alignment.centerLeft,
        oddRowDecoration:
            const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
      ),
    ],
  ));
  return doc.save();
}
