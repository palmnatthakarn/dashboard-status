import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/doc_details.dart';

class BranchDetailDialog extends StatelessWidget {
  final String shopId;
  final List<DocDetails> shops;

  const BranchDetailDialog({super.key, required this.shopId, required this.shops});

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
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withOpacity(0.05), Colors.white.withOpacity(0.8)],
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
                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลสาขา: $shopId',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'รายละเอียดและสถิติของสาขา',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildShopList()),
          if (shops.length > 10) _buildMoreIndicator(),
        ],
      ),
    );
  }

  Widget _buildShopList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        itemCount: shops.length > 10 ? 10 : shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: index.isEven ? Colors.white.withOpacity(0.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              title: Text(
                'Shop: ${shop.shopid ?? "N/A"}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                'Updated: ${shop.updatedAt ?? "N/A"}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF64748B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'และอีก ${shops.length - 10} รายการ',
            style: const TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
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

  const _SummaryCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
