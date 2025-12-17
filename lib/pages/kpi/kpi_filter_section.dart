import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/kpi_employee.dart';

class KpiFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController taxIdController;
  final String selectedBranch;
  final DateTime? documentReceiveStartDate;
  final DateTime? documentReceiveEndDate;
  final DateTimeRange? previousDateRange;
  final DateTimeRange? statusCheckDateRange;
  final bool isAdvancedFilterExpanded;
  final List<KpiEmployee> employees;

  final VoidCallback onToggleAdvancedFilter;
  final Function(String) onBranchChanged;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(DateTimeRange?) onPreviousDateRangeChanged;
  final Function(DateTimeRange?) onStatusCheckDateRangeChanged;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  const KpiFilterSection({
    super.key,
    required this.searchController,
    required this.taxIdController,
    required this.selectedBranch,
    required this.documentReceiveStartDate,
    required this.documentReceiveEndDate,
    required this.previousDateRange,
    required this.statusCheckDateRange,
    required this.isAdvancedFilterExpanded,
    required this.employees,
    required this.onToggleAdvancedFilter,
    required this.onBranchChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onPreviousDateRangeChanged,
    required this.onStatusCheckDateRangeChanged,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 900;

                if (isSmallScreen) {
                  // For small screens, use Wrap to allow elements to flow
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Search Field
                      SizedBox(
                        width: constraints.maxWidth > 500
                            ? constraints.maxWidth * 0.5 - 12
                            : constraints.maxWidth,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'ค้นหาชื่อหรือรหัสพนักงาน...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  color: const Color(0xFF94A3B8),
                                  onPressed: onClearSearch,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Branch Selector
                      SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'สาขา',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height: 24,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedBranch,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  items:
                                      [
                                        'ทุกสาขา',
                                        ...employees
                                            .map((e) => e.branch)
                                            .toSet(),
                                      ].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                  onChanged: (val) =>
                                      val != null ? onBranchChanged(val) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date Range
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactDateSelector(
                            context,
                            'วันที่รับเอกสาร',
                            documentReceiveStartDate,
                            onStartDateChanged,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          _buildCompactDateSelector(
                            context,
                            'ถึงวันที่',
                            documentReceiveEndDate,
                            onEndDateChanged,
                          ),
                        ],
                      ),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh_rounded),
                            color: const Color(0xFF64748B),
                            tooltip: 'รีเฟรชข้อมูล',
                          ),
                          IconButton(
                            onPressed: onToggleAdvancedFilter,
                            icon: Icon(
                              isAdvancedFilterExpanded
                                  ? Icons.tune_rounded
                                  : Icons.tune_outlined,
                            ),
                            color: isAdvancedFilterExpanded
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF64748B),
                            tooltip: 'ตัวกรองเพิ่มเติม',
                          ),
                          ElevatedButton.icon(
                            onPressed: onSearch,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('ค้นหา'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // For larger screens, use Row layout
                return Row(
                  children: [
                    // 1. Search Field (Expanded)
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF94A3B8),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'ค้นหาชื่อหรือรหัสพนักงาน...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: const Color(0xFF94A3B8),
                                onPressed: onClearSearch,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 16),

                    // 2. Branch Selector
                    SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'สาขา',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            height: 24,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBranch,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                                items:
                                    [
                                      'ทุกสาขา',
                                      ...employees.map((e) => e.branch).toSet(),
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (val) =>
                                    val != null ? onBranchChanged(val) : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 16),

                    // 3. Date Range Compact
                    Row(
                      children: [
                        _buildCompactDateSelector(
                          context,
                          'วันที่รับเอกสาร (ไม่ใช่วันที่ตามเอกสาร)',
                          documentReceiveStartDate,
                          onStartDateChanged,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        _buildCompactDateSelector(
                          context,
                          'ถึงวันที่',
                          documentReceiveEndDate,
                          onEndDateChanged,
                        ),
                      ],
                    ),

                    const Spacer(),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      color: const Color(0xFF64748B),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      tooltip: 'รีเฟรชข้อมูล',
                    ),
                    const SizedBox(width: 8),
                    // 4. Tools and Toggle
                    IconButton(
                      onPressed: onToggleAdvancedFilter,
                      icon: Icon(
                        isAdvancedFilterExpanded
                            ? Icons.tune_rounded
                            : Icons.tune_outlined,
                      ),
                      color: isAdvancedFilterExpanded
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF64748B),
                      style: IconButton.styleFrom(
                        backgroundColor: isAdvancedFilterExpanded
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                      ),
                      tooltip: 'ตัวกรองเพิ่มเติม',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('ค้นหา'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Collapsible Advanced Filters
          if (isAdvancedFilterExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Advanced fields
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เลขผู้เสียภาษี',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 45,
                              child: TextField(
                                controller: taxIdController,
                                decoration: InputDecoration(
                                  hintText: 'ระบุเลข 13 หลัก',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateFilterItem(
                          context,
                          'วันที่ก่อนหน้า',
                          previousDateRange,
                          onPreviousDateRangeChanged,
                          icon: Icons.history_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateFilterItem(
                          context,
                          'วันตรวจสอบสถานะ',
                          statusCheckDateRange,
                          onStatusCheckDateRangeChanged,
                          icon: Icons.fact_check_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactDateSelector(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onSelect,
  ) {
    final fmt = DateFormat('d MMM yy', 'th');
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: date != null ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: date != null
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: date != null
                        ? const Color(0xFF2563EB)
                        : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date != null ? fmt.format(date) : '- เลือก -',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: date != null
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterItem(
    BuildContext context,
    String label,
    DateTimeRange? range,
    Function(DateTimeRange?) onSelect, {
    IconData icon = Icons.calendar_month_rounded,
    Color color = const Color(0xFF64748B),
    String? subtitle,
    bool isWarning = false,
  }) {
    final dateFormat = DateFormat('d MMM yy', 'th');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isWarning ? const Color(0xFFEF4444) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onSelect(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    range != null
                        ? '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}'
                        : '- เลือกช่วงเวลา -',
                    style: TextStyle(
                      fontSize: 14,
                      color: range != null
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (range != null)
                  InkWell(
                    onTap: () => onSelect(null),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
