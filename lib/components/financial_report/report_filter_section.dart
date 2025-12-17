import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFilterSection extends StatelessWidget {
  final List<String> reportTypes;
  final String? selectedReportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String?> onReportTypeChanged;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const ReportFilterSection({
    super.key,
    required this.reportTypes,
    required this.selectedReportType,
    required this.startDate,
    required this.endDate,
    required this.onReportTypeChanged,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;

        if (isSmallScreen) {
          // For small screens, use Wrap to allow elements to flow
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: constraints.maxWidth > 400
                      ? constraints.maxWidth * 0.5
                      : constraints.maxWidth - 32,
                  child: _buildCompactDropdown(),
                ),
                SizedBox(
                  width: constraints.maxWidth > 400
                      ? constraints.maxWidth * 0.4
                      : constraints.maxWidth - 32,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCompactDatePicker(
                          label: 'จากวันที่',
                          selectedDate: startDate,
                          onTap: onStartDateTap,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Expanded(
                        child: _buildCompactDatePicker(
                          label: 'ถึงวันที่',
                          selectedDate: endDate,
                          onTap: onEndDateTap,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(
                  icon: Icons.search_rounded,
                  label: 'ค้นหา',
                  color: const Color(0xFF3B82F6),
                  textColor: Colors.white,
                  onTap: () {},
                ),
              ],
            ),
          );
        }

        // For larger screens, use the original Row layout
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildCompactDropdown()),
              Container(
                height: 24,
                width: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactDatePicker(
                        label: 'จากวันที่',
                        selectedDate: startDate,
                        onTap: onStartDateTap,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Expanded(
                      child: _buildCompactDatePicker(
                        label: 'ถึงวันที่',
                        selectedDate: endDate,
                        onTap: onEndDateTap,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.search_rounded,
                label: 'ค้นหา',
                color: const Color(0xFF3B82F6),
                textColor: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedReportType,
              hint: Text(
                'เลือกประเภทรายงาน',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              isDense: true,
              items: reportTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onReportTypeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: selectedDate != null
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : '- เลือก -',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
