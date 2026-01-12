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
import '../../pages/gl_journal_page.dart';

class BranchDataSource extends DataTableSource {
  final Map<String, List<DocDetails>> branchData;
  final DateTimeRange? selectedDateRange;
  final NumberFormat moneyFormat;
  final BuildContext context;

  BranchDataSource({
    required this.branchData,
    required this.selectedDateRange,
    required this.moneyFormat,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= branchData.length) return null;

    final shopId = branchData.keys.elementAt(index);
    final shops = branchData[shopId]!;

    final shopName = _extractShopName(shops, shopId);
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
        DataCell(_buildStatusIndicator(yearlyAmount)),
        DataCell(_buildBranchNameCell(shopId, shopName, shops)),
        // Removed shop code cell - code now shows under shop name
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
        //DataCell(_buildJournalCell(shopId, shops, totalIncome)),
        DataCell(_buildUploadCell(shopId, shops)),
        //DataCell(_buildResponsibleCell()),
      ],
    );
  }

  Color _getYearlyColor(double amount) {
    if (amount > 1800000) return const Color(0xFFEF4444);
    if (amount >= 1000000) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget _buildStatusIndicator(double amount) {
    final Color statusColor;
    final IconData statusIcon;
    // final String status; // Not currently used in display

    if (amount > 1800000) {
      // Exceeded / Critical
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.error_rounded;
      // status = 'มาก';
    } else if (amount >= 1000000) {
      // Warning
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_rounded;
      // status = 'ระวัง';
    } else {
      // Safe
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
      // status = 'ปกติ';
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Journal 1 Button
        InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showJournalDialogForBranch(shopId, shops);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                const SizedBox(width: 4),
                Text(
                  '1', // Label for Journal 1
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Journal 2 Button
        InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showJournal2DialogForBranch(shopId, shops);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6), // Different color for Journal 2
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  '2', // Label for Journal 2
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCell(String shopId, List<DocDetails> shops) {
    // Use API data if available
    if (shops.isNotEmpty && shops.first.localImageCount != null) {
      final imageCount = shops.first.localImageCount!;
      final hasImages = imageCount > 0;
      final color = hasImages
          ? const Color(0xFF10B981)
          : const Color(0xFF9CA3AF);

      return InkWell(
        onTap: () => _showImageGallery(shopId, shops),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$imageCount บิล',
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

    // Fallback to calculation
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
      onTap: () => _showImageGallery(shopId, shops),
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

  void _showImageGallery(String shopId, List<DocDetails> shops) {
    if (shops.isEmpty) return;

    // Use passed shopId instead of extracting from shops list
    // final shopId = shops.first.shopid ?? '';
    final shopName = _extractShopName(shops, shopId);

    showDialog(
      context: context,
      builder: (context) => ImageGalleryDialog(title: shopName, shopId: shopId),
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
    // Use API data if available
    if (shops.isNotEmpty && shops.first.dailyAverage != null) {
      return shops.first.dailyAverage!;
    }

    if (selectedDateRange == null) return 0.0;

    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end.add(const Duration(days: 1));

    double total = 0.0;
    for (final shop in shops) {
      if (shop.daily != null) {
        for (final dailyTransaction in shop.daily!) {
          if (dailyTransaction.timestamp != null) {
            final DateTime? txDate = DateTime.tryParse(
              dailyTransaction.timestamp!,
            );
            if (txDate != null &&
                txDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                txDate.isBefore(end)) {
              total += dailyTransaction.deposit ?? 0.0;
            }
          }
        }
      }
    }
    return total;
  }

  double _getMonthlyAmount(List<DocDetails> shops) {
    // Use API data if available
    if (shops.isNotEmpty && shops.first.monthlyAverage != null) {
      return shops.first.monthlyAverage!;
    }

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
    // Use API data if available
    if (shops.isNotEmpty && shops.first.yearlyAverage != null) {
      return shops.first.yearlyAverage!;
    }

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

  /// Extract shop name from names array or fallback to shopname/shopid
  String _extractShopName(List<DocDetails> shops, String shopId) {
    if (shops.isEmpty) return shopId;

    final shop = shops.first;

    // Try to get name from names array (new structure)
    // Expected structure: "names": [{"code": "th", "name": "ชื่อร้าน", ...}]
    try {
      if (shop.names != null && shop.names!.isNotEmpty) {
        // Find Thai name (code == 'th')
        final thaiName = shop.names!.firstWhere(
          (name) => name.code == 'th',
          orElse: () => shop.names!.first, // Fallback to first name if no 'th'
        );

        if (thaiName.name != null && thaiName.name!.isNotEmpty) {
          return thaiName.name!;
        }
      }

      // Fallback to shopname field (old structure)
      if (shop.shopname != null && shop.shopname!.isNotEmpty) {
        return shop.shopname!;
      }
    } catch (e) {
      debugPrint('Error extracting shop name: $e');
    }

    // Final fallback to shopid
    return shopId;
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
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showJournal2DialogForBranch(
    String shopId,
    List<DocDetails> shops,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _JournalLoadingDialog(),
    );

    try {
      // Extract shop name
      final shopName = _extractShopName(shops, shopId);

      final journalResponse = await JournalService.getAllGLJournals(
        shopId: shopId,
        limit: 1000,
      );
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GLJournalPage(
              shopids: shopId, // Changed from branchSync
              shopName: shopName, // Pass shop name
              journals: journalResponse.journals ?? [],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: Text('ไม่สามารถโหลดข้อมูล Journal ได้\n$message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
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
