import 'package:flutter/material.dart';

class JournalToolbar extends StatelessWidget {
  const JournalToolbar({
    super.key,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.onReset,
    required this.searchController,
    required this.onSearchChanged,
    required this.isChartView,
    required this.onViewToggle,
  });

  final String typeFilter;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onReset;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isChartView;
  final VoidCallback onViewToggle;

  static const _filterChips = [
    ['ALL', 'ทั้งหมด'],
    ['INCOME', 'รายได้'],
    ['EXPENSES', 'รายจ่าย'],
    ['ASSETS', 'สินทรัพย์'],
    ['LIABILITIES', 'หนี้สิน'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Search Field
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          // Filter Button
          _buildIconButton(Icons.filter_alt, () {}),
          const SizedBox(width: 8),
          // Filter Chips
          ..._filterChips.map((e) => _buildFilterChip(e[0], e[1])),
          const SizedBox(width: 8),
          // View Toggle
          _buildIconButton(
            isChartView ? Icons.table_chart : Icons.show_chart,
            onViewToggle,
          ),
          const SizedBox(width: 8),
          // Reset Button
          _buildIconButton(Icons.refresh, onReset),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          hintText: 'ค้นหา...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF6B7280),
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => onTypeChanged(value),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF374151),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
