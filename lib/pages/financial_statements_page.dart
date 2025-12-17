import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moniter/components/financial_report/report_content.dart';
import 'package:moniter/components/financial_report/report_empty_state.dart';
import 'package:moniter/components/financial_report/report_filter_section.dart';
import 'package:moniter/components/financial_report/report_header.dart';

class FinancialStatementsPage extends StatefulWidget {
  const FinancialStatementsPage({super.key});

  @override
  State<FinancialStatementsPage> createState() =>
      _FinancialStatementsPageState();
}

class _FinancialStatementsPageState extends State<FinancialStatementsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedReportType;

  final List<String> _reportTypes = [
    'งบทดลอง',
    'งบกำไรขาดทุน',
    'งบกำไรขาดทุน 12 เดือน',
    'งบแสดงฐานะทางการเงิน',
    'บัญชีแยกประเภท',
    'กระดาษทำการ',
    'รายงานการบันทึกบัญชี',
    'รายงานรหัสบัญชี',
    'รายงานสถานะเจ้าหนี้',
    'รายงานสถานะลูกหนี้',
  ];

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'งบการเงิน (Financial Statements)',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportFilterSection(
              reportTypes: _reportTypes,
              selectedReportType: _selectedReportType,
              startDate: _startDate,
              endDate: _endDate,
              onReportTypeChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                });
              },
              onStartDateTap: () => _selectDate(true),
              onEndDateTap: () => _selectDate(false),
            ),
            const SizedBox(height: 24),
            if (_selectedReportType != null) ...[
              ReportHeader(
                selectedReportType: _selectedReportType,
                startDate: _startDate,
                endDate: _endDate,
                onFullScreen: _openReportFullScreen,
                onExport: _handleExport,
              ),
              const SizedBox(height: 16),
              ReportContent(selectedReportType: _selectedReportType),
            ] else
              const ReportEmptyState(),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1), // Key color
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleExport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('กำลังดาวน์โหลดรายงาน $type...'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  void _openReportFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$_selectedReportType'),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ReportContent(selectedReportType: _selectedReportType),
            ),
          ),
        ),
      ),
    );
  }
}
