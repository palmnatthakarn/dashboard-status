import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class ReceivablesPage extends StatelessWidget {
  const ReceivablesPage({super.key});

  static const List<String> _reportTypes = [
    'วิเคราะห์อายุลูกหนี้ (AR Aging)',
    'สรุปยอดขายตามสินค้า / ตามลูกค้า (Sales Summary)',
    'การ์ดลูกหนี้รายตัว (Customer Ledger)',
  ];

  @override
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'ลูกหนี้และการขาย (Receivables & Sales)',
      reportTypes: _reportTypes,
    );
  }
}
