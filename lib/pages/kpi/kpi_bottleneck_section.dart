import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../blocs/kpi/kpi_state.dart';

class KpiBottleneckSection extends StatelessWidget {
  final KpiLoaded state;
  final Function(String?) onStatusSelected;

  const KpiBottleneckSection({
    super.key,
    required this.state,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalPending =
        state.waitingKey + state.waitingVerify + state.waitingFix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cards Row
        Row(
          children: [
            Expanded(
              child: _buildBottleneckCard(
                'จำนวนบิลทั้งหมด',
                state.totalDocuments,
                state.totalDocuments,
                Icons.description_rounded,
                const Color(0xFF3B82F6),
                'เอกสารทั้งหมดในระบบ',
                null, // All
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBottleneckCard(
                'รอคีย์ข้อมูล',
                state.waitingKey,
                totalPending,
                Icons.keyboard_rounded,
                const Color(0xFFF59E0B),
                'งานที่รอการคีย์อินข้อมูล',
                'waiting_key',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBottleneckCard(
                'รอตรวจสอบ',
                state.waitingVerify,
                totalPending,
                Icons.fact_check_rounded,
                const Color(0xFF8B5CF6),
                'คีย์เสร็จแล้ว รอการตรวจสอบ',
                'waiting_verify',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBottleneckCard(
                'รอแก้ไข',
                state.waitingFix,
                totalPending,
                Icons.build_circle_rounded,
                const Color(0xFFEF4444),
                'ส่งกลับมาให้แก้ไข',
                'waiting_fix',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottleneckCard(
    String title,
    int count,
    int total,
    IconData icon,
    Color color,
    String subtitle,
    String? statusFilter,
  ) {
    bool isSelected = state.selectedStatus == statusFilter;
    if (statusFilter == null && state.selectedStatus == null) isSelected = true;

    return InkWell(
      onTap: () {
        if (state.selectedStatus == statusFilter) {
          // Deselect if already selected (reset to all)
          if (statusFilter != null) onStatusSelected(null);
        } else {
          onStatusSelected(statusFilter);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    NumberFormat('#,###').format(count),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
