import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../components/common/custom_pagination.dart';
import 'dart:math';

class EmployeeDetailPage extends StatefulWidget {
  final dynamic employee;

  const EmployeeDetailPage({super.key, required this.employee});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  // Pagination state
  int _currentPage = 1;
  int _rowsPerPage = 5;

  // Generate mock team data
  List<Map<String, dynamic>> _generateTeamData() {
    return List.generate(100, (index) {
      final random = Random(index);
      final companies = ['บริษัท ก.', 'บริษัท ข.', 'บริษัท ค.', 'บริษัท ง.'];
      final employees = ['นาย A', 'นาง B', 'นาย C', 'นาง D'];

      return {
        'company': companies[random.nextInt(companies.length)],
        'employee': employees[random.nextInt(employees.length)],
        'recordingDate': DateTime.now().subtract(
          Duration(days: random.nextInt(30)),
        ),
        'assigned': random.nextInt(20),
        'pending': random.nextInt(10),
        'pendingEdit': random.nextInt(5),
        'reviewing': random.nextInt(5),
        'completed': random.nextInt(50),
        'cancelled': random.nextInt(2),
        'status': [
          'รอดำเนินการ',
          'กำลังดำเนินการ',
          'เสร็จสมบูรณ์',
        ][random.nextInt(3)],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.employee.status);
    final statusText = _getStatusText(widget.employee.status);
    final teamData = _generateTeamData();

    // Calculate pagination for team data
    final totalTeamMembers = teamData.length;
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, totalTeamMembers);
    final currentPageTeamData = teamData.sublist(start, end);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายละเอียดพนักงาน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Text(
                      widget.employee.name[0],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employee.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary Cards
            /*  Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'รวมทั้งหมด',
                    totalAssigned +
                        totalPending +
                        totalPendingEdit +
                        totalReviewing +
                        totalCompleted +
                        totalCancelled,
                    Icons.description_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'สมบูรณ์',
                    totalCompleted,
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'รอดำเนินการ',
                    totalPending + totalPendingEdit + totalReviewing,
                    Icons.pending_actions_rounded,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),*/
            const SizedBox(height: 20),

            // Team Data Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.table_chart_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'รายละเอียดลูกทีม',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Divider(height: 1),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 400,
                      maxHeight: 600, // Increased slightly
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DataTable2(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF9FAFB),
                                ),
                                columnSpacing: 12, // Reduced spacing
                                horizontalMargin: 20,
                                minWidth:
                                    600, // Reduced minWidth for responsiveness
                                headingRowHeight: 52,
                                dataRowHeight: 72, // Increased row height
                                showCheckboxColumn: false,
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF111827),
                                  letterSpacing: 0.1,
                                ),
                                dataTextStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                                dividerThickness: 0,
                                columns: const [
                                  DataColumn2(
                                    label: Text('ชื่อ-นามสกุลหัวทีม'),
                                    size: ColumnSize.L,
                                  ),
                                  DataColumn2(
                                    label: Text('วันที่บันทึก'),
                                    size: ColumnSize.S,
                                    fixedWidth: 100,
                                  ),
                                  DataColumn2(
                                    label: Text('มอบหมายคีย์อิน'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('รอการคีย์อิน'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('รอคีย์อิน(แก้ไข)'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('รอตรวจสอบหลังคีย์อิน'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('สมบูรณ์'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('ยกเลิก'),
                                    size: ColumnSize.S,
                                    numeric: true,
                                  ),
                                  DataColumn2(
                                    label: Text('สถานะ'),
                                    size: ColumnSize.M,
                                  ),
                                ],
                                rows: [
                                  ...currentPageTeamData.asMap().entries.map((
                                    entry,
                                  ) {
                                    final globalIndex = start + entry.key;
                                    final data = entry.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${globalIndex + 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      data['company'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      data['employee'],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          _buildRecordingDateCell(
                                            data['recordingDate'],
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['assigned'],
                                            const Color(0xFF3B82F6),
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['pending'],
                                            const Color(0xFFF59E0B),
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['pendingEdit'],
                                            const Color(0xFFEF4444),
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['reviewing'],
                                            const Color(0xFF8B5CF6),
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['completed'],
                                            const Color(0xFF10B981),
                                          ),
                                        ),
                                        DataCell(
                                          _buildCountChip(
                                            data['cancelled'],
                                            const Color(0xFF6B7280),
                                          ),
                                        ),
                                        DataCell(
                                          _buildStatusBadge(data['status']),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomPagination(
                            currentPage: _currentPage,
                            totalItems: totalTeamMembers,
                            rowsPerPage: _rowsPerPage,
                            rowsPerPageOptions: const [5, 10, 20],
                            onPageChanged: (page) =>
                                setState(() => _currentPage = page),
                            onRowsPerPageChanged: (rows) => setState(() {
                              _rowsPerPage = rows;
                              _currentPage = 1;
                            }),
                          ),
                        ],
                      ),
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

  Widget _buildSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCountChip(int count, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status) {
      case 'รอดำเนินการ':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'กำลังดำเนินการ':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'เสร็จสมบูรณ์':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecordingDateCell(DateTime date) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
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

  Color _getStatusColor(String status) {
    return switch (status) {
      'completed' => const Color(0xFF10B981),
      'assigned' => const Color(0xFF3B82F6),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF6B7280),
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'completed' => 'สมบูรณ์',
      'assigned' => 'มอบหมายแล้ว',
      'pending' => 'รอการคีย์',
      _ => 'ไม่ทราบ',
    };
  }
}
