import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../blocs/kpi_journal/kpi_journal_state.dart';
import '../../../components/common/searchable_dropdown.dart';

class KpiJournalFilterSection extends StatefulWidget {
  final List<KpiJournalEmployee> employees;
  final List<KpiJournalShopItem> shops;
  final VoidCallback onRefresh;
  final void Function(
    List<String> shopIds,
    List<String> shopNames,
    DateTime? startDate,
    DateTime? endDate,
  ) onSearch;
  final void Function(
    List<KpiJournalEmployee> selectedEmployees,
    List<String> bookCodes,
  ) onLocalFilterChanged;

  const KpiJournalFilterSection({
    super.key,
    required this.employees,
    required this.shops,
    required this.onRefresh,
    required this.onSearch,
    required this.onLocalFilterChanged,
  });

  @override
  State<KpiJournalFilterSection> createState() =>
      _KpiJournalFilterSectionState();
}

class _KpiJournalFilterSectionState extends State<KpiJournalFilterSection> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final List<KpiJournalEmployee> _selectedEmployees = [];
  List<String> _selectedShopIds = [];
  List<String> _selectedShopNames = [];
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedBookCodes = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    widget.onSearch(
        _selectedShopIds, _selectedShopNames, _startDate, _endDate);
  }

  void _notifyLocal() {
    widget.onLocalFilterChanged(
      List.from(_selectedEmployees),
      List.from(_selectedBookCodes),
    );
  }

  Widget _buildFDivider() =>
      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0));

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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildSearchField(),
            ),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            _buildShopSelector(),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            _buildBookCodeSelector(),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            _buildDateRange(),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCodeSelector() {
    // กรองเฉพาะพนักงานของร้านที่เลือก (ถ้ายังไม่เลือกร้าน → ใช้ทั้งหมด)
    final relevantEmployees = _selectedShopNames.isEmpty
        ? widget.employees
        : widget.employees
            .where((e) => e.shopNames.any(_selectedShopNames.contains))
            .toList();

    final codes = <String>{};
    for (final emp in relevantEmployees) {
      codes.addAll(emp.byBookCode.keys);
    }
    final items = (codes.toList()..sort())
        .map((c) => SearchableDropdownItem(id: c, label: c))
        .toList();

    // ถ้าค่าที่เลือกไว้ไม่อยู่ใน items ใหม่ → ล้างออก
    final validCodes =
        _selectedBookCodes.where(codes.contains).toList();
    if (validCodes.length != _selectedBookCodes.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedBookCodes = validCodes);
      });
    }

    return SearchableMultiDropdown(
      fieldLabel: 'สมุดบัญชี',
      allLabel: 'ทั้งหมด',
      searchHint: 'ค้นหาสมุดบัญชี...',
      icon: Icons.menu_book_rounded,
      items: items,
      selectedIds: validCodes,
      accentColor: const Color(0xFF6366F1),
      width: 180,
      onChanged: (ids, _) {
        setState(() => _selectedBookCodes = ids);
      },
    );
  }

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
      selectedIds: _selectedShopIds,
      onChanged: (ids, labels) {
        setState(() {
          _selectedShopIds = ids;
          _selectedShopNames = labels;
        });
      },
    );
  }

  Widget _buildSearchField() {
    return RawAutocomplete<KpiJournalEmployee>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      displayStringForOption: (e) => e.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<KpiJournalEmployee>.empty();
        }
        final q = textEditingValue.text.toLowerCase();
        return widget.employees.where((e) {
          if (_selectedEmployees.any((s) => s.name == e.name)) return false;
          return e.name.toLowerCase().contains(q);
        });
      },
      onSelected: (KpiJournalEmployee selection) {
        _searchController.clear();
        setState(() => _selectedEmployees.add(selection));
      },
      fieldViewBuilder:
          (ctx, fieldController, fieldFocusNode, onFieldSubmitted) {
            return GestureDetector(
              onTap: () {
                if (!fieldFocusNode.hasFocus) fieldFocusNode.requestFocus();
              },
              behavior: HitTestBehavior.opaque,
              child: ListenableBuilder(
                listenable: fieldFocusNode,
                builder: (_, __) => AnimatedContainer(
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
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: fieldFocusNode.hasFocus
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._selectedEmployees.map(
                              (emp) => _buildEmployeeChip(emp, () {
                                setState(
                                  () => _selectedEmployees.removeWhere(
                                    (e) => e.name == emp.name,
                                  ),
                                );
                              }),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 120),
                              child: IntrinsicWidth(
                                child: TextField(
                                  controller: fieldController,
                                  focusNode: fieldFocusNode,
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: (_) {
                                    _triggerSearch();
                                    onFieldSubmitted();
                                  },
                                  decoration: InputDecoration(
                                    hintText: _selectedEmployees.isEmpty
                                        ? 'ค้นหาชื่อพนักงาน...'
                                        : 'เพิ่ม...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedEmployees.isNotEmpty ||
                          _searchController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _selectedEmployees.clear());
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                    ],
                  ),
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
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          option.name.isNotEmpty
                              ? option.name[0].toUpperCase()
                              : '?',
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
                        '${option.totalJournals} รายการ',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
  }

  Widget _buildEmployeeChip(
    KpiJournalEmployee employee,
    VoidCallback onRemove,
  ) {
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
              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
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
            onTap: onRemove,
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

  Widget _buildDateRange() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDate('วันเริ่มต้น', _startDate, (d) {
          setState(() => _startDate = d);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: Colors.grey[300],
          ),
        ),
        _buildCompactDate('วันสิ้นสุด', _endDate, (d) {
          setState(() => _endDate = d);
        }),
      ],
    );
  }

  Widget _buildCompactDate(
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
          builder: (context, child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
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
          ),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'รีเฟรชข้อมูล',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onRefresh,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _triggerSearch();
              _notifyLocal();
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
}
