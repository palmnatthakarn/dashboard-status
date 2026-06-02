import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../common/searchable_dropdown.dart';

class ReportFilterSection extends StatelessWidget {
  final List<String> reportTypes;
  final List<Map<String, dynamic>> shops;
  final String? selectedReportType;
  final String? selectedShopId;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String?> onReportTypeChanged;
  final ValueChanged<String?> onShopChanged;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;
  final VoidCallback onSearch;
  final bool isLoadingShops;

  const ReportFilterSection({
    super.key,
    required this.reportTypes,
    this.shops = const [],
    required this.selectedReportType,
    this.selectedShopId,
    required this.startDate,
    required this.endDate,
    required this.onReportTypeChanged,
    required this.onShopChanged,
    required this.onStartDateTap,
    required this.onEndDateTap,
    required this.onSearch,
    this.isLoadingShops = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrappedLayout = constraints.maxWidth < 1180;

        if (useWrappedLayout) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 44) / 2
                      : constraints.maxWidth - 32,
                  child: _buildCompactShopDropdown(),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 44) / 2
                      : constraints.maxWidth - 32,
                  child: _buildCompactReportDropdown(),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 760
                      ? 320
                      : constraints.maxWidth - 32,
                  child: _buildDateRangePicker(),
                ),
                SizedBox(
                  height: 56,
                  child: _buildActionButton(
                    icon: Icons.search_rounded,
                    label: 'ค้นหา',
                    color: const Color(0xFF3B82F6),
                    textColor: Colors.white,
                    onTap: onSearch,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 4, child: _buildCompactShopDropdown()),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _buildCompactReportDropdown()),
              const SizedBox(width: 16),
              SizedBox(width: 320, child: _buildDateRangePicker()),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: _buildActionButton(
                  icon: Icons.search_rounded,
                  label: 'ค้นหา',
                  color: const Color(0xFF3B82F6),
                  textColor: Colors.white,
                  onTap: onSearch,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactShopDropdown() {
    final items = shops
        .map(
          (shop) => SearchableDropdownItem(
            id: _shopId(shop),
            label: _shopName(shop),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 280.0;
        final dropdownWidth = width.clamp(260.0, 420.0).toDouble();

        return SearchableDropdown(
          fieldLabel: 'ร้าน',
          allLabel: isLoadingShops ? 'กำลังโหลดร้าน...' : 'เลือกร้าน',
          searchHint: 'ค้นหาร้าน...',
          icon: Icons.store_rounded,
          items: items,
          selectedId: selectedShopId,
          onChanged: (id, _) => onShopChanged(id),
          width: width,
          dropdownWidth: dropdownWidth,
        );
      },
    );
  }

  Widget _buildCompactReportDropdown() {
    final items = reportTypes
        .map((type) => SearchableDropdownItem(id: type, label: type))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 280.0;
        final dropdownWidth = width.clamp(260.0, 420.0).toDouble();

        return SearchableDropdown(
          fieldLabel: 'รายงาน',
          allLabel: 'เลือกประเภทรายงาน',
          searchHint: 'ค้นหารายงาน...',
          icon: Icons.description_rounded,
          items: items,
          selectedId: selectedReportType,
          onChanged: (id, _) => onReportTypeChanged(id),
          width: width,
          dropdownWidth: dropdownWidth,
        );
      },
    );
  }

  String _shopId(Map<String, dynamic> shop) {
    return shop['shopid']?.toString() ??
        shop['shop_id']?.toString() ??
        shop['id']?.toString() ??
        '';
  }

  String _shopName(Map<String, dynamic> shop) {
    final names = shop['names'];
    if (names is List && names.isNotEmpty) {
      final first = names.first;
      if (first is Map && first['name'] != null) {
        return first['name'].toString();
      }
    }
    return shop['shopname']?.toString() ??
        shop['shop_name']?.toString() ??
        shop['name']?.toString() ??
        _shopId(shop);
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactDatePicker(
            label: 'จากวันที่',
            selectedDate: startDate,
            onTap: onStartDateTap,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.grey.shade400,
          ),
        ),
        Expanded(
          child: _buildCompactDatePicker(
            label: 'ถึงวันที่',
            selectedDate: endDate,
            onTap: onEndDateTap,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: selectedDate != null
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : '- เลือก -',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
