import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../models/journal.dart';
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

  int get _totalPages => (widget.rows.length / _rowsPerPage).ceil();
  
  List<Journal> get _currentPageRows {
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DataTable2(
              columnSpacing: 24,
              horizontalMargin: 20,
              headingRowHeight: 56,
              dataRowHeight: 64,
              minWidth: 900,
              sortColumnIndex: widget.sortColumnIndex,
              sortAscending: widget.sortAscending,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF374151),
                letterSpacing: 0.3,
              ),
              dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
              dividerThickness: 0,
              columns: _buildColumns(),
              rows: _buildRows(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous button
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 8),
          
          // Page numbers
          ..._buildPageNumbers(),
          
          const SizedBox(width: 8),
          // Next button
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
          ),
          
          const SizedBox(width: 24),
          
          // Rows per page dropdown
          _buildRowsPerPageDropdown(),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pages = [];
    final int total = _totalPages;
    
    if (total <= 7) {
      // Show all pages
      for (int i = 1; i <= total; i++) {
        pages.add(_buildPageButton(i));
      }
    } else {
      // Show first, last, current and nearby pages
      pages.add(_buildPageButton(1));
      
      if (_currentPage > 3) {
        pages.add(_buildEllipsis());
      }
      
      for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
        if (i > 1 && i < total) {
          pages.add(_buildPageButton(i));
        }
      }
      
      if (_currentPage < total - 2) {
        pages.add(_buildEllipsis());
      }
      
      pages.add(_buildPageButton(total));
    }
    
    return pages;
  }

  Widget _buildPageButton(int page) {
    final isSelected = page == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => setState(() => _currentPage = page),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF818CF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            '$page',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('•••', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
    );
  }

  Widget _buildNavButton({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: isEnabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _rowsPerPage,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
          style: const TextStyle(color: Color(0xFF374151), fontSize: 14, fontWeight: FontWeight.w500),
          items: [10, 20, 50].map((v) => DropdownMenuItem(
            value: v,
            child: Text('$v / page'),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _rowsPerPage = v;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
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
        label: _buildHeaderCell('เดบิต', Icons.arrow_upward_rounded, alignRight: true),
        size: ColumnSize.M,
        numeric: true,
        onSort: widget.onSort,
      ),
      DataColumn2(
        label: _buildHeaderCell('เครดิต', Icons.arrow_downward_rounded, alignRight: true),
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

  static Widget _buildHeaderCell(String text, IconData icon, {bool alignRight = false}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
      ],
    );
    return alignRight ? Align(alignment: Alignment.centerRight, child: content) : content;
  }

  DataCell _buildDateCell(String date) {
    return DataCell(
      Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
    );
  }

  DataCell _buildAccountNameCell(String? name) {
    return DataCell(
      Tooltip(
        message: name ?? '-',
        child: Text(name ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis, maxLines: 2),
      ),
    );
  }

  DataCell _buildTypeCell(String? accountType) {
    final color = widget.typeColor(accountType);
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          widget.typeDisplay(accountType),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  widget.numFmt.format(amount),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
                ),
              )
            : Text('-', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
