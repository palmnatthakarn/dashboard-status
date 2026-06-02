import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../models/journal.dart';
import '../utils/app_logger.dart';
import 'auth_repository.dart';
import 'journal_service.dart';

enum ReportDataStatus { ready, empty, unsupported }

enum ReportDataSource { live, sample }

class ReportTableData {
  final ReportDataStatus status;
  final ReportDataSource source;
  final List<String> headers;
  final List<List<String>> rows;
  final List<int> highlightRows;
  final List<Map<String, String>> rowDetails;
  final String? message;
  final String? paginationTotalLabel;

  const ReportTableData({
    required this.status,
    required this.source,
    this.headers = const [],
    this.rows = const [],
    this.highlightRows = const [],
    this.rowDetails = const [],
    this.message,
    this.paginationTotalLabel,
  });

  bool get canDrillDown => rowDetails.any((details) => details.isNotEmpty);
}

class _AccountTotals {
  final String code;
  final String name;
  final String type;
  double debit = 0;
  double credit = 0;

  _AccountTotals({
    required this.code,
    required this.name,
    required this.type,
  });

  void add(Journal journal) {
    debit += journal.debit ?? 0;
    credit += journal.credit ?? 0;
  }
}

/// Provides table data for report previews and exports.
class ReportDataProvider {
  static final _moneyFmt = NumberFormat('#,##0.00');
  static const int _journalDailyLimit = 500;
  static const int _journalDailyMaxRows = 300;

  static const Set<String> _liveJournalReports = {
    'ทุกสมุดรายวัน',
    'ทั่วไป',
    'จ่าย',
    'รับ',
    'ซื้อ',
    'ขาย',
    'ธนาคาร',
    'งบทดลอง',
    'งบกำไรขาดทุน',
    'งบกำไรขาดทุน 12 เดือน',
    'งบแสดงฐานะทางการเงิน',
  };

  static const Set<String> _unsupportedReports = {
  };

  static Future<ReportTableData> fetchReportData({
    required String reportType,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_unsupportedReports.contains(reportType)) {
      return ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'รายงานนี้ยังไม่ได้เชื่อมต่อข้อมูลในระบบ',
      );
    }

    if (_isFinancialStatement(reportType)) {
      return _fetchFinancialStatement(
        reportType: reportType,
        shopId: shopId,
        startDate: startDate,
        endDate: endDate,
      );
    }

    if (_isApiBackedReport(reportType)) {
      return _fetchApiBackedReport(
        reportType: reportType,
        shopId: shopId,
        startDate: startDate,
        endDate: endDate,
      );
    }

    if (_liveJournalReports.contains(reportType)) {
      return _fetchJournalReport(
        reportType: reportType,
        shopId: shopId,
        startDate: startDate,
        endDate: endDate,
      );
    }

    final sampleData = getTableData(reportType);
    if (sampleData == null) {
      return ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'ยังไม่รองรับรายงานประเภทนี้',
      );
    }

    final rows = (sampleData['rows'] as List<List<String>>?) ?? [];
    if (rows.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.sample,
        message: 'ไม่พบข้อมูลในเงื่อนไขที่เลือก',
      );
    }

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.sample,
      headers: (sampleData['headers'] as List<String>?) ?? [],
      rows: rows,
      highlightRows: _totalRowIndexes(rows),
      rowDetails: List.generate(rows.length, (_) => const <String, String>{}),
    );
  }

  static Future<ReportTableData> _fetchFinancialStatement({
    required String reportType,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (reportType == 'งบกำไรขาดทุน') {
      return _fetchIncomeStatementFromApi(
        shopId: shopId,
        startDate: startDate,
        endDate: endDate,
      );
    }
    if (reportType == 'งบกำไรขาดทุน 12 เดือน') {
      return _fetchIncomeStatement12ColumnsFromApi(
        shopId: shopId,
        endDate: endDate,
      );
    }
    if (reportType == 'งบแสดงฐานะทางการเงิน') {
      return _fetchBalanceSheetFromApi(
        shopId: shopId,
        endDate: endDate,
      );
    }

    final journals = await _fetchGlJournalsAcrossShops(
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
    );
    if (journals.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูล GL ในช่วงวันที่ที่เลือก',
      );
    }

    if (reportType == 'งบทดลอง') {
      return _buildTrialBalanceFromJournals(journals);
    }
    if (reportType == 'งบกำไรขาดทุน' || reportType == 'งบกำไรขาดทุน 12 เดือน') {
      return _buildProfitLossFromJournals(journals);
    }
    return _buildBalanceSheetFromJournals(journals);
  }

  static Future<ReportTableData> _fetchIncomeStatementFromApi({
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shopId == null || shopId.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'กรุณาเลือกร้านก่อนค้นหารายงาน',
      );
    }

    final fromDate = JournalService.formatDate(
      startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    final toDate = JournalService.formatDate(endDate ?? DateTime.now());
    final uri = Uri.parse(
      '${AuthRepository.baseUrl}/apireport/income-statement',
    ).replace(
      queryParameters: {
        'shopid': shopId,
        'fromdate': fromDate,
        'enddate': toDate,
      },
    );

    dLog('📊 Fetching income statement from: $uri');

    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthRepository.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'โหลดงบกำไรขาดทุนไม่สำเร็จ - Status: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    final root = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (root['success'] == false) {
      throw Exception(root['msg']?.toString() ?? 'โหลดงบกำไรขาดทุนไม่สำเร็จ');
    }

    final data = root['data'];
    final items = data is List ? data : const [];
    if (items.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูลงบกำไรขาดทุนในช่วงวันที่ที่เลือก',
      );
    }

    final rows = <List<String>>[];
    final details = <Map<String, String>>[];
    final highlightRows = <int>[];

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = rawItem.cast<String, dynamic>();
      final type = item['type']?.toString() ?? '';
      final accountCode = item['accountcode']?.toString() ?? '';
      final accountName = item['accountname']?.toString() ?? '-';
      final depth = (item['depth'] as num?)?.toInt() ?? 0;
      final balance = (item['balance'] as num?)?.toDouble();
      final isBold = item['isBold'] == true;
      final indent = '  ' * depth;

      rows.add([
        '$indent$accountName',
        accountCode.isEmpty ? '-' : accountCode,
        balance == null ? '' : _moneyFmt.format(balance),
      ]);

      details.add({
        'ประเภทแถว': type.isEmpty ? '-' : type,
        'รหัสบัญชี': accountCode.isEmpty ? '-' : accountCode,
        'ชื่อบัญชี': accountName,
        'จำนวนเงิน': balance == null ? '-' : _moneyFmt.format(balance),
      });

      if (isBold || type != 'account') {
        highlightRows.add(rows.length - 1);
      }
    }

    if (rows.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูลงบกำไรขาดทุนในช่วงวันที่ที่เลือก',
      );
    }

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: const ['รายการ', 'รหัสบัญชี', 'จำนวนเงิน'],
      rows: rows,
      highlightRows: highlightRows,
      rowDetails: details,
    );
  }

  static Future<ReportTableData> _fetchIncomeStatement12ColumnsFromApi({
    String? shopId,
    DateTime? endDate,
  }) async {
    if (shopId == null || shopId.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'กรุณาเลือกร้านก่อนค้นหารายงาน',
      );
    }

    final effectiveEndDate = endDate ?? DateTime.now();
    final endDateValue =
        '${JournalService.formatDate(effectiveEndDate)} 23:59:59';
    final uri = Uri.parse(
      '${AuthRepository.baseUrl}/apireport/journal12columns/',
    ).replace(
      queryParameters: {
        'endDate': endDateValue,
        'shopid': shopId,
        'shopname': '',
        'taxid': '',
        'address': '',
      },
    );

    dLog('📊 Fetching 12-column income statement from: $uri');

    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthRepository.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'โหลดงบกำไรขาดทุน 12 เดือนไม่สำเร็จ - Status: ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    final root = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (root['success'] == false) {
      throw Exception(
        root['msg']?.toString() ?? 'โหลดงบกำไรขาดทุน 12 เดือนไม่สำเร็จ',
      );
    }

    final data = root['data'];
    if (data is! Map) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูลงบกำไรขาดทุน 12 เดือน',
      );
    }

    final report = data.cast<String, dynamic>();
    final monthRange = (report['monthRange'] as List?)
            ?.whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    if (monthRange.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบช่วงเดือนสำหรับงบกำไรขาดทุน 12 เดือน',
      );
    }

    final monthKeys = monthRange
        .map((item) => item['key']?.toString() ?? '')
        .where((key) => key.isNotEmpty)
        .toList();
    final monthLabels = monthRange.map((item) {
      final displayName = item['displayName']?.toString() ?? '';
      final year = item['year']?.toString() ?? '';
      return year.length >= 4 ? '$displayName ${year.substring(2)}' : displayName;
    }).toList();

    final rows = <List<String>>[];
    final details = <Map<String, String>>[];
    final highlightRows = <int>[];

    void addRow(
      String name, {
      String accountCode = '',
      Map<String, dynamic>? values,
      bool highlight = false,
      String type = '',
    }) {
      final row = <String>[
        name,
        accountCode.isEmpty ? '-' : accountCode,
        ...monthKeys.map((key) => _formatDynamicMoney(values?[key])),
        _formatDynamicMoney(values?['total_amount'] ?? values?['grandTotal']),
      ];
      rows.add(row);
      details.add({
        'ประเภทแถว': type.isEmpty ? '-' : type,
        'รหัสบัญชี': accountCode.isEmpty ? '-' : accountCode,
        'รายการ': name,
      });
      if (highlight) highlightRows.add(rows.length - 1);
    }

    void addSection(String title) {
      addRow(title, highlight: true, type: 'section');
    }

    void addItems(String sectionKey) {
      final section = report[sectionKey];
      final items = section is Map ? section['items'] : null;
      if (items is! List) return;

      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final item = rawItem.cast<String, dynamic>();
        addRow(
          item['accountname']?.toString() ?? '-',
          accountCode: item['accountcode']?.toString() ?? '',
          values: item,
          type: sectionKey,
        );
      }
    }

    void addSummary(String title, String sectionKey) {
      final section = report[sectionKey];
      final summary = section is Map ? section['summary'] : null;
      if (summary is! Map) return;
      final summaryMap = summary.cast<String, dynamic>();
      final monthTotals = summaryMap['monthTotals'];
      final values = monthTotals is Map
          ? monthTotals.cast<String, dynamic>()
          : <String, dynamic>{};
      values['grandTotal'] = summaryMap['grandTotal'];
      addRow(title, values: values, highlight: true, type: 'summary');
    }

    void addCalculatedTotal(String title, String key) {
      final value = report[key];
      if (value is! Map) return;
      final valueMap = value.cast<String, dynamic>();
      final monthTotals = valueMap['monthTotals'];
      final values = monthTotals is Map
          ? monthTotals.cast<String, dynamic>()
          : <String, dynamic>{};
      values['grandTotal'] = valueMap['grandTotal'];
      addRow(title, values: values, highlight: true, type: key);
    }

    addSection('รายได้');
    addItems('revenue');
    addSummary('รวมรายได้', 'revenue');
    addSection('ต้นทุนขาย');
    addItems('costOfSales');
    addSummary('รวมต้นทุนขาย', 'costOfSales');
    addCalculatedTotal('กำไรขั้นต้น', 'grossProfit');
    addSection('ค่าใช้จ่าย');
    addItems('expense');
    addSummary('รวมค่าใช้จ่าย', 'expense');
    addCalculatedTotal('กำไร(ขาดทุน)สุทธิ', 'netProfit');

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: ['รายการ', 'รหัสบัญชี', ...monthLabels, 'รวม'],
      rows: rows,
      highlightRows: highlightRows,
      rowDetails: details,
    );
  }

  static Future<ReportTableData> _fetchBalanceSheetFromApi({
    String? shopId,
    DateTime? endDate,
  }) async {
    if (shopId == null || shopId.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'กรุณาเลือกร้านก่อนค้นหารายงาน',
      );
    }

    final toDate = JournalService.formatDate(endDate ?? DateTime.now());
    final uri = Uri.parse(
      '${AuthRepository.baseUrl}/apireport/balance-sheet',
    ).replace(
      queryParameters: {
        'shopid': shopId,
        'enddate': toDate,
        'shopname': '',
        'taxid': '',
        'address': '',
      },
    );

    final root = await _getJsonMap(uri, 'โหลดงบแสดงฐานะทางการเงินไม่สำเร็จ');
    final data = root['data'];
    final items = data is List ? data : const [];
    if (items.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูลงบแสดงฐานะทางการเงิน',
      );
    }

    final rows = <List<String>>[];
    final details = <Map<String, String>>[];
    final highlightRows = <int>[];

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = rawItem.cast<String, dynamic>();
      final type = item['type']?.toString() ?? '';
      final accountCode = item['accountcode']?.toString() ?? '';
      final accountName = item['accountname']?.toString() ?? '-';
      final depth = (item['depth'] as num?)?.toInt() ?? 0;
      final balance = item['balance'];
      final isBold = item['isBold'] == true;
      final indent = '  ' * depth;

      rows.add([
        '$indent$accountName',
        accountCode.isEmpty ? '-' : accountCode,
        _formatDynamicMoney(balance),
      ]);

      details.add({
        'ประเภทแถว': type.isEmpty ? '-' : type,
        'รหัสบัญชี': accountCode.isEmpty ? '-' : accountCode,
        'ชื่อบัญชี': accountName,
        'จำนวนเงิน': _formatDynamicMoney(balance),
      });

      if (isBold || type != 'account') {
        highlightRows.add(rows.length - 1);
      }
    }

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: const ['รายการ', 'รหัสบัญชี', 'จำนวนเงิน'],
      rows: rows,
      highlightRows: highlightRows,
      rowDetails: details,
    );
  }

  static Future<ReportTableData> _fetchApiBackedReport({
    required String reportType,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = JournalService.formatDate(
      startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    final end = JournalService.formatDate(endDate ?? DateTime.now());
    final year = (endDate ?? DateTime.now()).year + 543;
    final period = (endDate ?? DateTime.now()).month;
    final fromDateTime = '$start 00:00:00';
    final toDateTime = '$end 23:59:59';

    late final Uri uri;
    late final List<String> headers;
    late final List<List<String>> fields;

    switch (reportType) {
      case 'บัญชีแยกประเภท':
        uri = Uri.parse('${AuthRepository.baseUrl}/gl/report/ledgeraccount')
            .replace(queryParameters: {
          'startdate': start,
          'enddate': end,
        });
        headers = const [
          'รหัสบัญชี',
          'ชื่อบัญชี',
          'วันที่',
          'เลขที่เอกสาร',
          'รายละเอียด',
          'เครดิต',
          'เดบิต',
          'คงเหลือ',
        ];
        fields = const [
          ['accountcode', 'account_code', 'code'],
          ['accountname', 'account_name', 'name'],
          ['docdate', 'date', 'createdat'],
          ['docno', 'documentno', 'document_no', 'refno'],
          ['description', 'remark', 'details'],
          ['credit', 'credit_amount'],
          ['debit', 'debit_amount'],
          ['balance', 'amount'],
        ];
        break;
      case 'กระดาษทำการ':
        uri = Uri.parse('${AuthRepository.baseUrl}/gl/report/trialbalancesheet')
            .replace(queryParameters: {
          'startdate': start,
          'enddate': end,
          'ica': '0',
        });
        headers = const ['รหัสบัญชี', 'ชื่อบัญชี', 'เดบิต', 'เครดิต', 'คงเหลือ'];
        fields = const [
          ['accountcode', 'account_code', 'code'],
          ['accountname', 'account_name', 'name'],
          ['debit', 'debit_amount'],
          ['credit', 'credit_amount'],
          ['balance', 'amount'],
        ];
        break;
      case 'รายงานรหัสบัญชี':
        uri = Uri.parse('${AuthRepository.baseUrl}/gl/chartofaccount')
            .replace(queryParameters: {
          'limit': '2000',
          'q': '',
          'page': '1',
          'sort': 'accountcode:1',
        });
        headers = const ['รหัสบัญชี', 'ชื่อบัญชี', 'หมวด', 'ระดับ', 'สถานะ'];
        fields = const [
          ['accountcode', 'account_code', 'code'],
          ['accountname', 'account_name', 'name'],
          ['accountcategory', 'category', 'account_type'],
          ['accountlevel', 'level'],
          ['status', 'active'],
        ];
        break;
      case 'รายงานสถานะเจ้าหนี้':
        uri = Uri.parse('${AuthRepository.baseUrl}/debtaccount/creditor')
            .replace(queryParameters: {
          'limit': '1000',
          'q': '',
          'page': '1',
          'sort': 'code:1',
        });
        headers = const ['รหัส', 'ชื่อ', 'เลขประจำตัวผู้เสียภาษี', 'โทรศัพท์', 'ยอดคงเหลือ'];
        fields = const [
          ['code', 'creditorcode', 'id'],
          ['name', 'creditorname', 'accountname'],
          ['taxid', 'tax_id'],
          ['telephone', 'tel', 'phone'],
          ['balance', 'amount', 'debtamount'],
        ];
        break;
      case 'รายงานสถานะลูกหนี้':
        uri = Uri.parse('${AuthRepository.baseUrl}/debtaccount/debtor')
            .replace(queryParameters: {
          'limit': '1000',
          'q': '',
          'page': '1',
          'sort': 'code:1',
        });
        headers = const ['รหัส', 'ชื่อ', 'เลขประจำตัวผู้เสียภาษี', 'โทรศัพท์', 'ยอดคงเหลือ'];
        fields = const [
          ['code', 'debtorcode', 'id'],
          ['name', 'debtorname', 'accountname'],
          ['taxid', 'tax_id'],
          ['telephone', 'tel', 'phone'],
          ['balance', 'amount', 'debtamount'],
        ];
        break;
      case 'รายงานภาษีซื้อ':
        uri = Uri.parse('${AuthRepository.baseUrl}/apireport/journalvat')
            .replace(queryParameters: {
          'limit': '10',
          'offset': '0',
          'mode': '0',
          'year': year.toString(),
          'period': period.toString(),
          'fromdate': fromDateTime,
          'todate': toDateTime,
          'shopid': shopId ?? '',
          'shopname': '',
          'taxid': '',
          'address': '',
        });
        headers = const [
          'ลำดับ',
          'วันที่',
          'เลขที่ใบกำกับ',
          'เลขที่เอกสาร',
          'ชื่อผู้ขาย/ผู้ให้บริการ',
          'เลขประจำตัวผู้เสียภาษี',
          'สาขา',
          'ยอดยกเว้นภาษี',
          'มูลค่าสินค้า',
          'จำนวนภาษี',
          'รวมทั้งสิ้น',
          'ยื่นเพิ่มเติม',
        ];
        fields = const [
          ['__rowNumber'],
          ['docdate', 'taxdate', 'vatdate', 'date', 'createdat'],
          ['vatdocno', 'taxinvoice_no', 'taxinvoiceno', 'taxno', 'taxinvoice', 'invoiceno'],
          ['docno', 'documentno', 'document_no', 'refno', 'journalno'],
          ['custname', 'vendorname', 'creditor_name', 'suppliername', 'customername', 'name'],
          ['custtaxid', 'taxid', 'tax_id', 'vendortaxid', 'customertaxid'],
          ['branchcode', 'branch', 'branchname', 'branch_no', 'branchno'],
          [
            'exceptvat',
            'exemptamount',
            'vat_exempt_amount',
            'nonvatamount',
            'zeroamount',
            'amountzerovat',
            'novatamount',
            'exceptvatamount',
          ],
          [
            '__vatProductAmount',
            'vatbase',
            'baseamount',
            'vatbaseamount',
            'vatableamount',
            'amountbeforevat',
            'amount_before_vat',
            'beforevatamount',
            'goodsamount',
            'productamount',
            'serviceamount',
            'subtotal',
            'value',
          ],
          ['vatamount', 'taxamount', 'amountvat', 'vat', 'tax'],
          ['__vatTotalAmount', 'totalamount', 'grandtotal', 'netamount', 'total'],
          ['additional', 'isadditional', 'submitadditional', 'is_additional'],
        ];
        break;
      case 'รายงานภาษีขาย':
        uri = Uri.parse('${AuthRepository.baseUrl}/apireport/journalvat')
            .replace(queryParameters: {
          'limit': '10',
          'offset': '0',
          'mode': '1',
          'year': year.toString(),
          'period': period.toString(),
          'fromdate': fromDateTime,
          'todate': toDateTime,
          'shopid': shopId ?? '',
          'shopname': '',
          'taxid': '',
          'address': '',
        });
        headers = const [
          'ลำดับ',
          'วันที่',
          'เลขที่ใบกำกับ',
          'เลขที่เอกสาร',
          'ชื่อผู้ขาย/ผู้ให้บริการ',
          'เลขประจำตัวผู้เสียภาษี',
          'สาขา',
          'ฐานภาษี',
          'ภาษี',
          'ยกเว้นภาษี',
          'รวมทั้งสิ้น',
          'ยื่นเพิ่มเติม',
        ];
        fields = const [
          ['__rowNumber'],
          ['docdate', 'taxdate', 'vatdate', 'date', 'createdat'],
          ['vatdocno', 'taxinvoice_no', 'taxinvoiceno', 'taxno', 'taxinvoice', 'invoiceno'],
          ['docno', 'documentno', 'document_no', 'refno', 'journalno'],
          ['custname', 'customername', 'vendorname', 'creditor_name', 'debtor_name', 'name'],
          ['custtaxid', 'taxid', 'tax_id', 'customertaxid', 'vendortaxid'],
          ['branchcode', 'branch', 'branchname', 'branch_no', 'branchno'],
          ['vatbase', 'baseamount', 'vatbaseamount', 'vatableamount', 'amountbeforevat', 'amount_before_vat'],
          ['vatamount', 'taxamount', 'amountvat', 'vat', 'tax'],
          ['exceptvat', 'exemptamount', 'vat_exempt_amount', 'nonvatamount', 'zeroamount'],
          ['__vatTotalAmount', 'totalamount', 'grandtotal', 'netamount', 'total'],
          ['additional', 'isadditional', 'submitadditional', 'is_additional'],
        ];
        break;
      case 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.3)':
        uri = Uri.parse('${AuthRepository.baseUrl}/apireport/journaltax')
            .replace(queryParameters: {
          'limit': '10',
          'offset': '0',
          'taxtype': '1',
          'custtype': '0',
          'fromdate': fromDateTime,
          'todate': toDateTime,
          'shopid': shopId ?? '',
          'shopname': '',
          'taxid': '',
          'address': '',
        });
        headers = const [
          'ลำดับ',
          'วันที่',
          'ชื่อ',
          'ที่อยู่',
          'เลขประจำตัวผู้เสียภาษี',
          'เลขที่หนังสือรับรอง',
          'รายละเอียด',
          'อัตราภาษี',
          'จำนวนเงินที่จ่าย',
          'ภาษีที่หัก',
          'เงื่อนไข',
        ];
        fields = const [
          ['__rowNumber'],
          ['docdate', 'paydate', 'taxdate', 'date', 'createdat'],
          ['custname', 'customername', 'vendorname', 'creditor_name', 'debtor_name', 'name'],
          ['address'],
          ['custtaxid', 'taxid', 'tax_id', 'customertaxid', 'vendortaxid'],
          ['taxdocno', 'docno', 'documentno', 'document_no'],
          ['description'],
          ['taxrate'],
          ['taxbase', 'amount', 'baseamount', 'payamount', 'incomeamount'],
          ['taxamount', 'withholdingtax', 'whtamount', 'tax'],
          ['conditiontaxtype'],
        ];
        break;
      case 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.53)':
        uri = Uri.parse('${AuthRepository.baseUrl}/apireport/journaltax')
            .replace(queryParameters: {
          'limit': '10',
          'offset': '0',
          'taxtype': '1',
          'custtype': '1',
          'fromdate': fromDateTime,
          'todate': toDateTime,
          'shopid': shopId ?? '',
          'shopname': '',
          'taxid': '',
          'address': '',
        });
        headers = const [
          'ลำดับ',
          'วันที่',
          'ชื่อ',
          'ที่อยู่',
          'เลขประจำตัวผู้เสียภาษี',
          'เลขที่หนังสือรับรอง',
          'รายละเอียด',
          'อัตราภาษี',
          'จำนวนเงินที่จ่าย',
          'ภาษีที่หัก',
          'เงื่อนไข',
        ];
        fields = const [
          ['__rowNumber'],
          ['docdate', 'paydate', 'taxdate', 'date', 'createdat'],
          ['custname', 'customername', 'vendorname', 'creditor_name', 'debtor_name', 'name'],
          ['address'],
          ['custtaxid', 'taxid', 'tax_id', 'customertaxid', 'vendortaxid'],
          ['taxdocno', 'docno', 'documentno', 'document_no'],
          ['description'],
          ['taxrate'],
          ['taxbase', 'amount', 'baseamount', 'payamount', 'incomeamount'],
          ['taxamount', 'withholdingtax', 'whtamount', 'tax'],
          ['conditiontaxtype'],
        ];
        break;
      case 'ภาษีถูกหัก ณ ที่จ่าย':
        uri = Uri.parse('${AuthRepository.baseUrl}/apireport/journaltaxdeduct')
            .replace(queryParameters: {
          'limit': '10',
          'offset': '0',
          'taxtype': '0',
          'fromdate': fromDateTime,
          'todate': toDateTime,
          'shopid': shopId ?? '',
          'shopname': '',
          'taxid': '',
          'address': '',
        });
        headers = const [
          'ลำดับ',
          'วันที่ได้รับ',
          'ชื่อ',
          'ที่อยู่',
          'เลขประจำตัวผู้เสียภาษี',
          'ประเภทเงินได้ที่จ่าย',
          'อัตราภาษี(%)',
          'จำนวนเงิน',
          'ภาษี',
        ];
        fields = const [
          ['__rowNumber'],
          ['docdate', 'paydate', 'taxdate', 'date', 'createdat'],
          ['custname', 'customername', 'vendorname', 'creditor_name', 'debtor_name', 'name'],
          ['address'],
          ['custtaxid', 'taxid', 'tax_id', 'customertaxid', 'vendortaxid'],
          ['__detailText', 'description', 'incometype', 'taxtypename', 'tax_type', 'type'],
          ['__detailText', 'taxrate'],
          ['__detailMoney', 'taxbase', 'amount', 'baseamount', 'payamount', 'incomeamount'],
          ['__detailMoney', 'taxamount', 'withholdingtax', 'whtamount', 'tax'],
        ];
        break;
      default:
        return ReportTableData(
          status: ReportDataStatus.unsupported,
          source: ReportDataSource.live,
          message: 'ยังไม่รองรับรายงานประเภทนี้',
        );
    }

    final root = await _getJsonMap(uri, 'โหลด$reportTypeไม่สำเร็จ');
    final items = _extractList(root);
    if (items.isEmpty) {
      return ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูล$reportType',
      );
    }

    final rows = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return fields.asMap().entries.map((fieldEntry) {
        final fieldIndex = fieldEntry.key;
        final fieldNames = fieldEntry.value;
        final value = _reportFieldValue(item, fieldNames, index);
        final header = fieldIndex < headers.length ? headers[fieldIndex] : '';
        return _formatTableValueForHeader(value, header);
      }).toList();
    }).toList();

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: headers,
      rows: rows,
      highlightRows: _totalRowIndexes(rows),
      rowDetails: items
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key, _formatTableValue(value)),
            ),
          )
          .toList(),
    );
  }

  static ReportTableData _buildTrialBalanceFromJournals(List<Journal> journals) {
    final grouped = <String, _AccountTotals>{};

    for (final journal in journals) {
      final key = '${journal.accountCode ?? '-'}|${journal.accountName ?? '-'}';
      grouped.putIfAbsent(
        key,
        () => _AccountTotals(
          code: journal.accountCode ?? '-',
          name: journal.accountName ?? '-',
          type: journal.accountTypeDisplay,
        ),
      );
      grouped[key]!.add(journal);
    }

    final rows = <List<String>>[];
    var totalDebit = 0.0;
    var totalCredit = 0.0;

    for (final item in grouped.values) {
      totalDebit += item.debit;
      totalCredit += item.credit;
      rows.add([
        item.code,
        item.name,
        item.type,
        _formatMoneyOrDash(item.debit),
        _formatMoneyOrDash(item.credit),
      ]);
    }

    rows.add([
      'รวมทั้งสิ้น',
      '',
      '',
      _moneyFmt.format(totalDebit),
      _moneyFmt.format(totalCredit),
    ]);

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: const ['รหัสบัญชี', 'ชื่อบัญชี', 'หมวดบัญชี', 'เดบิต', 'เครดิต'],
      rows: rows,
      highlightRows: [rows.length - 1],
      rowDetails: List.generate(rows.length, (_) => const <String, String>{}),
    );
  }

  static ReportTableData _buildProfitLossFromJournals(List<Journal> journals) {
    var income = 0.0;
    var expense = 0.0;

    for (final journal in journals) {
      final type = journal.accountType?.toUpperCase();
      if (type == 'INCOME') {
        income += (journal.credit ?? 0) - (journal.debit ?? 0);
      } else if (type == 'EXPENSES') {
        expense += (journal.debit ?? 0) - (journal.credit ?? 0);
      }
    }

    final netProfit = income - expense;
    final rows = [
      ['รายได้รวม', _moneyFmt.format(income)],
      ['ค่าใช้จ่ายรวม', _moneyFmt.format(expense)],
      ['กำไรสุทธิ', _moneyFmt.format(netProfit)],
    ];

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: const ['รายการ', 'จำนวนเงิน'],
      rows: rows,
      highlightRows: const [2],
      rowDetails: List.generate(rows.length, (_) => const <String, String>{}),
    );
  }

  static ReportTableData _buildBalanceSheetFromJournals(List<Journal> journals) {
    var assets = 0.0;
    var liabilities = 0.0;
    var equityAndOther = 0.0;

    for (final journal in journals) {
      final type = journal.accountType?.toUpperCase();
      final balance = (journal.debit ?? 0) - (journal.credit ?? 0);
      if (type == 'ASSETS') {
        assets += balance;
      } else if (type == 'LIABILITIES') {
        liabilities += -balance;
      } else {
        equityAndOther += -balance;
      }
    }

    final rows = [
      ['สินทรัพย์', _moneyFmt.format(assets)],
      ['หนี้สิน', _moneyFmt.format(liabilities)],
      ['ทุน/กำไรสะสมและรายการอื่น', _moneyFmt.format(equityAndOther)],
      ['รวมหนี้สินและส่วนของผู้ถือหุ้น', _moneyFmt.format(liabilities + equityAndOther)],
    ];

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: const ['รายการ', 'จำนวนเงิน'],
      rows: rows,
      highlightRows: const [3],
      rowDetails: List.generate(rows.length, (_) => const <String, String>{}),
    );
  }

  static Future<ReportTableData> _fetchJournalReport({
    required String reportType,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _fetchJournalDailyReportFromApi(
      reportType: reportType,
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<ReportTableData> _fetchJournalDailyReportFromApi({
    required String reportType,
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shopId == null || shopId.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message: 'กรุณาเลือกร้านก่อนค้นหารายงาน',
      );
    }

    final fromDate = JournalService.formatDate(
      startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    final toDate = JournalService.formatDate(endDate ?? DateTime.now());
    final uri = Uri.parse(
      '${AuthRepository.baseUrl}/apireport/journaldaily',
    ).replace(
      queryParameters: {
        'shopid': shopId,
        'fromdate': fromDate,
        'todate': toDate,
        'shopname': '',
        'taxid': '',
        'address': '',
        'offset': '0',
        'limit': _journalDailyLimit.toString(),
      },
    );

    final root = await _getJsonMap(uri, 'โหลดรายงานสมุดรายวันไม่สำเร็จ');
    final items = _extractList(root);
    final filteredItems = _filterJournalDailyItems(reportType, items);

    if (filteredItems.isEmpty) {
      return const ReportTableData(
        status: ReportDataStatus.empty,
        source: ReportDataSource.live,
        message: 'ไม่พบข้อมูลจริงในช่วงวันที่หรือประเภทรายงานที่เลือก',
      );
    }

    final headers = reportType == 'ทุกสมุดรายวัน'
        ? [
            'ลำดับ',
            'วันที่',
            'เลขที่ใบสำคัญ',
            'ประเภท',
            'คู่ค้า/รายการ',
            'บัญชี',
            'เดบิต',
            'เครดิต',
          ]
        : [
            'ลำดับ',
            'วันที่',
            'เลขที่ใบสำคัญ',
            _partyHeaderFor(reportType),
            'บัญชี',
            'เดบิต',
            'เครดิต',
          ];

    final rows = <List<String>>[];
    final details = <Map<String, String>>[];
    final documentSequences = <String, int>{};

    for (final journal in filteredItems) {
      final description = _journalDailyDescription(journal);
      final date = _formatDisplayDate(journal['docdate']);
      final docNo = journal['docno']?.toString() ?? '-';
      final bookCode = journal['bookcode']?.toString() ?? '-';
      final documentKey = docNo == '-'
          ? '${journal['id'] ?? journal['journalid'] ?? documentSequences.length}'
          : docNo;
      final sequence = documentSequences.putIfAbsent(
        documentKey,
        () => documentSequences.length + 1,
      );

      final journalDetails = journal['journaldetail'];
      final detailItems = journalDetails is List
          ? journalDetails.whereType<Map>().map((item) {
              return item.cast<String, dynamic>();
            }).toList()
          : const <Map<String, dynamic>>[];

      final rowDetails = detailItems.isEmpty
          ? [<String, dynamic>{}]
          : detailItems;

      if (rows.length >= _journalDailyMaxRows) break;

      final accountCodes = <String>[];
      final accountNames = <String>[];
      final accountLines = <String>[];
      final debits = <String>[];
      final credits = <String>[];

      for (final detail in rowDetails) {
        final debit = _asDouble(detail['debitamount'] ?? detail['debit']);
        final credit = _asDouble(detail['creditamount'] ?? detail['credit']);

        final accountCode = detail['accountcode']?.toString() ?? '-';
        final accountName = detail['accountname']?.toString() ?? '-';
        accountCodes.add(accountCode);
        accountNames.add(accountName);
        accountLines.add('$accountCode  $accountName');
        debits.add(_formatMoneyOrDash(debit));
        credits.add(_formatMoneyOrDash(credit));
      }

      rows.add(
        reportType == 'ทุกสมุดรายวัน'
            ? [
                sequence.toString(),
                date,
                docNo,
                bookCode,
                description,
                accountLines.join('\n'),
                debits.join('\n'),
                credits.join('\n'),
              ]
            : [
                sequence.toString(),
                date,
                docNo,
                description,
                accountLines.join('\n'),
                debits.join('\n'),
                credits.join('\n'),
              ],
      );

      details.add({
        'ลำดับ': sequence.toString(),
        'เลขที่เอกสาร': docNo,
        'วันที่': date,
        'สมุดรายวัน': bookCode,
        'รายการ': description,
        'รหัสบัญชี': accountCodes.join('\n'),
        'ชื่อบัญชี': accountNames.join('\n'),
        'บัญชี': accountLines.join('\n'),
        'เดบิต': debits.join('\n'),
        'เครดิต': credits.join('\n'),
        'จำนวนเงินเอกสาร': _formatTableValue(journal['amount']),
      });

      if (rows.length >= _journalDailyMaxRows) break;
    }

    return ReportTableData(
      status: ReportDataStatus.ready,
      source: ReportDataSource.live,
      headers: headers,
      rows: rows,
      paginationTotalLabel: 'รวมรายการทั้งสิ้น ${filteredItems.length} รายการ',
      rowDetails: details,
    );
  }

  static List<Map<String, dynamic>> _filterJournalDailyItems(
    String reportType,
    List<Map<String, dynamic>> items,
  ) {
    if (reportType == 'ทุกสมุดรายวัน') return items;

    final needles = _journalTypeNeedles(reportType);
    if (needles.isEmpty) return items;

    return items.where((journal) {
      final haystack = [
        journal['bookcode'],
        journal['accountdescription'],
        journal['docno'],
        journal['creditor_name'],
        journal['debtor_name'],
      ].whereType<Object>().join(' ').toLowerCase();

      return needles.any(haystack.contains);
    }).toList();
  }

  static String _journalDailyDescription(Map<String, dynamic> journal) {
    for (final key in const [
      'accountdescription',
      'creditor_name',
      'debtor_name',
    ]) {
      final value = journal[key]?.toString();
      if (value != null && value.trim().isNotEmpty && value != 'null') {
        return value;
      }
    }
    return '-';
  }

  static Future<List<Journal>> _fetchGlJournalsAcrossShops({
    String? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate != null ? JournalService.formatDate(startDate) : null;
    final end = endDate != null ? JournalService.formatDate(endDate) : null;

    final response = await JournalService.getAllGLJournals(
      limit: 1000,
      shopId: shopId,
      startDate: start,
      endDate: end,
    );
    final journals = response.journals ?? [];
    dLog('📊 Report GL fetched for current shop/session: ${journals.length} row(s)');
    return journals;
  }

  static List<String> _journalTypeNeedles(String reportType) {
    switch (reportType) {
      case 'ทั่วไป':
        return const ['ทั่วไป', 'general', 'journal', 'jv', 'gj', 'gl'];
      case 'จ่าย':
        return const ['จ่าย', 'payment', 'pay', 'pv'];
      case 'รับ':
        return const ['รับ', 'receipt', 'receive', 'rv', 'rec'];
      case 'ซื้อ':
        return const ['ซื้อ', 'purchase', 'buy', 'pj'];
      case 'ขาย':
        return const ['ขาย', 'sale', 'sales', 'sell', 'sj'];
      case 'ธนาคาร':
        return const ['ธนาคาร', 'bank', 'bk'];
      default:
        return const [];
    }
  }

  static String _partyHeaderFor(String reportType) {
    switch (reportType) {
      case 'จ่าย':
        return 'จ่ายให้';
      case 'รับ':
        return 'รับจาก';
      case 'ซื้อ':
        return 'เจ้าหนี้';
      case 'ขาย':
        return 'ลูกค้า';
      default:
        return 'รายการ';
    }
  }

  static String _formatMoneyOrDash(double value) {
    return value == 0 ? '-' : _moneyFmt.format(value);
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _formatDisplayDate(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  static String _formatDynamicMoney(dynamic value) {
    if (value == null) return '';
    final amount = value is num ? value.toDouble() : double.tryParse('$value');
    if (amount == null) return '';
    return _moneyFmt.format(amount);
  }

  static String _formatTableValue(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) return DateFormat('dd/MM/yyyy').format(value.toLocal());
    if (value is num) return _moneyFmt.format(value);
    if (value is bool) return value ? 'ใช้งาน' : 'ไม่ใช้งาน';

    final text = value.toString();
    if (text.isEmpty) return '-';
    if (_looksLikeDate(text)) return _formatDisplayDate(text);
    final amount = double.tryParse(text);
    if (amount != null && _looksLikeAmount(text)) {
      return _moneyFmt.format(amount);
    }
    return text;
  }

  static String _formatTableValueForHeader(dynamic value, String header) {
    if (_isTextOnlyHeader(header)) {
      final text = value?.toString() ?? '';
      return text.isEmpty ? '-' : text;
    }
    if (_isMoneyHeader(header)) {
      return _formatMoneyTableValue(value);
    }
    return _formatTableValue(value);
  }

  static String _formatMoneyTableValue(dynamic value) {
    if (value == null) return '-';
    if (value is num) return _moneyFmt.format(value);
    final text = value.toString();
    if (text.isEmpty) return '-';
    if (text.contains('\n')) {
      return text
          .split('\n')
          .map((line) => _formatMoneyTableValue(line.trim()))
          .join('\n');
    }
    final amount = double.tryParse(text.replaceAll(',', ''));
    return amount == null ? text : _moneyFmt.format(amount);
  }

  static bool _isMoneyHeader(String header) {
    return header.contains('ฐานภาษี') ||
        header == 'ภาษี' ||
        header.contains('อัตราภาษี') ||
        header.contains('ภาษีที่หัก') ||
        header.contains('จำนวนเงิน') ||
        header.contains('ยกเว้นภาษี') ||
        header.contains('มูลค่าสินค้า') ||
        header.contains('จำนวนภาษี') ||
        header.contains('รวมทั้งสิ้น') ||
        header.contains('ยอด');
  }

  static bool _isTextOnlyHeader(String header) {
    return header.contains('ลำดับ') ||
        header.contains('เลข') ||
        header.contains('รหัส') ||
        header.contains('สาขา') ||
        header.contains('โทรศัพท์');
  }

  static bool _looksLikeAmount(String text) {
    return text.contains('.') || text.length > 6 || text.startsWith('-');
  }

  static bool _looksLikeDate(String text) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text) ||
        RegExp(r'^\d{4}/\d{2}/\d{2}').hasMatch(text);
  }

  static dynamic _firstValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) return item[key];
    }
    return null;
  }

  static dynamic _reportFieldValue(
    Map<String, dynamic> item,
    List<String> fieldNames,
    int index,
  ) {
    if (fieldNames.contains('__rowNumber')) return index + 1;
    if (fieldNames.contains('__vatProductAmount')) {
      return _vatProductAmount(item, fieldNames);
    }
    if (fieldNames.contains('__vatTotalAmount')) {
      return _vatTotalAmount(item, fieldNames);
    }
    if (fieldNames.contains('conditiontaxtype')) {
      return _formatConditionTaxType(_firstValue(item, fieldNames));
    }
    if (fieldNames.contains('__detailMoney')) {
      return _detailFieldValue(item, fieldNames, money: true);
    }
    if (fieldNames.contains('__detailText')) {
      return _detailFieldValue(item, fieldNames);
    }
    return _firstValue(item, fieldNames);
  }

  static dynamic _detailFieldValue(
    Map<String, dynamic> item,
    List<String> fieldNames, {
    bool money = false,
  }) {
    final keys = fieldNames.where((field) => !field.startsWith('__')).toList();
    final details = _extractDetailItems(item);
    if (details.isEmpty) return _firstValue(item, keys);

    final values = details
        .map((detail) => _firstValue(detail, keys))
        .where((value) {
          final text = value?.toString().trim() ?? '';
          return text.isNotEmpty && text != 'null';
        })
        .map((value) => money ? _formatMoneyTableValue(value) : value.toString())
        .toList();

    if (values.isEmpty) return _firstValue(item, keys);
    return values.join('\n');
  }

  static List<Map<String, dynamic>> _extractDetailItems(
    Map<String, dynamic> item,
  ) {
    for (final key in const ['details', 'detail', 'taxdetails', 'taxdetail']) {
      final value = item[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((detail) => detail.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  static String _formatConditionTaxType(dynamic value) {
    final code = value?.toString().trim();
    switch (code) {
      case '1':
        return 'หัก ณ ที่จ่าย';
      case '2':
        return 'ออกให้ตลอดไป';
      case '3':
        return 'ออกให้ครั้งเดียว';
      default:
        return code == null || code.isEmpty ? '-' : code;
    }
  }

  static dynamic _vatProductAmount(
    Map<String, dynamic> item,
    List<String> fieldNames,
  ) {
    final direct = _firstValue(
      item,
      fieldNames.where((field) => !field.startsWith('__')).toList(),
    );
    if (direct != null) return direct;

    final total = _asDouble(_firstValue(item, const [
      'totalamount',
      'grandtotal',
      'netamount',
      'total',
      'amounttotal',
      'amount_total',
    ]));
    if (total == 0) return null;

    final vat = _asDouble(_firstValue(item, const [
      'vatamount',
      'taxamount',
      'amountvat',
      'vat',
      'tax',
    ]));
    final exempt = _asDouble(_firstValue(item, const [
      'exemptamount',
      'exceptvat',
      'vat_exempt_amount',
      'nonvatamount',
      'zeroamount',
      'amountzerovat',
      'novatamount',
      'exceptvatamount',
    ]));

    return total - vat - exempt;
  }

  static dynamic _vatTotalAmount(
    Map<String, dynamic> item,
    List<String> fieldNames,
  ) {
    final direct = _firstValue(
      item,
      fieldNames.where((field) => !field.startsWith('__')).toList(),
    );
    if (direct != null) return direct;

    final product = _asDouble(_vatProductAmount(item, const [
      'baseamount',
      'vatbase',
      'vatbaseamount',
      'vatableamount',
      'amountbeforevat',
      'amount_before_vat',
      'beforevatamount',
      'goodsamount',
      'productamount',
      'serviceamount',
      'subtotal',
      'value',
    ]));
    final vat = _asDouble(_firstValue(item, const [
      'vatamount',
      'taxamount',
      'amountvat',
      'vat',
      'tax',
    ]));
    final exempt = _asDouble(_firstValue(item, const [
      'exemptamount',
      'exceptvat',
      'vat_exempt_amount',
      'nonvatamount',
      'zeroamount',
      'amountzerovat',
      'novatamount',
      'exceptvatamount',
    ]));

    final total = product + vat + exempt;
    return total == 0 ? null : total;
  }

  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> root) {
    final candidates = <dynamic>[
      root['data'],
      root['items'],
      root['docs'],
      root['rows'],
      root['list'],
      if (root['data'] is Map) (root['data'] as Map)['data'],
      if (root['data'] is Map) (root['data'] as Map)['items'],
      if (root['data'] is Map) (root['data'] as Map)['docs'],
      if (root['data'] is Map) (root['data'] as Map)['rows'],
      if (root['result'] is Map) (root['result'] as Map)['data'],
      if (root['result'] is Map) (root['result'] as Map)['items'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  static Future<Map<String, dynamic>> _getJsonMap(
    Uri uri,
    String errorMessage,
  ) async {
    dLog('📊 Fetching report API from: $uri');

    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthRepository.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('$errorMessage - Status: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    final root = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (root['success'] == false) {
      throw Exception(root['message']?.toString() ??
          root['msg']?.toString() ??
          errorMessage);
    }
    return root;
  }

  static bool _isApiBackedReport(String reportType) {
    return reportType == 'บัญชีแยกประเภท' ||
        reportType == 'กระดาษทำการ' ||
        reportType == 'รายงานรหัสบัญชี' ||
        reportType == 'รายงานสถานะเจ้าหนี้' ||
        reportType == 'รายงานสถานะลูกหนี้' ||
        reportType == 'รายงานภาษีซื้อ' ||
        reportType == 'รายงานภาษีขาย' ||
        reportType == 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.3)' ||
        reportType == 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.53)' ||
        reportType == 'ภาษีถูกหัก ณ ที่จ่าย';
  }

  static bool _isFinancialStatement(String reportType) {
    return reportType == 'งบทดลอง' ||
        reportType == 'งบกำไรขาดทุน' ||
        reportType == 'งบกำไรขาดทุน 12 เดือน' ||
        reportType == 'งบแสดงฐานะทางการเงิน';
  }

  static List<int> _totalRowIndexes(List<List<String>> rows) {
    final indexes = <int>[];
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isNotEmpty && rows[i].first.contains('รวม')) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  /// Returns table headers and rows for a given report type
  static Map<String, dynamic>? getTableData(String reportType) {
    switch (reportType) {
      // Daily Journal Reports
      case 'ทุกสมุดรายวัน':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'ประเภท',
            'คู่ค้า/รายการ',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '01/12/2025',
              'JV-001',
              'ทั่วไป',
              'ปรับปรุงบัญชีเงินเดือน',
              '55001',
              'เงินเดือน',
              '50,000.00',
              '-',
            ],
            ['', '', '', '', '21001', 'ค่าใช้จ่ายค้างจ่าย', '-', '50,000.00'],
            [
              '02/12/2025',
              'RV-001',
              'รับ',
              'ลูกค้าทั่วไป',
              '11001',
              'เงินสด',
              '5,000.00',
              '-',
            ],
            ['', '', '', '', '41001', 'รายได้จากการขาย', '-', '5,000.00'],
            [
              '03/12/2025',
              'SJ-001',
              'ขาย',
              'บจก. ลูกค้าประจำ',
              '13001',
              'ลูกหนี้การค้า',
              '107,000.00',
              '-',
            ],
            ['', '', '', '', '41001', 'ขายสินค้า', '-', '100,000.00'],
            ['', '', '', '', '21501', 'ภาษีขาย', '-', '7,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '', '346,200.00', '346,200.00'],
          ],
        };
      case 'ทั่วไป':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'รายการ',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '01/12/2025',
              'JV-001',
              'ปรับปรุงบัญชีเงินเดือน',
              '55001',
              'เงินเดือน',
              '50,000.00',
              '-',
            ],
            ['', '', '', '21001', 'ค่าใช้จ่ายค้างจ่าย', '-', '50,000.00'],
            [
              '15/12/2025',
              'JV-002',
              'ปรับปรุงค่าเสื่อมราคา',
              '51001',
              'ค่าเสื่อมราคา',
              '5,000.00',
              '-',
            ],
            ['', '', '', '12002', 'ค่าเสื่อมราคาสะสม', '-', '5,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '55,000.00', '55,000.00'],
          ],
        };
      case 'จ่าย':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'จ่ายให้',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '05/12/2025',
              'PV-001',
              'บจก. ซัพพลายเออร์',
              '21001',
              'เจ้าหนี้การค้า',
              '10,700.00',
              '-',
            ],
            ['', '', '', '11001', 'เงินสด', '-', '10,700.00'],
            [
              '10/12/2025',
              'PV-002',
              'การไฟฟ้า',
              '53001',
              'ค่าไฟฟ้า',
              '2,000.00',
              '-',
            ],
            ['', '', '', '11002', 'เงินฝากธนาคาร', '-', '2,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '12,700.00', '12,700.00'],
          ],
        };
      case 'รับ':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'รับจาก',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '02/12/2025',
              'RV-001',
              'ลูกค้าทั่วไป',
              '11001',
              'เงินสด',
              '5,000.00',
              '-',
            ],
            ['', '', '', '41001', 'รายได้จากการขาย', '-', '5,000.00'],
            [
              '12/12/2025',
              'RV-002',
              'บจก. เอ บี ซี',
              '11002',
              'เงินฝากธนาคาร',
              '20,000.00',
              '-',
            ],
            ['', '', '', '13001', 'ลูกหนี้การค้า', '-', '20,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '25,000.00', '25,000.00'],
          ],
        };
      case 'ซื้อ':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'เจ้าหนี้',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '01/12/2025',
              'PJ-001',
              'บจก. วัตถุดิบไทย',
              '52001',
              'ซื้อสินค้า',
              '50,000.00',
              '-',
            ],
            ['', '', '', '21001', 'เจ้าหนี้การค้า', '-', '53,500.00'],
            ['', '', '', '11501', 'ภาษีซื้อ', '3,500.00', '-'],
            ['รวมทั้งสิ้น', '', '', '', '', '53,500.00', '53,500.00'],
          ],
        };
      case 'ขาย':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'ลูกค้า',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '03/12/2025',
              'SJ-001',
              'บจก. ลูกค้าประจำ',
              '13001',
              'ลูกหนี้การค้า',
              '107,000.00',
              '-',
            ],
            ['', '', '', '41001', 'ขายสินค้า', '-', '100,000.00'],
            ['', '', '', '21501', 'ภาษีขาย', '-', '7,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '107,000.00', '107,000.00'],
          ],
        };
      case 'ธนาคาร':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบสำคัญ',
            'รายละเอียด',
            'เลขที่บัญชี',
            'ชื่อบัญชี',
            'เดบิต',
            'เครดิต',
          ],
          'rows': [
            [
              '08/12/2025',
              'BK-001',
              'โอนเงินจากเงินสดเข้าบัญชีธนาคาร',
              '11002',
              'เงินฝากธนาคาร',
              '100,000.00',
              '-',
            ],
            ['', '', '', '11001', 'เงินสด', '-', '100,000.00'],
            [
              '15/12/2025',
              'BK-002',
              'รับชำระหนี้โอนเข้าบัญชี',
              '11002',
              'เงินฝากธนาคาร',
              '50,000.00',
              '-',
            ],
            ['', '', '', '13001', 'ลูกหนี้การค้า', '-', '50,000.00'],
            ['รวมทั้งสิ้น', '', '', '', '', '165,500.00', '165,500.00'],
          ],
        };
      case 'ไม่บันทึกบัญชี':
        return {
          'headers': [
            'วันที่',
            'เลขที่เอกสาร',
            'รายละเอียด',
            'ประเภท',
            'จำนวนเงิน',
            'หมายเหตุ',
          ],
          'rows': [
            [
              '01/12/2025',
              'MEMO-001',
              'บันทึกภายใน - ของขวัญลูกค้า',
              'ค่าใช้จ่าย',
              '5,000.00',
              'ไม่บันทึกบัญชี',
            ],
            [
              '05/12/2025',
              'MEMO-002',
              'เงินสดย่อยพนักงาน',
              'เงินสดย่อย',
              '2,000.00',
              'รอตรวจสอบ',
            ],
            [
              '10/12/2025',
              'MEMO-003',
              'ค่าเลี้ยงรับรองลูกค้า',
              'ค่าใช้จ่าย',
              '3,500.00',
              'ไม่มีใบเสร็จ',
            ],
            ['รวมทั้งสิ้น', '', '', '', '22,000.00', ''],
          ],
        };

      // Financial Statements Reports
      case 'งบทดลอง':
        return {
          'headers': ['ชื่อบัญชี', 'เดบิต', 'เครดิต'],
          'rows': [
            ['เงินสด', '500,000.00', '-'],
            ['เงินฝากธนาคาร', '1,000,000.00', '-'],
            ['ลูกหนี้การค้า', '450,000.00', '-'],
            ['สินค้าคงเหลือ', '890,000.00', '-'],
            ['เจ้าหนี้การค้า', '-', '320,000.00'],
            ['ทุนจดทะเบียน', '-', '5,000,000.00'],
            ['รายได้จากการขาย', '-', '12,500,000.00'],
            ['ต้นทุนขาย', '8,000,000.00', '-'],
            ['รวมทั้งสิ้น', '17,820,000.00', '17,820,000.00'],
          ],
        };
      case 'งบกำไรขาดทุน':
      case 'งบกำไรขาดทุน 12 เดือน':
        return {
          'headers': ['รายการ', 'จำนวนเงิน'],
          'rows': [
            ['รายได้จากการขายและบริการ', '12,500,000.00'],
            ['หัก ต้นทุนขายและบริการ', '(8,000,000.00)'],
            ['กำไรขั้นต้น', '4,500,000.00'],
            ['รายได้อื่น', '50,000.00'],
            ['ค่าใช้จ่ายในการขายและบริหาร', '(1,200,000.00)'],
            ['กำไรก่อนดอกเบี้ยและภาษี', '3,350,000.00'],
            ['ต้นทุนทางการเงิน', '(50,000.00)'],
            ['ภาษีเงินได้', '(660,000.00)'],
            ['กำไรสุทธิ', '2,640,000.00'],
          ],
        };
      case 'งบแสดงฐานะทางการเงิน':
        return {
          'headers': ['รายการ', 'หมายเหตุ', 'จำนวนเงิน'],
          'rows': [
            ['สินทรัพย์หมุนเวียน', '', ''],
            ['  เงินสดและรายการเทียบเท่าเงินสด', '1', '1,500,000.00'],
            ['  ลูกหนี้การค้า', '2', '450,000.00'],
            ['  สินค้าคงเหลือ', '3', '890,000.00'],
            ['รวมสินทรัพย์หมุนเวียน', '', '2,840,000.00'],
            ['สินทรัพย์ไม่หมุนเวียน', '', ''],
            ['  ที่ดิน อาคารและอุปกรณ์', '4', '5,200,000.00'],
            ['รวมสินทรัพย์', '', '8,040,000.00'],
          ],
        };

      // Tax Reports
      case 'รายงานภาษีซื้อ':
      case 'รายงานภาษีขาย':
        return {
          'headers': [
            'วันที่',
            'เลขที่ใบกำกับ',
            'ชื่อผู้ซื้อ/ผู้ขาย',
            'สาขา',
            'มูลค่าสินค้า',
            'จำนวนภาษี',
          ],
          'rows': [
            [
              '01/12/2025',
              'INV-2025-001',
              'บริษัท เอ บี ซี จำกัด',
              '00000',
              '10,000.00',
              '700.00',
            ],
            [
              '02/12/2025',
              'INV-2025-002',
              'นาย สมชาย ใจดี',
              '-',
              '5,000.00',
              '350.00',
            ],
            [
              '05/12/2025',
              'EXP-2025-089',
              'บริษัท น้ำมันไทย จำกัด',
              '00001',
              '2,000.00',
              '140.00',
            ],
            ['รวมทั้งสิ้น', '', '', '', '32,000.00', '2,240.00'],
          ],
        };
      case 'ภาษีถูกหัก ณ ที่จ่าย':
        return {
          'headers': [
            'วันที่จ่าย',
            'ชื่อผู้ถูกหัก',
            'เลขประจำตัวผู้เสียภาษี',
            'ประเภทเงินได้',
            'อัตรา',
            'จำนวนเงินที่จ่าย',
            'ภาษีที่หัก',
          ],
          'rows': [
            [
              '05/12/2025',
              'นางสาว สมหญิง',
              '1-1002-xxxxx-xx-x',
              'ค่าบริการ',
              '3%',
              '10,000.00',
              '300.00',
            ],
            [
              '15/12/2025',
              'นาย มานะ',
              '3-4501-xxxxx-xx-x',
              'ค่าเช่า',
              '5%',
              '20,000.00',
              '1,000.00',
            ],
            ['รวมทั้งสิ้น', '', '', '', '', '35,000.00', '1,350.00'],
          ],
        };
      case 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.3)':
      case 'ภาษีหัก ณ ที่จ่าย(ภ.ง.ด.53)':
        return {
          'headers': [
            'ลำดับ',
            'ชื่อ-สกุล / ชื่อบริษัท',
            'เลขประจำตัวผู้เสียภาษี',
            'วันเดือนปีที่จ่าย',
            'ประเภทเงินได้',
            'จำนวนเงิน',
            'ภาษี',
          ],
          'rows': [
            [
              '1',
              'นางสาว สมหญิง',
              '1-1002-xxxxx-xx-x',
              '05/12/2025',
              '40(2)',
              '10,000.00',
              '300.00',
            ],
            [
              '2',
              'นาย มานะ',
              '3-4501-xxxxx-xx-x',
              '15/12/2025',
              '40(5)',
              '20,000.00',
              '1,000.00',
            ],
            ['รวมทั้งสิ้น', '', '', '', '', '35,000.00', '1,350.00'],
          ],
        };

      default:
        return null;
    }
  }
}
