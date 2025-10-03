import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard_bloc_exports.dart';
import 'shop_detail_popup.dart';
import 'shop_image_files_dialog.dart';

class ShopDataTable extends StatelessWidget {
  final List shops;
  final DateTime? selectedDate;
  final Function getIncomeForPeriod;
  final NumberFormat moneyFormat;
  final Function(DateTime?) onDateChanged;
  const ShopDataTable({
    super.key,
    required this.shops,
    this.selectedDate,
    required this.getIncomeForPeriod,
    required this.moneyFormat,
    required this.onDateChanged,
  });
  @override
  Widget build(BuildContext context) {
    final dataSource = _ShopDataSource(
      shops: shops,
      selectedDate: selectedDate,
      getIncomeForPeriod: getIncomeForPeriod,
      moneyFormat: moneyFormat,
      context: context,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  'รายการร้านค้า (${shops.length} ร้าน)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
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
                    if (pickedDate != null) {
                      onDateChanged(pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                              : 'เลือกวันที่',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 600,
            child: PaginatedDataTable2(
              showCheckboxColumn: false,
              columnSpacing: 16,
              horizontalMargin: 20,
              minWidth: 1200,
              rowsPerPage: 10,
              dataRowHeight: 50,
              headingRowHeight: 48,
              dividerThickness: 0,
              dataTextStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
              headingTextStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
              columns: const [
                DataColumn2(
                  label: Text('สถานะ'),
                  size: ColumnSize.S,
                  fixedWidth: 120,
                ),
                DataColumn2(
                  label: Center(child: Text('ชื่อร้านค้า')),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Center(child: Text('รหัสร้าน')),
                  size: ColumnSize.M,
                ),
                DataColumn2(
                  label: Center(child: Text('รายวัน')),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Center(child: Text('รายเดือน')),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Center(child: Text('รายปี')),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                DataColumn2(
                  label: Center(child: Text('อัปโหลด')),
                  size: ColumnSize.L,
                  numeric: false,
                ),
                DataColumn2(
                  label: Center(child: Text('ผู้รับผิดชอบ')),
                  size: ColumnSize.L,
                  numeric: false,
                ),
              ],
              source: dataSource,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopDataSource extends DataTableSource {
  final List shops;
  final DateTime? selectedDate;
  final Function getIncomeForPeriod;
  final NumberFormat moneyFormat;
  final BuildContext context;
  _ShopDataSource({
    required this.shops,
    this.selectedDate,
    required this.getIncomeForPeriod,
    required this.moneyFormat,
    required this.context,
  }) {
    // เพิ่ม debug logging
    print('🎯 ShopDataSource initialized with ${shops.length} shops');
    print(
      '📅 Selected date: ${selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'ไม่ได้เลือก'}',
    );
    for (int i = 0; i < shops.length && i < 3; i++) {
      final shop = shops[i];
      print('🏪 Shop $i: ${shop.shopname} (${shop.shopid})');
      if (shop.dailyImages != null) {
        print('📸 Daily images: ${shop.dailyImages!.length} items');
        print('🔢 Image count: ${shop.imageCount}');
      } else {
        print('❌ No daily images data');
      }
    }
  }
  @override
  DataRow? getRow(int index) {
    if (index >= shops.length) return null;
    final shop = shops[index];

    // เพิ่ม debug สำหรับแต่ละแถว
    if (index < 3) {
      print(
        '📊 Row $index: ${shop.shopname} -> imageCount: ${shop.imageCount}',
      );
    }

    // ใช้ข้อมูลจาก API แทน getIncomeForPeriod
    final yearIncome = _getYearlySum(shop);
    String status;
    Color statusColor;
    IconData statusIcon;
    if (yearIncome > 1800000) {
      status = 'Exceeded';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error;
    } else if (yearIncome >= 1000000 && yearIncome <= 1800000) {
      status = 'Warning';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber;
    } else {
      status = 'Safe';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
    }
    Color rowColor = yearIncome > 1800000
        ? const Color(0xFFFEF2F2)
        : yearIncome >= 1000000
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF0FDF4);
    return DataRow2(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return rowColor.withOpacity(0.8);
        }
        return rowColor;
      }),
      onSelectChanged: (selected) {
        if (selected == true) {
          showDialog(
            context: context,
            builder: (context) => ShopDetailPopup(
              shop: shop,
              moneyFormat: moneyFormat,
              selectedDate: selectedDate,
            ),
          );
        }
      },
      cells: [
        DataCell(
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    statusIcon,
                    key: ValueKey(statusIcon),
                    color: statusColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  child: Text(status),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(
            shop.shopname ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        DataCell(
          Text(
            shop.shopid ?? '-',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF64748B),
            ),
          ),
        ),

        DataCell(
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(
              begin: 0,
              end: _getDailySumForDate(shop, selectedDate),
            ),
            builder: (context, value, child) {
              return Text(
                _formatSafely(value),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              );
            },
          ),
        ),

        DataCell(
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0, end: _getMonthlySum(shop)),
            builder: (context, value, child) {
              return Text(
                _formatSafely(value),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              );
            },
          ),
        ),
        DataCell(
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0, end: _getYearlySum(shop)),
            builder: (context, value, child) {
              final yearlyValue = _getYearlySum(shop);
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: yearlyValue > 1800000
                      ? const Color(0xFFEF4444)
                      : yearlyValue >= 1000000
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF1E293B),
                ),
                child: Text(_formatSafely(value)),
              );
            },
          ),
        ),

        DataCell(
          Center(
            child: shop.imageCount > 0
                ? BlocBuilder<ImageApprovalBloc, ImageApprovalState>(
                    builder: (context, approvalState) {
                      final shopId = shop.shopid ?? '';
                      final approvedCount = approvalState.getApprovedCount(
                        shopId,
                      );
                      final totalCount = shop.imageCount;
                      final isAllApproved = approvedCount >= totalCount;
                      final statusColor = isAllApproved
                          ? const Color(0xFF10B981)
                          : approvedCount > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF64748B);
                      final statusIcon = isAllApproved
                          ? Icons.check_circle
                          : approvedCount > 0
                          ? Icons.hourglass_empty
                          : Icons.folder_open;

                      return InkWell(
                        onTap: () {
                          // อัปเดต total count ใน bloc
                          context.read<ImageApprovalBloc>().add(
                            UpdateTotalImageCount(
                              shopId: shopId,
                              count: totalCount,
                            ),
                          );
                          showDialog(
                            context: context,
                            builder: (dialogContext) => BlocProvider.value(
                              value: context.read<ImageApprovalBloc>(),
                              child: ShopImageFilesDialog(shop: shop),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  statusIcon,
                                  key: ValueKey(statusIcon),
                                  color: statusColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                child: TweenAnimationBuilder<int>(
                                  duration: const Duration(milliseconds: 400),
                                  tween: IntTween(begin: 0, end: approvedCount),
                                  builder: (context, value, child) {
                                    return Text("$value/$totalCount ไฟล์");
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        child: const Text('0/0 ไฟล์'),
                      ),
                    ],
                  ),
          ),
        ),

        DataCell(
          Center(
            child: Text(
              shop.responsible?.name ?? '-',
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount {
    final count = shops.length;
    return count;
  }

  @override
  int get selectedRowCount => 0;

  // คำนวณยอดรวมรายเดือนจากข้อมูล monthly_summary
  double _getMonthlySum(dynamic shop) {
    if (shop.monthlySummary == null) return 0.0;

    double sum = 0.0;
    shop.monthlySummary.forEach((String month, dynamic monthData) {
      if (monthData.deposit != null) {
        sum += monthData.deposit!;
      }
    });
    return sum / 12; // เฉลี่ยต่อเดือน
  }

  // คำนวณยอดรวมรายปีจากข้อมูล monthly_summary
  double _getYearlySum(dynamic shop) {
    if (shop.monthlySummary == null) return 0.0;

    double sum = 0.0;
    shop.monthlySummary.forEach((String month, dynamic monthData) {
      if (monthData.deposit != null) {
        sum += monthData.deposit!;
      }
    });
    return sum;
  }

  // คำนวณยอดรายวันตามวันที่เลือกจากข้อมูล daily transactions
  double _getDailySumForDate(dynamic shop, DateTime? selectedDate) {
    if (selectedDate == null) return 0.0;
    if (shop.dailyTransactions == null) return 0.0;

    // แปลงวันที่เลือกเป็น string format (YYYY-MM-DD)
    final targetDateStr =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    double dailySum = 0.0;

    for (final transaction in shop.dailyTransactions) {
      if (transaction.timestamp != null) {
        // ตรวจสอบว่า timestamp ตรงกับวันที่เลือกหรือไม่
        if (transaction.timestamp!.startsWith(targetDateStr)) {
          dailySum +=
              (transaction.deposit ?? 0.0) - (transaction.withdraw ?? 0.0);
        }
      }
    }

    return dailySum;
  }

  String _formatSafely(dynamic value) {
    final sanitized = _sanitizeNumber(value);
    if (sanitized == 0) return '-';
    return moneyFormat.format(sanitized);
  }

  double _sanitizeNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is! num) return 0.0;
    if (value.isNaN || value.isInfinite) return 0.0;
    return value.toDouble();
  }
}
