import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class PayablesPage extends StatelessWidget {
  const PayablesPage({super.key});

  static const List<String> _reportTypes = [
    'วิเคราะห์อายุเจ้าหนี้ (AP Aging)',
    'สรุปยอดซื้อ (Purchase Summary)',
  ];

  @override
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'เจ้าหนี้และการซื้อ (Payables & Purchase)',
      reportTypes: _reportTypes,
    );
  }
}
