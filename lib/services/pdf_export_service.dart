import 'package:pdf/pdf.dart'; // Trigger rebuild
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> exportTableToPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? startDate,
    DateTime? endDate,
    String userName = 'ผู้ใช้งาน',
  }) async {
    // Load Thai font from Google Fonts
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // Portrait orientation
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(
          title: title,
          startDate: startDate,
          endDate: endDate,
          userName: userName,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
          font: font,
          fontBold: fontBold,
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _buildTable(headers, rows, font, fontBold),
        ],
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name:
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String title,
    required DateTime? startDate,
    required DateTime? endDate,
    required String userName,
    required int pageNumber,
    required int pagesCount,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    final now = DateTime.now();
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange =
          'วันที่ ${_formatThaiDate(startDate)} ถึง ${_formatThaiDate(endDate)}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Date Range | Page Number
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'รายงานข้อมูลรายวัน $dateRange',
                  style: pw.TextStyle(font: fontBold, fontSize: 11),
                ),
              ),
              pw.Text(
                'หน้าที่ $pageNumber/$pagesCount',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          // Row 2: Print Date | User Name
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'วันที่ออกรายงาน ${_formatThaiDate(now)}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'ผู้ออกรายงาน $userName',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(
    List<String> headers,
    List<List<String>> rows,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: _getColumnWidths(headers.length),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map(
                (header) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(font: fontBold, fontSize: 9),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...rows.map((row) {
          final isTotal = row.isNotEmpty && row[0].contains('รวม');
          return pw.TableRow(
            decoration: isTotal
                ? const pw.BoxDecoration(color: PdfColors.grey100)
                : null,
            children: row.asMap().entries.map((entry) {
              final index = entry.key;
              final cell = entry.value;
              final isNumeric =
                  index >= row.length - 2; // Last 2 columns are numeric

              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                alignment: isNumeric
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(
                    font: isTotal ? fontBold : font,
                    fontSize: 8,
                  ),
                  textAlign: isNumeric ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> _getColumnWidths(int columnCount) {
    // Flexible widths based on column count
    if (columnCount == 6) {
      return {
        0: const pw.FlexColumnWidth(1.2), // วันที่/ผังบัญชี
        1: const pw.FlexColumnWidth(1.5), // สมุดรายวัน/คำอธิบาย
        2: const pw.FlexColumnWidth(1.2), // เลขที่เอกสาร
        3: const pw.FlexColumnWidth(2.0), // คำอธิบาย
        4: const pw.FlexColumnWidth(1.0), // เดบิต
        5: const pw.FlexColumnWidth(1.0), // เครดิต
      };
    } else if (columnCount == 7) {
      return {
        0: const pw.FlexColumnWidth(1.0),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.0),
        6: const pw.FlexColumnWidth(1.0),
      };
    } else if (columnCount == 8) {
      return {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(0.9),
        2: const pw.FlexColumnWidth(0.7),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(0.9),
        7: const pw.FlexColumnWidth(0.9),
      };
    }
    // Default: equal widths
    return {
      for (int i = 0; i < columnCount; i++) i: const pw.FlexColumnWidth(1),
    };
  }

  static String _formatThaiDate(DateTime date) {
    // Convert to Buddhist Era (พ.ศ.)
    final buddhistYear = date.year + 543;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/$buddhistYear';
  }
}
