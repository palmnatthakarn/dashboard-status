import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/doc_details.dart';

class BranchDetailDialog extends StatelessWidget {
  final String shopId;
  final List<DocDetails> shops;

  const BranchDetailDialog({
    super.key,
    required this.shopId,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Color(0xFF3B82F6),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'รายละเอียดและสถิติของสาขา',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Calculate financial summaries
    final totalIncome = shops.fold(0.0, (sum, s) => sum + s.totalDeposit);
    final totalWithdraw = shops.fold(0.0, (sum, s) => sum + s.totalWithdraw);
    final netIncome = totalIncome - totalWithdraw;

    // Calculate daily total from transactions
    double dailyTotal = 0.0;
    if (shops.isNotEmpty) {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      for (final shop in shops) {
        if (shop.daily != null) {
          for (final tx in shop.daily!) {
            if (tx.timestamp != null && tx.timestamp!.startsWith(todayStr)) {
              dailyTotal += tx.deposit ?? 0;
            }
          }
        }
      }
    }

    // Calculate monthly total
    double monthlyTotal = 0.0;
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    for (final shop in shops) {
      if (shop.monthlySummary != null) {
        for (final entry in shop.monthlySummary!.entries) {
          if (entry.key.startsWith(monthStr)) {
            monthlyTotal += entry.value.deposit ?? 0;
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Basic info
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
          const SizedBox(height: 16),
          // Row 2: Financial summary
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'รายวัน',
                  value: _formatAmount(dailyTotal),
                  color: const Color(0xFF06B6D4),
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'รายเดือน',
                  value: _formatAmount(monthlyTotal),
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'รายได้รวม',
                  value: _formatAmount(netIncome),
                  color: netIncome >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'รายการล่าสุด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildShopList()),
          if (shops.length > 10) _buildMoreIndicator(),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)}K';
    return amount.toStringAsFixed(2);
  }

  Widget _buildShopList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          itemCount: shops.length > 10 ? 10 : shops.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
          itemBuilder: (context, index) {
            final shop = shops[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                'Shop: ${shop.shopid ?? "N/A"}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
              subtitle: Text(
                'Updated: ${shop.updatedAt ?? "N/A"}',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          'และอีก ${shops.length - 10} รายการ',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
