import 'package:flutter/material.dart';

import '../../components/common/custom_pagination.dart';
import '../../components/common/empty_state_view.dart';
import '../../components/common/user_avatar.dart';
import '../../components/table/table_header_cell.dart';
import '../../models/kpi_employee.dart';
import 'kpi_constants.dart';
import 'kpi_text_styles.dart';
import 'widgets/kpi_data_cell.dart';

class KpiEmployeeTable extends StatelessWidget {
  final List<KpiEmployee> employees;
  final Set<String> expandedEmployeeIds;
  final int currentPage;
  final int rowsPerPage;
  final double fontScale;
  final int totalEmployees;

  final Function(String) onToggleExpand;
  final Function(int) onPageChanged;
  final Function(int) onRowsPerPageChanged;
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
    required this.onRowsPerPageChanged,
    required this.onFontScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Defensive check for pagination
    final totalPages = (employees.length / rowsPerPage).ceil();
    final effectivePage = (currentPage > totalPages && totalPages > 0)
        ? totalPages
        : currentPage;

    return Container(
      decoration: BoxDecoration(
        color: KpiColors.cardBackground,
        borderRadius: BorderRadius.circular(KpiDimensions.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
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
          Builder(
            builder: (context) {
              final start = (effectivePage - 1) * rowsPerPage;
              final end = (start + rowsPerPage).clamp(0, employees.length);

              // Additional safety check to prevent start > end if something is really off
              if (start > end) {
                return const EmptyStateView(
                  title: 'ไม่พบข้อมูลพนักงาน',
                  subtitle: 'ลองปรับเงื่อนไขการค้นหาใหม่อีกครั้ง',
                );
              }

              if (employees.isEmpty) {
                return const EmptyStateView(
                  title: 'ไม่พบข้อมูลพนักงาน',
                  subtitle: 'ลองปรับเงื่อนไขการค้นหาใหม่อีกครั้ง',
                );
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
                      children: const [
                        Expanded(
                          flex: 2,
                          child: TableHeaderCell(
                            text: 'พนักงาน',
                            alignLeft: true,
                            flex: 0,
                          ),
                        ),
                        TableHeaderCell(text: 'จำนวน'),
                        TableHeaderCell(text: 'รอตรวจสอบ'),
                        TableHeaderCell(text: 'ผ่าน'),
                        TableHeaderCell(text: 'ไม่ผ่าน'),
                        TableHeaderCell(text: 'รอบันทึก'),
                        TableHeaderCell(
                          text: 'บันทึก',
                        ), // New Reference Count Column
                        TableHeaderCell(
                          text: 'คงเหลือ',
                        ), // New Remaining Column

                        TableHeaderCell(text: 'บันทึกบัญชีเสร็จ'),

                        Expanded(
                          flex: 2,
                          child: TableHeaderCell(text: '% สำเร็จ'),
                        ),
                        Expanded(child: TableHeaderCell(text: 'ความล่าช้า')),

                        SizedBox(width: 40), // Space for expand icon
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
                      context,
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
                currentPage: effectivePage,
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

  Widget _buildExpandableEmployeeRow(
    BuildContext context,
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
                      UserAvatar(
                        name: employee.name,
                        fontScale: fontScale,
                        radius: KpiDimensions.avatarRadius,
                        colorPalette: KpiColors.avatarColors,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: KpiTextStyles.employeeName(fontScale),
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
                                style: KpiTextStyles.branchLabel(fontScale),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // บิลทั้งหมด
                KpiDataCell(
                  value: employee.totalDocuments,
                  color: KpiColors.totalDocuments,
                  fontScale: fontScale,
                ),
                // รอตรวจสอบ
                KpiDataCell(
                  value: employee.waitingVerify,
                  color: KpiColors.waitingVerify,
                  fontScale: fontScale,
                ),
                // ผ่าน (NEW)
                KpiDataCell(
                  value: employee.passedDocuments,
                  color: KpiColors
                      .completed, // Reusing color or need new one? Let's use waitingVerify for now or a green variant
                  fontScale: fontScale,
                ),
                // ไม่ผ่าน
                KpiDataCell(
                  value: employee.cancelledDocuments,
                  color: KpiColors.cancelled,
                  fontScale: fontScale,
                ),
                // รอบันทึก
                KpiDataCell(
                  value: employee.pendingDocuments,
                  color: KpiColors.waitingFix,
                  fontScale: fontScale,
                ),
                // บันทึก (NEW - Reference Count)
                KpiDataCell(
                  value: employee.referenceCount,
                  color: const Color(0xFF6366F1), // Indigo
                  fontScale: fontScale,
                ),
                // คงเหลือ (NEW - Status 0)
                KpiDataCell(
                  value: employee.remainingDocuments,
                  color: Colors
                      .blueGrey, // Use orange or define KpiColors.remaining
                  fontScale: fontScale,
                ),
                // เสร็จสิ้น
                KpiDataCell(
                  value: employee.completedDocuments,
                  color: KpiColors.completed,
                  fontScale: fontScale,
                ),

                // % สำเร็จ (Progress Bar)
                Expanded(
                  flex: 2,
                  child: _buildProgressBar(employee.completionRate, fontScale),
                ),
                // ความล่าช้า - Hide in main row
                const Expanded(child: SizedBox()),

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
                          // ชื่อเอกสาร (flex 2 = พนักงาน column)
                          // ชื่อเอกสาร (flex 2 = พนักงาน column)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${i + 1}. ${data.company}', // Now represents job/task name
                                  style: TextStyle(
                                    fontSize: 12 * fontScale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data.shopName != null
                                      ? '${data.shopName} · ${data.lastActiveFormatted}'
                                      : data.lastActiveFormatted,
                                  style: TextStyle(
                                    fontSize: 10 * fontScale,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // จำนวน
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.totalBillCount,
                              color: KpiColors.totalDocuments,
                              fontScale: fontScale,
                            ),
                          ),

                          // รอตรวจสอบ
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.waitingVerify,
                              color: KpiColors.waitingVerify,
                              fontScale: fontScale,
                            ),
                          ),
                          // ผ่าน (NEW)
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.passed,
                              color: KpiColors.completed,
                              fontScale: fontScale,
                            ),
                          ),
                          // ไม่ผ่าน
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.cancelled,
                              color: KpiColors.cancelled,
                              fontScale: fontScale,
                            ),
                          ),
                          // รอบันทึก
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.pending,
                              color: KpiColors.waitingFix,
                              fontScale: fontScale,
                            ),
                          ),
                          // บันทึก (NEW - referenceCount)
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.referenceCount,
                              color: const Color(0xFF6366F1), // Indigo
                              fontScale: fontScale,
                            ),
                          ),
                          // คงเหลือ (NEW)
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.remaining,
                              color: Colors.blueGrey,
                              fontScale: fontScale,
                            ),
                          ),
                          // เสร็จสิ้น
                          Expanded(
                            child: KpiSimpleCount(
                              count: data.completed,
                              color: KpiColors.completed,
                              fontScale: fontScale,
                            ),
                          ),

                          // % สำเร็จ (Progress Bar) - Moved here
                          Expanded(
                            flex: 2,
                            // Use progress getter from model
                            child: _buildProgressBar(data.progress, fontScale),
                          ),

                          // ความล่าช้า (Delay) - Moved here
                          Expanded(
                            child: _buildDelayIndicator(
                              data.delayStep,
                              data.delayDays,
                              fontScale,
                            ),
                          ),

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

  /// Build progress bar widget showing completion percentage
  Widget _buildProgressBar(double percentage, double fontScale) {
    final clampedPercentage = percentage.clamp(0.0, 100.0);
    final progressColor = clampedPercentage >= 100
        ? KpiColors.completed
        : clampedPercentage >= 50
        ? KpiColors.waitingVerify
        : KpiColors.cancelled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${clampedPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 40,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build delay indicator widget showing pending step and days
  Widget _buildDelayIndicator(
    String delayStep,
    int delayDays,
    double fontScale,
  ) {
    if (delayStep == 'none') {
      return Center(
        child: Text(
          '-',
          style: TextStyle(fontSize: 11 * fontScale, color: Colors.grey[400]),
        ),
      );
    }

    Color stepColor;
    switch (delayStep) {
      case 'รออัปโหลด':
        stepColor = Colors.grey;
        break;
      case 'รอตรวจสอบ':
        stepColor = KpiColors.delayVerify;
        break;
      case 'รอบันทึก':
        stepColor = KpiColors.delayRecord;
        break;
      case 'เสร็จสิ้น':
        stepColor = KpiColors.completed;
        break;
      case 'ยกเลิก':
        stepColor = KpiColors.cancelled;
        break;
      case 'คงเหลือ':
        stepColor = Colors.blueGrey;
        break;
      default:
        stepColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$delayStep:$delayDays วัน',
            style: TextStyle(
              fontSize: 10 * fontScale,
              color: stepColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build incentive status widget showing pass/fail with bills needed
  Widget _buildIncentiveStatus(bool passed, int billsNeeded, double fontScale) {
    if (passed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: KpiColors.incentivePass.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: KpiColors.incentivePass.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 14, color: KpiColors.incentivePass),
            const SizedBox(width: 4),
            Text(
              'ผ่าน',
              style: TextStyle(
                fontSize: 11 * fontScale,
                color: KpiColors.incentivePass,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: KpiColors.incentiveFail.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: KpiColors.incentiveFail.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 12, color: KpiColors.incentiveFail),
              const SizedBox(width: 2),
              Text(
                'ไม่ผ่าน',
                style: TextStyle(
                  fontSize: 10 * fontScale,
                  color: KpiColors.incentiveFail,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'ขาด $billsNeeded บิล',
            style: TextStyle(
              fontSize: 9 * fontScale,
              color: KpiColors.incentiveFail,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
