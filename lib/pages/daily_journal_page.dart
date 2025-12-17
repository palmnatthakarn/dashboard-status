import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class DailyJournalPage extends StatelessWidget {
  const DailyJournalPage({super.key});

  static const List<String> _reportTypes = [
    'ทุกสมุดรายวัน',
    'ทั่วไป',
    'จ่าย',
    'รับ',
    'ซื้อ',
    'ขาย',
    'ธนาคาร',
    'ไม่บันทึกบัญชี',
  ];

  @override
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'สมุดรายวัน (Daily Journal)',
      reportTypes: _reportTypes,
      defaultReportType: 'ทุกสมุดรายวัน',
    );
  }
}
