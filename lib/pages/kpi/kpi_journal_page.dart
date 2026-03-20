import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../blocs/kpi_journal/kpi_journal_bloc.dart';
import '../../blocs/kpi_journal/kpi_journal_event.dart';
import '../../blocs/kpi_journal/kpi_journal_state.dart';
import '../../components/common/custom_pagination.dart';
import '../../components/common/user_avatar.dart';
import '../../components/dashboard_loading_widgets.dart';
import 'kpi_constants.dart';
import 'kpi_text_styles.dart';
import 'widgets/kpi_journal_filter_section.dart';

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
  List<KpiJournalEmployee> _filterEmployees = [];
  List<String> _filterBookCodes = [];
  List<String> _filterShopNames = [];
  int _currentPage = 1;
  int _rowsPerPage = 10;
  double _fontScale = 1.0;
  final Set<String> _expandedIds = {};

  static final _dateFmt = DateFormat('dd/MM/yy');
  static final _dtFmt = DateFormat('dd/MM/yy HH:mm ');

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
                            KpiJournalFilterSection(
                              employees: state.employees,
                              shops: state.shops,
                              onRefresh: () => ctx
                                  .read<KpiJournalBloc>()
                                  .add(LoadKpiJournalData()),
                              onSearch: (shopIds, shopNames, startDate, endDate) {
                                // 0 or 1 shop → server-side filter; 2+ → fetch all + client-side
                                final shopId = shopIds.length == 1 ? shopIds.first : null;
                                final shopName = shopNames.length == 1 ? shopNames.first : null;
                                setState(() => _filterShopNames =
                                    shopIds.length > 1 ? shopNames : []);
                                ctx.read<KpiJournalBloc>().add(
                                  SelectShopAndSearchJournal(
                                    shopId: shopId,
                                    shopName: shopName,
                                    startDate: startDate,
                                    endDate: endDate,
                                  ),
                                );
                              },
                              onLocalFilterChanged: (employees, bookCodes) {
                                setState(() {
                                  _filterEmployees = employees;
                                  _filterBookCodes = bookCodes;
                                });
                              },
                            ),
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

  /// Creates a new [KpiJournalEmployee] containing only journals whose
  /// [KpiJournalDetail.bookCode] is in [codes]. Totals are recalculated.
  KpiJournalEmployee _applyShopFilter(
    KpiJournalEmployee emp,
    List<String> shopNames,
  ) {
    if (shopNames.isEmpty) return emp;
    final filteredStats = emp.shopStats
        .where((stat) => shopNames.contains(stat.shopName))
        .toList();
    final allDetails = filteredStats.expand((s) => s.details).toList();
    final mergedByBookCode = filteredStats.fold<Map<String, int>>(
      {},
      (map, stat) {
        for (final entry in stat.byBookCode.entries) {
          map[entry.key] = (map[entry.key] ?? 0) + entry.value;
        }
        return map;
      },
    );
    return KpiJournalEmployee(
      name: emp.name,
      totalJournals: filteredStats.fold(0, (s, e) => s + e.count),
      totalDebit: allDetails.fold<double>(0, (s, d) => s + d.debit),
      totalCredit: allDetails.fold<double>(0, (s, d) => s + d.credit),
      byBookCode: mergedByBookCode,
      lastActive: emp.lastActive,
      details: allDetails,
      shopNames: filteredStats.map((s) => s.shopName).toList(),
      shopStats: filteredStats,
      totalChecked: filteredStats.fold(0, (s, e) => s + e.totalChecked),
      totalUpdated: filteredStats.fold(0, (s, e) => s + e.totalUpdated),
    );
  }

  KpiJournalEmployee _applyBookCodeFilter(
    KpiJournalEmployee emp,
    List<String> codes,
  ) {
    if (codes.isEmpty) return emp;
    final filteredStats = emp.shopStats
        .map((stat) {
          final filteredDetails =
              stat.details.where((d) => codes.contains(d.bookCode)).toList();
          if (filteredDetails.isEmpty) return null;
          return KpiJournalShopStat(
            shopName: stat.shopName,
            count: filteredDetails.length,
            byBookCode: Map.fromEntries(
                stat.byBookCode.entries.where((e) => codes.contains(e.key))),
            lastActive: filteredDetails
                .where((d) => d.createdAt != null)
                .map((d) => d.createdAt!)
                .fold<DateTime?>(null, (latest, d) =>
                    latest == null || d.isAfter(latest) ? d : latest),
            details: filteredDetails,
            totalChecked: filteredDetails
                .where((d) =>
                    d.checkedBy != null && d.checkedBy!.isNotEmpty)
                .length,
            totalUpdated: filteredDetails
                .where((d) =>
                    d.updatedBy != null && d.updatedBy!.isNotEmpty)
                .length,
          );
        })
        .whereType<KpiJournalShopStat>()
        .toList();
    final totalJournals =
        filteredStats.fold<int>(0, (s, e) => s + e.count);
    return KpiJournalEmployee(
      name: emp.name,
      totalJournals: totalJournals,
      totalDebit: filteredStats
          .expand((s) => s.details)
          .fold<double>(0, (s, d) => s + d.debit),
      totalCredit: filteredStats
          .expand((s) => s.details)
          .fold<double>(0, (s, d) => s + d.credit),
      byBookCode: Map.fromEntries(
          emp.byBookCode.entries.where((e) => codes.contains(e.key))),
      lastActive: emp.lastActive,
      details: filteredStats.expand((s) => s.details).toList(),
      shopNames: emp.shopNames,
      shopStats: filteredStats,
      totalChecked:
          filteredStats.fold(0, (s, e) => s + e.totalChecked),
      totalUpdated:
          filteredStats.fold(0, (s, e) => s + e.totalUpdated),
    );
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
    final nameFiltered = _filterEmployees.isEmpty
        ? state.filteredEmployees
        : state.filteredEmployees
              .where((e) => _filterEmployees.any((s) => s.name == e.name))
              .toList();
    // Multi-shop client-side filter (only active when 2+ shops selected)
    final shopFiltered = _filterShopNames.isNotEmpty
        ? nameFiltered
              .map((e) => _applyShopFilter(e, _filterShopNames))
              .where((e) => e.shopStats.isNotEmpty)
              .toList()
        : nameFiltered;
    // Multi-book-code client-side filter — deep-filter details & recalc totals
    final displayEmployees = _filterBookCodes.isEmpty
        ? shopFiltered
        : shopFiltered
              .map((e) => _applyBookCodeFilter(e, _filterBookCodes))
              .where((e) => e.totalJournals > 0)
              .toList();

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
