import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../models/journal.dart';
import '../../components/common/custom_pagination.dart';
import 'doc_no_cell.dart';

class JournalTable extends StatefulWidget {
  const JournalTable({
    super.key,
    required this.rows,
    required this.typeColor,
    required this.typeDisplay,
    required this.numFmt,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  final List<Journal> rows;
  final Color Function(String?) typeColor;
  final String Function(String?) typeDisplay;
  final NumberFormat numFmt;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool) onSort;

  @override
  State<JournalTable> createState() => _JournalTableState();
}

class _JournalTableState extends State<JournalTable> {
  int _currentPage = 1;
  int _rowsPerPage = 10;

  int get _totalPages =>
      widget.rows.isEmpty ? 1 : (widget.rows.length / _rowsPerPage).ceil();

  List<Journal> get _currentPageRows {
    if (widget.rows.isEmpty) return [];
    // Reset page if current page exceeds total pages
    final validPage = _currentPage.clamp(1, _totalPages);
    if (validPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = validPage);
      });
    }
    final start = (validPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  void didUpdateWidget(JournalTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to page 1 when data changes significantly
    if (widget.rows.length != oldWidget.rows.length) {
      final maxPage = widget.rows.isEmpty
          ? 1
          : (widget.rows.length / _rowsPerPage).ceil();
      if (_currentPage > maxPage) {
        _currentPage = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DataTable2(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowHeight: 44,
              dataRowHeight: 52,
              minWidth: 900,
              sortColumnIndex: widget.sortColumnIndex,
              sortAscending: widget.sortAscending,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF374151),
                letterSpacing: 0.3,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1F2937),
              ),
              dividerThickness: 0,
              columns: _buildColumns(),
              rows: _buildRows(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomPagination(
          currentPage: _currentPage,
          totalItems: widget.rows.length,
          rowsPerPage: _rowsPerPage,
          onPageChanged: (page) => setState(() => _currentPage = page),
          onRowsPerPageChanged: (rows) => setState(() {
            _rowsPerPage = rows;
            _currentPage = 1;
          }),
        ),
      ],
    );
  }

  List<DataColumn2> _buildColumns() {
    return [
      DataColumn2(
        label: _buildHeaderCell('วันที่', Icons.calendar_today_rounded),
        size: ColumnSize.M,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell('เลขที่เอกสาร', Icons.description_rounded),
        size: ColumnSize.L,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell('รายการ', Icons.list_alt_rounded),
        size: ColumnSize.L,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell('ประเภท', Icons.category_rounded),
        size: ColumnSize.M,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell(
          'เดบิต',
          Icons.arrow_upward_rounded,
          alignRight: true,
        ),
        size: ColumnSize.M,
        numeric: true,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell(
          'เครดิต',
          Icons.arrow_downward_rounded,
          alignRight: true,
        ),
        size: ColumnSize.M,
        numeric: true,
        onSort: widget.onSort,
      ),
    ];
  }

  List<DataRow> _buildRows() {
    return _currentPageRows.asMap().entries.map((entry) {
      final i = entry.key;
      final j = entry.value;
      final debit = j.debit ?? 0;
      final credit = j.credit ?? 0;

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFEEF2FF);
          }
          return i.isEven ? Colors.white : const Color(0xFFFAFAFA);
        }),
        cells: [
          _buildDateCell(j.displayDate),
          DataCell(DocNoCell(docNo: j.docNo ?? '-')),
          _buildAccountNameCell(j.accountName),
          _buildTypeCell(j.accountType),
          _buildAmountCell(debit, isDebit: true),
          _buildAmountCell(credit, isDebit: false),
        ],
      );
    }).toList();
  }

  static Widget _buildHeaderCell(
    String text,
    IconData icon, {
    bool alignRight = false,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
        ),
      ],
    );
    return alignRight
        ? Align(alignment: Alignment.centerRight, child: content)
        : content;
  }

  DataCell _buildDateCell(String date) {
    return DataCell(
      Text(
        date,
        style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
      ),
    );
  }

  DataCell _buildAccountNameCell(String? name) {
    return DataCell(
      Tooltip(
        message: name ?? '-',
        child: Text(
          name ?? '-',
          style: const TextStyle(fontSize: 11, color: Color(0xFF1F2937)),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  DataCell _buildTypeCell(String? accountType) {
    final color = widget.typeColor(accountType);
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          widget.typeDisplay(accountType),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  DataCell _buildAmountCell(double amount, {required bool isDebit}) {
    final color = isDebit ? const Color(0xFF059669) : const Color(0xFF7C3AED);
    final bgColor = isDebit ? const Color(0xFFD1FAE5) : const Color(0xFFEDE9FE);

    return DataCell(
      Align(
        alignment: Alignment.centerRight,
        child: amount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.numFmt.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 11,
                  ),
                ),
              )
            : Text('-', style: TextStyle(fontSize: 11)),
      ),
    );
  }
}
