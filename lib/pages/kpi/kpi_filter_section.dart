import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../blocs/kpi/kpi_state.dart';
import '../../models/kpi_employee.dart';

class KpiFilterSection extends StatefulWidget {
  final TextEditingController searchController;
  final TextEditingController taxIdController;
  final String selectedBranch;
  final DateTime? documentReceiveStartDate;
  final DateTime? documentReceiveEndDate;
  final DateTimeRange? previousDateRange;
  final DateTimeRange? statusCheckDateRange;
  final bool isAdvancedFilterExpanded;
  final List<KpiEmployee> employees;
  // New shop list from API44
  final List<KpiShopItem> shops;
  final String? selectedShopId;
  final String? selectedShopName;
  final bool isSearching;

  final VoidCallback onToggleAdvancedFilter;
  final Function(String) onBranchChanged;
  final Function(String? shopId, String? shopName) onShopSelected;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(DateTimeRange?) onPreviousDateRangeChanged;
  final Function(DateTimeRange?) onStatusCheckDateRangeChanged;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;

  final VoidCallback onRefresh;

  // Multi-select support
  final List<String> selectedEmployeeIds;
  final Function(KpiEmployee) onEmployeeSelected;
  final Function(KpiEmployee) onEmployeeRemoved;

  const KpiFilterSection({
    super.key,
    required this.searchController,
    required this.taxIdController,
    required this.selectedBranch,
    required this.documentReceiveStartDate,
    required this.documentReceiveEndDate,
    required this.previousDateRange,
    required this.statusCheckDateRange,
    required this.isAdvancedFilterExpanded,
    required this.employees,
    this.shops = const [],
    this.selectedShopId,
    this.selectedShopName,
    this.isSearching = false,
    required this.onToggleAdvancedFilter,
    required this.onBranchChanged,
    required this.onShopSelected,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onPreviousDateRangeChanged,
    required this.onStatusCheckDateRangeChanged,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    this.selectedEmployeeIds = const [],
    required this.onEmployeeSelected,
    required this.onEmployeeRemoved,
  });

  @override
  State<KpiFilterSection> createState() => _KpiFilterSectionState();
}

class _KpiFilterSectionState extends State<KpiFilterSection>
    with SingleTickerProviderStateMixin {
  late FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  // Shop search
  final _shopSearchController = TextEditingController();
  final _shopSearchFocusNode = FocusNode();
  bool _isShopDropdownOpen = false;
  final LayerLink _shopLayerLink = LayerLink();
  OverlayEntry? _shopOverlay;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _shopSearchController.dispose();
    _shopSearchFocusNode.dispose();
    _removeShopOverlay();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch();
    });
  }

  void _removeShopOverlay() {
    _shopOverlay?.remove();
    _shopOverlay = null;
    _isShopDropdownOpen = false;
  }

  void _toggleShopDropdown() {
    if (_isShopDropdownOpen) {
      _removeShopOverlay();
    } else {
      _showShopDropdown();
    }
    setState(() {});
  }

  void _showShopDropdown() {
    _shopSearchController.clear();
    _shopOverlay = _buildShopOverlay();
    Overlay.of(context).insert(_shopOverlay!);
    _isShopDropdownOpen = true;
    // Delay to ensure overlay is built before requesting focus
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_shopSearchFocusNode.canRequestFocus) {
        _shopSearchFocusNode.requestFocus();
      }
    });
  }

  OverlayEntry _buildShopOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeShopOverlay();
          setState(() {});
        },
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _shopLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                child: _ShopSearchDropdown(
                  shops: widget.shops,
                  selectedShopId: widget.selectedShopId,
                  searchController: _shopSearchController,
                  focusNode: _shopSearchFocusNode,
                  onSelect: (shopId, shopName) {
                    widget.onShopSelected(shopId, shopName);
                    _removeShopOverlay();
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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

          // Advanced Filters (animated expand/collapse)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _buildAdvancedFilters(),
            crossFadeState: widget.isAdvancedFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
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
          displayStringForOption: (KpiEmployee option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<KpiEmployee>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return widget.employees.where((KpiEmployee option) {
              if (widget.selectedEmployeeIds.contains(option.id)) return false;
              return option.name.toLowerCase().contains(query) ||
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
                            onTap: widget.onClearSearch,
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
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              option.name.isNotEmpty ? option.name[0] : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            option.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                          subtitle: Text(
                            option.id,
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
              employee.name.isNotEmpty ? employee.name[0] : '?',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            employee.name,
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

  // ────────────────────── Shop Selector ──────────────────────

  Widget _buildShopSelector() {
    final displayName =
        widget.selectedShopId != null && widget.selectedShopId!.isNotEmpty
        ? (widget.selectedShopName ?? 'ทุกร้าน')
        : 'ทุกร้าน';

    return CompositedTransformTarget(
      link: _shopLayerLink,
      child: InkWell(
        onTap: _toggleShopDropdown,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isShopDropdownOpen
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isShopDropdownOpen
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store_rounded,
                size: 16,
                color: _isShopDropdownOpen
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ร้าน',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isShopDropdownOpen
                            ? const Color(0xFF2563EB)
                            : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isShopDropdownOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
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
          'ตั้งแต่',
          widget.documentReceiveEndDate,
          widget.onEndDateChanged,
        ),
      ],
    );
  }

  Widget _buildCompactDateSelector(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onSelect,
  ) {
    final fmt = DateFormat('d MMM yy', 'th');
    final hasDate = date != null;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
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
          onTap: widget.onRefresh,
        ),
        const SizedBox(width: 4),
        // Advanced filter toggle
        _buildToolButton(
          icon: widget.isAdvancedFilterExpanded
              ? Icons.tune_rounded
              : Icons.tune_outlined,
          tooltip: 'ตัวกรองเพิ่มเติม',
          isActive: widget.isAdvancedFilterExpanded,
          onTap: widget.onToggleAdvancedFilter,
        ),
        const SizedBox(width: 8),
        // Search button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSearch,
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

  // ────────────────────── Advanced Filters ──────────────────────

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tax ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลขผู้เสียภาษี',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 45,
                      child: TextField(
                        controller: widget.taxIdController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => widget.onSearch(),
                        decoration: InputDecoration(
                          hintText: 'ระบุเลข 13 หลัก',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF93C5FD),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Previous date range
              Expanded(
                child: _buildDateFilterItem(
                  context,
                  'วันที่ก่อนหน้า',
                  widget.previousDateRange,
                  widget.onPreviousDateRangeChanged,
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 16),
              // Status check date range
              Expanded(
                child: _buildDateFilterItem(
                  context,
                  'วันตรวจสอบสถานะ',
                  widget.statusCheckDateRange,
                  widget.onStatusCheckDateRangeChanged,
                  icon: Icons.fact_check_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterItem(
    BuildContext context,
    String label,
    DateTimeRange? range,
    Function(DateTimeRange?) onSelect, {
    IconData icon = Icons.calendar_month_rounded,
    Color color = const Color(0xFF64748B),
  }) {
    final dateFormat = DateFormat('d MMM yy', 'th');
    final hasRange = range != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
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
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: hasRange
                  ? const Color(0xFFF0F9FF)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasRange
                    ? const Color(0xFFBAE6FD)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: hasRange ? const Color(0xFF0284C7) : color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasRange
                        ? '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}'
                        : '- เลือกช่วงเวลา -',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasRange
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasRange)
                  InkWell(
                    onTap: () => onSelect(null),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Searchable Shop Dropdown (Overlay)
// ════════════════════════════════════════════════════════════

class _ShopSearchDropdown extends StatefulWidget {
  final List<KpiShopItem> shops;
  final String? selectedShopId;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final Function(String? shopId, String? shopName) onSelect;

  const _ShopSearchDropdown({
    required this.shops,
    required this.selectedShopId,
    required this.searchController,
    required this.focusNode,
    required this.onSelect,
  });

  @override
  State<_ShopSearchDropdown> createState() => _ShopSearchDropdownState();
}

class _ShopSearchDropdownState extends State<_ShopSearchDropdown> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(() {
      setState(() => _query = widget.searchController.text.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredShops = _query.isEmpty
        ? widget.shops
        : widget.shops
              .where(
                (s) =>
                    s.shopName.toLowerCase().contains(_query) ||
                    s.shopId.toLowerCase().contains(_query),
              )
              .toList();

    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: widget.searchController,
              focusNode: widget.focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ค้นหาร้าน...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          // "ทุกร้าน" option
          _buildShopOption(
            null,
            'ทุกร้าน',
            isSelected:
                widget.selectedShopId == null || widget.selectedShopId!.isEmpty,
          ),
          // Shop list
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filteredShops.length,
              itemBuilder: (context, index) {
                final shop = filteredShops[index];
                return _buildShopOption(
                  shop.shopId,
                  shop.shopName,
                  isSelected: shop.shopId == widget.selectedShopId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopOption(
    String? shopId,
    String shopName, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () {
        widget.onSelect(shopId ?? '', shopName);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: isSelected ? const Color(0xFFEFF6FF) : null,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 16,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shopName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
          ],
        ),
      ),
    );
  }
}
