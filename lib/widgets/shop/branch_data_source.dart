import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../models/doc_details.dart';
import '../../services/journal_service.dart';
import '../../pages/journal_page.dart';
import 'branch_detail_dialog.dart';
import 'image_gallery_dialog.dart';

class BranchDataSource extends DataTableSource {
  final Map<String, List<DocDetails>> branchData;
  final DateTime? selectedDate;
  final NumberFormat moneyFormat;
  final BuildContext context;

  BranchDataSource({
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

    final shopName = shops.isNotEmpty ? shops.first.shopname ?? shopId : shopId;
    final dailyAmount = _getDailyAmount(shops);
    final monthlyAmount = _getMonthlyAmount(shops);
    final yearlyAmount = _getYearlyAmount(shops);
    final totalIncome = _getTotalIncome(shops);

    return DataRow2(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFF3F4F6);
        }
        return index.isEven ? Colors.white : const Color(0xFFFAFAFA);
      }),
      onSelectChanged: (selected) {
        if (selected == true) {
          HapticFeedback.lightImpact();
          _showJournalDialogForBranch(shopId, shops);
        }
      },
      cells: [
        DataCell(_buildStatusIndicator(shops.length)),
        DataCell(_buildBranchNameCell(shopId, shopName, shops)),
        DataCell(
          InkWell(
            onTap: () => _showBranchDetail(shopId, shops),
            borderRadius: BorderRadius.circular(6),
            child: _buildBranchCodeCell(shopId),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _showBranchDetail(shopId, shops),
            borderRadius: BorderRadius.circular(6),
            child: _buildAmountChip(
              dailyAmount,
              const Color(0xFF06B6D4),
              Icons.today_rounded,
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _showBranchDetail(shopId, shops),
            borderRadius: BorderRadius.circular(6),
            child: _buildAmountChip(
              monthlyAmount,
              const Color(0xFF8B5CF6),
              Icons.calendar_month_rounded,
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _showBranchDetail(shopId, shops),
            borderRadius: BorderRadius.circular(6),
            child: _buildAmountChip(
              yearlyAmount,
              _getYearlyColor(yearlyAmount),
              Icons.date_range_rounded,
            ),
          ),
        ),
        DataCell(_buildJournalCell(shopId, shops, totalIncome)),
        DataCell(_buildUploadCell(shops)),
        DataCell(_buildResponsibleCell()),
      ],
    );
  }

  Color _getYearlyColor(double amount) {
    if (amount > 1800000) return const Color(0xFFEF4444);
    if (amount >= 1000000) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget _buildStatusIndicator(int count) {
    final Color statusColor;
    final IconData statusIcon;
    final String status;

    if (count > 10) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
      status = 'ปกติ';
    } else if (count > 5) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber;
      status = 'ระวัง';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error;
      status = 'มาก';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      /*decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),*/
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          //const SizedBox(width: 6),
          //Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBranchNameCell(
    String shopId,
    String shopName,
    List<DocDetails> shops,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showBranchDetail(shopId, shops);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            /*decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(6),
            ),*/
            child: const Icon(
              Icons.store_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shopName.isEmpty ? shopId : shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${shops.length} รายการ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCodeCell(String shopId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      /*decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),*/
      child: Text(
        shopId,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAmountChip(double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      /* decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),*/
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Icon(icon, size: 12, color: color),
          //const SizedBox(width: 6),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCell(
    String shopId,
    List<DocDetails> shops,
    double totalIncome,
  ) {
    final isPositive = totalIncome >= 0;
    final primaryColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showJournalDialogForBranch(shopId, shops);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              _formatAmount(totalIncome),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCell(List<DocDetails> shops) {
    // Calculate total images from dailyImages
    int imageCount = 0;
    for (final shop in shops) {
      if (shop.dailyImages != null) {
        imageCount += shop.dailyImages!
            .where((img) => img.imageUrl?.isNotEmpty == true)
            .length;
      }
    }

    final hasImages = imageCount > 0;
    final color = hasImages ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: () => _showImageGallery(shops),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(Icons.image_rounded, size: 14, color: color),
            // const SizedBox(width: 6),
            Text(
              '$imageCount รูป',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageGallery(List<DocDetails> shops) {
    showDialog(
      context: context,
      builder: (context) => ImageGalleryDialog(
        title: 'บิลสาขา ${shops.first.shopid}',
        shops: shops,
      ),
    );
  }

  Widget _buildResponsibleCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      /*decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),*/
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Icon(Icons.smart_toy, size: 14, color: Color(0xFF6366F1)),
          //SizedBox(width: 6),
          Text(
            'สมชาย ใจดี',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Data calculation methods
  double _getTotalIncome(List<DocDetails> shops) {
    return shops.fold(0.0, (total, shop) => total + shop.totalDeposit);
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
    final yearStr = '${DateTime.now().year}';
    double total = 0.0;
    for (final shop in shops) {
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
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)}K';
    return amount.toStringAsFixed(2);
  }

  // Dialog methods
  void _showBranchDetail(String shopId, List<DocDetails> shops) {
    showDialog(
      context: context,
      builder: (context) => BranchDetailDialog(shopId: shopId, shops: shops),
    );
  }

  void _showJournalDialogForBranch(
    String shopId,
    List<DocDetails> shops,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _JournalLoadingDialog(),
    );

    try {
      final journalResponse = await JournalService.getAllJournals(
        shopId: shopId,
        limit: 1000,
      );
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JournalPage(
              branchSync: shopId,
              journals: journalResponse.journals ?? [],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
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

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => branchData.length;
  @override
  int get selectedRowCount => 0;
}

class _JournalLoadingDialog extends StatelessWidget {
  const _JournalLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: const Color(0xFF3B82F6),
                    size: 45,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'กำลังโหลดข้อมูล',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'กรุณารอสักครู่...',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
