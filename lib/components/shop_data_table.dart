import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../models/doc_details.dart';
import '../widgets/shop/shop_widgets.dart';
import './common/custom_pagination.dart';

class ShopDataTable extends StatefulWidget {
  final List<dynamic> shops;
  final DateTimeRange? selectedDateRange;
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function getIncomeForPeriod;
  final NumberFormat moneyFormat;

  const ShopDataTable({
    super.key,
    required this.shops,
    this.selectedDateRange,
    required this.onDateRangeChanged,
    required this.getIncomeForPeriod,
    required this.moneyFormat,
  });

  @override
  State<ShopDataTable> createState() => _ShopDataTableState();
}

class _ShopDataTableState extends State<ShopDataTable>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pagination state
  int _currentPage = 1;
  int _rowsPerPage = 8;
  bool _rowsPerPageInitialized = false;

  // Layout constants for row calculation
  static const double _dataRowHeight = 52.0;
  static const double _headingRowHeight = 44.0;
  // ShopHeader (~100) + Divider (1) + Padding (24) + Pagination (~60) + extra padding (20)
  static const double _fixedOverhead = 205.0;

  /// Calculate how many rows fit in the given container height
  int _calcRowsForHeight(double containerHeight) {
    final available = containerHeight - _fixedOverhead - _headingRowHeight;
    final rows = (available / _dataRowHeight).floor();
    return rows.clamp(3, 50); // minimum 3, max 50
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rowsPerPageInitialized) {
      final screenHeight = MediaQuery.of(context).size.height;
      final containerHeight = (screenHeight - 390.0).clamp(
        400.0,
        double.infinity,
      );
      _rowsPerPage = _calcRowsForHeight(containerHeight);
      _rowsPerPageInitialized = true;
    }
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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
        selectedDateRange: widget.selectedDateRange,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ShopHeader(
              selectedDateRange: widget.selectedDateRange,
              onDateRangeChanged: widget.onDateRangeChanged,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

            // Table content (height based on number of rows)
            _buildDataTable(dataSource),

            // Pagination
            if (dataSource.rowCount > 0) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPagination(dataSource.rowCount),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BranchDataSource dataSource) {
    // Calculate pagination
    final totalRows = dataSource.rowCount;
    final totalPages = totalRows == 0 ? 1 : (totalRows / _rowsPerPage).ceil();
    final validPage = _currentPage.clamp(1, totalPages);

    // Get current page rows
    final start = (validPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, totalRows);
    final currentPageRows = List.generate(
      end - start,
      (index) => dataSource.getRow(start + index),
    ).whereType<DataRow>().toList();

    // Calculate height based on row count (like KPI table)
    // heading row (44) + data rows (52 each) + padding (24)
    final tableHeight =
        _headingRowHeight + (currentPageRows.length * _dataRowHeight) + 24.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: tableHeight.clamp(150.0, 1200.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable2(
            columnSpacing: 8,
            horizontalMargin: 12,
            minWidth: 1000,
            headingRowHeight: _headingRowHeight,
            dataRowHeight: _dataRowHeight,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            showCheckboxColumn: false,
            columns: _buildColumns(),
            rows: currentPageRows,
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalRows) {
    return CustomPagination(
      currentPage: _currentPage,
      totalItems: totalRows,
      rowsPerPage: _rowsPerPage,
      rowsPerPageOptions: _buildRowsPerPageOptions(),
      onPageChanged: (page) => setState(() => _currentPage = page),
      onRowsPerPageChanged: (rows) => setState(() {
        _rowsPerPage = rows;
        _currentPage = 1;
      }),
    );
  }

  /// Build dynamic dropdown options: 1x, 2x, 3x of the auto-calculated base
  List<int> _buildRowsPerPageOptions() {
    final base = _calcRowsForHeight(
      (MediaQuery.of(context).size.height - 390.0).clamp(
        400.0,
        double.infinity,
      ),
    );
    final options = <int>{base, base * 2, base * 3};
    // Ensure current value is always in the list
    options.add(_rowsPerPage);
    final sorted = options.toList()..sort();
    return sorted;
  }

  List<DataColumn2> _buildColumns() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFF6B7280),
      fontSize: 11,
    );

    return const [
      DataColumn2(label: Text('สถานะ', style: headerStyle), fixedWidth: 60),
      DataColumn2(
        label: Text('ชื่อร้าน', style: headerStyle),
        size: ColumnSize.L,
      ),
      // Removed shop code column - code now shows under shop name
      DataColumn2(
        label: Text('รายวัน', style: headerStyle),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text('รายเดือน', style: headerStyle),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text('รายปี', style: headerStyle),
        size: ColumnSize.S,
      ),
      /*DataColumn2(
        label: Text('Journal', style: headerStyle),
        size: ColumnSize.S,
      ),*/
      DataColumn2(
        label: Text('บิล', style: headerStyle),
        size: ColumnSize.S,
      ),
      /* DataColumn2(
        label: Text('ผู้รับผิดชอบ', style: headerStyle),
        size: ColumnSize.S,
      ),*/
    ];
  }

  Widget _buildErrorState() {
    return SizedBox(
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
