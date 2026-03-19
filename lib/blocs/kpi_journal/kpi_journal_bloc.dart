import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_logger.dart';
import '../../services/auth_repository.dart';
import '../../services/journal_service.dart';
import '../../services/multi_shop_service.dart';
import 'kpi_journal_event.dart';
import 'kpi_journal_state.dart';

class KpiJournalBloc extends Bloc<KpiJournalEvent, KpiJournalState> {
  KpiJournalBloc() : super(KpiJournalInitial()) {
    on<LoadKpiJournalData>(_onLoadData);
    on<SelectShopAndSearchJournal>(_onSelectShopAndSearch);
    on<FilterKpiJournalByDateRange>(_onFilterByDateRange);
    on<ResetKpiJournalFilters>(_onReset);
  }

  Future<void> _onLoadData(
    LoadKpiJournalData event,
    Emitter<KpiJournalState> emit,
  ) async {
    emit(KpiJournalLoading());
    try {

      List<KpiJournalShopItem> shops = [];
      if (AuthRepository.isAuthenticated) {
        try {
          final rawShops = await MultiShopService.listShops();
          shops = rawShops.map((s) {
            final id = s['shopid']?.toString() ??
                s['shop_id']?.toString() ??
                s['id']?.toString() ??
                '';
            String name = s['shopname']?.toString() ?? s['shop_name']?.toString() ?? id;
            if (s['names'] != null && (s['names'] as List).isNotEmpty) {
              name = (s['names'] as List).first['name']?.toString() ?? name;
            }
            return KpiJournalShopItem(shopId: id, shopName: name);
          }).toList();
        } catch (e) {
          dLog('⚠️ Failed to load shops: $e');
        }
      }

      final employees = await _fetchAndGroup(
        shops: shops,
        shopId: null,
        startDate: null,
        endDate: null,
      );

      emit(KpiJournalLoaded(
        employees: employees.employees,
        filteredEmployees: employees.employees,
        shops: shops,
        selectedShopId: '',
        selectedShopName: 'ทุกร้าน',
        startDate: null,
        endDate: null,
        grandTotalJournals:
            employees.employees.fold(0, (s, e) => s + e.totalJournals),
        grandTotalEmployees: employees.employees.length,
        allCheckers: employees.allCheckers,
        allUpdaters: employees.allUpdaters,
      ));
    } catch (e) {
      emit(KpiJournalError('ไม่สามารถโหลดข้อมูลได้: $e'));
    }
  }

  Future<void> _onSelectShopAndSearch(
    SelectShopAndSearchJournal event,
    Emitter<KpiJournalState> emit,
  ) async {
    if (state is! KpiJournalLoaded) return;
    final current = state as KpiJournalLoaded;

    emit(current.copyWith(
      isSearching: true,
      selectedShopId: event.shopId,
      selectedShopName: event.shopName,
    ));

    try {
      final startDate = event.startDate;
      final endDate = event.endDate;

      final result = await _fetchAndGroup(
        shops: current.shops,
        shopId: event.shopId,
        startDate: startDate,
        endDate: endDate,
      );

      final query = event.query ?? current.searchQuery;
      final filtered = _applySearch(result.employees, query);

      emit(KpiJournalLoaded(
        employees: result.employees,
        filteredEmployees: filtered,
        shops: current.shops,
        selectedShopId: event.shopId,
        selectedShopName: event.shopName,
        startDate: startDate,
        endDate: endDate,
        searchQuery: query,
        isSearching: false,
        grandTotalJournals: current.grandTotalJournals,
        grandTotalEmployees: current.grandTotalEmployees,
        allCheckers: result.allCheckers,
        allUpdaters: result.allUpdaters,
      ));
    } catch (e) {
      dLog('❌ Error in SelectShopAndSearchJournal: $e');
      emit((state as KpiJournalLoaded).copyWith(isSearching: false));
    }
  }

  Future<void> _onFilterByDateRange(
    FilterKpiJournalByDateRange event,
    Emitter<KpiJournalState> emit,
  ) async {
    if (state is! KpiJournalLoaded) return;
    final current = state as KpiJournalLoaded;
    add(SelectShopAndSearchJournal(
      shopId: current.selectedShopId,
      shopName: current.selectedShopName,
      startDate: event.startDate,
      endDate: event.endDate,
      query: current.searchQuery,
    ));
  }

  Future<void> _onReset(
    ResetKpiJournalFilters event,
    Emitter<KpiJournalState> emit,
  ) async {
    add(LoadKpiJournalData());
  }

  /// Fetch GL Journals for given shop(s) and group by createdBy
  Future<_FetchResult> _fetchAndGroup({
    required List<KpiJournalShopItem> shops,
    required String? shopId,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final Map<String, _Accumulator> accMap = {};
    final Map<String, int> checkedCount = {};
    final Map<String, int> updatedCount = {};

    final startStr = startDate != null
        ? '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
        : null;
    final endStr = endDate != null
        ? '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
        : null;

    final bool isAllShops =
        shopId == null || shopId.isEmpty || shopId == 'all';

    // list of shops to iterate
    final targetShops = isAllShops
        ? shops
        : shops.where((s) => s.shopId == shopId).toList();

    // fallback: if shop list is empty, try a single call with the current session
    if (targetShops.isEmpty) {
      dLog('⚠️ No shops found, doing single fallback call');
      await _fetchPagesIntoMap(
        accMap: accMap,
        checkedCount: checkedCount,
        updatedCount: updatedCount,
        shopId: null,
        shopName: 'ไม่ระบุร้าน',
        startStr: startStr,
        endStr: endStr,
        rangeStart: startDate,
        rangeEnd: endDate,
      );
    } else {
      for (final shop in targetShops) {
        await _fetchPagesIntoMap(
          accMap: accMap,
          checkedCount: checkedCount,
          updatedCount: updatedCount,
          shopId: shop.shopId,
          shopName: shop.shopName,
          startStr: startStr,
          endStr: endStr,
          rangeStart: startDate,
          rangeEnd: endDate,
        );
      }
    }

    final rawEmployees = accMap.values.map((a) => a.build()).toList();
    final employees = rawEmployees.map((e) => KpiJournalEmployee(
      name: e.name,
      totalJournals: e.totalJournals,
      totalDebit: e.totalDebit,
      totalCredit: e.totalCredit,
      byBookCode: e.byBookCode,
      lastActive: e.lastActive,
      details: e.details,
      shopNames: e.shopNames,
      shopStats: e.shopStats,
      totalChecked: checkedCount[e.name] ?? 0,
      totalUpdated: updatedCount[e.name] ?? 0,
    )).toList()
      ..sort((a, b) => b.totalJournals.compareTo(a.totalJournals));

    // ── Build reviewMap: reviewer → shop → [details they reviewed but didn't key] ──
    final keyerNames = Set<String>.from(accMap.keys);
    final Map<String, Map<String, Map<String, KpiJournalDetail>>> reviewMap = {};
    // (reviewer → (shopName → (docNo → detail))) — dedup by docNo per shop

    for (final emp in rawEmployees) {
      for (final det in emp.details) {
        final shop = det.shopName ?? 'ไม่ระบุร้าน';
        void collect(String? reviewer) {
          if (reviewer == null || reviewer == emp.name) return; // skip self-review
          reviewMap
              .putIfAbsent(reviewer, () => {})
              .putIfAbsent(shop, () => {})[det.docNo] = det;
        }
        collect(det.checkedBy);
        collect(det.updatedBy);
      }
    }

    // ── 1. Merge review docs into existing keyer employees' shopStats ─────
    KpiJournalShopStat _mergeShopStat(
      String empName,
      KpiJournalShopStat? existing,
      String shopName,
      List<KpiJournalDetail> reviewDocs,
    ) {
      final allDetails = [
        ...?existing?.details,
        ...reviewDocs,
      ]..sort((a, b) {
          if (a.docDate == null) return 1;
          if (b.docDate == null) return -1;
          return b.docDate!.compareTo(a.docDate!);
        });
      int chk = 0, upd = 0;
      DateTime? la = existing?.lastActive;
      for (final d in allDetails) {
        if (d.checkedBy == empName) chk++;
        if (d.updatedBy == empName) upd++;
        if (d.docDate != null && (la == null || d.docDate!.isAfter(la))) la = d.docDate;
      }
      return KpiJournalShopStat(
        shopName: shopName,
        count: existing?.count ?? 0,
        byBookCode: existing?.byBookCode ?? const {},
        lastActive: la,
        details: List.unmodifiable(allDetails),
        totalChecked: chk,
        totalUpdated: upd,
      );
    }

    final mergedEmployees = employees.map((emp) {
      final reviewByShop = reviewMap[emp.name];
      if (reviewByShop == null || reviewByShop.isEmpty) return emp;

      final statsMap = <String, KpiJournalShopStat>{
        for (final s in emp.shopStats) s.shopName: s,
      };
      for (final shopEntry in reviewByShop.entries) {
        final shopName = shopEntry.key;
        final reviewDocs = shopEntry.value.values.toList();
        statsMap[shopName] = _mergeShopStat(
            emp.name, statsMap[shopName], shopName, reviewDocs);
      }
      final updatedStats = statsMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      return KpiJournalEmployee(
        name: emp.name,
        totalJournals: emp.totalJournals,
        totalDebit: emp.totalDebit,
        totalCredit: emp.totalCredit,
        byBookCode: emp.byBookCode,
        lastActive: emp.lastActive,
        details: emp.details,
        shopNames: updatedStats.map((s) => s.shopName).toList(),
        shopStats: updatedStats,
        totalChecked: emp.totalChecked,
        totalUpdated: emp.totalUpdated,
      );
    }).toList();

    // ── 2. Synthetic employees for pure non-keyer reviewers ───────────────
    final syntheticEmployees = reviewMap.entries
        .where((e) => !keyerNames.contains(e.key))
        .map((entry) {
      final revName = entry.key;
      final shopStats = entry.value.entries.map((shopEntry) {
        final details = shopEntry.value.values.toList()
          ..sort((a, b) {
            if (a.docDate == null) return 1;
            if (b.docDate == null) return -1;
            return b.docDate!.compareTo(a.docDate!);
          });
        int chk = 0, upd = 0;
        DateTime? la;
        for (final d in details) {
          if (d.checkedBy == revName) chk++;
          if (d.updatedBy == revName) upd++;
          if (d.docDate != null && (la == null || d.docDate!.isAfter(la))) la = d.docDate;
        }
        return KpiJournalShopStat(
          shopName: shopEntry.key,
          count: 0,
          byBookCode: const {},
          lastActive: la,
          details: List.unmodifiable(details),
          totalChecked: chk,
          totalUpdated: upd,
        );
      }).toList()
        ..sort((a, b) =>
            (b.totalChecked + b.totalUpdated)
                .compareTo(a.totalChecked + a.totalUpdated));

      DateTime? lastActive;
      for (final s in shopStats) {
        if (s.lastActive != null &&
            (lastActive == null || s.lastActive!.isAfter(lastActive))) {
          lastActive = s.lastActive;
        }
      }
      return KpiJournalEmployee(
        name: revName,
        totalJournals: 0,
        totalDebit: 0,
        totalCredit: 0,
        byBookCode: const {},
        lastActive: lastActive,
        shopNames: shopStats.map((s) => s.shopName).toList(),
        shopStats: shopStats,
        totalChecked: checkedCount[revName] ?? 0,
        totalUpdated: updatedCount[revName] ?? 0,
      );
    }).toList()
      ..sort((a, b) =>
          (b.totalChecked + b.totalUpdated)
              .compareTo(a.totalChecked + a.totalUpdated));

    mergedEmployees.addAll(syntheticEmployees);
    // ─────────────────────────────────────────────────────────────────────

    final allCheckers = (checkedCount.keys.toList()..sort());
    final allUpdaters = (updatedCount.keys.toList()..sort());

    return _FetchResult(
      employees: mergedEmployees,
      allCheckers: allCheckers,
      allUpdaters: allUpdaters,
    );
  }

  Future<void> _fetchPagesIntoMap({
    required Map<String, _Accumulator> accMap,
    required Map<String, int> checkedCount,
    required Map<String, int> updatedCount,
    required String? shopId,
    required String shopName,
    required String? startStr,
    required String? endStr,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) async {
    // Normalise to date-only boundaries (inclusive) — null means no filter
    final dayStart = rangeStart != null
        ? DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
        : null;
    final dayEnd = rangeEnd != null
        ? DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59, 999)
        : null;

    try {
      await MultiShopService.selectShop(
          shopId: shopId?.isNotEmpty == true ? shopId : null);

      const pageLimit = 500;
      int page = 1;
      int totalPages = 1;

      do {
        final resp = await JournalService.getAllGLJournals(
          page: page,
          limit: pageLimit,
          sort: 'docdate:-1',
          timezone: '+07',
          shopId: shopId?.isNotEmpty == true ? shopId : null,
          startDate: startStr,
          endDate: endStr,
        );

        if (resp.success != true || resp.journals == null) break;

        final journals = resp.journals!;

        if (page == 1) {
          final p = resp.pagination;
          if (p != null) {
            // Prefer explicit total_pages; fall back to computing from total/limit
            totalPages = p.totalPages ??
                (p.total != null && p.total! > 0
                    ? ((p.total! + pageLimit - 1) ~/ pageLimit)
                    : 1);
          }
          dLog('📄 Shop "$shopName" ($shopId): totalPages=$totalPages, total=${resp.pagination?.total}');
        }

        for (final j in journals) {
          final creator = (j.createdBy ?? '').trim();
          if (creator.isEmpty) continue;

          // Filter by doc_date — only when the user has picked a date range
          if (dayStart != null && dayEnd != null && j.docDatetime != null) {
            try {
              final docDate = DateTime.parse(j.docDatetime!);
              if (docDate.isBefore(dayStart) || docDate.isAfter(dayEnd)) continue;
            } catch (_) {}
          }

          accMap.putIfAbsent(creator, () => _Accumulator(creator));
          accMap[creator]!.add(j, shopName);

          // track checkedBy / updatedBy counts
          final checked = (j.checkedBy ?? '').trim();
          if (checked.isNotEmpty) {
            checkedCount[checked] = (checkedCount[checked] ?? 0) + 1;
          }
          final updated = (j.updatedBy ?? '').trim();
          if (updated.isNotEmpty) {
            updatedCount[updated] = (updatedCount[updated] ?? 0) + 1;
          }
        }

        // If the server returned fewer records than requested, this is the last page
        if (journals.length < pageLimit) break;

        page++;
      } while (page <= totalPages);

      dLog('✅ Shop "$shopName": fetched ${page - 1} page(s)');
    } catch (e) {
      dLog('⚠️ Failed to fetch GL for shop "$shopName": $e');
    }
  }

  List<KpiJournalEmployee> _applySearch(
    List<KpiJournalEmployee> employees,
    String? query,
  ) {
    if (query == null || query.trim().isEmpty) return employees;
    final q = query.trim().toLowerCase();
    return employees.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
}

// ─── Private accumulator ────────────────────────────────────────────────────

// ─── per-shop accumulator ────────────────────────────────────────────────────
class _ShopAccum {
  final String shopName;
  int count = 0;
  int checkedCount = 0;
  int updatedCount = 0;
  DateTime? lastActive;
  final Map<String, int> byBookCode = {};
  final List<KpiJournalDetail> details = [];

  _ShopAccum(this.shopName);

  KpiJournalShopStat build() {
    details.sort((a, b) {
      if (a.docDate == null && b.docDate == null) return 0;
      if (a.docDate == null) return 1;
      if (b.docDate == null) return -1;
      return b.docDate!.compareTo(a.docDate!);
    });
    return KpiJournalShopStat(
      shopName: shopName,
      count: count,
      byBookCode: Map.unmodifiable(byBookCode),
      lastActive: lastActive,
      details: List.unmodifiable(details),
      totalChecked: checkedCount,
      totalUpdated: updatedCount,
    );
  }
}

class _Accumulator {
  final String name;
  int totalJournals = 0;
  double totalDebit = 0;
  double totalCredit = 0;
  DateTime? lastActive;
  final List<KpiJournalDetail> details = [];
  final Map<String, int> byBookCode = {};
  final Map<String, _ShopAccum> _shopAccums = {};

  _Accumulator(this.name);

  void add(dynamic j, String shopName) {
    totalJournals++;
    final d = (j.debit ?? 0.0) is double ? (j.debit ?? 0.0) : (j.debit ?? 0.0).toDouble();
    final c = (j.credit ?? 0.0) is double ? (j.credit ?? 0.0) : (j.credit ?? 0.0).toDouble();
    totalDebit += d as double;
    totalCredit += c as double;

    final bk = (j.bookCode ?? '').toString();
    if (bk.isNotEmpty) byBookCode[bk] = (byBookCode[bk] ?? 0) + 1;

    DateTime? docDate;
    try {
      if (j.docDatetime != null) docDate = DateTime.parse(j.docDatetime!).toLocal();
    } catch (_) {}
    DateTime? createdAt;
    try {
      if (j.createdAt != null) createdAt = DateTime.parse(j.createdAt!).toLocal();
    } catch (_) {}
    DateTime? updatedAt;
    try {
      if (j.updatedAt != null) updatedAt = DateTime.parse(j.updatedAt!).toLocal();
    } catch (_) {}
    DateTime? checkedAt;
    try {
      if (j.checkedAt != null) checkedAt = DateTime.parse(j.checkedAt!).toLocal();
    } catch (_) {}
    if (docDate != null &&
        (lastActive == null || docDate.isAfter(lastActive!))) {
      lastActive = docDate;
    }

    final amount = (j.apiAmount ?? 0.0) is double
        ? (j.apiAmount ?? 0.0) as double
        : ((j.apiAmount ?? 0.0) as num).toDouble();

    final detail = KpiJournalDetail(
      docNo: (j.docNo ?? '').toString(),
      docDate: docDate,
      bookCode: bk,
      debit: d,
      credit: c,
      amount: amount,
      shopName: shopName,
      accountDescription: j.description?.toString(),
      checkedBy: (j.checkedBy ?? '').trim().isNotEmpty ? j.checkedBy!.trim() : null,
      checkedAt: checkedAt,
      updatedBy: (j.updatedBy ?? '').trim().isNotEmpty ? j.updatedBy!.trim() : null,
      createdBy: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    details.add(detail);

    // per-shop tracking
    if (shopName.isNotEmpty) {
      _shopAccums.putIfAbsent(shopName, () => _ShopAccum(shopName));
      final sa = _shopAccums[shopName]!;
      sa.count++;
      if (bk.isNotEmpty) sa.byBookCode[bk] = (sa.byBookCode[bk] ?? 0) + 1;
      if (docDate != null &&
          (sa.lastActive == null || docDate.isAfter(sa.lastActive!))) {
        sa.lastActive = docDate;
      }
      sa.details.add(detail);
      // Only count when THIS employee (the keyer) is also the checker/updater
      final checked = (j.checkedBy ?? '').trim();
      if (checked == name) sa.checkedCount++;
      final updated = (j.updatedBy ?? '').trim();
      if (updated == name) sa.updatedCount++;
    }
  }

  KpiJournalEmployee build() {
    final shopStats = _shopAccums.values
        .map((sa) => sa.build())
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    details.sort((a, b) {
      if (a.docDate == null && b.docDate == null) return 0;
      if (a.docDate == null) return 1;
      if (b.docDate == null) return -1;
      return b.docDate!.compareTo(a.docDate!);
    });
    return KpiJournalEmployee(
      name: name,
      totalJournals: totalJournals,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      byBookCode: Map.unmodifiable(byBookCode),
      lastActive: lastActive,
      details: List.unmodifiable(details),
      shopNames: shopStats.map((s) => s.shopName).toList(),
      shopStats: shopStats,
      // totalChecked / totalUpdated are injected after build() in _fetchAndGroup
    );
  }
}

// ─── Result container ────────────────────────────────────────────────────────

class _FetchResult {
  final List<KpiJournalEmployee> employees;
  final List<String> allCheckers;
  final List<String> allUpdaters;

  const _FetchResult({
    required this.employees,
    required this.allCheckers,
    required this.allUpdaters,
  });
}
