import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/app_models.dart';

class PdfReportService {
  Future<String> generateReport(
      List<ReportSection> sections, String dbName) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Database Analysis Report: $dbName',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Divider(color: PdfColors.blue200),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('AI Database Analyzer — Page ${context.pageNumber}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
        build: (context) {
          final items = <pw.Widget>[];
          for (int i = 0; i < sections.length; i++) {
            items.addAll([
              pw.SizedBox(height: 16),
              pw.Text(
                '${i + 1}. ${sections[i].title}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 8),
              ...sections[i].content.split('\n').map((line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  )),
              pw.Divider(color: PdfColors.grey300),
            ]);
          }
          return items;
        },
      ),
    );

    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/${dbName}_Comprehensive_Analysis.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await doc.save());
    return filePath;
  }
}
