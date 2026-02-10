import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../models/mission_details.dart';
import '../models/risk_entry.dart';

// ---------------------------------------------------------------------------
// Colour palette – military OD-green / black theme
// ---------------------------------------------------------------------------
const _black = PdfColor(0.05, 0.05, 0.05); // near-black background
const _darkGreen = PdfColor(0.11, 0.24, 0.15); // #1C3D2C
const _midGreen = PdfColor(0.18, 0.29, 0.25); // section headers
const _accentGreen = PdfColor(0.29, 0.40, 0.25); // #4A6741 borders/accents
const _lightGreen = PdfColor(0.72, 0.83, 0.66); // #B8D4A8 headings text
const _paleGreen = PdfColor(0.83, 0.91, 0.78); // #D4E8C8 body text
const _gold = PdfColor(0.85, 0.75, 0.20); // accent stripe / score bg
const _white = PdfColor(1, 1, 1);

// Risk-badge colours  (match the Flutter app exactly)
const _riskColors = {
  'Low risk': [PdfColor(0.30, 0.69, 0.31), _black], // green  / black text
  'Moderate risk': [PdfColor(1.0, 0.76, 0.04), _black], // yellow / black text
  'High risk': [PdfColor(1.0, 0.60, 0.0), _black], // orange / black text
  'Very high risk': [PdfColor(0.96, 0.26, 0.21), _white], // red    / white text
  'Extreme risk': [PdfColor(0.20, 0.20, 0.20), _white], // dark   / white text
};

String _riskLabel(double score) {
  if (score >= 21) return 'Extreme risk';
  if (score >= 15) return 'Very high risk';
  if (score >= 10) return 'High risk';
  if (score >= 5) return 'Moderate risk';
  if (score >= 1) return 'Low risk';
  return '-';
}

class ExportService {
  // Platform channel for Android MediaStore
  static const platform = MethodChannel('com.yourapp.export/mediastore');

  // ─────────────────────────────────────────────────────────────────────────
  // Save file to appropriate location based on platform
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> _saveFile({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (Platform.isAndroid) {
      // Use MediaStore API for Android (the CORRECT way for Android 10+)
      try {
        final result = await platform.invokeMethod('saveToDownloads', {
          'fileName': fileName,
          'fileBytes': fileBytes,
          'mimeType': mimeType,
        });
        return result as String?;
      } catch (e) {
        print('Error saving to MediaStore: $e');
        return null;
      }
    } else if (Platform.isIOS) {
      // For iOS, save to Documents directory (accessible via Files app)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      return file.path;
    } else if (Platform.isWindows) {
      // Windows - use Downloads folder
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsDir = Directory('$userProfile\\Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final file = File('${downloadsDir.path}\\$fileName');
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
      // Fallback
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final file = File('${dir.path}\\$fileName');
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
    } else if (Platform.isMacOS) {
      // macOS - use Downloads directory
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
    } else if (Platform.isLinux) {
      // Linux - use Downloads directory
      final home = Platform.environment['HOME'];
      if (home != null) {
        final downloadsDir = Directory('$home/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(fileBytes);
        return file.path;
      }
    }

    // Ultimate fallback - app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(fileBytes);
    return file.path;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Excel (CSV format)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> exportExcel({
    required MissionDetails mission,
    required Map<String, List<dynamic>> rowsByCategory,
    required double? ormScore,
  }) async {
    final buffer = StringBuffer()
      ..writeln('ORM Risk Assessment')
      ..writeln('Pilot,${mission.pilotName}')
      ..writeln('Code,${mission.pilotCode}')
      ..writeln('Mission,${mission.missionType}')
      ..writeln('Date,${mission.missionTime}')
      ..writeln('ORM Score,${ormScore ?? ""}')
      ..writeln('')
      ..writeln(
          'Category,Title,Description,Likelihood,Severity,Deduction,Risk,Final');

    rowsByCategory.forEach((category, rows) {
      for (final r in rows) {
        buffer.writeln(
          '$category,'
          '${_csv(r.title)},'
          '${_csv(r.description)},'
          '${r.likelihood},'
          '${r.severity},'
          '${r.deduction},'
          '${r.riskValue},'
          '${r.finalRiskValue}',
        );
      }
    });

    final fileBytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    return await _saveFile(
      fileName: 'orm_assessment_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      fileBytes: fileBytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CSV
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> exportCsv({
    required MissionDetails mission,
    required Map<String, List<dynamic>> rowsByCategory,
  }) async {
    final rows = <String>[
      'Category,Title,Description,Likelihood,Severity,Deduction,Risk,Final'
    ];

    rowsByCategory.forEach((category, risks) {
      for (final r in risks) {
        rows.add(
          '$category,'
          '${_csv(r.title)},'
          '${_csv(r.description)},'
          '${r.likelihood},'
          '${r.severity},'
          '${r.deduction},'
          '${r.riskValue},'
          '${r.finalRiskValue}',
        );
      }
    });

    final fileBytes = Uint8List.fromList(utf8.encode(rows.join('\n')));
    return await _saveFile(
      fileName: 'orm_assessment_${DateTime.now().millisecondsSinceEpoch}.csv',
      fileBytes: fileBytes,
      mimeType: 'text/csv',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PDF  – real PDF with military design
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String?> exportPdf({
    required MissionDetails mission,
    required Map<String, List<dynamic>> rowsByCategory,
    required double? ormScore,
  }) async {
    final pdf = pw.Document(
      title: 'ORM Risk Assessment',
      author: mission.pilotName,
      subject: mission.missionType,
    );

    // ── helper styles ────────────────────────────────────────────────────
    final titleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: _white,
    );
    final subTitleStyle = pw.TextStyle(
      fontSize: 11,
      color: _lightGreen,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _white,
    );
    final cellStyle = pw.TextStyle(
      fontSize: 8,
      color: _paleGreen,
    );
    final catHeaderStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: _lightGreen,
    );

    // ── column widths (proportional) ─────────────────────────────────────
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.5), // Title
      1: const pw.FlexColumnWidth(2.5), // Description
      2: const pw.FlexColumnWidth(1.2), // Likelihood
      3: const pw.FlexColumnWidth(1.2), // Severity
      4: const pw.FlexColumnWidth(1.0), // Deduction
      5: const pw.FlexColumnWidth(1.2), // Risk
      6: const pw.FlexColumnWidth(1.5), // Final Risk
    };

    final headers = [
      'Title',
      'Description',
      'Likelihood',
      'Severity',
      'Deduction',
      'Risk',
      'Final Risk',
    ];

    // ── build story (page content) ───────────────────────────────────────
    final story = <pw.Widget>[];

    // --- ORM Score badge ---
    if (ormScore != null) {
      final label = _riskLabel(ormScore);
      final colors = _riskColors[label] ?? [_accentGreen, _white];

      story.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: pw.BoxDecoration(
            color: colors[0],
            border: pw.Border.all(color: _gold, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'OVERALL ORM SCORE:  ${ormScore.toStringAsFixed(0)}  –  $label',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: colors[1],
                ),
              ),
            ],
          ),
        ),
      );
      story.add(pw.SizedBox(height: 14));
    }

    // --- Per-category tables ---
    for (final cat in rowsByCategory.keys) {
      final rows = rowsByCategory[cat]!;
      if (rows.isEmpty) continue;

      // Category header bar
      story.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: _midGreen,
            border: pw.Border(
              bottom: pw.BorderSide(color: _gold, width: 1.5),
            ),
          ),
          child: pw.Text(cat.toUpperCase(), style: catHeaderStyle),
        ),
      );
      story.add(pw.SizedBox(height: 4));

      // Table
      story.add(
        pw.Table(
          columnWidths: colWidths,
          border: pw.TableBorder.all(color: _accentGreen, width: 0.5),
          children: [
            // header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _darkGreen),
              children: headers
                  .map(
                    (h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(h, style: tableHeaderStyle),
                    ),
                  )
                  .toList(),
            ),
            // data rows
            ...rows.map((r) {
              final riskVal = r.riskValue as double;
              final finalVal = r.finalRiskValue as double;
              final riskLabel = _riskLabel(riskVal);
              final finalLabel = _riskLabel(finalVal);

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor(0.08, 0.08, 0.08),
                ),
                children: [
                  // Title
                  _cell(r.title as String, cellStyle),
                  // Description
                  _cell(r.description as String, cellStyle),
                  // Likelihood
                  _cell('${r.likelihood}', cellStyle),
                  // Severity
                  _cell('${r.severity}', cellStyle),
                  // Deduction
                  _cell('${(r.deduction as double).toStringAsFixed(1)}',
                      cellStyle),
                  // Risk value + badge
                  _riskCell(riskVal, riskLabel),
                  // Final risk + badge
                  _riskCell(finalVal, finalLabel),
                ],
              );
            }),
          ],
        ),
      );
      story.add(pw.SizedBox(height: 12));
    }

    // ── add pages with header + footer ──────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 70, 28, 50),
        header: (ctx) => _pageHeader(mission),
        footer: (ctx) => _pageFooter(ctx, mission),
        build: (ctx) => story,
      ),
    );

    // ── save to Downloads ───────────────────────────────────────────────
    final pdfBytes = await pdf.save();
    return await _saveFile(
      fileName: 'orm_assessment_${DateTime.now().millisecondsSinceEpoch}.pdf',
      fileBytes: pdfBytes,
      mimeType: 'application/pdf',
    );
  }

  // ─── Page Header ──────────────────────────────────────────────────────────
  static pw.Widget _pageHeader(MissionDetails mission) {
    return pw.Column(
      children: [
        // top colour bar
        pw.Container(
          width: double.infinity,
          height: 6,
          decoration: pw.BoxDecoration(color: _gold),
        ),
        pw.SizedBox(height: 6),
        // title row
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: _darkGreen,
            border: pw.Border(
              bottom: pw.BorderSide(color: _accentGreen, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ORM RISK ASSESSMENT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _lightGreen,
                  )),
              pw.Text(mission.missionTime,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _paleGreen,
                  )),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // crew info row
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColor(0.08, 0.18, 0.12),
            border: pw.Border.all(color: _accentGreen, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                  'Pilot: ${mission.pilotName}  |  Code: ${mission.pilotCode}',
                  style: pw.TextStyle(fontSize: 8, color: _paleGreen)),
              pw.Text('Mission: ${mission.missionType}',
                  style: pw.TextStyle(fontSize: 8, color: _paleGreen)),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  // ─── Page Footer ──────────────────────────────────────────────────────────
  static pw.Widget _pageFooter(pw.Context ctx, MissionDetails mission) {
    return pw.Column(
      children: [
        pw.Divider(color: _accentGreen, height: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                'ORM Assessment – ${mission.pilotName} / ${mission.missionType}',
                style: pw.TextStyle(fontSize: 7, color: _accentGreen)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: _accentGreen)),
            pw.Text('CONFIDENTIAL',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: _gold,
                )),
          ],
        ),
        pw.SizedBox(height: 2),
        // bottom gold stripe
        pw.Container(
          width: double.infinity,
          height: 3,
          decoration: pw.BoxDecoration(color: _gold),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static pw.Widget _cell(String text, pw.TextStyle style) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text, style: style),
      );

  static pw.Widget _riskCell(double value, String label) {
    final colors = _riskColors[label] ?? [_accentGreen, _white];
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: colors[0],
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          '${value.toInt()} – $label',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: colors[1],
          ),
        ),
      ),
    );
  }

  static String _csv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
