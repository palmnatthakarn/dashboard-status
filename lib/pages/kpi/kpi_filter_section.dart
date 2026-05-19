import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../blocs/kpi/kpi_state.dart';
import '../../components/common/searchable_dropdown.dart';
import '../../models/kpi_employee.dart';

class KpiFilterSection extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedBranch;
  final DateTime? documentReceiveStartDate;
  final DateTime? documentReceiveEndDate;
  final List<KpiEmployee> employees;
  final List<KpiShopItem> shops;
  final List<String> selectedShopIds;
  final List<String> selectedShopNames;
  final bool isSearching;

  final Function(String) onBranchChanged;
  final Function(List<String> shopIds, List<String> shopNames) onShopSelected;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  final List<String> selectedEmployeeIds;
  final Function(KpiEmployee) onEmployeeSelected;
  final Function(KpiEmployee) onEmployeeRemoved;
  final Map<String, String> nameMappings;

  const KpiFilterSection({
    super.key,
    required this.searchController,
    required this.selectedBranch,
    required this.documentReceiveStartDate,
    required this.documentReceiveEndDate,
    required this.employees,
    this.shops = const [],
    this.selectedShopIds = const [],
    this.selectedShopNames = const [],
    this.isSearching = false,
    required this.onBranchChanged,
    required this.onShopSelected,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    this.selectedEmployeeIds = const [],
    required this.onEmployeeSelected,
    required this.onEmployeeRemoved,
    this.nameMappings = const {},
  });

  @override
  State<KpiFilterSection> createState() => _KpiFilterSectionState();
}

class _KpiFilterSectionState extends State<KpiFilterSection> {
  late FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchFocusNode.unfocus();
      widget.onSearch();
    });
  }

  // ────────────────────── Shop Selector (Multi-select) ──────────────────────

  Widget _buildShopSelector() {
    final items = widget.shops
        .map((s) => SearchableDropdownItem(id: s.shopId, label: s.shopName))
        .toList();
    return SearchableMultiDropdown(
      fieldLabel: 'ร้าน',
      allLabel: 'ทุกร้าน',
      searchHint: 'ค้นหาร้าน...',
      icon: Icons.store_rounded,
      items: items,
      selectedIds: widget.selectedShopIds,
      onChanged: (ids, labels) {
        widget.onShopSelected(ids, labels);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main filter bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 900;

                if (isSmallScreen) {
                  return _buildSmallScreenLayout(constraints);
                }

                return _buildLargeScreenLayout();
              },
            ),
          ),

        ],
      ),
    );
  }

  // ────────────────────── Small Screen ──────────────────────

  Widget _buildSmallScreenLayout(BoxConstraints constraints) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search field
        SizedBox(
          width: constraints.maxWidth > 500
              ? constraints.maxWidth * 0.5 - 12
              : constraints.maxWidth,
          child: _buildSearchField(),
        ),
        // Shop selector
        _buildShopSelector(),
        // Date range
        _buildDateRange(),
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  // ────────────────────── Large Screen ──────────────────────

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        // 1. Search Field
        Expanded(flex: 3, child: _buildSearchField()),

        const SizedBox(width: 12),
        _buildDivider(),
        const SizedBox(width: 12),

        // 2. Shop Selector
        _buildShopSelector(),

        const SizedBox(width: 12),
        _buildDivider(),
        const SizedBox(width: 12),

        // 3. Date Range
        _buildDateRange(),

        const Spacer(),

        // 4. Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: const Color(0xFFE2E8F0));
  }

  // ────────────────────── Search Field ──────────────────────

  Widget _buildSearchField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<KpiEmployee>(
          textEditingController: widget.searchController,
          focusNode: _searchFocusNode,
          displayStringForOption: (KpiEmployee option) =>
              widget.nameMappings[option.name] ?? option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<KpiEmployee>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return widget.employees.where((KpiEmployee option) {
              if (widget.selectedEmployeeIds.contains(option.id)) return false;
              final displayName =
                  (widget.nameMappings[option.name] ?? option.name).toLowerCase();
              return displayName.contains(query) ||
                  option.name.toLowerCase().contains(query) ||
                  option.id.toLowerCase().contains(query);
            });
          },
          onSelected: (KpiEmployee selection) {
            widget.searchController.clear();
            widget.onEmployeeSelected(selection);
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                final selectedObjects = widget.employees
                    .where((e) => widget.selectedEmployeeIds.contains(e.id))
                    .toList();

                return GestureDetector(
                  onTap: () {
                    if (!fieldFocusNode.hasFocus) {
                      fieldFocusNode.requestFocus();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: fieldFocusNode.hasFocus
                          ? Colors.white
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: fieldFocusNode.hasFocus
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                        width: fieldFocusNode.hasFocus ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Search icon
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: fieldFocusNode.hasFocus
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        // Wrap chips inside expanded area
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...selectedObjects.map((employee) {
                                return _buildEmployeeChip(employee);
                              }),
                              // Text input
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 120,
                                ),
                                child: IntrinsicWidth(
                                  child: TextField(
                                    controller: fieldTextEditingController,
                                    focusNode: fieldFocusNode,
                                    textInputAction: TextInputAction.search,
                                    onChanged: _onSearchChanged,
                                    onSubmitted: (_) {
                                      fieldFocusNode.unfocus();
                                      widget.onSearch();
                                      onFieldSubmitted();
                                    },
                                    style: const TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: selectedObjects.isEmpty
                                          ? 'ค้นหาชื่อหรือรหัสพนักงาน...'
                                          : 'เพิ่ม...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.only(
                                        bottom: 12,
                                      ), // Adjust alignment
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Clear button
                        if (widget.selectedEmployeeIds.isNotEmpty ||
                            widget.searchController.text.isNotEmpty)
                          _buildMiniIconButton(
                            Icons.clear_rounded,
                            onTap: () {
                              _searchFocusNode.unfocus();
                              widget.onClearSearch();
                            },
                            tooltip: 'ล้างการค้นหา',
                          ),
                      ],
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    maxWidth: 320,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        final displayName =
                            widget.nameMappings[option.name] ?? option.name;
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                          subtitle: Text(
                            widget.nameMappings.containsKey(option.name)
                                ? '(${option.name})'
                                : option.id,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          onTap: () => onSelected(option),
                          hoverColor: const Color(0xFFF0F9FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmployeeChip(KpiEmployee employee) {
    final displayName = widget.nameMappings[employee.name] ?? employee.name;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: Colors.white,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => widget.onEmployeeRemoved(employee),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ────────────────────── Date Range ──────────────────────


  Widget _buildDateRange() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDateSelector(
          context,
          'วันรับเอกสาร',
          widget.documentReceiveStartDate,
          widget.onStartDateChanged,
          lastDate: widget.documentReceiveEndDate,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: Colors.grey[300],
          ),
        ),
        _buildCompactDateSelector(
          context,
          'ถึง',
          widget.documentReceiveEndDate,
          widget.onEndDateChanged,
          firstDate: widget.documentReceiveStartDate,
        ),
      ],
    );
  }

  Widget _buildCompactDateSelector(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onSelect, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final fmt = DateFormat('d MMM yy', 'th');
    final hasDate = date != null;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030),
          builder: (context, child) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400.0,
                  maxHeight: 520.0,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3B82F6),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF1E293B),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: child!,
                  ),
                ),
              ),
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasDate ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: hasDate
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: hasDate ? const Color(0xFF2563EB) : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hasDate ? fmt.format(date) : '- เลือก -',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── Action Buttons ──────────────────────

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh
        _buildToolButton(
          icon: Icons.refresh_rounded,
          tooltip: 'รีเฟรชข้อมูล',
          onTap: () {
            _searchFocusNode.unfocus();
            widget.onRefresh();
          },
        ),
        const SizedBox(width: 8),
        // Search button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _searchFocusNode.unfocus();
              widget.onSearch();
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'ค้นหา',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFFBFDBFE) : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIconButton(
    IconData icon, {
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

}

