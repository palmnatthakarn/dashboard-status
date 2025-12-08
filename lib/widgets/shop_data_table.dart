import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/models_old/doc_details.dart';
import '../services/journal_service.dart';
import 'journal_dialog.dart';

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

class _ShopDataTableState extends State<ShopDataTable>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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

    // เรียกครั้งแรกเท่านั้น
    if (!_isInitialized) {
      _isInitialized = true;
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Use shops from widget props
      final shops = widget.shops;

      // Check if shops list is empty
      if (shops.isEmpty) {
        return _buildEmptyState();
      }

      // Filter shops that have branch information
      final branchShops = shops
          .where((shop) => shop.shopid != null && shop.shopid!.isNotEmpty)
          .toList();

      // If no branch data, show empty state
      if (branchShops.isEmpty) {
        return _buildEmptyState();
      }

      // Group by shop ID (branch)
      final Map<String, List<DocDetails>> groupedByBranch = {};
      for (final shop in branchShops) {
        final shopId = shop.shopid!;
        if (!groupedByBranch.containsKey(shopId)) {
          groupedByBranch[shopId] = [];
        }
        groupedByBranch[shopId]!.add(shop);
      }

      final dataSource = _BranchDataSource(
        branchData: groupedByBranch,
        selectedDate: widget.selectedDate,
        moneyFormat: widget.moneyFormat,
        context: context,
      );

      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFAFBFC),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient background
                  _buildHeader(),

                  // Divider with gradient
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Data table
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 400, maxHeight: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildDataTable(dataSource),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error in ShopDataTable build: $e');
      return Container(
        height: 400,
        child: Center(
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

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่มีข้อมูลสาขา',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ยังไม่มีข้อมูลสาขาในระบบ\nกรุณาตรวจสอบการเชื่อมต่อหรือเพิ่มข้อมูลสาขา',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh handled by parent
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('โหลดข้อมูลใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: [
            // Icon with animated gradient
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, animation, child) {
                return Transform.scale(
                  scale: 0.8 + (animation * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                            animation,
                          )!,
                          Color.lerp(
                            const Color(0xFF2563EB),
                            const Color(0xFF1D4ED8),
                            animation,
                          )!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.3 * animation),
                          blurRadius: 16 * animation,
                          offset: Offset(0, 4 * animation),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),

            // Title with animation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, animation, child) {
                      return Transform.translate(
                        offset: Offset(20 * (1 - animation), 0),
                        child: Opacity(
                          opacity: animation,
                          child: const Text(
                            'ข้อมูลสาขา',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, animation, child) {
                      return Transform.translate(
                        offset: Offset(20 * (1 - animation), 0),
                        child: Opacity(
                          opacity: animation,
                          child: const Text(
                            'จัดการและติดตามข้อมูลสาขาทั้งหมด',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Date picker with beautiful design
            _buildDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (animation * 0.2),
          child: Opacity(
            opacity: animation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: widget.selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3B82F6),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    widget.onDateChanged(picked);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAFBFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'วันที่เลือก',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            widget.selectedDate != null
                                ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(widget.selectedDate!)
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(_BranchDataSource dataSource) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PaginatedDataTable2(
          columnSpacing: 16,
          horizontalMargin: 20,
          minWidth: 900,
          headingRowHeight: 60,
          dataRowHeight: 80,
          rowsPerPage: 8,
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFF8FAFC).withValues(alpha: 0.8),
          ),
          showCheckboxColumn: false,
          columns: const [
            DataColumn2(
              label: Text(
                'สถานะ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                ),
              ),
              size: ColumnSize.S,
              fixedWidth: 120,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'ชื่อสาขา',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.L,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'รหัสสาขา',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'รายวัน',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
              numeric: true,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'รายเดือน',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
              numeric: true,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'รายปี',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
              numeric: true,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'Journal',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'อัปโหลด',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Center(
                child: Text(
                  'ผู้รับผิดชอบ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              size: ColumnSize.L,
            ),
          ],
          source: dataSource,
        ),
      ),
    );
  }
}

class _BranchDataSource extends DataTableSource {
  final Map<String, List<DocDetails>> branchData;
  final DateTime? selectedDate;
  final NumberFormat moneyFormat;
  final BuildContext context;

  _BranchDataSource({
    required this.branchData,
    required this.selectedDate,
    required this.moneyFormat,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= branchData.length) return null;

    final shopId = branchData.keys.elementAt(index);
    final shops = branchData[shopId]!;

    // Calculate data for each column
    final shopName = shops.isNotEmpty ? shops.first.shopname ?? shopId : shopId;
    final dailyAmount = _getDailyAmount(shops);
    final monthlyAmount = _getMonthlyAmount(shops);
    final yearlyAmount = _getYearlyAmount(shops);
    final totalIncome = _getTotalIncome(shops);

    return DataRow2(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFF3B82F6).withValues(alpha: 0.05);
        }
        return index.isEven
            ? Colors.white.withValues(alpha: 0.5)
            : const Color(0xFFFAFBFC).withValues(alpha: 0.3);
      }),
      onSelectChanged: (selected) {
        if (selected == true) {
          HapticFeedback.lightImpact();
          _showJournalDialogForBranch(shopId, shops);
        }
      },
      cells: [
        // Status Cell
        DataCell(Center(child: _buildStatusIndicator(shops.length))),

        // Branch Name Cell
        DataCell(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showBranchDetail(shopId, shops);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shopName.isEmpty ? shopId : shopName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${shops.length} รายการ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Branch Code Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF64748B).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              shopId,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Daily Amount Cell
        DataCell(
          _buildAmountChip(
            dailyAmount,
            const Color(0xFF06B6D4),
            Icons.today_rounded,
          ),
        ),

        // Monthly Amount Cell
        DataCell(
          _buildAmountChip(
            monthlyAmount,
            const Color(0xFF8B5CF6),
            Icons.calendar_month_rounded,
          ),
        ),

        // Yearly Amount Cell
        DataCell(
          _buildAmountChip(
            yearlyAmount,
            yearlyAmount > 1800000
                ? const Color(0xFFEF4444)
                : yearlyAmount >= 1000000
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
            Icons.date_range_rounded,
          ),
        ),

        // Journal Cell
        DataCell(
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showJournalDialog(shopId, shops);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: totalIncome >= 0
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (totalIncome >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Journal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(totalIncome),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Upload Cell
        DataCell(
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${shops.length} ไฟล์',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Responsible Person Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ระบบอัตโนมัติ',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountChip(double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(int count) {
    final Color statusColor;
    final IconData statusIcon;
    final String status;

    if (count > 10) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
      status = 'ปกติ';
    } else if (count > 5) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_rounded;
      status = 'ระวัง';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_rounded;
      status = 'น้อย';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showBranchDetail(String shopId, List<DocDetails> shops) {
    showDialog(
      context: context,
      builder: (context) => _BranchDetailDialog(shopId: shopId, shops: shops),
    );
  }

  void _showJournalDialog(String shopId, List<DocDetails> shops) {
    // Show a simple dialog for now since JournalDialog expects Journal objects
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ข้อมูลสาขา: $shopId'),
        content: Text('มีข้อมูล ${shops.length} รายการ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  /// แสดง JournalDialog โดยดึงข้อมูล journal จาก API
  void _showJournalDialogForBranch(
    String shopId,
    List<DocDetails> shops,
  ) async {
    // แสดง loading dialog ก่อน
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ดึงข้อมูล journal สำหรับสาขานี้
      final journalResponse = await JournalService.getAllJournals(
        shopId: shopId,
        limit: 1000,
      );

      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // แสดง JournalDialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => JournalDialog(
            branchSync: shopId,
            journals: journalResponse.journals ?? [],
          ),
        );
      }
    } catch (e) {
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // แสดง error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('เกิดข้อผิดพลาด'),
            content: Text('ไม่สามารถโหลดข้อมูล Journal ได้\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด'),
              ),
            ],
          ),
        );
      }
    }
  }

  double _getTotalIncome(List<DocDetails> shops) {
    double total = 0.0;
    for (final shop in shops) {
      // ใช้ totalDeposit แทน totalAmount
      total += shop.totalDeposit;
    }
    return total;
  }

  double _getDailyAmount(List<DocDetails> shops) {
    if (selectedDate == null) return 0.0;

    final targetDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    double total = 0.0;

    for (final shop in shops) {
      if (shop.daily != null) {
        for (final dailyTransaction in shop.daily!) {
          if (dailyTransaction.timestamp != null &&
              dailyTransaction.timestamp!.startsWith(targetDate)) {
            total += dailyTransaction.deposit ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  double _getMonthlyAmount(List<DocDetails> shops) {
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double total = 0.0;
    for (final shop in shops) {
      // ใช้ข้อมูลจาก monthly summary
      if (shop.monthlySummary != null) {
        for (final entry in shop.monthlySummary!.entries) {
          if (entry.key.startsWith(monthStr)) {
            total += entry.value.deposit ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  double _getYearlyAmount(List<DocDetails> shops) {
    final now = DateTime.now();
    final yearStr = '${now.year}';

    double total = 0.0;
    for (final shop in shops) {
      // ใช้ข้อมูลจาก monthly summary
      if (shop.monthlySummary != null) {
        for (final entry in shop.monthlySummary!.entries) {
          if (entry.key.startsWith(yearStr)) {
            total += entry.value.deposit ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => branchData.length;

  @override
  int get selectedRowCount => 0;
}

class _BranchDetailDialog extends StatelessWidget {
  final String shopId;
  final List<DocDetails> shops;

  const _BranchDetailDialog({required this.shopId, required this.shops});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        height: 600,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFAFBFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ข้อมูลสาขา: $shopId',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'รายละเอียดและสถิติของสาขา',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'รายการทั้งหมด',
                              value: shops.length.toString(),
                              color: const Color(0xFF3B82F6),
                              icon: Icons.list_alt_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'วันที่ล่าสุด',
                              value: _getLatestDate(),
                              color: const Color(0xFF10B981),
                              icon: Icons.calendar_today_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Journal List
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            border: Border.all(
                              color: const Color(
                                0xFFE2E8F0,
                              ).withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            itemCount: shops.length > 10 ? 10 : shops.length,
                            itemBuilder: (context, index) {
                              final shop = shops[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Shop: ${shop.shopid ?? "N/A"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Updated: ${shop.updatedAt ?? "N/A"}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      if (shops.length > 10) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF64748B,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'และอีก ${shops.length - 10} รายการ',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLatestDate() {
    if (shops.isEmpty) return 'N/A';

    String? latestDate;
    for (final shop in shops) {
      if (shop.updatedAt != null) {
        if (latestDate == null || shop.updatedAt!.compareTo(latestDate) > 0) {
          latestDate = shop.updatedAt;
        }
      }
    }

    if (latestDate != null) {
      try {
        final date = DateTime.parse(latestDate);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        return latestDate;
      }
    }

    return 'N/A';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
