import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/report_content.dart';
import 'package:moniter/components/financial_report/report_empty_state.dart';
import 'package:moniter/components/financial_report/report_filter_section.dart';
import 'package:moniter/components/financial_report/report_header.dart';
import 'package:moniter/services/multi_shop_service.dart';
import 'package:moniter/services/pdf_export_service.dart';
import 'package:moniter/services/report_data_provider.dart';

/// A reusable base report page that provides consistent layout for all report pages
class BaseReportPage extends StatefulWidget {
  final String title;
  final List<String> reportTypes;
  final String? defaultReportType;

  const BaseReportPage({
    super.key,
    required this.title,
    required this.reportTypes,
    this.defaultReportType,
  });

  @override
  State<BaseReportPage> createState() => _BaseReportPageState();
}

class _BaseReportPageState extends State<BaseReportPage> {
  static const Duration _reportTimeout = Duration(seconds: 30);
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _shops = const [];
  String? _selectedShopId;
  bool _isLoadingShops = false;
  String? _selectedReportType;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String? _appliedReportType;
  int _queryVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedReportType = widget.defaultReportType;
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadShops();
    if (_selectedReportType != null) {
      _applySearch();
    }
  }

  Future<void> _loadShops() async {
    setState(() => _isLoadingShops = true);
    final shops = await MultiShopService.listShops();
    if (!mounted) return;
    setState(() {
      _shops = shops;
      _selectedShopId = shops.length == 1 ? _shopId(shops.first) : null;
      _isLoadingShops = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
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
              reportTypes: widget.reportTypes,
              shops: _shops,
              selectedReportType: _selectedReportType,
              selectedShopId: _selectedShopId,
              startDate: _startDate,
              endDate: _endDate,
              onReportTypeChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                });
              },
              onShopChanged: (value) {
                setState(() {
                  _selectedShopId = value;
                });
              },
              onStartDateTap: () => _selectDate(true),
              onEndDateTap: () => _selectDate(false),
              onSearch: _applySearch,
              isLoadingShops: _isLoadingShops,
            ),
            const SizedBox(height: 24),
            if (_appliedReportType != null) ...[
              ReportHeader(
                selectedReportType: _appliedReportType,
                startDate: _appliedStartDate,
                endDate: _appliedEndDate,
                onFullScreen: _openReportFullScreen,
                onExport: _handleExport,
              ),
              const SizedBox(height: 16),
              ReportContent(
                selectedReportType: _appliedReportType,
                shopId: _selectedShopId,
                startDate: _appliedStartDate,
                endDate: _appliedEndDate,
                queryVersion: _queryVersion,
              ),
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
              primary: Color(0xFF6366F1),
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

  void _handleExport(String type) async {
    if (_appliedReportType == null) {
      _showSnack('กรุณาค้นหารายงานก่อนดาวน์โหลด', const Color(0xFFF59E0B));
      return;
    }

    final tableData = await ReportDataProvider.fetchReportData(
      reportType: _appliedReportType!,
      shopId: _selectedShopId,
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
    ).timeout(
      _reportTimeout,
      onTimeout: () => const ReportTableData(
        status: ReportDataStatus.unsupported,
        source: ReportDataSource.live,
        message:
            'โหลดรายงานเกิน 30 วินาที กรุณาลองเลือกช่วงวันที่ให้แคบลงหรือค้นหาใหม่',
      ),
    );

    if (!mounted) return;

    if (tableData.status != ReportDataStatus.ready) {
      _showSnack(
        tableData.message ?? 'ไม่มีข้อมูลสำหรับดาวน์โหลด',
        const Color(0xFFF59E0B),
      );
      return;
    }

    if (type == 'PDF') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('กำลังสร้างไฟล์ PDF...'),
              ],
            ),
            backgroundColor: const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(24),
            duration: const Duration(seconds: 2),
          ),
        );

        await PdfExportService.exportTableToPdf(
          title: _appliedReportType!,
          headers: tableData.headers,
          rows: tableData.rows,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
        );
    } else {
      _showSnack(
        'เตรียมข้อมูล $type แล้ว (${tableData.rows.length} รายการ)',
        const Color(0xFF10B981),
      );
    }
  }

  void _openReportFullScreen() {
    if (_appliedReportType == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$_appliedReportType'),
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
              child: ReportContent(
                selectedReportType: _appliedReportType,
                shopId: _selectedShopId,
                startDate: _appliedStartDate,
                endDate: _appliedEndDate,
                queryVersion: _queryVersion,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applySearch() {
    if (_selectedShopId == null || _selectedShopId!.isEmpty) {
      _showSnack('กรุณาเลือกร้านก่อนค้นหารายงาน', const Color(0xFFF59E0B));
      return;
    }

    if (_selectedReportType == null) {
      _showSnack('กรุณาเลือกประเภทรายงาน', const Color(0xFFF59E0B));
      return;
    }

    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      _showSnack('วันที่เริ่มต้นต้องไม่เกินวันที่สิ้นสุด', const Color(0xFFEF4444));
      return;
    }

    setState(() {
      _appliedReportType = _selectedReportType;
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _queryVersion++;
    });
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  String _shopId(Map<String, dynamic> shop) {
    return shop['shopid']?.toString() ??
        shop['shop_id']?.toString() ??
        shop['id']?.toString() ??
        '';
  }
}
