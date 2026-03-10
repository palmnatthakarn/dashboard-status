import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';

import '../../components/common/custom_pagination.dart';
import '../../components/common/empty_state_view.dart';
import '../../components/common/user_avatar.dart';
import '../../models/kpi_employee.dart';
import 'kpi_constants.dart';
import 'kpi_text_styles.dart';

class KpiEmployeeTable extends StatefulWidget {
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
  State<KpiEmployeeTable> createState() => _KpiEmployeeTableState();
}

class _KpiEmployeeTableState extends State<KpiEmployeeTable> {
  static final _numFmt = NumberFormat('#,###');
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync header scroll with table scroll
    _tableScrollController.addListener(() {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(_tableScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive check for pagination
    final totalPages = (widget.employees.length / widget.rowsPerPage).ceil();
    final effectivePage = (widget.currentPage > totalPages && totalPages > 0)
        ? totalPages
        : widget.currentPage;

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
          // Header
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table content
          // Table content
          _buildTableContent(effectivePage),

          // Pagination
          if (widget.employees.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPagination(
                currentPage: effectivePage,
                totalItems: widget.totalEmployees,
                rowsPerPage: widget.rowsPerPage,
                onPageChanged: widget.onPageChanged,
                onRowsPerPageChanged: widget.onRowsPerPageChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'รายชื่อพนักงาน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ทั้งหมด ${widget.totalEmployees} คน',
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(int effectivePage) {
    final start = (effectivePage - 1) * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, widget.employees.length);

    if (start > end || widget.employees.isEmpty) {
      return const EmptyStateView(
        title: 'ไม่พบข้อมูลพนักงาน',
        subtitle: 'ลองปรับเงื่อนไขการค้นหาใหม่อีกครั้ง',
      );
    }

    final currentPageEmployees = widget.employees.sublist(start, end);
    final rows = _buildRows(currentPageEmployees);

    // Calculate height based on number of rows
    // Header row (48) + data rows (60 each) + super header (32) + padding
    final tableHeight = 32.0 + 48.0 + (rows.length * 60.0) + 16.0;

    return SizedBox(
      height: tableHeight.clamp(200.0, 800.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Enforce arbitrary minimum width for the table content
          const double minTableWidth = 1200.0;
          final double totalTableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;

          // Calculate width for the scrollable part of the header
          // Fixed column (Employee) is 350
          const double fixedColWidth = 350.0;
          final double scrollableWidth = totalTableWidth - fixedColWidth;

          return Column(
            children: [
              // Super Header Row
              Container(
                height: 32,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Fixed Header Part (Empty/White to match Employee column)
                    SizedBox(
                      width: fixedColWidth,
                      child: Container(color: Colors.white),
                    ),
                    // Scrollable Header Part
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _headerScrollController,
                        scrollDirection: Axis.horizontal,
                        // Disable user interaction on header scroll to enforce strict sync from table
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: scrollableWidth,
                          child: _buildScrollableHeaderGroups(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Table
              Expanded(
                child: DataTable2(
                  border: TableBorder.all(
                    color: const Color.fromRGBO(238, 238, 238, 1),
                    width: 0.5,
                  ),
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  headingRowHeight: 48,
                  dataRowHeight: 60,
                  // Disable internal horizontal scrolling by setting minWidth
                  minWidth: totalTableWidth,
                  fixedLeftColumns: 1, // Fix the Employee column
                  horizontalScrollController: _tableScrollController,
                  dividerThickness: 0,
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11 * widget.fontScale,
                    color: const Color(0xFF374151),
                    letterSpacing: 0.3,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: 11 * widget.fontScale,
                    color: const Color(0xFF1F2937),
                  ),
                  columns: _buildColumns(),
                  rows: rows,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScrollableHeaderGroups() {
    // 11 Flex columns (Size S) + 1 Fixed width column (50)
    // Group 1: Count (1 col)
    // Group 2: Verify (4 cols)
    // Group 3: Account (4 cols)
    // Group 4: Spacer (2 cols for %/Delay) + Fixed 50
    return Row(
      children: [
        // Section 1: Count (1 flex unit) - Spacer to merge visually
        Expanded(
          flex: 1,
          child: Container(), // Empty container to leave header space blank
        ),

        // Section 2: Verification Status (4 flex units)
        Expanded(
          flex: 4,
          child: _buildGroupedHeaderLabel(
            'สถานะการตรวจสอบ',
            KpiColors.section2Background,
          ),
        ),

        // Section 3: Accounting Status (4 flex units)
        Expanded(
          flex: 4,
          child: _buildGroupedHeaderLabel(
            'สถานะการบันทึกบัญชี',
            KpiColors.section3Background,
          ),
        ),

        // Empty space for Stats columns (2 flex units)
        Expanded(flex: 2, child: Container(color: Colors.white)),

        // Blank space for Expand column (Fixed 50)
        SizedBox(width: 50, child: Container(color: Colors.white)),
      ],
    );
  }

  Widget _buildGroupedHeaderLabel(String label, Color color) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        border: const Border(
          left: BorderSide(color: Colors.white, width: 1),
          right: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11 * widget.fontScale,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  List<DataColumn2> _buildColumns() {
    return [
      DataColumn2(
        label: _buildHeaderCell('พนักงาน', Icons.person_outline),
        size: ColumnSize.L,
        fixedWidth: 350,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'จำนวน',
          KpiColors.section1Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'รอตรวจสอบ',
          KpiColors.section2Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'ผ่าน',
          KpiColors.section2Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'ไม่ผ่าน',
          KpiColors.section2Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'ไม่บันทึก',
          KpiColors.section2Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'เอกสารที่ต้องบันทึก',
          KpiColors.section3Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'บันทึก',
          KpiColors.section3Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'คงเหลือ',
          KpiColors.section3Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      DataColumn2(
        label: _buildHeaderCellColored(
          'บันทึกบัญชีเสร็จ',
          KpiColors.section3Background.withValues(alpha: 0.5),
        ),
        size: ColumnSize.S,
        numeric: true,
      ),
      const DataColumn2(
        label: Center(child: Text('% สำเร็จ')),
        size: ColumnSize.S,
      ),
      const DataColumn2(
        label: Center(child: Text('ความล่าช้า')),
        size: ColumnSize.S,
      ),
      const DataColumn2(
        label: SizedBox(width: 40),
        size: ColumnSize.S,
        fixedWidth: 50,
      ),
    ];
  }

  List<DataRow> _buildRows(List<KpiEmployee> currentPageEmployees) {
    final List<DataRow> rows = [];

    for (var i = 0; i < currentPageEmployees.length; i++) {
      final employee = currentPageEmployees[i];
      final isExpanded = widget.expandedEmployeeIds.contains(employee.id);

      // Main employee row
      rows.add(_buildMainRow(employee, i, isExpanded));

      // Sub-rows if expanded
      if (isExpanded) {
        for (var j = 0; j < employee.companyDetails.length; j++) {
          final detail = employee.companyDetails[j];
          rows.add(_buildSubRow(detail, j));
        }
      }
    }

    return rows;
  }

  DataRow _buildMainRow(KpiEmployee employee, int index, bool isExpanded) {
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFEEF2FF);
        }
        return index.isEven ? Colors.white : const Color(0xFFF8FAFC);
      }),
      onSelectChanged: (_) => widget.onToggleExpand(employee.id),
      cells: [
        // พนักงาน
        DataCell(_buildEmployeeCell(employee)),
        // จำนวน
        DataCell(
          _buildCountCell(
            employee.totalDocuments,
            KpiColors.section1Background,
          ),
        ),
        // รอตรวจสอบ
        DataCell(
          _buildCountCell(
            employee.waitingVerify,
            KpiColors.section2Background.withValues(alpha: 0.6),
          ),
        ),
        // ผ่าน
        DataCell(
          _buildCountCell(
            employee.passedDocuments,
            KpiColors.section2Background.withValues(alpha: 0.6),
          ),
        ),
        // ไม่ผ่าน
        DataCell(
          _buildCountCell(
            employee.cancelledDocuments,
            KpiColors.section2Background.withValues(alpha: 0.6),
          ),
        ),
        // ไม่บันทึก
        DataCell(
          _buildCountCell(
            employee.notRecordedDocuments,
            KpiColors.section2Background.withValues(alpha: 0.6),
          ),
        ),
        // เอกสารที่ต้องบันทึก
        DataCell(
          _buildCountCell(
            employee.passedDocuments,
            KpiColors.section3Background.withValues(alpha: 0.6),
          ),
        ),
        // บันทึก
        DataCell(
          _buildCountCell(
            employee.referenceCount,
            KpiColors.section3Background.withValues(alpha: 0.6),
          ),
        ),
        // คงเหลือ
        DataCell(
          _buildCountCell(
            employee.passedDocuments - employee.referenceCount,
            KpiColors.section3Background.withValues(alpha: 0.6),
          ),
        ),
        // บันทึกบัญชีเสร็จ
        DataCell(
          _buildCountCell(
            employee.completedDocuments,
            KpiColors.section3Background.withValues(alpha: 0.6),
          ),
        ),
        // % สำเร็จ
        DataCell(Center(child: _buildProgressBar(employee.completionRate))),
        // ความล่าช้า
        const DataCell(Center(child: SizedBox())),
        // Expand icon
        DataCell(
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Center(
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildSubRow(KpiCompanyDetail detail, int index) {
    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
      cells: [
        // พนักงาน (indented sub-row)
        DataCell(_buildSubRowLabel(detail, index)),
        // จำนวน
        DataCell(
          _buildCountCell(
            detail.totalBillCount,
            KpiColors.section1Background.withValues(alpha: 0.3),
          ),
        ),
        // รอตรวจสอบ
        DataCell(
          _buildCountCell(
            detail.waitingVerify,
            KpiColors.section2Background.withValues(alpha: 0.3),
          ),
        ),
        // ผ่าน
        DataCell(
          _buildCountCell(
            detail.passed,
            KpiColors.section2Background.withValues(alpha: 0.3),
          ),
        ),
        // ไม่ผ่าน
        DataCell(
          _buildCountCell(
            detail.cancelled,
            KpiColors.section2Background.withValues(alpha: 0.3),
          ),
        ),
        // ไม่บันทึก
        DataCell(
          _buildCountCell(
            detail.notRecorded,
            KpiColors.section2Background.withValues(alpha: 0.3),
          ),
        ),
        // เอกสารที่ต้องบันทึก
        DataCell(
          _buildCountCell(
            detail.passed,
            KpiColors.section3Background.withValues(alpha: 0.3),
          ),
        ),
        // บันทึก
        DataCell(
          _buildCountCell(
            detail.referenceCount,
            KpiColors.section3Background.withValues(alpha: 0.3),
          ),
        ),
        // คงเหลือ
        DataCell(
          _buildCountCell(
            detail.passed - detail.referenceCount,
            KpiColors.section3Background.withValues(alpha: 0.3),
          ),
        ),
        // บันทึกบัญชีเสร็จ
        DataCell(
          _buildCountCell(
            detail.completed,
            KpiColors.section3Background.withValues(alpha: 0.3),
          ),
        ),
        // % สำเร็จ
        DataCell(Center(child: _buildProgressBar(detail.progress))),
        // ความล่าช้า
        DataCell(
          Center(
            child: _buildDelayIndicator(detail.delayStep, detail.delayDays),
          ),
        ),
        // Empty for expand icon column
        const DataCell(SizedBox()),
      ],
    );
  }

  Widget _buildEmployeeCell(KpiEmployee employee) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          UserAvatar(
            name: employee.name,
            fontScale: widget.fontScale,
            radius: KpiDimensions.avatarRadius,
            colorPalette: KpiColors.avatarColors,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  employee.name,
                  style: KpiTextStyles.employeeName(widget.fontScale),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 10,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${employee.companyDetails.length} เอกสาร',
                      style: TextStyle(
                        fontSize: 9 * widget.fontScale,
                        color: Colors.grey[500],
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

  Widget _buildSubRowLabel(KpiCompanyDetail detail, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}. ${detail.company}',
            style: TextStyle(
              fontSize: 11 * widget.fontScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            detail.shopName != null
                ? '${detail.shopName} · ${detail.lastActiveFormatted}'
                : detail.lastActiveFormatted,
            style: TextStyle(
              fontSize: 9 * widget.fontScale,
              color: Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCountCell(int value, Color bgColor) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        _numFmt.format(value),
        style: TextStyle(
          fontSize: 11 * widget.fontScale,
          fontWeight: FontWeight.w600,
          color: value > 0 ? KpiColors.baseColor : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double percentage) {
    final clampedPercentage = percentage.clamp(0.0, 100.0);
    final progressColor = clampedPercentage >= 100
        ? KpiColors.completed
        : clampedPercentage >= 50
        ? KpiColors.waitingVerify
        : KpiColors.cancelled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${clampedPercentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11 * widget.fontScale,
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
    );
  }

  Widget _buildDelayIndicator(String delayStep, int delayDays) {
    if (delayStep == 'none') {
      return const SizedBox();
    }

    Color stepColor;
    IconData stepIcon;
    switch (delayStep) {
      case 'รออัปโหลด':
        stepColor = Colors.grey;
        stepIcon = Icons.file_upload_outlined;
        break;
      case 'รอตรวจสอบ':
        stepColor = KpiColors.delayVerify;
        stepIcon = Icons.list_alt_outlined;
        break;
      case 'รอบันทึก':
        stepColor = KpiColors.delayRecord;
        stepIcon = Icons.file_download_outlined;
        break;
      case 'เสร็จสิ้น':
        stepColor = KpiColors.completed;
        stepIcon = Icons.check_circle_outlined;
        break;
      case 'ยกเลิก':
        stepColor = KpiColors.cancelled;
        stepIcon = Icons.cancel_outlined;
        break;
      default:
        stepColor = Colors.grey;
        stepIcon = Icons.access_time;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(stepIcon, size: 16, color: stepColor),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delayStep,
              style: TextStyle(
                fontSize: 9 * widget.fontScale,
                color: stepColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$delayDays วัน',
              style: TextStyle(
                fontSize: 9 * widget.fontScale,
                color: stepColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontScaleButton(IconData icon, double scale) {
    final isSelected = widget.fontScale == scale;
    return InkWell(
      onTap: () => widget.onFontScaleChanged(scale),
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

  Widget _buildHeaderCell(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12 * widget.fontScale, // Scaled icon size
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11 * widget.fontScale, // Scaled font size
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCellColored(String text, Color bgColor) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * widget.fontScale, // Scaled font size
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
