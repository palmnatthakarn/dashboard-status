import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../models/doc_details.dart';
import '../widgets/shop/shop_widgets.dart';

class ShopDataTable extends StatefulWidget {
  final List<dynamic> shops;
  final DateTime? selectedDate;
  final Function(DateTime?) onDateChanged;
  final Function getIncomeForPeriod;
  final NumberFormat moneyFormat;

  const ShopDataTable({
    super.key,
    required this.shops,
    this.selectedDate,
    required this.onDateChanged,
    required this.getIncomeForPeriod,
    required this.moneyFormat,
  });

  @override
  State<ShopDataTable> createState() => _ShopDataTableState();
}

class _ShopDataTableState extends State<ShopDataTable> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _animationController.forward();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final shops = widget.shops;

      if (shops.isEmpty) {
        return const ShopEmptyState();
      }

      final branchShops = shops
          .where((shop) => shop.shopid != null && shop.shopid!.isNotEmpty)
          .toList();

      if (branchShops.isEmpty) {
        return const ShopEmptyState();
      }

      final groupedByBranch = _groupByBranch(branchShops);
      final dataSource = BranchDataSource(
        branchData: groupedByBranch,
        selectedDate: widget.selectedDate,
        moneyFormat: widget.moneyFormat,
        context: context,
      );

      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildContainer(dataSource),
        ),
      );
    } catch (e) {
      debugPrint('Error in ShopDataTable build: $e');
      return _buildErrorState();
    }
  }

  Map<String, List<DocDetails>> _groupByBranch(List<dynamic> branchShops) {
    final Map<String, List<DocDetails>> grouped = {};
    for (final shop in branchShops) {
      final shopId = shop.shopid!;
      grouped.putIfAbsent(shopId, () => []);
      grouped[shopId]!.add(shop);
    }
    return grouped;
  }

  Widget _buildContainer(BranchDataSource dataSource) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShopHeader(
              selectedDate: widget.selectedDate,
              onDateChanged: widget.onDateChanged,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 400, maxHeight: 450),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildDataTable(dataSource),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BranchDataSource dataSource) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: PaginatedDataTable2(
        columnSpacing: 12,
        horizontalMargin: 16,
        minWidth: 900,
        headingRowHeight: 56,
        dataRowHeight: 72,
        rowsPerPage: 8,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
        showCheckboxColumn: false,
        columns: _buildColumns(),
        source: dataSource,
      ),
    );
  }

  List<DataColumn2> _buildColumns() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFF6B7280),
      fontSize: 13,
    );

    return const [
      DataColumn2(label: Text('สถานะ', style: headerStyle), size: ColumnSize.S, fixedWidth: 100),
      DataColumn2(label: Text('ชื่อสาขา', style: headerStyle), size: ColumnSize.L),
      DataColumn2(label: Text('รหัสสาขา', style: headerStyle), size: ColumnSize.M),
      DataColumn2(label: Text('รายวัน', style: headerStyle), size: ColumnSize.M, numeric: true),
      DataColumn2(label: Text('รายเดือน', style: headerStyle), size: ColumnSize.M, numeric: true),
      DataColumn2(label: Text('รายปี', style: headerStyle), size: ColumnSize.M, numeric: true),
      DataColumn2(label: Text('Journal', style: headerStyle), size: ColumnSize.M),
      DataColumn2(label: Text('อัปโหลด', style: headerStyle), size: ColumnSize.M),
      DataColumn2(label: Text('ผู้รับผิดชอบ', style: headerStyle), size: ColumnSize.L),
    ];
  }

  Widget _buildErrorState() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาดในการแสดงข้อมูล',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
