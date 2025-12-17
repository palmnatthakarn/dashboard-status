import 'package:flutter/material.dart';

class DashboardFilterSection extends StatelessWidget {
  final String searchQuery;
  final String selectedFilter;
  final List shops;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final Function(String) getShopCountByStatus;

  const DashboardFilterSection({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.shops,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.getShopCountByStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search and Period Selector
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อร้าน หรือ Shop ID',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              FilterChip(
                label: 'ทั้งหมด',
                count: shops.length,
                isSelected: selectedFilter == 'all',
                color: const Color(0xFF3B82F6),
                onTap: () => onFilterChanged('all'),
              ),
              FilterChip(
                label: 'Safe',
                count: getShopCountByStatus('safe') as int,
                isSelected: selectedFilter == 'safe',
                color: const Color(0xFF10B981),
                onTap: () => onFilterChanged('safe'),
              ),
              FilterChip(
                label: 'Warning',
                count: getShopCountByStatus('warning') as int,
                isSelected: selectedFilter == 'warning',
                color: const Color(0xFFF59E0B),
                onTap: () => onFilterChanged('warning'),
              ),
              FilterChip(
                label: 'Exceeded',
                count: getShopCountByStatus('exceeded') as int,
                isSelected: selectedFilter == 'exceeded',
                color: const Color(0xFFEF4444),
                onTap: () => onFilterChanged('exceeded'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterChip extends StatefulWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  State<FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<FilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.1)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? widget.color : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: widget.isSelected
                    ? Container(
                        key: const ValueKey('dot'),
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected
                      ? widget.color
                      : const Color(0xFF64748B),
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 11,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.color.withValues(alpha: 0.2)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TweenAnimationBuilder<int>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  tween: IntTween(begin: 0, end: widget.count),
                  builder: (context, value, child) {
                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: widget.isSelected
                            ? widget.color
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      child: Text(value.toString()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
