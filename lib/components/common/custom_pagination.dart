import 'package:flutter/material.dart';

/// A reusable pagination widget with page navigation, smart page numbers, and rows per page selector.
///
/// Features:
/// - Previous/Next navigation buttons
/// - Smart page number display with ellipsis for large page counts
/// - Configurable rows per page dropdown
/// - Responsive design matching the app's design system
///
/// Example usage:
/// ```dart
/// CustomPagination(
///   currentPage: _currentPage,
///   totalItems: _items.length,
///   rowsPerPage: _rowsPerPage,
///   onPageChanged: (page) => setState(() => _currentPage = page),
///   onRowsPerPageChanged: (rows) => setState(() {
///     _rowsPerPage = rows;
///     _currentPage = 1;
///   }),
/// )
/// ```
class CustomPagination extends StatelessWidget {
  const CustomPagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.rowsPerPageOptions = const [10, 20, 50],
  });

  /// Current active page (1-indexed)
  final int currentPage;

  /// Total number of items in the dataset
  final int totalItems;

  /// Number of rows to display per page
  final int rowsPerPage;

  /// Callback when page is changed
  final Function(int) onPageChanged;

  /// Callback when rows per page is changed
  final Function(int) onRowsPerPageChanged;

  /// Available options for rows per page dropdown
  final List<int> rowsPerPageOptions;

  int get _totalPages =>
      totalItems == 0 ? 1 : (totalItems / rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
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
            onTap: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          const SizedBox(width: 8),

          // Page numbers
          ..._buildPageNumbers(),

          const SizedBox(width: 8),
          // Next button
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: currentPage < _totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
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

      if (currentPage > 3) {
        pages.add(_buildEllipsis());
      }

      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i > 1 && i < total) {
          pages.add(_buildPageButton(i));
        }
      }

      if (currentPage < total - 2) {
        pages.add(_buildEllipsis());
      }

      pages.add(_buildPageButton(total));
    }

    return pages;
  }

  Widget _buildPageButton(int page) {
    final isSelected = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onPageChanged(page),
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
      child: Text(
        '•••',
        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
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
          value: rowsPerPage,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: rowsPerPageOptions
              .map((v) => DropdownMenuItem(value: v, child: Text('$v / page')))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              onRowsPerPageChanged(v);
            }
          },
        ),
      ),
    );
  }
}
