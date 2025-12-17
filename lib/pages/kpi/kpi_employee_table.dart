import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/common/custom_pagination.dart';
import '../../models/kpi_employee.dart';

class KpiEmployeeTable extends StatelessWidget {
  final List<KpiEmployee> employees;
  final Set<String> expandedEmployeeIds;
  final int currentPage;
  final int rowsPerPage;
  final double fontScale;
  final int totalEmployees;

  final Function(String) onToggleExpand;
  final Function(int) onPageChanged;
  final Function(int) onRowsPerPageChanged; // Added
  final Function(double) onFontScaleChanged;

  const KpiEmployeeTable({
    super.key,
    required this.employees,
    required this.expandedEmployeeIds,
    required this.currentPage,
    required this.rowsPerPage,
    required this.fontScale,
    required this.totalEmployees,
    required this.onToggleExpand,
    required this.onPageChanged,
    required this.onRowsPerPageChanged, // Added
    required this.onFontScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'รายชื่อพนักงาน',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                // Font size toggle buttons
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildFontScaleButton(Icons.text_decrease_rounded, 1.0),
                      Container(width: 1, height: 20, color: Colors.grey[300]),
                      _buildFontScaleButton(Icons.text_fields_rounded, 1.2),
                      Container(width: 1, height: 20, color: Colors.grey[300]),
                      _buildFontScaleButton(Icons.text_increase_rounded, 1.4),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ทั้งหมด $totalEmployees คน',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Determine current page data locally for display
          // Note: The parent passes pre-paginated data usually, but if 'employees'
          // is the FULL list, we slice it here. Assuming parent passes FULL list from BLoC.
          // Correct logic: BLoC provides filtered list. We slice it for current page.
          Builder(
            builder: (context) {
              final start = (currentPage - 1) * rowsPerPage;
              final end = (start + rowsPerPage).clamp(0, employees.length);

              if (employees.isEmpty) {
                return _buildEmptyState();
              }

              final currentPageEmployees = employees.sublist(start, end);

              return Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildHeaderCell(
                            'ชื่อ - นามสกุล',
                            alignLeft: true,
                          ),
                        ),

                        _buildHeaderCellWithFlex('มอบหมาย\nคีย์อิน'),
                        _buildHeaderCellWithFlex('ค้างอยู่'),
                        _buildHeaderCellWithFlex('รอคีย์'),
                        _buildHeaderCellWithFlex('รอแก้ไข'),
                        _buildHeaderCellWithFlex('รอตรวจ'),
                        _buildHeaderCellWithFlex('สมบูรณ์'),
                        _buildHeaderCellWithFlex('ยกเลิก'),
                        Expanded(flex: 1, child: _buildHeaderCell('สถานะ')),
                        const SizedBox(width: 40), // Space for expand icon
                      ],
                    ),
                  ),
                  // Data Rows
                  ...currentPageEmployees.asMap().entries.map((entry) {
                    final index = entry.key;
                    final employee = entry.value;
                    final isExpanded = expandedEmployeeIds.contains(
                      employee.id,
                    );
                    return _buildExpandableEmployeeRow(
                      employee,
                      isExpanded,
                      index,
                    );
                  }),
                ],
              );
            },
          ),

          // Pagination
          if (employees.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPagination(
                currentPage: currentPage,
                totalItems: totalEmployees,
                rowsPerPage: rowsPerPage,
                onPageChanged: onPageChanged,
                onRowsPerPageChanged: onRowsPerPageChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่พบข้อมูลพนักงาน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ลองปรับเงื่อนไขการค้นหาใหม่อีกครั้ง',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableEmployeeRow(
    KpiEmployee employee,
    bool isExpanded,
    int index,
  ) {
    return Column(
      children: [
        // Main Row
        InkWell(
          onTap: () => onToggleExpand(employee.id),
          hoverColor: Colors.grey[50], // Add hover effect
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: index % 2 == 0
                  ? Colors.white
                  : const Color(0xFFF8FAFC), // Alternating colors
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16 * fontScale,
                        backgroundColor: _getAvatarColor(
                          employee.name,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          employee.name.substring(0, 1),
                          style: TextStyle(
                            color: _getAvatarColor(employee.name),
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * fontScale,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: TextStyle(
                                fontSize: 13 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                employee.branch,
                                style: TextStyle(
                                  fontSize: 10 * fontScale,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDataCell(
                  employee.assignedDocuments,
                  color: const Color(0xFF3B82F6),
                ),
                _buildDataCell(
                  employee.pendingDocuments,
                  color: const Color(0xFFF59E0B),
                ),
                _buildDataCell(
                  employee.waitingKey,
                  color: const Color(0xFFF59E0B),
                ),
                _buildDataCell(
                  employee.waitingFix,
                  color: const Color(0xFFEF4444),
                ),
                _buildDataCell(
                  employee.waitingVerify,
                  color: const Color(0xFF8B5CF6),
                ),
                _buildDataCell(
                  employee.completedDocuments,
                  color: const Color(0xFF10B981),
                ),
                _buildDataCell(
                  employee.cancelledDocuments,
                  color: const Color(0xFF64748B),
                  isZeroDim: true,
                ),
                Expanded(
                  flex: 1,
                  child: Center(child: _buildStatusBadge(employee.status)),
                ),
                SizedBox(
                  width: 40,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded Details
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Sub-table rows
                  ...employee.companyDetails.asMap().entries.map((entry) {
                    final i = entry.key;
                    final data = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: i < employee.companyDetails.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFFF1F5F9)),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.company,
                                  style: TextStyle(
                                    fontSize: 12 * fontScale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      data.employee,
                                      style: TextStyle(
                                        fontSize: 12 * fontScale,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${_formatDate(data.recordingDate)}',
                                      style: TextStyle(
                                        fontSize: 11 * fontScale,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.assigned,
                              const Color(0xFF3B82F6),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.pending,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.waitingKey,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.waitingFix,
                              const Color(0xFFEF4444),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.waitingVerify,
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.completed,
                              const Color(0xFF10B981),
                            ),
                          ),
                          Expanded(
                            child: _buildSimpleCount(
                              data.cancelled,
                              const Color(0xFF64748B),
                              isZeroDim: true,
                            ),
                          ),
                          const Expanded(flex: 1, child: SizedBox()),
                          const SizedBox(width: 40),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSimpleCount(int count, Color color, {bool isZeroDim = false}) {
    if (count == 0 && isZeroDim) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(color: Colors.grey[300], fontSize: 12 * fontScale),
        ),
      );
    }
    return Center(
      child: Text(
        NumberFormat('#,###').format(count),
        style: TextStyle(
          fontSize: 12 * fontScale,
          fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
          color: count > 0 ? color : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return Container(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildHeaderCellWithFlex(String text) {
    return Expanded(child: _buildHeaderCell(text));
  }

  Widget _buildDataCell(int value, {bool isZeroDim = false, Color? color}) {
    // If specific color provided, use it. Otherwise fallback to _getCountColor logic if needed (or default)
    final displayColor = color ?? _getCountColor(value);

    return Expanded(
      child: Center(
        child: value == 0 && isZeroDim
            ? Text('-', style: TextStyle(color: Colors.grey[300], fontSize: 13))
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                /* decoration: value > 0
                    ? BoxDecoration(
                        color: displayColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,*/
                child: Text(
                  NumberFormat('#,###').format(value),
                  style: TextStyle(
                    fontSize: 13 * fontScale,
                    fontWeight: value > 0 ? FontWeight.w600 : FontWeight.w400,
                    color: value > 0 ? displayColor : const Color(0xFF94A3B8),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    Color bg;

    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF166534);
        bg = const Color(0xFFDCFCE7);
        text = 'ปกติ';
        break;
      case 'warning':
        color = const Color(0xFF854D0E);
        bg = const Color(0xFFFEF9C3);
        text = 'เฝ้าระวัง';
        break;
      case 'critical':
        color = const Color(0xFF991B1B);
        bg = const Color(0xFFFEE2E2);
        text = 'วิกฤต';
        break;
      case 'completed':
        color = const Color(0xFF166534);
        bg = const Color(0xFFDCFCE7);
        text = 'เสร็จสิ้น';
        break;
      case 'pending':
        color = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        text = 'รอดำเนินการ';
        break;
      case 'cancelled':
      case 'cancel':
        color = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        text = 'ยกเลิก';
        break;
      case 'inactive':
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF8FAFC);
        text = 'ไม่เคลื่อนไหว';
        break;
      default:
        color = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        // Try to map known english words if they slip through, or just return status
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11 * fontScale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCountColor(int value) {
    if (value > 50) return const Color(0xFFEF4444);
    if (value > 20) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildFontScaleButton(IconData icon, double scale) {
    final isSelected = fontScale == scale;
    return InkWell(
      onTap: () => onFontScaleChanged(scale),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getThaiMonth(date.month)} ${date.year + 543}';
  }

  String _getThaiMonth(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return months[month - 1];
  }
}
