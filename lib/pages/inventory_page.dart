import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const List<String> _reportTypes = [
    'บัญชีคุมสินค้า (Stock Card)',
    'สรุปความเคลื่อนไหวสินค้า (Stock Movement)',
  ];

  @override
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'สินค้าคงคลัง (Inventory)',
      reportTypes: _reportTypes,
    );
  }
}
