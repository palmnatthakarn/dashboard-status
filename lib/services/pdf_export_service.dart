import 'package:pdf/pdf.dart'; // Trigger rebuild
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// One person's section in a grouped report (see [PdfExportService.
/// exportGroupedTableToPdf]) — a bold name/summary banner followed by a
/// small table of that person's rows (e.g. one row per shop).
class KpiPdfGroup {
  final String name;
  final String summary;
  final List<List<String>> rows;
  final List<List<String>>? totalRows;
  final Set<int> contextRowIndexes;
  final bool showColumnTotals;

  const KpiPdfGroup({
    required this.name,
    required this.summary,
    this.rows = const [],
    this.totalRows,
    this.contextRowIndexes = const {},
    this.showColumnTotals = false,
  });
}

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

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Report grouped by person (e.g. employee), each with its own bold
  /// name/summary banner followed by a small breakdown table (e.g. one row
  /// per shop). Use this instead of [exportTableToPdf] whenever a flat
  /// table would make it hard to tell which rows belong to which person —
  /// the banner makes "who did what, where" unambiguous at a glance.
  static Future<void> exportGroupedTableToPdf({
    required String title,
    required List<String> subHeaders,
    required List<KpiPdfGroup> groups,
    DateTime? startDate,
    DateTime? endDate,
    String userName = 'ผู้ใช้งาน',
  }) async {
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        // The default is 20 pages. A full KPI export can contain more than
        // that once each employee's shop table is laid out and paginated.
        maxPages: 200,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildFormalHeader(
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
          pw.SizedBox(height: 10),
          for (var i = 0; i < groups.length; i++)
            ..._buildGroupBlocks(i, groups[i], subHeaders, font, fontBold),
        ],
      ),
    );

    final pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static List<pw.Widget> _buildGroupBlocks(
    int index,
    KpiPdfGroup group,
    List<String> subHeaders,
    pw.Font font,
    pw.Font fontBold,
  ) {
    if (group.rows.isEmpty) {
      return [_buildGroupBanner(index + 1, group, font, fontBold)];
    }

    if (group.rows.length == 1) {
      return [
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildGroupBanner(index + 1, group, font, fontBold),
              pw.SizedBox(height: 4),
              _buildGroupTable(
                subHeaders,
                group.rows,
                font,
                fontBold,
                group.showColumnTotals,
                totalRows: group.totalRows ?? group.rows,
                contextRowIndexes: group.contextRowIndexes,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    final widgets = <pw.Widget>[
      // Keep the employee banner, column headings, and first data row
      // together so a banner can never be orphaned at the bottom of a page.
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildGroupBanner(index + 1, group, font, fontBold),
            pw.SizedBox(height: 4),
            _buildGroupTable(
              subHeaders,
              group.rows.sublist(0, 1),
              font,
              fontBold,
              false,
              contextRowIndexes: group.contextRowIndexes.contains(0)
                  ? const {0}
                  : const {},
            ),
          ],
        ),
      ),
    ];

    if (group.rows.length > 2) {
      widgets.add(
        _buildGroupTable(
          subHeaders,
          group.rows.sublist(1, group.rows.length - 1),
          font,
          fontBold,
          false,
          includeHeader: false,
          contextRowIndexes: group.contextRowIndexes
              .where((rowIndex) => rowIndex > 0 && rowIndex < group.rows.length - 1)
              .map((rowIndex) => rowIndex - 1)
              .toSet(),
        ),
      );
    }

    // Keep the final data row and grand total together so the total can
    // never appear alone at the top of the following page.
    widgets.add(
      pw.Inseparable(
        child: _buildGroupTable(
          subHeaders,
          group.rows.sublist(group.rows.length - 1),
          font,
          fontBold,
          group.showColumnTotals,
          includeHeader: false,
          totalRows: group.totalRows ?? group.rows,
          contextRowIndexes: group.contextRowIndexes.contains(group.rows.length - 1)
              ? const {0}
              : const {},
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));
    return widgets;
  }

  static pw.Widget _buildGroupBanner(
    int index,
    KpiPdfGroup group,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.75, color: PdfColors.black),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            '$index. ${group.name}',
            style: pw.TextStyle(font: fontBold, fontSize: 11),
          ),
          pw.Text(
            group.summary,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  /// Formal header: centered document title/date range, then a metadata
  /// row (printer, print date, page number), separated by a solid rule —
  /// styled to read like an official printed report rather than an
  /// in-app card.
  static pw.Widget _buildFormalHeader({
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
          'ช่วงข้อมูล ${_formatThaiDate(startDate)} ถึง ${_formatThaiDate(endDate)}';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 1.2, color: PdfColors.black),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: fontBold, fontSize: 16),
            textAlign: pw.TextAlign.center,
          ),
          if (dateRange.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              dateRange,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ผู้จัดพิมพ์ $userName',
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'วันที่จัดพิมพ์ ${_formatThaiDate(now)}',
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
                ],
              ),
              pw.Text(
                'หน้า $pageNumber / $pagesCount',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGroupTable(
    List<String> headers,
    List<List<String>> rows,
    pw.Font font,
    pw.Font fontBold,
    bool showColumnTotals, {
    bool includeHeader = true,
    List<List<String>>? totalRows,
    Set<int> contextRowIndexes = const {},
  }) {
    if (rows.isEmpty) {
      return pw.Text(
        'ไม่มีข้อมูลรายละเอียด',
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          color: PdfColors.grey500,
        ),
      );
    }
    final rowsToTotal = totalRows ?? rows;
    final totals = List<String>.generate(headers.length, (index) {
      if (index == 0) return 'รวม';
      return rowsToTotal
          .map((row) => int.tryParse(row[index].replaceAll(',', '')) ?? 0)
          .fold(0, (sum, value) => sum + value)
          .toString();
    });

    pw.TableRow totalRow() => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      children: totals.asMap().entries.map((entry) {
        final isFirst = entry.key == 0;
        return pw.Container(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: isFirst ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
          child: pw.Text(
            entry.value,
            style: pw.TextStyle(font: fontBold, fontSize: 8),
            textAlign: isFirst ? pw.TextAlign.left : pw.TextAlign.right,
          ),
        );
      }).toList(),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        for (var i = 1; i < headers.length; i++) i: const pw.FlexColumnWidth(1),
      },
      children: [
        if (includeHeader)
          pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.asMap().entries
              .map(
                (entry) {
                  final index = entry.key;
                  final h = entry.value;
                  final color = index == 0 || index == 1
                      ? PdfColors.blue100
                      : index <= 6
                      ? PdfColors.amber100
                  : index <= 10
                      ? PdfColors.green100
                      : PdfColors.indigo100;
                  return pw.Container(
                    decoration: pw.BoxDecoration(color: color),
                    height: 38,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(font: fontBold, fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                },
              )
              .toList(),
        ),
        ...rows.asMap().entries.map(
          (rowEntry) => pw.TableRow(
            children: rowEntry.value.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final isContextMetric =
                  contextRowIndexes.contains(rowEntry.key) &&
                  entry.key >= 1 &&
                  entry.key <= 10 &&
                  entry.value != '0' &&
                  entry.value != '-';
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 3,
                ),
                alignment: isFirst
                    ? pw.Alignment.centerLeft
                    : pw.Alignment.centerRight,
                child: pw.Text(
                  entry.value,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: isContextMetric ? PdfColors.deepOrange : null,
                  ),
                  textAlign: isFirst ? pw.TextAlign.left : pw.TextAlign.right,
                ),
              );
            }).toList(),
          ),
        ),
        if (showColumnTotals) totalRow(),
      ],
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
                  dateRange.isEmpty ? title : '$title $dateRange',
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
