import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/kpi_combined/kpi_combined_bloc.dart';
import '../../blocs/kpi_combined/kpi_combined_event.dart';
import '../../blocs/kpi_combined/kpi_combined_state.dart';
import '../../components/common/custom_pagination.dart';
import '../../components/common/searchable_dropdown.dart';
import '../../components/common/user_avatar.dart';
import '../../components/dashboard_loading_widgets.dart';
import '../../models/kpi_combined_employee.dart';
import '../../services/auth_repository.dart';
import '../../services/employee_mapping_service.dart';
import '../../services/pdf_export_service.dart';
import 'kpi_constants.dart';

/// Merged KPI page — combines what used to be two separate pages (KPI and
/// KPI Journal) into one table, one filter bar, one fetch. Columns are
/// color-grouped so it's clear which numbers are about document *workflow
/// status* (from /task) versus actual *GL journal keying* (from
/// /gl/journal) — see KpiCombinedEmployee's doc comment for why
/// "ต้องบันทึก" appears twice with different colors (two different data
/// sources, not a mistake).
class KpiCombinedPage extends StatelessWidget {
  const KpiCombinedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KpiCombinedBloc()..add(const LoadKpiCombinedData()),
      child: const _KpiCombinedPageContent(),
    );
  }
}

class _KpiCombinedPageContent extends StatefulWidget {
  const _KpiCombinedPageContent();

  @override
  State<_KpiCombinedPageContent> createState() =>
      _KpiCombinedPageContentState();
}

class _KpiCombinedPageContentState extends State<_KpiCombinedPageContent> {
  // Multi-select employee filter (2026-07) — replaced the old single
  // free-text search box. Holds raw employee names (KpiCombinedEmployee.
  // name), same ids used as SearchableMultiDropdown item ids below.
  List<String> _selectedEmployeeIds = [];

  // Multi-select shop filter (2026-07) — replaced the old single-select
  // dropdown. The bloc/event side already accepted List<String> shopIds/
  // shopNames (SelectShopAndSearchCombined), so only this page's state and
  // the filter widget needed to change.
  List<String> _selectedShopIds = [];
  List<String> _selectedShopNames = [];

  DateTime? _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );

  int _currentPage = 1;
  int _rowsPerPage = 10;
  double _fontScale = 1.0;
  final Set<String> _expandedIds = {};
  final Set<String> _expandedShopKeys = {};
  final Set<String> _expandedTaskKeys = {};
  Map<String, String> _nameMappings = {};

  static final _dateFmt = DateFormat('dd/MM/yy');
  // Includes time-of-day, unlike _dateFmt — used specifically for the GL
  // row's "คีย์เมื่อ" stamp, since that's an action timestamp (createdat)
  // where the exact time matters, not just the calendar day.
  static final _dateTimeFmt = DateFormat('dd/MM/yy HH:mm');

  // Journal-side column group uses a distinct color from the task-workflow
  // group (which reuses KpiColors.section1/2/3Background) so the two data
  // sources are visually unmistakable, not just labeled.
  static const Color _journalGroupColor = Color(0xFFE0E7FF); // light indigo

  // Fixed column widths — kept as named constants (rather than scattered
  // magic numbers) because DataTable2 asserts totalFixedWidth < minWidth;
  // _minTableWidth below is derived from these so the two can never drift
  // out of sync and re-trigger that assertion.
  static const double _nameColWidth = 290;
  static const double _numColWidth = 90;
  // จำนวน..แก้ไข — 1 (จำนวน) + 5 (สถานะการตรวจสอบ) + 4 (สถานะการบันทึกบัญชี)
  // + 5 (บันทึกบัญชี GL: คีย์, คีย์(ไม่มีรูป), คีย์รวม, ตรวจสอบ, แก้ไข —
  // "ต้องบันทึก(รูปภาพ)" and "คงเหลือ(บันทึกบัญชี)" both removed 2026-07,
  // same shop-broadcast issue, see _buildColumns). Must match the actual
  // number of numeric DataColumn2s in _buildDataColumns exactly — this
  // drives _minTableWidth below, and DataTable2 asserts totalFixedWidth <
  // minWidth, so drifting out of sync (as happened 2026-07 when คีย์
  // (ไม่มีรูป)/คีย์รวม/คงเหลือ were added here without updating this count)
  // throws "totalFixedWidth < totalColAvailableWidth" and renders nothing
  // but a red error screen.
  static const int _numColCount = 15;
  static const double _expandColWidth = 50;
  static const double _minTableWidth =
      _nameColWidth +
      (_numColWidth * _numColCount) +
      _expandColWidth +
      130; // margin so DataTable2's "<" (not "<=") check always passes

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  @override
  void dispose() {
    _bodyScroll.dispose();
    super.dispose();
  }

  Future<void> _loadMappings() async {
    final mappings = await EmployeeMappingService.getAllMappings();
    if (mounted) setState(() => _nameMappings = mappings);
  }

  void _search(BuildContext ctx) {
    ctx.read<KpiCombinedBloc>().add(
      SelectShopAndSearchCombined(
        shopIds: _selectedShopIds,
        shopNames: _selectedShopNames,
        startDate: _startDate,
        endDate: _endDate,
        employeeNames: _selectedEmployeeIds,
      ),
    );
  }

  // Split into two single-date pickers (2026-07, replacing showDateRangePicker)
  // — matches a requested reference look (compact Material calendar dialog
  // per field, "วันเริ่มต้น"/"วันสิ้นสุด" as two separate boxes) rather than
  // one combined range field. showDatePicker's default calendar-entry-mode
  // dialog already renders this way (large selected-date header, month
  // nav, grid, ยกเลิก/ตกลง) since the app's MaterialLocalizations locale is
  // already set to th_TH — no custom picker widget needed.
  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 3),
      // Can't pick a start date after the current end date.
      lastDate: _endDate ?? DateTime(now.year + 1),
      helpText: 'เลือกวันเริ่มต้น',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final earliest = _startDate ?? DateTime(now.year - 3);
    final initial = _endDate != null && !_endDate!.isBefore(earliest)
        ? _endDate!
        : earliest;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // Can't pick an end date before the current start date.
      firstDate: earliest,
      lastDate: DateTime(now.year + 1),
      helpText: 'เลือกวันสิ้นสุด',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KpiCombinedBloc, KpiCombinedState>(
      listener: (context, state) {
        if (state is KpiCombinedError &&
            AuthRepository.isSessionExpiredError(state.message)) {
          context.read<AuthBloc>().add(LogoutRequested());
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: _buildAppBar(context),
              body: Builder(
                builder: (ctx) {
                  if (state is KpiCombinedLoading) {
                    return const DashboardLoadingWidget();
                  }
                  if (state is KpiCombinedError) {
                    return DashboardErrorWidget(
                      message: state.message,
                      onRetry: () => ctx.read<KpiCombinedBloc>().add(
                        const LoadKpiCombinedData(),
                      ),
                    );
                  }
                  if (state is KpiCombinedLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _selectedShopIds = [];
                          _selectedShopNames = [];
                          final now = DateTime.now();
                          _startDate = DateTime(now.year, now.month, 1);
                          _endDate = DateTime(now.year, now.month + 1, 0);
                        });
                        ctx.read<KpiCombinedBloc>().add(
                          const LoadKpiCombinedData(forceRefresh: true),
                        );
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(state),
                            const SizedBox(height: 16),
                            _buildFilterBar(ctx, state),
                            _buildActiveFilterSummary(),
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
            if (state is KpiCombinedLoaded && state.isSearching)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF8FAFC).withValues(alpha: 0.82),
                  child: const DashboardLoadingWidget(),
                ),
              ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: isMobile
          ? IconButton(
              tooltip: 'เปิดเมนู',
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155)),
              onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
            )
          : null,
      title: const Row(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            color: Color(0xFF3B82F6),
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'KPI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ─── Filter bar ─────────────────────────────────────────────────────────

  // Compact date field — label above, value below, calendar icon on the
  // left — matching SearchableDropdown's trigger styling so it reads as
  // part of the same family of filter controls, not a mismatched one-off.
  // Two of these (วันเริ่มต้น / วันสิ้นสุด) replaced the old single
  // "เลือกช่วงวันที่" range field per 2026-07 request, each opening its own
  // showDatePicker instead of one combined showDateRangePicker.
  Widget _dateField(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    double width = 150,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    date != null ? _dateFmt.format(date) : '-',
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
          ],
        ),
      ),
    );
  }

  // Filter bar spans the full page width (matching the summary cards/table
  // below it, both already full-width) instead of shrink-wrapping to the
  // sum of its children's widths — was previously only as wide as its
  // content, leaving a visible gap on wide screens. `Wrap` already handles
  // the responsive part: on narrow screens the controls flow onto extra
  // rows instead of overflowing, so no separate mobile layout is needed.
  Widget _buildFilterBar(BuildContext ctx, KpiCombinedLoaded state) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KpiDimensions.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final employeeWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth * 0.32).clamp(300.0, 420.0).toDouble();
            final shopWidth = isCompact ? constraints.maxWidth : 220.0;
            final dateWidth = isCompact
                ? (constraints.maxWidth - 24) / 2
                : 150.0;

            final filters = Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SearchableMultiDropdown(
                  fieldLabel: 'พนักงาน',
                  allLabel: 'ค้นหาชื่อพนักงาน...',
                  searchHint: 'ค้นหาพนักงาน...',
                  icon: Icons.person_search_rounded,
                  width: employeeWidth,
                  dropdownWidth: isCompact ? constraints.maxWidth : 280,
                  chipStyle: true,
                  items: state.employees
                      .map(
                        (e) => SearchableDropdownItem(
                          id: e.name,
                          label: _nameMappings[e.name] ?? e.name,
                        ),
                      )
                      .toList(),
                  selectedIds: _selectedEmployeeIds,
                  onChanged: (ids, labels) {
                    setState(() => _selectedEmployeeIds = ids);
                  },
                ),
                SearchableMultiDropdown(
                  fieldLabel: 'ร้าน',
                  allLabel: 'ทุกร้าน',
                  searchHint: 'ค้นหาร้าน...',
                  icon: Icons.store_outlined,
                  width: shopWidth,
                  dropdownWidth: isCompact ? constraints.maxWidth : 280,
                  items: state.shops
                      .map(
                        (s) => SearchableDropdownItem(
                          id: s.shopId,
                          label: s.shopName,
                        ),
                      )
                      .toList(),
                  selectedIds: _selectedShopIds,
                  onChanged: (ids, labels) {
                    setState(() {
                      _selectedShopIds = ids;
                      _selectedShopNames = labels;
                    });
                  },
                ),
                SizedBox(
                  width: dateWidth,
                  child: _dateField(
                    'วันเริ่มต้น',
                    _startDate,
                    () => _pickStartDate(context),
                    width: double.infinity,
                  ),
                ),
                if (!isCompact)
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                SizedBox(
                  width: dateWidth,
                  child: _dateField(
                    'วันสิ้นสุด',
                    _endDate,
                    () => _pickEndDate(context),
                    width: double.infinity,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 6,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: 'รีเฟรชข้อมูล',
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedShopIds = [];
                        _selectedShopNames = [];
                        _selectedEmployeeIds = [];
                        final now = DateTime.now();
                        _startDate = DateTime(now.year, now.month, 1);
                        _endDate = DateTime(now.year, now.month + 1, 0);
                      });
                      ctx.read<KpiCombinedBloc>().add(
                        const LoadKpiCombinedData(forceRefresh: true),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                Tooltip(
                  message: 'ดาวน์โหลด PDF',
                  child: IconButton(
                    onPressed: () => _exportPdf(state),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
                ),
                SizedBox(
                  width: isCompact ? constraints.maxWidth - 96 : null,
                  child: ElevatedButton.icon(
                    onPressed: state.isSearching ? null : () => _search(ctx),
                    icon: state.isSearching
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 18,
                          )
                        : const Icon(Icons.search_rounded, size: 16),
                    label: Text(state.isSearching ? 'กำลังค้นหา' : 'ค้นหา'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      disabledForegroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [filters, const SizedBox(height: 12), actions],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: filters),
                const SizedBox(width: 10),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilterSummary() {
    final parts = <String>[
      _selectedEmployeeIds.isEmpty
          ? 'พนักงานทั้งหมด'
          : '${_selectedEmployeeIds.length} พนักงาน',
      _selectedShopNames.isEmpty
          ? 'ทุกร้าน'
          : '${_selectedShopNames.length} ร้าน',
      '${_startDate != null ? _dateFmt.format(_startDate!) : '-'} - ${_endDate != null ? _dateFmt.format(_endDate!) : '-'}',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'กำลังดู:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          for (final part in parts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                part,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Summary cards ──────────────────────────────────────────────────────
  // Icon-badge stat cards — back to the softer, shadowed card style (per
  // reference screenshot) instead of the flat bordered strip.

  Widget _buildSummaryCards(KpiCombinedLoaded state) {
    final employees = state.filteredEmployees;
    int sum(int Function(KpiCombinedEmployee) f) =>
        employees.fold(0, (s, e) => s + f(e));

    final cards = <_SummaryCardData>[
      _SummaryCardData(
        label: 'คงเหลือ',
        value: state.filteredRemainingDocuments,
        bg: const Color(0xFFFFEDD5),
        accent: const Color(0xFFF97316),
        icon: Icons.priority_high_rounded,
      ),
      _SummaryCardData(
        label: 'จำนวนบิลทั้งหมด',
        value: sum((e) => e.totalDocuments),
        bg: KpiColors.section1Background,
        accent: const Color(0xFF0EA5E9),
        icon: Icons.description_outlined,
      ),
      _SummaryCardData(
        label: 'รอตรวจ',
        value: sum((e) => e.waitingVerify),
        bg: const Color(0xFFFEF3C7),
        accent: const Color(0xFFCA8A04),
        icon: Icons.hourglass_bottom_rounded,
      ),
      _SummaryCardData(
        label: 'ต้องบันทึกทั้งหมด',
        value: sum((e) => e.requiredToRecordDocuments),
        bg: const Color(0xFFDCFCE7),
        accent: const Color(0xFF10B981),
        icon: Icons.assignment_turned_in_outlined,
      ),
      _SummaryCardData(
        label: 'บันทึกแล้ว (จากสถานะงาน)',
        value: sum((e) => e.recordedDocuments),
        bg: const Color(0xFFDCFCE7),
        accent: const Color(0xFF22C55E),
        icon: Icons.check_circle_outline_rounded,
      ),
      _SummaryCardData(
        label: 'คีย์บัญชีแล้ว',
        value: sum((e) => e.totalJournals),
        bg: const Color(0xFFE0E7FF),
        accent: const Color(0xFF6366F1),
        icon: Icons.playlist_add_check_rounded,
      ),
      _SummaryCardData(
        label: 'คีย์บัญชีแล้ว (ไม่มีรูป)',
        value: sum((e) => e.totalJournalsNoPhoto),
        bg: const Color(0xFFFEE2E2),
        accent: const Color(0xFFEF4444),
        icon: Icons.no_photography_outlined,
      ),
      _SummaryCardData(
        label: 'คีย์รวม',
        value: sum((e) => e.totalJournalsCombined),
        bg: const Color(0xFFEDE9FE),
        accent: const Color(0xFF7C3AED),
        icon: Icons.functions_rounded,
      ),
      _SummaryCardData(
        // Deliberately a SEPARATE card from "จำนวนบิลทั้งหมด" (cards[1]),
        // not a replacement — totalUploaded (who personally uploaded the
        // photo) and totalDocuments (documents in tasks this
        // employee/shop OWNS) answer different questions and aren't
        // guaranteed to relate to each other (an employee can upload into
        // tasks they don't own at all). The other cards here (คงเหลือ/
        // รอตรวจ/ต้องบันทึกทั้งหมด) are task-workflow STATUS figures with
        // no per-uploader breakdown in the underlying data (/task's
        // totalDocumentStatus is per-task, not per-image-uploader), so
        // they stay task-based regardless of which employee is filtered —
        // replacing "จำนวนบิลทั้งหมด" with an upload count would make
        // those cards visually disagree with the top card for no real
        // reason. 2026-08.
        label: 'รูปที่อัปโหลด',
        value: sum((e) => e.totalUploaded),
        bg: const Color(0xFFE0F2FE),
        accent: const Color(0xFF0369A1),
        icon: Icons.upload_file_outlined,
      ),
    ];
    final visibleCards = [
      cards[1], // จำนวนบิลทั้งหมด
      cards[8], // รูปที่อัปโหลด
      cards[0], // คงเหลือ
      cards[2], // รอตรวจ
      cards[3], // ต้องบันทึกทั้งหมด
      cards[7], // คีย์รวม
    ];

    return LayoutBuilder(
      builder: (ctx, bc) {
        if (bc.maxWidth > 1180) {
          // Generated from visibleCards instead of one hardcoded Expanded
          // per index (was 5 fixed slots) — 2026-08, when a 6th card
          // (uploaded photos) was added, so a future card count change
          // doesn't require hand-editing this Row to match.
          final children = <Widget>[];
          for (var i = 0; i < visibleCards.length; i++) {
            if (i > 0) children.add(const SizedBox(width: 12));
            children.add(
              Expanded(
                child: _summaryCard(
                  visibleCards[i],
                  priority: true,
                  loading: !state.summaryReady,
                ),
              ),
            );
          }
          return Row(children: children);
        }

        final perRow = bc.maxWidth > 900 ? 3 : (bc.maxWidth > 560 ? 2 : 1);
        final gap = 12.0 * (perRow - 1);
        final cardWidth = (bc.maxWidth - gap) / perRow;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: visibleCards
              .map(
                (c) => SizedBox(
                  width: cardWidth,
                  child: _summaryCard(c, loading: !state.summaryReady),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(
    _SummaryCardData c, {
    bool priority = false,
    bool loading = false,
  }) {
    final fmt = NumberFormat('#,###');
    return Container(
      constraints: BoxConstraints(minHeight: priority ? 94 : 80),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priority ? c.bg.withValues(alpha: 0.55) : Colors.white,
        borderRadius: BorderRadius.circular(KpiDimensions.cardBorderRadius),
        border: Border.all(
          color: priority
              ? c.accent.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: priority ? Colors.white.withValues(alpha: 0.85) : c.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: c.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: c.accent,
                    size: 28,
                  )
                else
                  Text(
                    fmt.format(c.value),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: KpiColors.primaryText,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PDF export ─────────────────────────────────────────────────────────

  Future<void> _exportPdf(KpiCombinedLoaded state) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('กำลังสร้างไฟล์ PDF...'),
          ],
        ),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 2),
      ),
    );

    const subHeaders = [
      'ร้าน',
      'จำนวน',
      'รูปที่อัปโหลด',
      'รอตรวจสอบ',
      'ผ่าน',
      'ไม่ผ่าน',
      'ไม่บันทึก',
      'ไม่ต้องอนุมัติ',
      'ต้องบันทึก(งาน)',
      'บันทึกแล้ว(งาน)',
      'คงเหลือ',
      'เสร็จ',
      'คีย์',
      'คีย์(ไม่มีรูป)',
      'คีย์รวม',
      'ตรวจสอบ',
      'แก้ไข',
    ];

    final groups = state.filteredEmployees.map((emp) {
      final displayName = _nameMappings[emp.name] ?? emp.name;
      final shopRows = emp.shopStats
          .map((s) => _pdfShopRow(state, s))
          .toList();
      final rows = <List<String>>[];
      final contextRowIndexes = <int>{};
      final employeeExpanded = _expandedIds.contains(emp.name);

      for (var si = 0; si < emp.shopStats.length; si++) {
        final shop = emp.shopStats[si];
        rows.add(shopRows[si]);

        final shopKey = _shopKey(emp.name, shop.shopName);
        final shopExpanded = _expandedShopKeys.contains(shopKey);
        final detailReady = state.detailLoadedShopNames.contains(shop.shopName);
        if (!employeeExpanded || !shopExpanded || !detailReady) continue;

        for (var ti = 0; ti < shop.tasks.length; ti++) {
          final task = shop.tasks[ti];
          if (!task.isOwner) contextRowIndexes.add(rows.length);
          rows.add(_pdfTaskRow(task));

          final taskKey = '$shopKey#$ti';
          if (_expandedTaskKeys.contains(taskKey)) {
            rows.addAll(task.journalEntries.map(_pdfJournalRow));
          }
        }
        rows.addAll(
          shop.orphanJournalEntries.map(
            (journal) => _pdfJournalRow(journal, orphan: true),
          ),
        );
      }

      return KpiPdfGroup(
        name: displayName,
        summary:
            'เอกสาร ${emp.totalDocuments} · คีย์บัญชี ${emp.totalJournals} รายการ',
        rows: rows,
        totalRows: shopRows,
        contextRowIndexes: contextRowIndexes,
        showColumnTotals: true,
      );
    }).toList();

    try {
      await PdfExportService.exportGroupedTableToPdf(
        title: 'รายงาน KPI',
        subHeaders: subHeaders,
        groups: groups,
        startDate: _startDate,
        endDate: _endDate,
        userName: AuthRepository.username ?? 'ผู้ใช้งาน',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้าง PDF ไม่สำเร็จ: $error'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<String> _pdfShopRow(
    KpiCombinedLoaded state,
    KpiCombinedShopStat shop,
  ) => [
    shop.shopName,
    '${shop.totalDocuments}',
    '${shop.uploadedCount}',
    '${shop.waitingVerify}',
    '${shop.passed}',
    '${shop.cancelled}',
    '${shop.notRecorded}',
    '${shop.notRequiredApproval}',
    '${shop.requiredToRecord}',
    '${shop.recorded}',
    '${shop.remaining}',
    '${shop.completed}',
    '${shop.journalCount}',
    (state.summaryReady ||
            state.detailLoadedShopNames.contains(shop.shopName))
        ? '${shop.journalCountNoPhoto}'
        : '-',
    '${shop.journalCountTotal}',
    '${shop.journalChecked}',
    '${shop.journalUpdated}',
  ];

  List<String> _pdfTaskRow(KpiCombinedTaskItem task) {
    final label = task.taskName.trim().isNotEmpty
        ? task.taskName
        : task.taskCode;
    final keyed = task.journalEntries.where((journal) {
      if (journal.createdBy.isEmpty) return false;
      if (!task.isOwner) return true;
      return journal.createdBy.trim() == task.ownerBy.trim();
    }).length;
    final checked = task.journalEntries
        .where((journal) => journal.checkedBy.isNotEmpty)
        .length;
    final updated = task.journalEntries
        .where((journal) => journal.updatedBy.isNotEmpty)
        .length;

    return [
      '  งาน: $label (${_dateFmt.format(task.ownerAt)})',
      '${task.totalDocument}',
      '-', // รูปที่อัปโหลด — tracked per shop/employee only, not per task
      '${task.waitingVerify}',
      '${task.passed}',
      '${task.cancelled}',
      '${task.notRecorded}',
      '${task.notRequiredApproval}',
      '${task.requiredToRecord}',
      '${task.recorded}',
      '${task.remaining}',
      '${task.completed}',
      '$keyed',
      '0',
      '$keyed',
      '$checked',
      '$updated',
    ];
  }

  List<String> _pdfJournalRow(
    KpiCombinedJournalItem journal, {
    bool orphan = false,
  }) {
    final hasDocumentRef = (journal.documentRef ?? '').trim().isNotEmpty;
    final noPhoto =
        (journal.resolvedTaskGuid == null ||
            journal.resolvedTaskGuid!.trim().isEmpty) &&
        !hasDocumentRef;
    final labelPrefix = orphan ? '    รายการไม่ผูกงาน' : '    รายการ';

    return [
      '$labelPrefix: ${journal.docNo} · ${journal.accountName}',
      '1',
      '-', // รูปที่อัปโหลด — tracked per shop/employee only, not per journal entry
      ...List.generate(9, (_) => '0'),
      journal.createdBy.isNotEmpty && !noPhoto ? '1' : '0',
      journal.createdBy.isNotEmpty && noPhoto ? '1' : '0',
      journal.createdBy.isNotEmpty ? '1' : '0',
      journal.checkedBy.isNotEmpty ? '1' : '0',
      journal.updatedBy.isNotEmpty ? '1' : '0',
    ];
  }

  // ─── Table ──────────────────────────────────────────────────────────────

  final ScrollController _bodyScroll = ScrollController();

  Widget _buildTable(KpiCombinedLoaded state) {
    final employees = state.filteredEmployees;
    final totalPages = (employees.length / _rowsPerPage).ceil().clamp(1, 99999);
    final effectivePage = _currentPage > totalPages ? totalPages : _currentPage;
    final start = (effectivePage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, employees.length);
    final pageEmployees = employees.sublist(start, end);
    final rows = _buildDataRows(state, pageEmployees);

    // Base 62 (was 52) so the GL journal drill-down row (_journalRow) can
    // wrap its doc/account name and its amount/keyer/date meta onto two
    // lines instead of squeezing both onto one line with heavy ellipsis.
    // Employee/shop/task name labels were later also switched from
    // single-line-ellipsis to 2-line-wrap (no more trailing ".."), so the
    // row needs to grow a bit further at larger font-scale settings too —
    // DataTable2 only supports one row height for every row, so this has
    // to cover the worst case (2 wrapped lines at 1.4x) for every row, not
    // just the ones that actually wrap. Bumped 62 -> 84 to additionally
    // fit _journalRow's optional link-status line (showLinkStatus) for
    // orphan entries without a "BOTTOM OVERFLOWED BY N PIXELS" render
    // error — that line only appears on orphan rows, but DataTable2 can't
    // vary height per row, so every row pays for the extra headroom. Bumped
    // 84 -> 96 when the date was split off amount/keyer onto its own line
    // (was getting ellipsised away by long keyer emails).
    final double dataRowH = 96.0 + (_fontScale - 1.0) * 30;
    const double headerH =
        64.0; // taller to fit the group-banner + label two-row header
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'รายชื่อพนักงาน',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                _fontScaleToggle(),
                _countPill('ทั้งหมด ${employees.length} คน'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Row(
              children: [
                _legendDot(KpiColors.section1Background, 'เอกสาร'),
                const SizedBox(width: 8),
                _legendDot(_journalGroupColor, 'บันทึกบัญชี'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (employees.isEmpty)
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
          else if (MediaQuery.sizeOf(context).width < 720)
            _buildCompactEmployeeCards(state, pageEmployees)
          else
            SizedBox(
              height: tableH,
              child: LayoutBuilder(
                builder: (ctx, bc) {
                  final double totalW = bc.maxWidth < _minTableWidth
                      ? _minTableWidth
                      : bc.maxWidth;
                  return DataTable2(
                    border: TableBorder.all(
                      color: const Color(0xFFEEEEEE),
                      width: 1,
                    ),
                    columnSpacing: 0,
                    horizontalMargin: 0,
                    headingRowHeight: 64,
                    dataRowHeight: dataRowH,
                    minWidth: totalW,
                    fixedLeftColumns: 1,
                    horizontalScrollController: _bodyScroll,
                    dividerThickness: 0,
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: _buildColumns(),
                    rows: rows,
                  );
                },
              ),
            ),
          if (employees.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomPagination(
                currentPage: effectivePage,
                totalItems: employees.length,
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildCompactEmployeeCards(
    KpiCombinedLoaded state,
    List<KpiCombinedEmployee> employees,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: employees.map((emp) {
          final isExpanded = _expandedIds.contains(emp.name);
          final displayName = _nameMappings[emp.name] ?? emp.name;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(emp.name);
                    } else {
                      _expandedIds.add(emp.name);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: displayName,
                          radius: KpiDimensions.avatarRadius,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: KpiColors.primaryText,
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${emp.shopStats.length} ร้าน · ${_totalTaskCount(emp)} งาน',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _compactMetric(
                        'เอกสาร',
                        emp.totalDocuments,
                        KpiColors.section1Background,
                      ),
                      _compactMetric(
                        'รอตรวจสอบ',
                        emp.waitingVerify,
                        KpiColors.section2Background,
                      ),
                      _compactMetric(
                        'ต้องบันทึก(งาน)',
                        emp.requiredToRecordDocuments,
                        KpiColors.section3Background,
                      ),
                      _compactMetric(
                        'บันทึกแล้ว(งาน)',
                        emp.recordedDocuments,
                        KpiColors.section3Background,
                      ),
                      _compactMetric(
                        'ยอดคีย์ทั้งหมด',
                        emp.totalJournalsCombined,
                        _journalGroupColor,
                      ),
                      _compactMetric(
                        'คีย์ไม่มีรูป',
                        _employeeNoPhotoResolved(state, emp)
                            ? emp.totalJournalsNoPhoto
                            : null,
                        _journalGroupColor,
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  for (final shop in emp.shopStats) _compactShopRow(shop),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _compactMetric(String label, int? value, Color bg) {
    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null || value == 0
                ? '—'
                : NumberFormat('#,###').format(value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: KpiColors.primaryText,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _compactShopRow(KpiCombinedShopStat shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.shopName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _compactPill('เอกสาร ${shop.totalDocuments}'),
              _compactPill('รอ ${shop.waitingVerify}'),
              _compactPill('คงเหลืองาน ${shop.remaining}'),
              _compactPill('คีย์รวม ${shop.journalCountTotal}'),
              _compactPill('คงเหลือบัญชี ${shop.journalRemaining}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Zoom the table's text size up/down without changing layout — handy on
  // large screens or for anyone who wants bigger numbers to read.
  Widget _fontScaleToggle() {
    const options = [1.0, 1.2, 1.4];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((v) {
          final selected = _fontScale == v;
          return InkWell(
            onTap: () => setState(() => _fontScale = v),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${v}x'.replaceFirst('.0x', 'x'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _countPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }

  // Total number of underlying task rows across every shop this employee
  // has activity in — lets the employee row show "how many tasks" without
  // having to expand every shop underneath it to count.
  int _totalTaskCount(KpiCombinedEmployee emp) =>
      emp.shopStats.fold(0, (sum, s) => sum + s.tasks.length);

  // Small inline badge showing how many task rows are nested under a
  // (still collapsed, possibly) employee or shop row.
  Widget _taskCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count งาน',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  // Badge showing how many images this employee personally uploaded
  // (emp.totalUploaded / s.uploadedCount — see KpiCombinedShopStat.
  // uploadedCount doc comment) — deliberately a DIFFERENT color from
  // _taskCountBadge so "how many tasks" and "how many photos uploaded"
  // aren't visually confused; an employee can have uploads without owning
  // any task at all. 2026-08.
  Widget _uploadCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'อัปโหลด $count รูป',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0369A1),
        ),
      ),
    );
  }

  // Badge for a shop row that has GL journal activity but no task rows at
  // all (see orphanJournalEntries) — styled with the journal group's color
  // instead of the neutral task badge so it reads as "these come from the
  // บันทึกบัญชี side only, not a task", not just a smaller task count.
  Widget _orphanCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _journalGroupColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count คีย์ (ไม่ผูกงาน)',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }

  List<DataColumn2> _buildColumns() {
    // Two-row header: the group banner is painted once by the first column
    // in a group and deliberately spans its full width. DataTable2 does not
    // support merged header cells, so letting text overflow across opaque
    // neighboring cells makes it disappear when centered.
    // [tooltip] added 2026-07 so columns whose meaning isn't obvious from
    // a 1-2 word header (e.g. the two differently-sourced "ต้องบันทึก"
    // columns, or "คีย์"/"คีย์รวม" counting GL lines rather than
    // documents) can explain themselves on hover instead of relying on
    // users remembering a table-wide convention or filing a "these
    // numbers don't match" report.
    DataColumn2 col(
      String label,
      Color bg, {
      double size = _numColWidth,
      String? groupLabel,
      double? groupWidth,
      bool groupContinuation = false,
      String? tooltip,
    }) {
      final header = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 20,
              child: groupLabel != null
                  ? OverflowBox(
                      minWidth: groupWidth,
                      maxWidth: groupWidth,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: groupWidth,
                        child: ColoredBox(
                          color: bg,
                          child: Center(
                            child: Text(
                              groupLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    )
                  : groupContinuation
                  ? const SizedBox()
                  : ColoredBox(color: bg),
            ),
            Expanded(
              child: ColoredBox(
                color: bg,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (tooltip != null) ...[
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
      );
      return DataColumn2(
        label: tooltip != null
            ? Tooltip(
                message: tooltip,
                textStyle: const TextStyle(fontSize: 11, color: Colors.white),
                child: header,
              )
            : header,
        size: ColumnSize.S,
        numeric: true,
        fixedWidth: size,
      );
    }

    return [
      // Deliberately NOT fixedWidth — every other column below is
      // fixedWidth, and data_table_2's _calculateDataColumnSizes only ever
      // stretches columns that AREN'T fixedWidth to fill leftover space
      // (see its ColumnSize/ratio logic). With every column fixed, the
      // table always rendered at exactly the sum of the fixed widths
      // (~1690px) no matter how wide the browser window was, leaving a
      // dead gap on both sides instead of actually filling the screen.
      // Making this one column (size: L) flexible lets it absorb all of
      // that leftover width — matches the well-known pattern for
      // DataTable2 (fixed numeric columns + one flexible text column).
      DataColumn2(
        label: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'พนักงาน',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
        size: ColumnSize.L,
        minWidth: _nameColWidth,
      ),
      // เอกสาร (task workflow) — "จำนวน" stands alone, no group banner.
      col('จำนวน', KpiColors.section1Background),
      // สถานะการตรวจสอบ (5 cols).
      col(
        'รอตรวจสอบ',
        KpiColors.section2Background,
        groupLabel: 'สถานะการตรวจสอบ',
        groupWidth: _numColWidth * 5,
      ),
      col('ผ่าน', KpiColors.section2Background, groupContinuation: true),
      col('ไม่ผ่าน', KpiColors.section2Background, groupContinuation: true),
      col('ไม่บันทึก', KpiColors.section2Background, groupContinuation: true),
      col('ไม่ต้องอนุมัติ', KpiColors.section2Background, groupContinuation: true),
      // สถานะการบันทึกบัญชี (4 cols).
      col(
        'ต้องบันทึก\n(งาน)',
        KpiColors.section3Background,
        groupLabel: 'สถานะการบันทึกบัญชี',
        groupWidth: _numColWidth * 4,
        tooltip: 'คำนวณจากสถานะของงาน (task) ฝั่ง /task',
      ),
      col(
        'บันทึกแล้ว\n(งาน)',
        KpiColors.section3Background,
        groupContinuation: true,
      ),
      col('คงเหลือ', KpiColors.section3Background, groupContinuation: true),
      col('เสร็จ', KpiColors.section3Background, groupContinuation: true),
      // บันทึกบัญชี (GL journal, 5 cols) — "ต้องบันทึก(รูปภาพ)" and
      // "คงเหลือ(บันทึกบัญชี)" both removed 2026-07: both were derived from
      // journalRequiredDocs, a shop-wide /documentimagegroup total
      // broadcast identically onto every employee/task row (not
      // attributable to a specific person/task), so they read as
      // inconsistent next to the per-person "คีย์" figures.
      // journalRequiredDocs/journalRemaining are kept as fields on
      // KpiCombinedEmployee/KpiCombinedShopStat (still used by the mobile
      // compact shop row) even though no longer shown as table columns.
      col(
        'คีย์',
        _journalGroupColor,
        groupLabel: 'บันทึกบัญชี (GL)',
        groupWidth: _numColWidth * 5,
        tooltip:
            'นับจากจำนวนบรรทัดใน GL journal ไม่ใช่จำนวนเอกสาร — '
            'ใบสำคัญ 1 ใบอาจมีทั้งบรรทัดเดบิตและเครดิต ทำให้ตัวเลขนี้อาจมากกว่า '
            'จำนวนเอกสารจริง',
      ),
      // Split out of "คีย์" (2026-07): entries keyed with no jobguidfixed
      // AND no documentimagegroup photo reference at all — no evidence
      // behind the entry, as opposed to a photo that exists but whose task
      // couldn't be resolved (those stay counted in "คีย์").
      col(
        'คีย์\n(ไม่มีรูป)',
        _journalGroupColor,
        groupContinuation: true,
        tooltip:
            'รายการที่คีย์เข้ามาโดยไม่มีรูป/เอกสารอ้างอิงใดๆ เลย — '
            'แยกออกจาก "คีย์" เพื่อไม่ให้ปนกับรายการที่มีหลักฐานแต่แค่ยังหางานไม่เจอ',
      ),
      // Summary pair requested 2026-07 to speed up reading the GL group at
      // a glance instead of adding คีย์+คีย์(ไม่มีรูป) manually every time.
      col(
        'คีย์รวม',
        _journalGroupColor,
        groupContinuation: true,
        tooltip:
            '= คีย์ + คีย์(ไม่มีรูป) — นับรวมทุกบรรทัดที่คีย์เข้ามา ไม่ว่าจะมีหลักฐานหรือไม่',
      ),
      col('ตรวจสอบ', _journalGroupColor, groupContinuation: true),
      col('แก้ไข', _journalGroupColor, groupContinuation: true),
      const DataColumn2(
        label: SizedBox(width: 40),
        size: ColumnSize.S,
        fixedWidth: _expandColWidth,
      ),
    ];
  }

  String _shopKey(String empName, String shopName) => '$empName $shopName';

  List<DataRow> _buildDataRows(
    KpiCombinedLoaded state,
    List<KpiCombinedEmployee> pageEmployees,
  ) {
    final rows = <DataRow>[];
    for (var i = 0; i < pageEmployees.length; i++) {
      final emp = pageEmployees[i];
      final isExpanded = _expandedIds.contains(emp.name);
      rows.add(_empRow(state, emp, i, isExpanded));
      if (isExpanded) {
        for (var si = 0; si < emp.shopStats.length; si++) {
          final shop = emp.shopStats[si];
          final isLastShop = si == emp.shopStats.length - 1;
          final shopKey = _shopKey(emp.name, shop.shopName);
          final shopExpanded = _expandedShopKeys.contains(shopKey);
          rows.add(
            _shopRow(
              state,
              emp.name,
              shop,
              shopExpanded,
              isLast: isLastShop && !shopExpanded,
            ),
          );
          if (shopExpanded) {
            if (state.detailLoadingShopNames.contains(shop.shopName)) {
              rows.add(_detailStatusRow('กำลังโหลดรายละเอียด...'));
              continue;
            }
            if (state.detailErrorShopNames.contains(shop.shopName)) {
              rows.add(
                _detailStatusRow(
                  'โหลดรายละเอียดไม่สำเร็จ กดร้านนี้อีกครั้งเพื่อลองใหม่',
                ),
              );
              continue;
            }
            if (!state.detailLoadedShopNames.contains(shop.shopName)) {
              rows.add(_detailStatusRow('กำลังเตรียมรายละเอียด...'));
              continue;
            }
            for (var ti = 0; ti < shop.tasks.length; ti++) {
              final t = shop.tasks[ti];
              final taskKey = '$shopKey#$ti';
              final taskExpanded = _expandedTaskKeys.contains(taskKey);
              final isLastTask =
                  ti == shop.tasks.length - 1 &&
                  shop.orphanJournalEntries.isEmpty;
              rows.add(
                _taskRow(
                  taskKey,
                  t,
                  taskExpanded,
                  isLast: isLastTask && !taskExpanded,
                ),
              );
              if (taskExpanded) {
                for (var gi = 0; gi < t.journalEntries.length; gi++) {
                  final g = t.journalEntries[gi];
                  rows.add(
                    _journalRow(g, isLast: gi == t.journalEntries.length - 1),
                  );
                }
              }
            }
            // GL entries that count toward this shop's คีย์/ตรวจสอบ/แก้ไข
            // totals but don't trace back to any task above — surfaced
            // directly under the shop (same indent depth as a task row)
            // instead of being an invisible dead end when the shop has no
            // task rows to expand at all.
            for (var gi = 0; gi < shop.orphanJournalEntries.length; gi++) {
              final g = shop.orphanJournalEntries[gi];
              rows.add(
                _journalRow(
                  g,
                  indent: 50,
                  showLinkStatus: true,
                  isLast: gi == shop.orphanJournalEntries.length - 1,
                ),
              );
            }
          }
        }
      }
    }
    return rows;
  }

  Widget _treeCell({
    required int level,
    required Widget child,
    bool isLast = false,
    double rowHeight = 84,
  }) {
    return Row(
      children: [
        CustomPaint(
          size: Size(18 + (level * 22), rowHeight),
          painter: _TreeConnectorPainter(level: level, isLast: isLast),
        ),
        Expanded(child: child),
      ],
    );
  }

  DataRow _empRow(
    KpiCombinedLoaded state,
    KpiCombinedEmployee emp,
    int index,
    bool isExpanded,
  ) {
    final displayName = _nameMappings[emp.name] ?? emp.name;
    final context = _employeeContributorContext(emp);
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((s) {
        if (s.contains(WidgetState.hovered)) return const Color(0xFFEFF6FF);
        return index.isEven ? Colors.white : const Color(0xFFF8FAFC);
      }),
      onSelectChanged: (_) => setState(() {
        if (isExpanded) {
          _expandedIds.remove(emp.name);
          // Cascade-collapse: also close any shop/task drill-downs left
          // open underneath this employee — otherwise re-expanding the
          // employee later silently re-opens whatever shop/task was
          // expanded before instead of starting from a fresh collapsed
          // state (reported: reopening after a collapse showed the exact
          // same drilled-down GL rows as the first time it was opened).
          _expandedShopKeys.removeWhere((k) => k.startsWith('${emp.name} '));
          _expandedTaskKeys.removeWhere((k) => k.startsWith('${emp.name} '));
        } else {
          _expandedIds.add(emp.name);
        }
      }),
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                UserAvatar(
                  name: displayName,
                  radius: KpiDimensions.avatarRadius,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12 * _fontScale,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                  ),
                ),
                if (_totalTaskCount(emp) > 0) ...[
                  _taskCountBadge(_totalTaskCount(emp)),
                  const SizedBox(width: 6),
                ],
                if (emp.totalUploaded > 0) ...[
                  _uploadCountBadge(emp.totalUploaded),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        _aggregateWorkCell(emp.totalDocuments, context.totalDocuments),
        _aggregateWorkCell(emp.waitingVerify, context.waitingVerify),
        _aggregateWorkCell(emp.passedDocuments, context.passed),
        _aggregateWorkCell(emp.cancelledDocuments, context.cancelled),
        _aggregateWorkCell(emp.notRecordedDocuments, context.notRecorded),
        _aggregateWorkCell(
          emp.notRequiredApprovalDocuments,
          context.notRequiredApproval,
        ),
        _aggregateWorkCell(
          emp.requiredToRecordDocuments,
          context.requiredToRecord,
        ),
        _aggregateWorkCell(emp.recordedDocuments, context.recorded),
        _aggregateWorkCell(emp.remainingDocuments, context.remaining),
        _aggregateWorkCell(emp.completedDocuments, context.completed),
        _numCell(emp.totalJournals),
        _employeeNoPhotoResolved(state, emp)
            ? _numCell(emp.totalJournalsNoPhoto)
            : _dashCell(),
        _numCell(emp.totalJournalsCombined),
        _numCell(emp.totalChecked),
        _numCell(emp.totalUpdated),
        // Moved here (was inline next to the name, far from this trailing
        // column that was sitting blank) so every row's expand/collapse
        // chevron lives in one consistent place — the actual last column
        // — instead of the name cell.
        DataCell(
          Center(
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _shopRow(
    KpiCombinedLoaded state,
    String empName,
    KpiCombinedShopStat s,
    bool isExpanded, {
    bool isLast = false,
  }) {
    final hasTasks = s.tasks.isNotEmpty;
    final hasOrphans = s.orphanJournalEntries.isNotEmpty;
    final workContext = _shopContributorContext(s);
    // A shop can have GL journal activity (คีย์ > 0) with zero tasks — e.g.
    // the linked task was deleted, or the entries were never tied to a
    // task workflow at all. Previously that meant no chevron and no way to
    // drill in even though the number on screen was real; now
    // orphanJournalEntries covers that case too, so "has anything to show"
    // is tasks OR orphan journals, not just tasks.
    final detailReady = state.detailLoadedShopNames.contains(s.shopName);
    final hasDrillDown = !detailReady || hasTasks || hasOrphans;
    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      onSelectChanged: hasDrillDown
          ? (_) => setState(() {
              final key = _shopKey(empName, s.shopName);
              if (isExpanded) {
                _expandedShopKeys.remove(key);
                // Cascade-collapse: also close any task drill-downs left
                // open underneath this shop — same reasoning as the
                // employee-level cascade in _empRow, otherwise
                // re-expanding this shop later silently re-opens
                // whatever task was expanded before.
                _expandedTaskKeys.removeWhere((k) => k.startsWith('$key#'));
              } else {
                _expandedShopKeys.add(key);
                if (!state.detailLoadedShopNames.contains(s.shopName) &&
                    !state.detailLoadingShopNames.contains(s.shopName)) {
                  context.read<KpiCombinedBloc>().add(
                    LoadKpiCombinedShopDetails(shopName: s.shopName),
                  );
                }
              }
            })
          : null,
      cells: [
        DataCell(
          _treeCell(
            level: 1,
            isLast: isLast,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1, right: 8),
                  child: Icon(
                    Icons.store_outlined,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.shopName,
                    style: TextStyle(
                      fontSize: 11 * _fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                    // Wraps instead of ellipsis-truncating — shop names were
                    // getting cut with "..." even though most fit in two
                    // lines just fine.
                    maxLines: 2,
                  ),
                ),
                if (hasTasks) ...[
                  _taskCountBadge(s.tasks.length),
                  const SizedBox(width: 6),
                ] else if (hasOrphans) ...[
                  _orphanCountBadge(s.orphanJournalEntries.length),
                  const SizedBox(width: 6),
                ],
                if (s.uploadedCount > 0) ...[
                  _uploadCountBadge(s.uploadedCount),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        _aggregateWorkCell(s.totalDocuments, workContext.totalDocuments),
        _aggregateWorkCell(s.waitingVerify, workContext.waitingVerify),
        _aggregateWorkCell(s.passed, workContext.passed),
        _aggregateWorkCell(s.cancelled, workContext.cancelled),
        _aggregateWorkCell(s.notRecorded, workContext.notRecorded),
        _aggregateWorkCell(
          s.notRequiredApproval,
          workContext.notRequiredApproval,
        ),
        _aggregateWorkCell(s.requiredToRecord, workContext.requiredToRecord),
        _aggregateWorkCell(s.recorded, workContext.recorded),
        _aggregateWorkCell(s.remaining, workContext.remaining),
        _aggregateWorkCell(s.completed, workContext.completed),
        _numCell(s.journalCount),
        (state.summaryReady || state.detailLoadedShopNames.contains(s.shopName))
            ? _numCell(s.journalCountNoPhoto)
            : _dashCell(),
        _numCell(s.journalCountTotal),
        _numCell(s.journalChecked),
        _numCell(s.journalUpdated),
        // Moved here (see _empRow) for the same consistency reason — one
        // shared trailing column for the expand chevron instead of it
        // sitting inline next to the shop name.
        DataCell(
          hasDrillDown
              ? Center(
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFFB0B8C4),
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  // Task-level drill-down row — shown when a shop row is expanded. Each
  // row is one underlying task/document group, so a viewer can see exactly
  // what makes up the shop's totals instead of just trusting the numbers.
  // If the task has linked GL journal entries, it can itself be expanded
  // one level further to show them (see _journalRow).
  DataRow _taskRow(
    String taskKey,
    KpiCombinedTaskItem t,
    bool isExpanded, {
    bool isLast = false,
  }) {
    final label = t.taskName.trim().isNotEmpty ? t.taskName : t.taskCode;
    final hasJournals = t.journalEntries.isNotEmpty;
    // Root-caused 2026-07: "จำนวน" (totalDocuments) only credits the task
    // OWNER (see KpiCombinedBloc._applyTaskToShopAcc's `if
    // (!isContributorRow) acc.totalDocuments += docCount`), while "คีย์"
    // credits whoever actually created each GL row regardless of task
    // ownership — so a contributor can show a real "คีย์" number with
    // "จำนวน" staying blank for that shop, which looked like a bug but
    // isn't. The collapsed "N งาน" badge on shop/employee rows doesn't
    // distinguish owner vs. contributor rows either (counts both), so this
    // was invisible without expanding all the way to the task row. Now
    // every task row states its ownership status explicitly instead of
    // only flagging the contributor case.
    final ownerDisplay = _nameMappings[t.ownerBy] ?? t.ownerBy;
    // 16 columns total: name + 14 numeric metric columns + 1 trailing
    // expand-arrow column. จำนวน/สถานะการตรวจสอบ/สถานะการบันทึกบัญชี (10
    // columns) come straight from the task item. The 3 GL action columns
    // (คีย์/ตรวจสอบ/แก้ไข) are rolled up here too — one count per action —
    // from this task's own journalEntries list, so the task row doesn't
    // just say "1 entry exists below" without saying what it is. Only
    // ต้องบันทึก(รูปภาพ) is left blank: that figure is a shop-wide total
    // (broadcast the same to every task in the shop), not something that
    // can be meaningfully attributed to a single task.
    final glKeyedCount = t.journalEntries.where((j) {
      if (j.createdBy.isEmpty) return false;
      if (!t.isOwner) return true;
      return j.createdBy.trim() == t.ownerBy.trim();
    }).length;
    final glCheckedCount = t.journalEntries
        .where((j) => j.checkedBy.isNotEmpty)
        .length;
    final glUpdatedCount = t.journalEntries
        .where((j) => j.updatedBy.isNotEmpty)
        .length;
    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFF5F7FF)),
      onSelectChanged: hasJournals
          ? (_) => setState(() {
              if (isExpanded) {
                _expandedTaskKeys.remove(taskKey);
              } else {
                _expandedTaskKeys.add(taskKey);
              }
            })
          : null,
      cells: [
        DataCell(
          _treeCell(
            level: 2,
            isLast: isLast,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.description_outlined,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11 * _fontScale,
                            color: const Color(0xFF475569),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _taskStatusChip(t.status),
                            if (t.isOwner) ...[
                              Tooltip(
                                message:
                                    '"จำนวน" ของงานนี้นับเข้าแถวของพนักงานคนนี้ (เจ้าของงาน)',
                                child: _taskMetaChip(
                                  'เจ้าของงาน',
                                  bg: const Color(0xFFDCFCE7),
                                  fg: const Color(0xFF16A34A),
                                ),
                              ),
                            ] else ...[
                              if (t.keyedByThisEmployee > 0)
                                Tooltip(
                                  message:
                                      'พนักงานแถวนี้คีย์ ${t.keyedByThisEmployee} รายการในงานของ $ownerDisplay',
                                  child: _taskMetaChip(
                                    'ร่วมคีย์ ${t.keyedByThisEmployee}',
                                    bg: _journalGroupColor,
                                    fg: const Color(0xFF4F46E5),
                                    maxWidth: 135,
                                  ),
                                ),
                              Tooltip(
                                message:
                                    'ตัวเลขฝั่งงานเป็นบริบทของงานจากเจ้าของ $ownerDisplay และไม่ถูกนับเข้า total ของแถวนี้',
                                child: _taskMetaChip(
                                  'บริบทงาน',
                                  bg: const Color(0xFFFFF7ED),
                                  fg: const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                            // อัปโหลดรูป — who actually put the photo(s) into
                            // this task, separate from who opened it
                            // (เจ้าของงาน) or who keyed the GL entry (ร่วมคีย์).
                            // Shown on EITHER the owner row (owner uploaded
                            // their own task's photos) or a contributor row
                            // (someone else uploaded into this task) —
                            // whichever row this employee's uploads actually
                            // landed on. 2026-08.
                            if (t.uploadedByThisEmployee > 0)
                              Tooltip(
                                message: t.isOwner
                                    ? 'เจ้าของงานอัปโหลดรูปเอง ${t.uploadedByThisEmployee} รูปในงานนี้'
                                    : 'พนักงานแถวนี้อัปโหลดรูป ${t.uploadedByThisEmployee} รูปในงานของ $ownerDisplay',
                                child: _taskMetaChip(
                                  'อัปโหลด ${t.uploadedByThisEmployee}',
                                  bg: const Color(0xFFE0F2FE),
                                  fg: const Color(0xFF0369A1),
                                  maxWidth: 135,
                                ),
                              ),
                            Text(
                              _dateFmt.format(t.ownerAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _taskWorkCell(t.totalDocument, t.isOwner, ownerDisplay),
        _taskWorkCell(t.waitingVerify, t.isOwner, ownerDisplay),
        _taskWorkCell(t.passed, t.isOwner, ownerDisplay),
        _taskWorkCell(t.cancelled, t.isOwner, ownerDisplay),
        _taskWorkCell(t.notRecorded, t.isOwner, ownerDisplay),
        _taskWorkCell(t.notRequiredApproval, t.isOwner, ownerDisplay),
        _taskWorkCell(t.requiredToRecord, t.isOwner, ownerDisplay),
        _taskWorkCell(t.recorded, t.isOwner, ownerDisplay),
        _taskWorkCell(t.remaining, t.isOwner, ownerDisplay),
        _taskWorkCell(t.completed, t.isOwner, ownerDisplay),
        _numCell(glKeyedCount),
        // Always 0: a task's own journalEntries only ever contains entries
        // that DID resolve to this exact task, so none of them can be a
        // "no link found at all" no-photo orphan by definition — those only
        // ever appear under KpiCombinedShopStat.orphanJournalEntries.
        _numCell(0),
        _numCell(
          glKeyedCount,
        ), // คีย์รวม == glKeyedCount since the no-photo half is always 0 here
        _numCell(glCheckedCount),
        _numCell(glUpdatedCount),
        // Moved here (see _empRow) for the same consistency reason — one
        // shared trailing column for the expand chevron instead of it
        // sitting inline next to the task name/date.
        DataCell(
          hasJournals
              ? Center(
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFFB0B8C4),
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  // GL journal drill-down row — the bottom of the chain: employee → shop →
  // task → actual journal entry. Lets a viewer trace any number all the
  // way back to a real accounting record instead of trusting an aggregate.
  DataRow _journalRow(
    KpiCombinedJournalItem g, {
    double indent = 70,
    bool isLast = false,
    // Shows a short, plain-language reason under orphan entries (see
    // KpiCombinedShopStat.orphanJournalEntries) so accounting staff can
    // see at a glance why a GL entry isn't linked to a task, without
    // digging into DevTools/terminal logs. Started life as a raw
    // engineering diagnostic (printing jobguidfixed/documentRef/
    // documentimagegroup directly) while root-causing orphan
    // misclassifications in 2026-07 — reworded to plain Thai now that
    // those are resolved, since real users shouldn't see backend field
    // names.
    bool showLinkStatus = false,
  }) {
    // Task-status columns after จำนวน (รอตรวจสอบ through เสร็จ — 9 columns)
    // don't apply to a single GL entry, so those 9 stay blank. จำนวน itself
    // gets a 1 — this entry is one of the rows rolled up into the parent
    // task/shop/employee's "จำนวน" total, and leaving it blank read as "not
    // counted at all" (reported: user couldn't tell this row contributed to
    // the total above it). คีย์/คีย์(ไม่มีรูป)/ตรวจสอบ/แก้ไข (the "บันทึกบัญชี
    // (GL)" group) get a 1 when this entry actually has that action's
    // person recorded on it — mirrors exactly how the aggregate
    // totalJournals/totalJournalsNoPhoto/totalChecked/totalUpdated counters
    // are built in KpiCombinedBloc (one increment per journal row that has
    // that field set, split between คีย์ and คีย์(ไม่มีรูป) based on whether
    // resolvedTaskGuid is empty), just at the single-row level instead of
    // summed.
    final leadingBlanks = [
      _numCell(1),
      ...List.generate(9, (_) => const DataCell(SizedBox())),
    ];
    // Mirrors KpiCombinedBloc's noPhotoAtAll exactly: resolvedTaskGuid
    // empty is not enough on its own — documentRef non-empty is separate,
    // direct evidence a photo/manual reference exists even when it
    // couldn't be resolved to a task guid (see the long comment on
    // noPhotoAtAll in kpi_combined_bloc.dart for why).
    final hasDocumentRef = (g.documentRef ?? '').trim().isNotEmpty;
    final isNoPhotoOrphan =
        (g.resolvedTaskGuid == null || g.resolvedTaskGuid!.trim().isEmpty) &&
        !hasDocumentRef;
    final amount = g.debit != 0 ? g.debit : g.credit;
    final amountLabel = g.debit != 0
        ? 'เดบิต'
        : (g.credit != 0 ? 'เครดิต' : '');
    final fmt = NumberFormat('#,##0.00');
    final createdDisplay = _nameMappings[g.createdBy] ?? g.createdBy;

    // Amount / keyer / date used to each be their own un-constrained Text
    // sitting next to the doc/account Text — with a long email in "คีย์โดย
    // {email}" that combined width regularly exceeded the 260px name
    // column (108px of which is already eaten by this row's indent), so
    // Flutter threw a RenderFlex overflow and painted its black/yellow
    // hazard stripes on every journal row. Squeezing both onto one line
    // side-by-side (previous fix) stopped the overflow but ellipsised both
    // down to a handful of characters each — unreadable. Stacking them as
    // two full-width lines (doc/account on top, amount/keyer/date below)
    // gives each its own line to breathe; dataRowH was bumped to 62 in
    // _buildTable to fit this.
    //
    // The date was still getting ellipsised off the end of that combined
    // line whenever the keyer email was long, so it's split onto its own
    // (third) line below amount/keyer — see dataRowH bump in _buildTable.
    final metaParts = <String>[
      if (amount != 0) '$amountLabel ${fmt.format(amount)}',
      if (createdDisplay.isNotEmpty) 'คีย์โดย $createdDisplay',
    ];
    // Shows keyedAt (createdat — when the entry was actually keyed), NOT
    // docDate (the document's own dated period). The selected date-range
    // filter includes/excludes entries by keyedAt (see KpiCombinedBloc.
    // journalInRange), so showing docDate here could display a date
    // outside the range the user picked even though the entry correctly
    // belongs in it — reported as "the date filter and the GL shown don't
    // match". Falls back to docDate (labelled) only for the rare entry
    // with no createdat at all, so something is still shown.
    final metaDate = g.keyedAt != null
        ? 'คีย์เมื่อ ${_dateTimeFmt.format(g.keyedAt!)}'
        : (g.docDate != null
              ? 'เอกสารลงวันที่ ${_dateTimeFmt.format(g.docDate!)}'
              : null);
    // Plain-language reason this entry shows under "ไม่ผูกงาน" — no field
    // names, no GUIDs, just what an accounting user needs to know: is
    // there any evidence behind this entry at all, and if so, why can't it
    // be matched to a task in the current list.
    String linkStatusText() {
      final resolved = g.resolvedTaskGuid;
      final hasResolvedLink = resolved != null && resolved.trim().isNotEmpty;
      if (!hasResolvedLink && !hasDocumentRef) {
        return 'ยังไม่มีรูปหรือเอกสารอ้างอิงสำหรับรายการนี้';
      }
      if (!hasResolvedLink && hasDocumentRef) {
        return 'มีเอกสารอ้างอิงแล้ว แต่ยังไม่พบงานที่ตรงกัน';
      }
      return g.resolvedTaskGuidFound
          ? 'เชื่อมกับงานแล้ว'
          : 'พบการเชื่อมโยงแล้ว แต่ไม่พบงานนี้ในรายการปัจจุบัน (อาจถูกลบหรืออยู่นอกร้าน/ช่วงที่ดึงมา)';
    }

    final linkStatusDisplay = showLinkStatus ? linkStatusText() : null;

    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFFDFEFF)),
      cells: [
        DataCell(
          _treeCell(
            level: indent <= 50 ? 2 : 3,
            isLast: isLast,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 12,
                      color: Color(0xFFB0B8C4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${g.docNo} · ${g.accountName}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            metaParts.join('   ·   '),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                        if (metaDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            metaDate,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                        if (linkStatusDisplay != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            linkStatusDisplay,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFCA8A04),
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...leadingBlanks,
        _numCell(g.createdBy.isNotEmpty && !isNoPhotoOrphan ? 1 : 0),
        _numCell(g.createdBy.isNotEmpty && isNoPhotoOrphan ? 1 : 0),
        // คีย์รวม — 1 whenever createdBy is set, regardless of no-photo
        // status (mirrors journalCountTotal = journalCount +
        // journalCountNoPhoto at the aggregate level).
        _numCell(g.createdBy.isNotEmpty ? 1 : 0),
        _numCell(g.checkedBy.isNotEmpty ? 1 : 0),
        _numCell(g.updatedBy.isNotEmpty ? 1 : 0),
        const DataCell(SizedBox()), // trailing expand-arrow column
      ],
    );
  }

  Widget _taskStatusChip(int status) {
    final (label, color) = _taskStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
        softWrap: false,
      ),
    );
  }

  // Simplified label for the task's overall status — mirrors the same
  // status codes KpiCombinedBloc buckets into totals (4/1/6), plus common
  // sense labels for the others, purely for display in the drill-down.
  (String, Color) _taskStatusInfo(int status) {
    switch (status) {
      case 4:
        return ('เสร็จ', const Color(0xFF16A34A));
      case 1:
        return ('รอตรวจสอบ', const Color(0xFFCA8A04));
      case 6:
        return ('ไม่ต้องอนุมัติ', const Color(0xFF6366F1));
      case 2:
        return ('ยกเลิก', const Color(0xFFDC2626));
      case 3:
        return ('รอแก้ไข', const Color(0xFFEA580C));
      default:
        return ('รอดำเนินการ', const Color(0xFF64748B));
    }
  }

  Widget _taskMetaChip(
    String text, {
    required Color bg,
    required Color fg,
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  DataCell _taskWorkCell(int value, bool isOwner, String ownerDisplay) {
    if (isOwner) return _numCell(value);
    final fmt = NumberFormat('#,###');
    final text = value == 0 ? '—' : fmt.format(value);
    return DataCell(
      Tooltip(
        message:
            'บริบทของงานจากเจ้าของ $ownerDisplay ไม่ถูกนับเข้า total ของพนักงานแถวนี้',
        child: Container(
          alignment: Alignment.center,
          decoration: value == 0
              ? null
              : BoxDecoration(
                  color: const Color(0xFFFFF7ED).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12 * _fontScale,
              fontWeight: FontWeight.w600,
              color: value == 0
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFFEA580C),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  ({
    int totalDocuments,
    int waitingVerify,
    int passed,
    int cancelled,
    int notRecorded,
    int notRequiredApproval,
    int requiredToRecord,
    int recorded,
    int remaining,
    int completed,
  })
  _employeeContributorContext(KpiCombinedEmployee emp) {
    final values = emp.shopStats.map(_shopContributorContext).toList();
    int sum(
      int Function(
        ({
          int totalDocuments,
          int waitingVerify,
          int passed,
          int cancelled,
          int notRecorded,
          int notRequiredApproval,
          int requiredToRecord,
          int recorded,
          int remaining,
          int completed,
        }),
      )
      f,
    ) => values.fold(0, (s, v) => s + f(v));

    return (
      totalDocuments: sum((v) => v.totalDocuments),
      waitingVerify: sum((v) => v.waitingVerify),
      passed: sum((v) => v.passed),
      cancelled: sum((v) => v.cancelled),
      notRecorded: sum((v) => v.notRecorded),
      notRequiredApproval: sum((v) => v.notRequiredApproval),
      requiredToRecord: sum((v) => v.requiredToRecord),
      recorded: sum((v) => v.recorded),
      remaining: sum((v) => v.remaining),
      completed: sum((v) => v.completed),
    );
  }

  ({
    int totalDocuments,
    int waitingVerify,
    int passed,
    int cancelled,
    int notRecorded,
    int notRequiredApproval,
    int requiredToRecord,
    int recorded,
    int remaining,
    int completed,
  })
  _shopContributorContext(KpiCombinedShopStat shop) {
    final tasks = shop.tasks.where((t) => !t.isOwner);
    int sum(int Function(KpiCombinedTaskItem) f) =>
        tasks.fold(0, (s, t) => s + f(t));

    return (
      totalDocuments: sum((t) => t.totalDocument),
      waitingVerify: sum((t) => t.waitingVerify),
      passed: sum((t) => t.passed),
      cancelled: sum((t) => t.cancelled),
      notRecorded: sum((t) => t.notRecorded),
      notRequiredApproval: sum((t) => t.notRequiredApproval),
      requiredToRecord: sum((t) => t.requiredToRecord),
      recorded: sum((t) => t.recorded),
      remaining: sum((t) => t.remaining),
      completed: sum((t) => t.completed),
    );
  }

  DataCell _aggregateWorkCell(int countedValue, int contextValue) {
    if (countedValue != 0 || contextValue == 0) return _numCell(countedValue);
    final fmt = NumberFormat('#,###');
    return DataCell(
      Tooltip(
        message: 'เลขสีส้มเป็นบริบทของงานที่ร่วมคีย์ ไม่ถูกนับเข้า total นี้',
        child: Container(
          alignment: Alignment.center,
          child: Text(
            fmt.format(contextValue),
            style: TextStyle(
              fontSize: 12 * _fontScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEA580C),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  bool _employeeNoPhotoResolved(
    KpiCombinedLoaded state,
    KpiCombinedEmployee emp,
  ) {
    return emp.shopStats.every(
      (s) =>
          state.summaryReady ||
          state.detailLoadedShopNames.contains(s.shopName),
    );
  }

  DataRow _detailStatusRow(String message) {
    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      cells: [
        DataCell(
          _treeCell(
            level: 2,
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11 * _fontScale,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        ...List.generate(_numColCount, (_) => const DataCell(SizedBox())),
        const DataCell(SizedBox()),
      ],
    );
  }

  DataCell _dashCell() {
    return DataCell(
      Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 12 * _fontScale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  DataCell _numCell(int value) {
    final fmt = NumberFormat('#,###');
    return DataCell(
      Container(
        alignment: Alignment.center,
        child: Text(
          value == 0 ? '—' : fmt.format(value),
          style: TextStyle(
            fontSize: 12 * _fontScale,
            fontWeight: FontWeight.w600,
            color: value == 0
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF374151),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _TreeConnectorPainter extends CustomPainter {
  const _TreeConnectorPainter({required this.level, required this.isLast});

  final int level;
  final bool isLast;

  static const _lineColor = Color(0xFFCBD5E1);

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;

    final paint = Paint()
      ..color = _lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;

    for (var i = 0; i < level; i++) {
      final x = 14.0 + (i * 22.0);
      final isCurrentLevel = i == level - 1;
      final endY = isCurrentLevel && isLast ? midY : size.height;
      canvas.drawLine(Offset(x, 0), Offset(x, endY), paint);
    }

    final branchX = 14.0 + ((level - 1) * 22.0);
    canvas.drawLine(Offset(branchX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.isLast != isLast;
  }
}

class _SummaryCardData {
  final String label;
  final int value;
  final Color bg;
  final Color accent;
  final IconData icon;

  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.bg,
    required this.accent,
    required this.icon,
  });
}
