import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/base_report_page.dart';

class TaxPage extends StatelessWidget {
  const TaxPage({super.key});

  static const List<String> _reportTypes = [
    'รายงานภาษีซื้อ',
    'รายงานภาษีขาย',
    'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.3)',
    'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.53)',
    'ภาษีถูกหัก ณ ที่จ่าย',
  ];

  @override
  Widget build(BuildContext context) {
    return const BaseReportPage(
      title: 'รายงานภาษี (Tax Reports)',
      reportTypes: _reportTypes,
    );
  }
}
