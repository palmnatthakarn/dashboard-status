import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../blocs/kpi_journal/kpi_journal_bloc.dart';
import '../../blocs/kpi_journal/kpi_journal_event.dart';
import '../../blocs/kpi_journal/kpi_journal_state.dart';
import '../../components/common/custom_pagination.dart';
import '../../components/common/searchable_dropdown.dart';
import '../../components/common/user_avatar.dart';
import '../../components/dashboard_loading_widgets.dart';
import 'kpi_constants.dart';
import 'kpi_text_styles.dart';

class KpiJournalPage extends StatelessWidget {
  const KpiJournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KpiJournalBloc()..add(LoadKpiJournalData()),
      child: const _KpiJournalPageContent(),
    );
  }
}

class _KpiJournalPageContent extends StatefulWidget {
  const _KpiJournalPageContent();

  @override
  State<_KpiJournalPageContent> createState() => _KpiJournalPageContentState();
}

class _KpiJournalPageContentState extends State<_KpiJournalPageContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final List<KpiJournalEmployee> _selectedEmployees = [];
  String? _selectedShopId;
  String? _selectedShopName;
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  double _fontScale = 1.0;
  final Set<String> _expandedIds = {};
  String? _selectedBookCode;
  String? _selectedChecker;
  String? _selectedUpdater;

  static final _dateFmt = DateFormat('dd/MM/yy');
  static final _dtFmt = DateFormat('dd/MM/yy HH:mm ');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _search(BuildContext context) {
    context.read<KpiJournalBloc>().add(
      SelectShopAndSearchJournal(
        shopId: _selectedShopId,
        shopName: _selectedShopName,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KpiJournalBloc, KpiJournalState>(
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: _buildAppBar(),
              body: Builder(
                builder: (ctx) {
                  if (state is KpiJournalLoading) {
                    return const DashboardLoadingWidget();
                  }
                  if (state is KpiJournalError) {
                    return DashboardErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          ctx.read<KpiJournalBloc>().add(LoadKpiJournalData()),
                    );
                  }
                  if (state is KpiJournalLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ctx.read<KpiJournalBloc>().add(LoadKpiJournalData()),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(state),
                            const SizedBox(height: 16),
                            _buildFilterSection(ctx, state),
                            const SizedBox(height: 16),
                            _buildTable(state),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            if (state is KpiJournalLoaded && state.isSearching)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const DashboardLoadingWidget(),
                ),
              ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 22),
          SizedBox(width: 8),
          Text(
            'KPI Journal — ยอดคีย์พนักงาน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards(KpiJournalLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            data: _CardData(
              title: 'Journal ทั้งหมด',
              value: NumberFormat('#,###').format(state.grandTotalJournals),
              icon: Icons.description_rounded,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            data: _CardData(
              title: 'จำนวนพนักงาน',
              value: '${state.grandTotalEmployees} คน',
              icon: Icons.people_rounded,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Filter Section ───────────────────────────────────────────────────────

  Widget _buildFilterSection(BuildContext context, KpiJournalLoaded state) {
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
              child: _buildSearchField(context, state.employees),
            ),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            _buildShopSelector(state.shops),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            _buildBookCodeSelector(state.employees),
            const SizedBox(width: 12),
            _buildFDivider(),
            const SizedBox(width: 12),
            //_buildCheckerSelector(state.allCheckers),
            //  const SizedBox(width: 12),
            //  _buildFDivider(),
            // const SizedBox(width: 12),
            // _buildUpdaterSelector(state.allUpdaters),
            //const SizedBox(width: 12),
            // _buildFDivider(),
            // const SizedBox(width: 12),
            _buildDateRange(context),
            const Spacer(),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFDivider() =>
      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0));

  Widget _buildBookCodeSelector(List<KpiJournalEmployee> employees) {
    final codes = <String>{};
    for (final emp in employees) {
      codes.addAll(emp.byBookCode.keys);
    }
    final items = (codes.toList()..sort())
        .map((c) => SearchableDropdownItem(id: c, label: c))
        .toList();
    return SearchableDropdown(
      fieldLabel: 'สมุดบัญชี',
      allLabel: 'ทั้งหมด',
      searchHint: 'ค้นหาสมุดบัญชี...',
      icon: Icons.menu_book_rounded,
      items: items,
      selectedId: _selectedBookCode,
      accentColor: const Color(0xFF6366F1),
      width: 160,
      onChanged: (id, _) => setState(() => _selectedBookCode = id),
    );
  }

  Widget _buildCheckerSelector(List<String> checkers) {
    final items = checkers
        .map((c) => SearchableDropdownItem(id: c, label: c))
        .toList();
    return SearchableDropdown(
      fieldLabel: 'ตรวจสอบโดย',
      allLabel: 'ทั้งหมด',
      searchHint: 'ค้นหาผู้ตรวจสอบ...',
      icon: Icons.verified_user_rounded,
      items: items,
      selectedId: _selectedChecker,
      accentColor: const Color(0xFF10B981),
      width: 160,
      onChanged: (id, _) => setState(() => _selectedChecker = id),
    );
  }

  Widget _buildUpdaterSelector(List<String> updaters) {
    final items = updaters
        .map((u) => SearchableDropdownItem(id: u, label: u))
        .toList();
    return SearchableDropdown(
      fieldLabel: 'แก้ไขโดย',
      allLabel: 'ทั้งหมด',
      searchHint: 'ค้นหาผู้แก้ไข...',
      icon: Icons.edit_rounded,
      items: items,
      selectedId: _selectedUpdater,
      accentColor: const Color(0xFFF59E0B),
      width: 160,
      onChanged: (id, _) => setState(() => _selectedUpdater = id),
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    List<KpiJournalEmployee> employees,
  ) {
    return RawAutocomplete<KpiJournalEmployee>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      displayStringForOption: (e) => e.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<KpiJournalEmployee>.empty();
        }
        final q = textEditingValue.text.toLowerCase();
        return employees.where((e) {
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
                                    _search(ctx);
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

  Widget _buildShopSelector(List<KpiJournalShopItem> shops) {
    final items = shops
        .map((s) => SearchableDropdownItem(id: s.shopId, label: s.shopName))
        .toList();
    return SearchableDropdown(
      fieldLabel: 'ร้าน',
      allLabel: 'ทุกร้าน',
      searchHint: 'ค้นหาร้าน...',
      icon: Icons.store_rounded,
      items: items,
      selectedId: (_selectedShopId?.isEmpty ?? true) ? null : _selectedShopId,
      onChanged: (id, label) => setState(() {
        _selectedShopId = id;
        _selectedShopName = label;
      }),
    );
  }

  Widget _buildDateRange(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDate(context, 'วันเริ่มต้น', _startDate, (d) {
          setState(() => _startDate = d);
          if (_endDate != null) _search(context);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 12,
            color: Colors.grey[300],
          ),
        ),
        _buildCompactDate(context, 'วันสิ้นสุด', _endDate, (d) {
          setState(() => _endDate = d);
          if (_startDate != null) _search(context);
        }),
      ],
    );
  }

  Widget _buildCompactDate(
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'รีเฟรชข้อมูล',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  context.read<KpiJournalBloc>().add(LoadKpiJournalData()),
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
            onTap: () => _search(context),
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

  // ─── Table ─────────────────────────────────────────────────────────────────

  // scroll controllers for header↔body sync
  final ScrollController _headerScroll = ScrollController();
  final ScrollController _bodyScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyScroll.addListener(() {
      if (_headerScroll.hasClients) _headerScroll.jumpTo(_bodyScroll.offset);
    });
  }

  List<DataRow> _buildDataRows(List<KpiJournalEmployee> pageEmployees) {
    final rows = <DataRow>[];
    for (var i = 0; i < pageEmployees.length; i++) {
      final emp = pageEmployees[i];
      final isExpanded = _expandedIds.contains(emp.name);
      rows.add(_empRow(emp, i, isExpanded));
      if (isExpanded) {
        final shops = emp.shopStats;
        for (var si = 0; si < shops.length; si++) {
          final stat = shops[si];
          final isLastShop = si == shops.length - 1;
          final shopKey = '${emp.name}::${stat.shopName}';
          final shopExpanded = _expandedIds.contains(shopKey);
          rows.add(_shopRow(emp, stat, shopKey, shopExpanded, isLastShop));
          if (shopExpanded) {
            final docs = stat.details.take(200).toList();
            for (var di = 0; di < docs.length; di++) {
              rows.add(
                _docRow(docs[di], emp.name, di == docs.length - 1, isLastShop),
              );
            }
          }
        }
      }
    }
    return rows;
  }

  DataRow _empRow(KpiJournalEmployee emp, int idx, bool isExpanded) {
    final fmt = NumberFormat('#,###');
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((s) {
        if (s.contains(WidgetState.hovered)) return const Color(0xFFEEF2FF);
        return idx.isEven ? Colors.white : const Color(0xFFF8FAFC);
      }),
      onSelectChanged: (_) => setState(() {
        if (isExpanded)
          _expandedIds.remove(emp.name);
        else
          _expandedIds.add(emp.name);
      }),
      cells: [
        // พนักงาน
        DataCell(
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                UserAvatar(name: emp.name, radius: KpiDimensions.avatarRadius),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emp.name,
                        style: KpiTextStyles.employeeName(_fontScale),
                        overflow: TextOverflow.ellipsis,
                      ),
                      /*if (emp.shopNames.isNotEmpty)
                        Text(
                          emp.shopNames.join(', '),
                          style: TextStyle(
                            fontSize: 9 * _fontScale,
                            color: const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),*/
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // คีย์
        DataCell(
          _numCell(
            emp.totalJournals,
            KpiColors.section1Background.withValues(alpha: 0.5),
            const Color(0xFF6366F1),
          ),
        ),
        // ตรวจสอบ
        DataCell(
          _numCell(
            emp.totalChecked,
            KpiColors.section3Background.withValues(alpha: 0.5),
            const Color(0xFF10B981),
          ),
        ),
        // แก้ไข
        DataCell(
          _numCell(
            emp.totalUpdated,
            KpiColors.section2Background.withValues(alpha: 0.5),
            const Color(0xFFF59E0B),
          ),
        ),
        // expand icon
        DataCell(
          Center(
            child: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _shopRow(
    KpiJournalEmployee emp,
    KpiJournalShopStat stat,
    String shopKey,
    bool isExpanded,
    bool isLast,
  ) {
    // dataRowHeight: 52 → half = 26
    const double half = 26.0;
    return DataRow(
      color: WidgetStateProperty.all(Colors.transparent),
      onSelectChanged: (_) => setState(() {
        if (isExpanded)
          _expandedIds.remove(shopKey);
        else
          _expandedIds.add(shopKey);
      }),
      cells: [
        // ร้าน (indented with tree lines)
        DataCell(
          Stack(
            fit: StackFit.expand,
            children: [
              // vertical guide line (emp level) — ├ or └
              Positioned(
                left: 24,
                top: 0,
                height: isLast ? half : null,
                bottom: isLast ? null : 0,
                child: Container(width: 1, color: const Color(0xFFD1D5DB)),
              ),
              // horizontal connector at mid-height
              Positioned(
                left: 25,
                top: half - 0.5,
                child: Container(
                  width: 15,
                  height: 1,
                  color: const Color(0xFFD1D5DB),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat.shopName,
                    style: TextStyle(
                      fontSize: 11 * _fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          _numCell(stat.count, Colors.transparent, const Color(0xFF6366F1)),
        ),
        DataCell(
          _numCell(
            stat.totalChecked,
            Colors.transparent,
            const Color(0xFF10B981),
          ),
        ),
        DataCell(
          _numCell(
            stat.totalUpdated,
            Colors.transparent,
            const Color(0xFFF59E0B),
          ),
        ),
        DataCell(
          Center(
            child: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _docRow(
    KpiJournalDetail d,
    String empName,
    bool isLast,
    bool parentIsLastShop,
  ) {
    final dStr = d.docDate != null ? _dateFmt.format(d.docDate!) : '—';
    const double half = 26.0;
    return DataRow(
      color: WidgetStateProperty.all(Colors.transparent),
      cells: [
        // doc info (indented with tree lines)
        DataCell(
          Stack(
            fit: StackFit.expand,
            children: [
              // emp-level vertical line — only if parent shop is NOT the last shop
              if (!parentIsLastShop)
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 1, color: const Color(0xFFD1D5DB)),
                ),
              // shop-level vertical line — ├ or └
              Positioned(
                left: 48,
                top: 0,
                height: isLast ? half : null,
                bottom: isLast ? null : 0,
                child: Container(width: 1, color: const Color(0xFFD1D5DB)),
              ),
              // horizontal connector at mid-height
              Positioned(
                left: 49,
                top: half - 0.5,
                child: Container(
                  width: 15,
                  height: 1,
                  color: const Color(0xFFD1D5DB),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Align(
                  alignment:
                      Alignment.centerLeft, // จัดเนื้อหาทั้งหมดให้ชิดซ้าย
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // จัด Text ภายใน Column ให้ชิดซ้าย
                    mainAxisSize:
                        MainAxisSize.min, // ใช้พื้นที่แนวตั้งเท่าที่จำเป็น
                    children: [
                      // --- บรรทัดแรก: docNo และ bookCode ---
                      Row(
                        mainAxisSize:
                            MainAxisSize.min, // ให้ Row กินพื้นที่เท่าที่จำเป็น
                        children: [
                          Flexible(
                            // ใช้ Flexible เพื่อให้ d.docNo ตัดคำได้ถ้าหน้าจอแคบ
                            child: Text(
                              d.docNo,
                              style: TextStyle(
                                fontSize: 11 * _fontScale,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ), // ระยะห่างระหว่าง docNo และ bookCode
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              d.bookCode,
                              style: TextStyle(
                                fontSize: 9 * _fontScale,
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 2,
                      ), // ระยะห่างระหว่างบรรทัด (ปรับได้ตามต้องการ)
                      // --- บรรทัดที่สอง: dStr ---
                      Text(
                        dStr,
                        style: TextStyle(
                          fontSize: 10 * _fontScale,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // คีย์
        DataCell(
          d.createdBy == empName
              ? Tooltip(
                  richMessage: TextSpan(
                    children: [
                      if (d.createdAt != null) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.access_time,
                            size: 14 * _fontScale,
                            color: Colors
                                .white, // สีไอคอนใน Tooltip (ปกติพื้นหลังจะมืด)
                          ),
                        ),
                        TextSpan(
                          text: ' ${_dtFmt.format(d.createdAt!)}',
                          style: TextStyle(fontSize: 12 * _fontScale),
                        ),
                      ],
                    ],
                  ),
                  child: _dot(const Color(0xFF6366F1), Colors.transparent),
                )
              : const SizedBox(),
        ),
        // ตรวจสอบ
        DataCell(
          d.checkedBy == empName
              ? Tooltip(
                  richMessage: TextSpan(
                    children: [
                      if (d.checkedAt != null) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.access_time,
                            size: 14 * _fontScale,
                            color: Colors
                                .white, // สีไอคอนใน Tooltip (ปกติพื้นหลังจะมืด)
                          ),
                        ),
                        TextSpan(
                          text: ' ${_dtFmt.format(d.checkedAt!)}',
                          style: TextStyle(fontSize: 12 * _fontScale),
                        ),
                      ],
                    ],
                  ),
                  child: _dot(const Color(0xFF10B981), Colors.transparent),
                )
              : const SizedBox(),
        ),
        // แก้ไข
        DataCell(
          d.updatedBy == empName
              ? Tooltip(
                  richMessage: TextSpan(
                    children: [
                      if (d.updatedAt != null) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.access_time,
                            size: 14 * _fontScale,
                            color: Colors
                                .white, // สีไอคอนใน Tooltip (ปกติพื้นหลังจะมืด)
                          ),
                        ),
                        TextSpan(
                          text: ' ${_dtFmt.format(d.updatedAt!)}',
                          style: TextStyle(fontSize: 12 * _fontScale),
                        ),
                      ],
                    ],
                  ),
                  child: _dot(const Color(0xFFF59E0B), Colors.transparent),
                )
              : const SizedBox(),
        ),
        const DataCell(SizedBox()),
      ],
    );
  }

  Widget _numCell(int value, Color bg, Color fg) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg),
    child: Text(
      value == 0 ? '—' : NumberFormat('#,###').format(value),
      style: TextStyle(
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w700,
        color: value == 0 ? const Color(0xFFCBD5E1) : fg,
      ),
    ),
  );

  Widget _dot(Color fg, Color bg) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg),
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '1',
          style: TextStyle(
            fontSize: 11 * _fontScale,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    ),
  );

  Widget _buildTable(KpiJournalLoaded state) {
    // ── filters ──
    final nameFiltered = _selectedEmployees.isEmpty
        ? state.filteredEmployees
        : state.filteredEmployees
              .where((e) => _selectedEmployees.any((s) => s.name == e.name))
              .toList();
    final bookFiltered = _selectedBookCode == null
        ? nameFiltered
        : nameFiltered
              .where((e) => e.byBookCode.containsKey(_selectedBookCode))
              .toList();
    final checkerFiltered = _selectedChecker == null
        ? bookFiltered
        : bookFiltered.where((e) => e.totalChecked > 0).toList();
    final displayEmployees = _selectedUpdater == null
        ? checkerFiltered
        : checkerFiltered.where((e) => e.totalUpdated > 0).toList();

    final filteredJournalCount = displayEmployees.fold(
      0,
      (s, e) => s + e.totalJournals,
    );
    final totalPages = (displayEmployees.length / _rowsPerPage).ceil().clamp(
      1,
      99999,
    );
    final effectivePage = (_currentPage > totalPages)
        ? totalPages
        : _currentPage;
    final start = (effectivePage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, displayEmployees.length);
    final pageEmployees = displayEmployees.sublist(start, end);
    final rows = _buildDataRows(pageEmployees);

    // header(48) + exact row count * dataRowHeight(52)
    const double dataRowH = 52.0;
    const double headerH = 48.0;
    final tableH = (headerH + rows.length * dataRowH + 2).clamp(200.0, 1400.0);

    return Container(
      decoration: BoxDecoration(
        color: KpiColors.cardBackground,
        borderRadius: BorderRadius.circular(KpiDimensions.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── card header bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'ยอดคีย์รายพนักงาน',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                _chipBadge(
                  icon: Icons.description_outlined,
                  label:
                      '${NumberFormat('#,###').format(filteredJournalCount)} รายการ',
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  textColor: const Color(0xFF1D4ED8),
                  iconColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 6),
                _chipBadge(
                  icon: Icons.person_outline_rounded,
                  label: '${displayEmployees.length} คน',
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  textColor: const Color(0xFF92400E),
                  iconColor: const Color(0xFFD97706),
                ),
                const Spacer(),
                _FontScaleButton(
                  currentScale: _fontScale,
                  onChanged: (s) => setState(() => _fontScale = s),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          if (displayEmployees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'ไม่พบข้อมูล',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: tableH,
              child: LayoutBuilder(
                builder: (ctx, bc) {
                  const double fixedW = 350.0;
                  const double minTableW = 900.0;
                  final double totalW = bc.maxWidth < minTableW
                      ? minTableW
                      : bc.maxWidth;
                  final double scrollW = totalW - fixedW;

                  return Column(
                    children: [
                      // ── data table ──
                      Expanded(
                        child: DataTable2(
                          border: TableBorder.all(
                            color: const Color(0xFFEEEEEE),
                            width: 1,
                          ),
                          columnSpacing: 0,
                          horizontalMargin: 0,
                          headingRowHeight: 48,
                          dataRowHeight: 52,
                          minWidth: totalW,
                          fixedLeftColumns: 1,
                          horizontalScrollController: _bodyScroll,
                          dividerThickness: 0,
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF8FAFC),
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11 * _fontScale,
                            color: const Color(0xFF374151),
                          ),
                          columns: [
                            DataColumn2(
                              label: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'พนักงาน',
                                      style: TextStyle(
                                        fontSize: 11 * _fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              size: ColumnSize.L,
                              fixedWidth: fixedW,
                            ),
                            DataColumn2(
                              label: _hCell(
                                'คีย์',
                                KpiColors.section1Background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: _hCell(
                                'ตรวจสอบ',
                                KpiColors.section3Background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            DataColumn2(
                              label: _hCell(
                                'แก้ไข',
                                KpiColors.section2Background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              size: ColumnSize.S,
                              numeric: true,
                            ),
                            const DataColumn2(
                              label: SizedBox(width: 40),
                              size: ColumnSize.S,
                              fixedWidth: 50,
                            ),
                          ],
                          rows: rows,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          if (displayEmployees.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPagination(
                currentPage: effectivePage,
                totalItems: displayEmployees.length,
                rowsPerPage: _rowsPerPage,
                onPageChanged: (p) => setState(() => _currentPage = p),
                onRowsPerPageChanged: (r) => setState(() {
                  _rowsPerPage = r;
                  _currentPage = 1;
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hCell(String text, Color bg) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg),
    child: Text(
      text,
      style: TextStyle(fontSize: 11 * _fontScale, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );

  Widget _groupLabel(String text, Color color) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.3),
      border: const Border(
        left: BorderSide(color: Colors.white),
        right: BorderSide(color: Colors.white),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11 * _fontScale,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF374151),
      ),
    ),
  );

  Widget _chipBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

// ─── Sub-Widgets ───────────────────────────────────────────────────────────

class _CardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _CardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FontScaleButton extends StatelessWidget {
  final double currentScale;
  final Function(double) onChanged;

  const _FontScaleButton({required this.currentScale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [1.0, 1.2, 1.4].map((scale) {
        final isActive = currentScale == scale;
        return GestureDetector(
          onTap: () => onChanged(scale),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scale == 1.0 ? '1x' : '${scale}x',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LastActiveWidget extends StatelessWidget {
  final DateTime? date;
  final double fontScale;

  const _LastActiveWidget({this.date, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Text('—', style: TextStyle(fontSize: 12 * fontScale));
    }
    final diff = DateTime.now().difference(date!);
    String label;
    if (diff.inMinutes < 60) {
      label = '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours} ชม. ที่แล้ว';
    } else {
      label = DateFormat('dd/MM/yy HH:mm').format(date!);
    }
    return Text(
      label,
      style: TextStyle(
        fontSize: 12 * fontScale,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}

class _ColSep extends StatelessWidget {
  const _ColSep();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xFFE2E8F0),
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double fontScale;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12 * fontScale,
          color: const Color(0xFFCBD5E1),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            NumberFormat('#,###').format(count),
            style: TextStyle(
              fontSize: 12 * fontScale,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
