import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class FinancialStatementsPage extends StatelessWidget {
  const FinancialStatementsPage({super.key});

  static const List<String> _reportTypes = [
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
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'งบการเงิน (Financial Statements)',
      reportTypes: _reportTypes,
    );
  }
}
