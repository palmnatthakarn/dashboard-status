import 'package:flutter/material.dart';
import 'package:moniter/components/financial_report/generic_report_table.dart';
import 'package:moniter/services/report_data_provider.dart';

class ReportContent extends StatefulWidget {
  final String? selectedReportType;
  final String? shopId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int queryVersion;

  const ReportContent({
    super.key,
    required this.selectedReportType,
    this.shopId,
    this.startDate,
    this.endDate,
    this.queryVersion = 0,
  });

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  static const Duration _reportTimeout = Duration(seconds: 30);
  Future<ReportTableData>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ReportContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedReportType != widget.selectedReportType ||
        oldWidget.shopId != widget.shopId ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.queryVersion != widget.queryVersion) {
      _reload();
    }
  }

  void _reload() {
    final type = widget.selectedReportType;
    _future = type == null
        ? Future.value(
            const ReportTableData(
              status: ReportDataStatus.unsupported,
              source: ReportDataSource.live,
              message: 'กรุณาเลือกประเภทรายงาน',
            ),
          )
        : ReportDataProvider.fetchReportData(
            reportType: type,
            shopId: widget.shopId,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ).timeout(
            _reportTimeout,
            onTimeout: () => const ReportTableData(
              status: ReportDataStatus.unsupported,
              source: ReportDataSource.live,
              message:
                  'โหลดรายงานเกิน 30 วินาที กรุณาลองเลือกช่วงวันที่ให้แคบลงหรือค้นหาใหม่',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportTableData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShell(child: _buildLoading());
        }

        if (snapshot.hasError) {
          return _buildShell(
            child: _buildStateMessage(
              icon: Icons.error_outline_rounded,
              title: 'โหลดรายงานไม่สำเร็จ',
              message: snapshot.error.toString(),
              color: const Color(0xFFEF4444),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.status == ReportDataStatus.empty) {
          return _buildShell(
            child: _buildStateMessage(
              icon: Icons.inbox_outlined,
              title: 'ไม่มีข้อมูล',
              message: data?.message ?? 'ไม่พบข้อมูลในเงื่อนไขที่เลือก',
              color: const Color(0xFF64748B),
            ),
          );
        }

        if (data.status == ReportDataStatus.unsupported) {
          return _buildShell(
            child: _buildStateMessage(
              icon: Icons.construction_rounded,
              title: 'ยังไม่รองรับรายงานนี้',
              message: data.message ?? 'รายงานนี้ยังไม่ได้เชื่อมต่อข้อมูล',
              color: const Color(0xFFF59E0B),
            ),
          );
        }

        return _buildShell(
          data: data,
          child: GenericReportTable(
            headers: data.headers,
            rows: data.rows,
            highlightRows: data.highlightRows,
            paginationTotalLabel: data.paginationTotalLabel,
            onRowTap: data.canDrillDown
                ? (index, cells) => _showRowDetails(context, data, index)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildShell({required Widget child, ReportTableData? data}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.selectedReportType ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (data != null) _buildSourceBadge(data.source),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSourceBadge(ReportDataSource source) {
    final isLive = source == ReportDataSource.live;
    final color = isLive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isLive ? 'ข้อมูลจริง' : 'ข้อมูลตัวอย่าง',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRowDetails(
    BuildContext context,
    ReportTableData data,
    int rowIndex,
  ) {
    if (rowIndex >= data.rowDetails.length) return;

    final details = data.rowDetails[rowIndex];
    if (details.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('รายละเอียดรายการ'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: details.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }
}
