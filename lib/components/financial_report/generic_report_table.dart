import 'package:flutter/material.dart';

import '../common/custom_pagination.dart';

class GenericReportTable extends StatefulWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int>? highlightRows;
  final void Function(int index, List<String> cells)? onRowTap;
  final String? paginationTotalLabel;

  const GenericReportTable({
    super.key,
    required this.headers,
    required this.rows,
    this.highlightRows,
    this.onRowTap,
    this.paginationTotalLabel,
  });

  @override
  State<GenericReportTable> createState() => _GenericReportTableState();
}

class _GenericReportTableState extends State<GenericReportTable> {
  static const int _defaultRowsPerPage = 10;

  int _currentPage = 1;
  int _rowsPerPage = _defaultRowsPerPage;

  int get _totalPages =>
      widget.rows.isEmpty ? 1 : (widget.rows.length / _rowsPerPage).ceil();

  bool _isNumericHeader(String header) {
    if (header.contains('เลข') ||
        header.contains('รหัส') ||
        header.contains('สาขา') ||
        header.contains('ลำดับ')) {
      return false;
    }
    return header.contains('เดบิต') ||
        header.contains('เครดิต') ||
        header.contains('จำนวน') ||
        header.contains('ยอด') ||
        header.contains('คงเหลือ') ||
        header.contains('ราคา') ||
        header.contains('ภาษี') ||
        header == 'รวม';
  }

  bool _isCenteredHeader(String header) {
    return header.contains('ลำดับ') || header == '#';
  }

  TextAlign _textAlignFor(String header) {
    if (_isCenteredHeader(header)) return TextAlign.center;
    if (_isNumericHeader(header)) return TextAlign.right;
    return TextAlign.left;
  }

  Alignment _alignmentFor(String header) {
    if (_isCenteredHeader(header)) return Alignment.center;
    if (_isNumericHeader(header)) return Alignment.centerRight;
    return Alignment.centerLeft;
  }

  bool get _isDenseTable => widget.headers.length >= 9;

  bool get _isTaxDeductedTable =>
      widget.headers.contains('วันที่ได้รับ') &&
      widget.headers.contains('ประเภทเงินได้ที่จ่าย');

  double _columnWidthFor(String header, double tableWidth) {
    if (_isTaxDeductedTable) {
      if (header.contains('ลำดับ')) return 42;
      if (header == 'วันที่ได้รับ') return 86;
      if (header == 'ชื่อ') return 170;
      if (header == 'ที่อยู่') return 180;
      if (header.contains('ผู้เสียภาษี')) return 132;
      if (header == 'ประเภทเงินได้ที่จ่าย') return 150;
      if (header.contains('อัตราภาษี')) return 78;
      if (header == 'จำนวนเงิน') return 86;
      if (header == 'ภาษี') return 76;
    }

    final scale = tableWidth < 1100 ? 0.78 : 0.86;
    double width;
    if (header.contains('ลำดับ')) {
      width = 40;
    } else if (header == 'วันที่') {
      width = 76;
    } else if (header.contains('ใบกำกับ') || header.contains('เอกสาร')) {
      width = 102;
    } else if (header.contains('ชื่อ')) {
      width = 136;
    } else if (header.contains('ผู้เสียภาษี')) {
      width = 118;
    } else if (header.contains('สาขา')) {
      width = 50;
    } else if (header.contains('ยื่น')) {
      width = 58;
    } else if (_isNumericHeader(header)) {
      width = 78;
    } else {
      width = 96;
    }
    return _isDenseTable ? width * scale : width + 24;
  }

  double _tableContentWidth(double tableWidth) {
    final horizontalMargin = _isDenseTable ? 8.0 : 24.0;
    final columnSpacing = _isDenseTable ? 8.0 : 24.0;
    final columnsWidth = widget.headers.fold<double>(
      0,
      (sum, header) => sum + _columnWidthFor(header, tableWidth),
    );
    final spacingWidth = widget.headers.length > 1
        ? columnSpacing * (widget.headers.length - 1)
        : 0;
    return columnsWidth + spacingWidth + (horizontalMargin * 2);
  }

  @override
  void didUpdateWidget(covariant GenericReportTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rows != widget.rows || oldWidget.headers != widget.headers) {
      _currentPage = 1;
      _rowsPerPage = _defaultRowsPerPage;
      return;
    }

    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalRows = widget.rows.length;
        final totalPages = _totalPages;
        final currentPage = _currentPage.clamp(1, totalPages);
        final startIndex = totalRows == 0
            ? 0
            : (currentPage - 1) * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage).clamp(0, totalRows);
        final visibleRows = widget.rows
            .asMap()
            .entries
            .skip(startIndex)
            .take(endIndex - startIndex)
            .toList();
        final headingFontSize = _isDenseTable ? 10.5 : 14.0;
        final dataFontSize = _isDenseTable ? 10.5 : 14.0;
        final horizontalMargin = _isDenseTable ? 8.0 : 24.0;
        final columnSpacing = _isDenseTable ? 8.0 : 24.0;
        final rowMinHeight = _isDenseTable ? 44.0 : 64.0;
        final tableContentWidth = _tableContentWidth(constraints.maxWidth);
        final minTableWidth = _isTaxDeductedTable
            ? tableContentWidth
            : constraints.maxWidth > 800
                ? constraints.maxWidth
                : 800.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: minTableWidth,
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.grey.shade200),
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF1F5F9),
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFFF8FAFC);
                        }
                        return null;
                      }),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        fontSize: 14,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                      ),
                      horizontalMargin: horizontalMargin,
                      columnSpacing: columnSpacing,
                      headingRowHeight: _isDenseTable ? 46 : 52,
                      dataRowMinHeight: rowMinHeight,
                      dataRowMaxHeight: double.infinity,
                      dividerThickness: 1,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                        bottom: BorderSide.none,
                      ),
                      columns: widget.headers.asMap().entries.map((entry) {
                        final header = entry.value;
                        return DataColumn(
                          label: SizedBox(
                            width: _columnWidthFor(
                              header,
                              constraints.maxWidth,
                            ),
                            child: Text(
                              header,
                              textAlign: _textAlignFor(header),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: headingFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                                height: 1.25,
                              ),
                            ),
                          ),
                          numeric: _isNumericHeader(header),
                        );
                      }).toList(),
                      rows: visibleRows.map((entry) {
                        final index = entry.key;
                        final cells = entry.value;
                        final isHighlight =
                            widget.highlightRows?.contains(index) ?? false;
                        final isEven = index % 2 == 0;

                        Color rowColor = isEven
                            ? Colors.white
                            : const Color(0xFFF8FAFC);
                        if (isHighlight) {
                          rowColor = const Color(0xFFEFF6FF);
                        }

                        final isTotalRow = isHighlight;
                        final fontWeight = isTotalRow
                            ? FontWeight.bold
                            : FontWeight.normal;
                        final textColor = isTotalRow
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569);

                        return DataRow(
                          onSelectChanged: widget.onRowTap == null
                              ? null
                              : (_) => widget.onRowTap!(index, cells),
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(
                                0xFFE2E8F0,
                              ).withValues(alpha: 0.4);
                            }
                            return rowColor;
                          }),
                          cells: cells.asMap().entries.map((cellEntry) {
                            final cellIndex = cellEntry.key;
                            final cell = cellEntry.value;
                            final header = cellIndex < widget.headers.length
                                ? widget.headers[cellIndex]
                                : '';

                            return DataCell(
                              SizedBox(
                                width: _columnWidthFor(
                                  header,
                                  constraints.maxWidth,
                                ),
                                child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                alignment: _alignmentFor(header),
                                child: Text(
                                  cell,
                                  style: TextStyle(
                                    fontWeight: fontWeight,
                                    color: textColor,
                                      fontSize: dataFontSize,
                                      height: 1.35,
                                  ),
                                  textAlign: _textAlignFor(header),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              if (totalRows > 0) ...[
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                CustomPagination(
                  currentPage: currentPage,
                  totalItems: totalRows,
                  rowsPerPage: _rowsPerPage,
                  totalLabel:
                      widget.paginationTotalLabel ??
                      'รวมรายการทั้งสิ้น $totalRows รายการ',
                  rowsPerPageOptions: const [_defaultRowsPerPage],
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  onRowsPerPageChanged: (rows) {
                    setState(() {
                      _rowsPerPage = rows;
                      _currentPage = 1;
                    });
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
