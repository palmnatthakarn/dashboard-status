import 'package:flutter/material.dart';
import 'custom_pagination.dart';

class CustomColumn {
  final String label;
  final int flex;
  final Alignment alignment;
  final bool isNumeric;

  const CustomColumn({
    required this.label,
    required this.flex,
    this.alignment = Alignment.centerLeft,
    this.isNumeric = false,
  });
}

class GenericPaginatedTable<T> extends StatefulWidget {
  final List<T> items;
  final List<CustomColumn> columns;
  final List<Widget> Function(T item) cellBuilder;
  final Widget Function(T item)? expandedDetailBuilder;
  final bool Function(T item)? isRowExpanded;
  final Function(T item)? onRowTap;
  final bool isLoading;
  final Widget? emptyWidget;
  final List<int> rowsPerPageOptions;
  final bool useAlternatingRowColors;

  const GenericPaginatedTable({
    super.key,
    required this.items,
    required this.columns,
    required this.cellBuilder,
    this.expandedDetailBuilder,
    this.isRowExpanded,
    this.onRowTap,
    this.isLoading = false,
    this.emptyWidget,
    this.rowsPerPageOptions = const [10, 20, 50, 100],
    this.useAlternatingRowColors = true,
  });

  @override
  State<GenericPaginatedTable<T>> createState() =>
      _GenericPaginatedTableState<T>();
}

class _GenericPaginatedTableState<T> extends State<GenericPaginatedTable<T>> {
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void didUpdateWidget(GenericPaginatedTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      // Logic to keep current page if valid, or reset?
      // For simplicity, if total items change drastically or becoming smaller than current view, adjust.
      // But typically search resets to page 1 externally if needed.
      // Let's ensure _currentPage is valid
      if ((_currentPage - 1) * _rowsPerPage >= widget.items.length &&
          widget.items.isNotEmpty) {
        _currentPage = 1;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.rowsPerPageOptions.isNotEmpty) {
      _rowsPerPage = widget.rowsPerPageOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.rule_folder_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ไม่พบรายการ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
        // border: Border.all(color: const Color(0xFFE2E8F0)), // KPI table doesn't have outer border, just shadow
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _buildHeaderRow(),
            ),
            // Table Body
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      // Changed to builder since separator not needed with striping typically, but KPI has border bottom
                      itemCount:
                          (widget.items.length -
                                  (_currentPage - 1) * _rowsPerPage)
                              .clamp(0, _rowsPerPage),
                      itemBuilder: (context, index) {
                        final actualIndex =
                            (_currentPage - 1) * _rowsPerPage + index;
                        if (actualIndex >= widget.items.length)
                          return const SizedBox();

                        final item = widget.items[actualIndex];
                        return _buildItemRow(item, index);
                      },
                    ),
            ),
            // Pagination Footer
            if (widget.items.isNotEmpty) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: CustomPagination(
                  currentPage: _currentPage,
                  totalItems: widget.items.length,
                  rowsPerPage: _rowsPerPage,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  onRowsPerPageChanged: (rows) => setState(() {
                    _rowsPerPage = rows;
                    _currentPage = 1;
                  }),
                  rowsPerPageOptions: widget.rowsPerPageOptions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: widget.columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Container(
            alignment: col.alignment,
            child: Text(
              col.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemRow(T item, int index) {
    final bool expanded = widget.isRowExpanded?.call(item) ?? false;
    final List<Widget> cells = widget.cellBuilder(item);

    Color rowColor = Colors.white;
    if (expanded) {
      rowColor = const Color(0xFFF1F5F9); // Highlight expanded
    } else if (widget.useAlternatingRowColors) {
      rowColor = index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC);
    }

    return Column(
      children: [
        InkWell(
          onTap: () => widget.onRowTap?.call(item),
          hoverColor: Colors.grey[50],
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Match header padding
            decoration: BoxDecoration(
              color: rowColor,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: List.generate(widget.columns.length, (index) {
                final col = widget.columns[index];
                final cell = cells.length > index
                    ? cells[index]
                    : const SizedBox();
                return Expanded(
                  flex: col.flex,
                  child: Container(
                    alignment: col.alignment,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: cell,
                  ),
                );
              }),
            ),
          ),
        ),
        if (expanded && widget.expandedDetailBuilder != null)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            padding: const EdgeInsets.all(24),
            child: widget.expandedDetailBuilder!(item),
          ),
      ],
    );
  }
}
