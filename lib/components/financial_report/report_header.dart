import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportHeader extends StatelessWidget {
  final String? selectedReportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onFullScreen;
  final Function(String) onExport;

  const ReportHeader({
    Key? key,
    required this.selectedReportType,
    required this.startDate,
    required this.endDate,
    required this.onFullScreen,
    required this.onExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตัวอย่างรายงาน (Preview)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            if (startDate != null && endDate != null)
              Text(
                'ข้อมูล ณ วันที่ ${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: onFullScreen,
              icon: const Icon(Icons.fullscreen_rounded),
              color: const Color(0xFF64748B),
              tooltip: 'Full Screen',
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => onExport('PDF'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              label: 'Excel',
              icon: Icons.table_view_rounded,
              color: const Color(0xFF10B981),
              onTap: () => onExport('Excel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
