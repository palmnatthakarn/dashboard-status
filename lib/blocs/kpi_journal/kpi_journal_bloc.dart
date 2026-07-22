import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/journal.dart';
import '../../utils/app_logger.dart';
import '../../services/auth_repository.dart';
import '../../services/document_image_service.dart';
import '../../services/journal_service.dart';
import '../../services/multi_shop_service.dart';
import '../../services/task_service.dart';
import 'kpi_journal_event.dart';
import 'kpi_journal_state.dart';
import '../../services/employee_mapping_service.dart';

typedef KpiJournalAuthCheck = bool Function();
typedef KpiJournalListShops = Future<List<Map<String, dynamic>>> Function();
typedef KpiJournalSelectShop = Future<bool> Function({String? shopId});
typedef KpiJournalFetchImageGroups =
    Future<Map<String, int>> Function({
      int page,
      int perPage,
      String? fromDate,
      String? toDate,
      int ref,
      String? shopId,
    });
typedef KpiJournalFetchTasksForShop =
    Future<TaskResponse> Function({
      required String shopId,
      int limit,
      List<int> status,
      int page,
    });
typedef KpiJournalFetchGLJournals =
    Future<JournalResponse> Function({
      int page,
      int limit,
      String? shopId,
      String? task,
      String sort,
      String timezone,
      String? startDate,
      String? endDate,
    });

/// Cached result of [KpiJournalBloc._fetchAndGroupUncached] for a given
/// combination of shop selection + date range.
class _JournalFetchCacheEntry {
  final _FetchResult result;
  final DateTime cachedAt;

  _JournalFetchCacheEntry(this.result, this.cachedAt);
}

class KpiJournalBloc extends Bloc<KpiJournalEvent, KpiJournalState> {
  final KpiJournalAuthCheck _isAuthenticated;
  final KpiJournalListShops _listShops;
  final KpiJournalSelectShop _selectShop;
  final KpiJournalFetchImageGroups _fetchDocumentImageGroups;
  final KpiJournalFetchTasksForShop _fetchTasksForShop;
  final KpiJournalFetchGLJournals _fetchGLJournals;

  /// How long a fetched result stays valid before a fresh fetch runs again
  /// for the same (shop, date range) combination.
  static const Duration _cacheTtl = Duration(minutes: 2);

  // NOTE: shop fetches (tasks AND GL journals) are intentionally kept
  // strictly SEQUENTIAL, one shop fully at a time. Confirmed by live testing
  // against the real API (2026-07) that /gl/journal ignores its own
  // shopId/shopids query param entirely and instead returns data for
  // whichever shop was last selected via POST /select-shop on this
  // session/token. Parallelizing across shops would race on that shared
  // session state and silently mix up / drop data between shops. Do not
  // parallelize this without a backend change that makes shop scoping
  // stateless per-request.

  // static (not instance) so the cache survives KpiJournalBloc being
  // disposed and recreated — which happens every time the user navigates
  // away from the KPI Journal page and back, since KpiJournalPage builds a
  // brand-new BlocProvider/KpiJournalBloc each time. An instance field here
  // would never actually get reused.
  static final Map<String, _JournalFetchCacheEntry> _resultCache = {};

  /// Call this on logout / account switch so the next login doesn't briefly
  /// show a previous account's cached KPI Journal data (the cache above is
  /// static and otherwise survives across BlocProvider recreation).
  static void clearCache() => _resultCache.clear();

  KpiJournalBloc({
    KpiJournalAuthCheck? isAuthenticated,
    KpiJournalListShops? listShops,
    KpiJournalSelectShop? selectShop,
    KpiJournalFetchImageGroups? fetchDocumentImageGroups,
    KpiJournalFetchTasksForShop? fetchTasksForShop,
    KpiJournalFetchGLJournals? fetchGLJournals,
  })  : _isAuthenticated =
            isAuthenticated ?? (() => AuthRepository.isAuthenticated),
        _listShops = listShops ?? MultiShopService.listShops,
        _selectShop = selectShop ?? MultiShopService.selectShop,
        _fetchDocumentImageGroups =
            fetchDocumentImageGroups ??
            DocumentImageService.fetchDocumentImageGroups,
        _fetchTasksForShop = fetchTasksForShop ?? TaskService.fetchTasksForShop,
        _fetchGLJournals = fetchGLJournals ?? JournalService.getAllGLJournals,
        super(KpiJournalInitial()) {
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
      final defaultRange = _currentMonthRange();
      List<KpiJournalShopItem> shops = [];
      if (_isAuthenticated()) {
        try {
          final rawShops = await _listShops();
          shops = rawShops.map((s) {
            final id =
                s['shopid']?.toString() ??
                s['shop_id']?.toString() ??
                s['id']?.toString() ??
                '';
            String name =
                s['shopname']?.toString() ?? s['shop_name']?.toString() ?? id;
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
        startDate: defaultRange.start,
        endDate: defaultRange.end,
      );

      emit(
        KpiJournalLoaded(
          employees: employees.employees,
          filteredEmployees: employees.employees,
          shops: shops,
          selectedShopId: '',
          selectedShopName: 'ทุกร้าน',
          startDate: defaultRange.start,
          endDate: defaultRange.end,
          grandTotalJournals: employees.employees.fold(
            0,
            (s, e) => s + e.totalJournals,
          ),
          grandTotalEmployees: employees.employees.length,
          allCheckers: employees.allCheckers,
          allUpdaters: employees.allUpdaters,
        ),
      );
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

    emit(
      current.copyWith(
        isSearching: true,
        selectedShopId: event.shopId,
        selectedShopName: event.shopName,
      ),
    );

    try {
      final startDate = event.startDate;
      final endDate = event.endDate;

      var result = await _fetchAndGroup(
        shops: current.shops,
        shopId: event.shopId,
        startDate: startDate,
        endDate: endDate,
      );
      final totalJournalsFound = result.employees.fold(0, (sum, emp) => sum + emp.totalJournals);
      dLog('[KPI_DEBUG] 🔎 Shop "${event.shopName}" (${event.shopId}): employees=${result.employees.length}, totalJournals=$totalJournalsFound');

      final selectedShopHasNoJournals =
          event.shopId?.isNotEmpty == true &&
          event.shopName?.isNotEmpty == true &&
          totalJournalsFound == 0;
      if (selectedShopHasNoJournals) {
        dLog('[KPI_DEBUG] ⚠️ No GL journals found by shopId=${event.shopId}; retrying by branch name "${event.shopName}"');
        result = await _fetchAndGroup(
          shops: [
            KpiJournalShopItem(
              shopId: event.shopId ?? '',
              shopName: event.shopName ?? '',
            ),
          ],
          shopId: null,
          startDate: startDate,
          endDate: endDate,
          journalShopNameFilter: event.shopName,
          skipShopSelection: true,
        );
        final retryTotal = result.employees.fold(0, (sum, emp) => sum + emp.totalJournals);
        dLog('[KPI_DEBUG] 🔁 Retry result: employees=${result.employees.length}, totalJournals=$retryTotal');
      }

      final query = event.query ?? current.searchQuery;
      final filtered = _applySearch(result.employees, query);

      emit(
        KpiJournalLoaded(
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
        ),
      );
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
    add(
      SelectShopAndSearchJournal(
        shopId: current.selectedShopId,
        shopName: current.selectedShopName,
        startDate: event.startDate,
        endDate: event.endDate,
        query: current.searchQuery,
      ),
    );
  }

  Future<void> _onReset(
    ResetKpiJournalFilters event,
    Emitter<KpiJournalState> emit,
  ) async {
    add(LoadKpiJournalData());
  }

  /// Cache key covering everything that affects the fetched result: which
  /// shop(s), the date range, and the special retry-by-branch-name path.
  String _resultCacheKey({
    required String? shopId,
    required DateTime? startDate,
    required DateTime? endDate,
    String? journalShopNameFilter,
    required bool skipShopSelection,
  }) {
    final s = startDate != null ? JournalService.formatDate(startDate) : '-';
    final e = endDate != null ? JournalService.formatDate(endDate) : '-';
    return '${shopId ?? 'ALL'}|$s|$e|${journalShopNameFilter ?? ''}|$skipShopSelection';
  }

  /// Fetch GL Journals for given shop(s) and group by createdBy, using a
  /// short-lived cache so switching filters back and forth (or minor UI
  /// re-renders) doesn't always trigger a brand-new full re-fetch.
  Future<_FetchResult> _fetchAndGroup({
    required List<KpiJournalShopItem> shops,
    required String? shopId,
    required DateTime? startDate,
    required DateTime? endDate,
    String? journalShopNameFilter,
    bool skipShopSelection = false,
  }) async {
    final cacheKey = _resultCacheKey(
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
      journalShopNameFilter: journalShopNameFilter,
      skipShopSelection: skipShopSelection,
    );
    final cached = _resultCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      dLog(
        '📋 Using cached KPI Journal data for key="$cacheKey" '
        '(${DateTime.now().difference(cached.cachedAt).inSeconds}s old)',
      );
      return cached.result;
    }

    final result = await _fetchAndGroupUncached(
      shops: shops,
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
      journalShopNameFilter: journalShopNameFilter,
      skipShopSelection: skipShopSelection,
    );

    _resultCache[cacheKey] = _JournalFetchCacheEntry(result, DateTime.now());
    return result;
  }

  Future<_FetchResult> _fetchAndGroupUncached({
    required List<KpiJournalShopItem> shops,
    required String? shopId,
    required DateTime? startDate,
    required DateTime? endDate,
    String? journalShopNameFilter,
    bool skipShopSelection = false,
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

    final bool isAllShops = shopId == null || shopId.isEmpty || shopId == 'all';

    // list of shops to iterate
    final targetShops = journalShopNameFilter?.isNotEmpty == true
        ? [
            KpiJournalShopItem(
              shopId: shopId ?? (shops.isNotEmpty ? shops.first.shopId : ''),
              shopName: journalShopNameFilter!,
            ),
          ]
        : isAllShops
        ? shops
        : shops.where((s) => s.shopId == shopId).toList();

    final Map<String, int> taskDocCountMap = {};
    final Map<String, String> taskNameMap = {};
    final Map<String, int> shopTotalDocsMap = {};
    final Set<String> activeTaskGuids = {};

    try {
      final imageGroupDocCountByShopId =
          await _fetchDocumentImageGroups(
            page: 1,
            perPage: 9999,
            fromDate: startStr,
            toDate: endStr,
            ref: 1,
            shopId: isAllShops ? null : shopId,
          );
      for (final shop in targetShops) {
        final count =
            imageGroupDocCountByShopId[shop.shopId] ??
            imageGroupDocCountByShopId[shop.shopName] ??
            imageGroupDocCountByShopId[shop.shopName.trim().toLowerCase()];
        if (count != null) {
          shopTotalDocsMap[shop.shopName] = count;
        }
      }
    } catch (e) {
      dLog('⚠️ Failed to fetch document image groups: $e');
    }

    // fallback: if shop list is empty, try a single call with the current session
    if (targetShops.isEmpty) {
      dLog('⚠️ No shops found, doing single fallback call');

      List<TaskItem> fallbackTasks = [];
      try {
        final resp = await _fetchTasksForShop(
          shopId: '',
          limit: 5000,
          status: [0, 1, 2, 3, 4, 5, 6],
        );
        if (resp.success && resp.tasks.isNotEmpty) {
          fallbackTasks = resp.tasks;
          int shopPassedDocs = 0;
          Set<String> processedTasks = {};
          
          for (final t in resp.tasks) {
            final requiredDocs = _requiredDocsToRecord(t);

            // Only sum top-level tasks in the selected ownerAt range to avoid
            // comparing this period's keying work against old carried-over jobs.
            if (t.parentGuidfixed.isEmpty &&
                (t.status == 3 || t.status == 4 || t.status == 6) &&
                _isTaskOwnerAtInRange(t, startDate, endDate)) {
              if (!processedTasks.contains(t.guidfixed)) {
                processedTasks.add(t.guidfixed);
                shopPassedDocs += requiredDocs;
              }
            }

            taskDocCountMap[t.guidfixed] = requiredDocs;
            taskNameMap[t.guidfixed] = t.name;
            if (t.taskChild != null && t.taskChild!.guidfixed.isNotEmpty) {
              taskDocCountMap[t.taskChild!.guidfixed] = requiredDocs;
              taskNameMap[t.taskChild!.guidfixed] = t.taskChild!.name;
            }
          }
          shopTotalDocsMap['ไม่ระบุร้าน'] = shopPassedDocs;
        }
      } catch (e) {
        /* ignore */
      }

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
        taskDocCountMap: taskDocCountMap,
        taskNameMap: taskNameMap,
        activeTaskGuids: activeTaskGuids,
        journalShopNameFilter: journalShopNameFilter,
        skipShopSelection: skipShopSelection,
      );
      if (fallbackTasks.isNotEmpty) {
        shopTotalDocsMap['ไม่ระบุร้าน'] = _sumTaskDocsForPeriod(
          fallbackTasks,
          startDate,
          endDate,
          activeTaskGuids,
        );
      }
    } else {
      // Fetch each shop fully SEQUENTIALLY: select-shop -> fetch tasks ->
      // fetch ALL GL journal pages for THAT SAME shop, then move to the
      // next shop. /gl/journal ignores its own shopId/shopids param and
      // just returns data for whatever shop the session currently has
      // selected, so the GL fetch for a shop must happen immediately after
      // that shop was selected, with nothing else touching the session in
      // between — see the NOTE near _cacheTtl above.
      for (final shop in targetShops) {
        List<TaskItem> shopTasks = [];
        try {
          final resp = await _fetchTasksForShop(
            shopId: shop.shopId,
            limit: 5000,
            status: [0, 1, 2, 3, 4, 5, 6],
          );
          if (resp.success && resp.tasks.isNotEmpty) {
            shopTasks = resp.tasks;
            int shopPassedDocs = 0;
            Set<String> processedTasks = {};

            for (final t in resp.tasks) {
              final requiredDocs = _requiredDocsToRecord(t);

              // Only sum top-level tasks in the selected ownerAt range to avoid
              // comparing this period's keying work against old carried-over jobs.
              if (t.parentGuidfixed.isEmpty &&
                  (t.status == 3 || t.status == 4 || t.status == 6) &&
                  _isTaskOwnerAtInRange(t, startDate, endDate)) {
                if (!processedTasks.contains(t.guidfixed)) {
                  processedTasks.add(t.guidfixed);
                  shopPassedDocs += requiredDocs;
                }
              }

              taskDocCountMap[t.guidfixed] = requiredDocs;
              taskNameMap[t.guidfixed] = t.name;
              if (t.taskChild != null && t.taskChild!.guidfixed.isNotEmpty) {
                taskDocCountMap[t.taskChild!.guidfixed] = requiredDocs;
                taskNameMap[t.taskChild!.guidfixed] = t.taskChild!.name;
              }
            }
            shopTotalDocsMap[shop.shopName] = shopPassedDocs;
          }
        } catch (e) {
          dLog('⚠️ Failed to fetch tasks for shop ${shop.shopName}: $e');
        }

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
          taskDocCountMap: taskDocCountMap,
          taskNameMap: taskNameMap,
          activeTaskGuids: activeTaskGuids,
          journalShopNameFilter: journalShopNameFilter,
          skipShopSelection: skipShopSelection,
        );
        if (shopTasks.isNotEmpty) {
          shopTotalDocsMap[shop.shopName] = _sumTaskDocsForPeriod(
            shopTasks,
            startDate,
            endDate,
            activeTaskGuids,
          );
        }
      }
    }

    final rawEmployees = accMap.values.map((a) => a.build(shopTotalDocsMap)).toList();
    final employees =
        rawEmployees
            .map(
              (e) => KpiJournalEmployee(
                name: e.name,
                totalJournals: e.totalJournals,
                totalLinkedJournals: e.totalLinkedJournals,
                totalDocument: e.totalDocument,
                totalDebit: e.totalDebit,
                totalCredit: e.totalCredit,
                byBookCode: e.byBookCode,
                lastActive: e.lastActive,
                details: e.details,
                shopNames: e.shopNames,
                shopStats: e.shopStats,
                totalChecked: checkedCount[e.name] ?? 0,
                totalUpdated: updatedCount[e.name] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalJournals.compareTo(a.totalJournals));

    // ── Build reviewMap: reviewer → shop → [details they reviewed but didn't key] ──
    final keyerNames = Set<String>.from(accMap.keys);
    final Map<String, Map<String, Map<String, KpiJournalDetail>>> reviewMap =
        {};
    // (reviewer → (shopName → (docNo → detail))) — dedup by docNo per shop

    for (final emp in rawEmployees) {
      for (final det in emp.details) {
        final shop = det.shopName ?? 'ไม่ระบุร้าน';
        void collect(String? reviewer) {
          if (reviewer == null || reviewer.isEmpty || reviewer == emp.name) {
            return; // skip self-review
          }
          reviewMap
                  .putIfAbsent(reviewer, () => {})
                  .putIfAbsent(shop, () => {})[det.docNo] =
              det;
        }

        collect(det.checkedBy);
        collect(det.updatedBy);
      }
    }

    // ── 1. Merge review docs into existing keyer employees' shopStats ─────
    KpiJournalShopStat mergeShopStat(
      String empName,
      KpiJournalShopStat? existing,
      String shopName,
      List<KpiJournalDetail> reviewDocs,
    ) {
      final allDetails = [...?existing?.details, ...reviewDocs]
        ..sort((a, b) {
          if (a.docDate == null) return 1;
          if (b.docDate == null) return -1;
          return b.docDate!.compareTo(a.docDate!);
        });
      int chk = 0, upd = 0;
      DateTime? la;
      for (final d in allDetails) {
        if (d.checkedBy == empName) chk++;
        if (d.updatedBy == empName) upd++;
        if (d.docDate != null && (la == null || d.docDate!.isAfter(la))) {
          la = d.docDate;
        }
      }
      return KpiJournalShopStat(
        shopName: shopName,
        count: existing?.count ?? 0,
        totalDocument: shopTotalDocsMap[shopName] ?? 0,
        byBookCode: existing?.byBookCode ?? const {},
        lastActive: la ?? existing?.lastActive,
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
        statsMap[shopName] = mergeShopStat(
          emp.name,
          statsMap[shopName],
          shopName,
          reviewDocs,
        );
      }
      final updatedStats = statsMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));
        
      int recalculatedTotalDoc = 0;
      for (final s in updatedStats) {
        recalculatedTotalDoc += s.totalDocument;
      }

      return KpiJournalEmployee(
        name: emp.name,
        totalJournals: emp.totalJournals,
        totalLinkedJournals: emp.totalLinkedJournals,
        totalDocument: recalculatedTotalDoc,
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
    final syntheticEmployees =
        reviewMap.entries.where((e) => !keyerNames.contains(e.key)).map((
          entry,
        ) {
          final revName = entry.key;
          final shopStats =
              entry.value.entries.map((shopEntry) {
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
                  if (d.docDate != null &&
                      (la == null || d.docDate!.isAfter(la))) {
                    la = d.docDate;
                  }
                }
                return KpiJournalShopStat(
                  shopName: shopEntry.key,
                  count: 0,
                  totalDocument: shopTotalDocsMap[shopEntry.key] ?? 0,
                  byBookCode: const {},
                  lastActive: la,
                  details: List.unmodifiable(details),
                  totalChecked: chk,
                  totalUpdated: upd,
                );
              }).toList()..sort(
                (a, b) => (b.totalChecked + b.totalUpdated).compareTo(
                  a.totalChecked + a.totalUpdated,
                ),
              );

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
            totalLinkedJournals: 0,
            totalDocument: shopStats.fold(0, (sum, s) => sum + s.totalDocument),
            totalDebit: 0,
            totalCredit: 0,
            byBookCode: const {},
            lastActive: lastActive,
            shopNames: shopStats.map((s) => s.shopName).toList(),
            shopStats: shopStats,
            totalChecked: checkedCount[revName] ?? 0,
            totalUpdated: updatedCount[revName] ?? 0,
          );
        }).toList()..sort(
          (a, b) => (b.totalChecked + b.totalUpdated).compareTo(
            a.totalChecked + a.totalUpdated,
          ),
        );

    mergedEmployees.addAll(syntheticEmployees);
    // ─────────────────────────────────────────────────────────────────────

    // ✅ บันทึกชื่อพนักงานที่พบในระบบลง Cache เพื่อแนะนำในหน้าตั้งค่า
    final namesFromApi = mergedEmployees.map((e) => e.name).toList();
    EmployeeMappingService.saveKnownEmployees(namesFromApi);

    final allCheckers = (checkedCount.keys.toList()..sort());
    final allUpdaters = (updatedCount.keys.toList()..sort());

    return _FetchResult(
      employees: mergedEmployees,
      allCheckers: allCheckers,
      allUpdaters: allUpdaters,
    );
  }

  /// Selects the shop (if needed), fetches every GL journal page for it,
  /// then accumulates the results. Called once per shop, sequentially, from
  /// both the fallback path and the main multi-shop loop in
  /// [_fetchAndGroupUncached] — see the NOTE near _cacheTtl for why this
  /// can't be parallelized across shops.
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
    required Map<String, int> taskDocCountMap,
    required Map<String, String> taskNameMap,
    required Set<String> activeTaskGuids,
    String? journalShopNameFilter,
    bool skipShopSelection = false,
  }) async {
    // Normalise to date-only boundaries (inclusive) — null means no filter
    final dayStart = rangeStart != null
        ? DateTime(rangeStart.year, rangeStart.month, rangeStart.day)
        : null;
    final dayEnd = rangeEnd != null
        ? DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59, 999)
        : null;

    if (!skipShopSelection) {
      try {
        await _selectShop(shopId: shopId?.isNotEmpty == true ? shopId : null);
      } catch (e) {
        dLog('⚠️ Failed to select shop "$shopName" before GL fetch: $e');
      }
    }

    final queryShopId =
        journalShopNameFilter?.isNotEmpty == true ? null : shopId;
    final journals = await _fetchAllJournalPagesForShop(
      shopId: queryShopId,
      shopName: shopName,
      startStr: startStr,
      endStr: endStr,
      journalShopNameFilter: journalShopNameFilter,
    );

    _accumulateJournalsIntoMaps(
      journals: journals,
      shopName: shopName,
      accMap: accMap,
      checkedCount: checkedCount,
      updatedCount: updatedCount,
      dayStart: dayStart,
      dayEnd: dayEnd,
      taskDocCountMap: taskDocCountMap,
      taskNameMap: taskNameMap,
      activeTaskGuids: activeTaskGuids,
      journalShopNameFilter: journalShopNameFilter,
    );
  }

  /// Fetches every page of GL journals for one shop and returns the raw
  /// list. Despite taking a `shopId` param, the real API ignores it and
  /// returns data for whichever shop is currently selected on the session
  /// (confirmed by live testing) — so the caller MUST call selectShop for
  /// this shop immediately beforehand and must not call this concurrently
  /// for other shops. See [_fetchPagesIntoMap], which does exactly that.
  Future<List<Journal>> _fetchAllJournalPagesForShop({
    required String? shopId,
    required String shopName,
    required String? startStr,
    required String? endStr,
    String? journalShopNameFilter,
  }) async {
    final List<Journal> allJournals = [];

    try {
      const pageLimit = 500;
      int page = 1;
      int totalPages = 1;

      do {
        final resp = await _fetchGLJournals(
          page: page,
          limit: pageLimit,
          sort: 'docdate:-1',
          timezone: '+07',
          shopId: shopId?.isNotEmpty == true ? shopId : null,
          startDate: startStr,
          endDate: endStr,
        );

        if (resp.success != true || resp.journals == null) {
          dLog('[KPI_DEBUG] ❌ Break! Shop "$shopName" ($shopId) page=$page success=${resp.success} journals=${resp.journals == null ? "NULL" : "empty?"}');
          break;
        }

        final journals = resp.journals!;
        allJournals.addAll(journals);

        if (page == 1) {
          final p = resp.pagination;
          if (p != null) {
            // Prefer explicit total_pages; fall back to computing from total/limit
            totalPages =
                p.totalPages ??
                (p.total != null && p.total! > 0
                    ? ((p.total! + pageLimit - 1) ~/ pageLimit)
                    : 1);
          }
          dLog('[KPI_DEBUG] 📄 Shop "$shopName" ($shopId): totalPages=$totalPages, total=${resp.pagination?.total}');
        }

        dLog('[KPI_DEBUG]   📊 Page $page | fetched=${journals.length}');

        // If the server returned fewer records than requested, this is the last page
        if (journals.length < pageLimit) break;

        page++;
      } while (page <= totalPages);

      dLog('✅ Shop "$shopName": fetched ${allJournals.length} journal row(s) across pages');
    } catch (e) {
      dLog('⚠️ Failed to fetch GL for shop "$shopName": $e');
    }

    return allJournals;
  }

  /// Filters and accumulates a shop's already-fetched journals into the
  /// shared maps. Pure in-memory work (no awaits), so calling it
  /// sequentially per shop after a parallel fetch phase is cheap and avoids
  /// any concurrent-mutation concerns on accMap/checkedCount/updatedCount.
  void _accumulateJournalsIntoMaps({
    required List<Journal> journals,
    required String shopName,
    required Map<String, _Accumulator> accMap,
    required Map<String, int> checkedCount,
    required Map<String, int> updatedCount,
    required DateTime? dayStart,
    required DateTime? dayEnd,
    required Map<String, int> taskDocCountMap,
    required Map<String, String> taskNameMap,
    required Set<String> activeTaskGuids,
    String? journalShopNameFilter,
  }) {
    int skippedNoCreator = 0;
    int skippedNameMismatch = 0;
    int accepted = 0;

    for (final j in journals) {
      final creator = (j.createdBy ?? '').trim();
      if (creator.isEmpty) {
        skippedNoCreator++;
        continue;
      }

      if (journalShopNameFilter?.isNotEmpty == true) {
        final expected = _normalizeShopName(journalShopNameFilter!);
        final actual = _normalizeShopName(j.branchName ?? j.shopName ?? '');
        if (actual != expected) {
          skippedNameMismatch++;
          if (skippedNameMismatch <= 3) {
            dLog('[KPI_DEBUG]   🔍 name mismatch: expected="$expected" actual="$actual" (branchName="${j.branchName}")');
          }
          continue;
        }
      }
      accepted++;

      // Filter by doc_date — only when the user has picked a date range.
      // Rows with a missing/unparseable docdate are excluded too (not
      // skipped), since previously they always bypassed this filter and
      // showed up regardless of the selected date range.
      if (dayStart != null && dayEnd != null) {
        DateTime? docDate;
        if (j.docDatetime != null) {
          try {
            docDate = DateTime.parse(j.docDatetime!);
          } catch (_) {}
        }
        if (docDate == null ||
            docDate.isBefore(dayStart) ||
            docDate.isAfter(dayEnd)) {
          continue;
        }
      }

      final taskGuid = (j.jobGuidfixed ?? '').toString().trim();
      if (taskGuid.isNotEmpty) {
        activeTaskGuids.add(taskGuid);
      }

      accMap.putIfAbsent(creator, () => _Accumulator(creator));
      accMap[creator]!.add(j, shopName, taskDocCountMap, taskNameMap);

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
    dLog('[KPI_DEBUG]   📊 Shop "$shopName" | total=${journals.length} | accepted=$accepted | skipped(noCreator)=$skippedNoCreator | skipped(nameMismatch)=$skippedNameMismatch');
  }

  List<KpiJournalEmployee> _applySearch(
    List<KpiJournalEmployee> employees,
    String? query,
  ) {
    if (query == null || query.trim().isEmpty) return employees;
    final q = query.trim().toLowerCase();
    return employees.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  int _sumTaskDocsForPeriod(
    List<TaskItem> tasks,
    DateTime? startDate,
    DateTime? endDate,
    Set<String> activeTaskGuids,
  ) {
    int total = 0;
    final processedTasks = <String>{};

    for (final task in tasks) {
      if (task.parentGuidfixed.isNotEmpty) continue;
      if (task.status != 3 && task.status != 4 && task.status != 6) continue;
      if (!_isTaskRelevantToPeriod(
        task,
        startDate,
        endDate,
        activeTaskGuids,
      )) {
        continue;
      }
      if (!processedTasks.add(task.guidfixed)) continue;

      total += _requiredDocsToRecord(task);
    }

    return total;
  }

  int _requiredDocsToRecord(TaskItem task) {
    int passedDocs = 0;
    int notRequiredApprovalDocs = 0;

    for (final status in task.totalDocumentStatus) {
      if (status.status == 1) passedDocs += status.total;
      if (status.status == 6) notRequiredApprovalDocs += status.total;
    }

    if (task.status == 6 && notRequiredApprovalDocs == 0) {
      notRequiredApprovalDocs = task.totalDocument;
    }

    final requiredDocs = passedDocs - notRequiredApprovalDocs;
    return requiredDocs > 0 ? requiredDocs : 0;
  }

  bool _isTaskRelevantToPeriod(
    TaskItem task,
    DateTime? startDate,
    DateTime? endDate,
    Set<String> activeTaskGuids,
  ) {
    if (_isTaskOwnerAtInRange(task, startDate, endDate)) return true;
    if (activeTaskGuids.contains(task.guidfixed)) return true;

    final childGuid = task.taskChild?.guidfixed;
    return childGuid != null &&
        childGuid.isNotEmpty &&
        activeTaskGuids.contains(childGuid);
  }

  bool _isTaskOwnerAtInRange(
    TaskItem task,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final ownerAt = task.ownerAt;
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      if (ownerAt.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      if (ownerAt.isAfter(end)) return false;
    }
    return true;
  }

  String _normalizeShopName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  _DateRange _currentMonthRange() {
    final now = DateTime.now();
    return _DateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month, now.day),
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange(this.start, this.end);
}

// ─── Private accumulator ────────────────────────────────────────────────────

// ─── per-shop accumulator ────────────────────────────────────────────────────
class _ShopAccum {
  final String shopName;
  int count = 0;
  final Map<String, int> byBookCode = {};
  DateTime? lastActive;
  final List<KpiJournalDetail> details = [];

  int totalChecked = 0;
  int totalUpdated = 0;

  _ShopAccum(this.shopName);

  KpiJournalShopStat build() {
    return KpiJournalShopStat(
      shopName: shopName,
      count: count,
      totalDocument: 0, // This is overwritten in Accumulator.build
      byBookCode: Map.unmodifiable(byBookCode),
      lastActive: lastActive,
      details: List.unmodifiable(details),
      totalChecked: totalChecked,
      totalUpdated: totalUpdated,
    );
  }
}

class _Accumulator {
  final String name;
  int totalJournals = 0;
  int totalLinkedJournals = 0;
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  DateTime? lastActive;
  final List<KpiJournalDetail> details = [];
  final Map<String, int> byBookCode = {};
  final Map<String, _ShopAccum> _shopAccums = {};

  _Accumulator(this.name);

  void add(
    dynamic j,
    String shopName,
    Map<String, int> taskDocCountMap,
    Map<String, String> taskNameMap,
  ) {
    final String taskId = j.jobGuidfixed?.toString() ?? '';
    final String docRef = j.documentRef?.toString() ?? '';

    totalJournals++;
    final bool isLinkedToTask = taskId.isNotEmpty || docRef.isNotEmpty;
    if (isLinkedToTask) {
      totalLinkedJournals++;
    }

    final d = (j.debit ?? 0.0) is double
        ? (j.debit ?? 0.0)
        : (j.debit ?? 0.0).toDouble();
    final c = (j.credit ?? 0.0) is double
        ? (j.credit ?? 0.0)
        : (j.credit ?? 0.0).toDouble();
    totalDebit += d as double;
    totalCredit += c as double;

    final bk = (j.bookCode ?? '').toString();
    if (bk.isNotEmpty) byBookCode[bk] = (byBookCode[bk] ?? 0) + 1;

    DateTime? dt;
    try {
      if (j.docDatetime != null) dt = DateTime.parse(j.docDatetime!).toLocal();
    } catch (_) {}
    DateTime? creAt;
    try {
      if (j.createdAt != null) creAt = DateTime.parse(j.createdAt!).toLocal();
    } catch (_) {}
    DateTime? updAt;
    try {
      if (j.updatedAt != null) updAt = DateTime.parse(j.updatedAt!).toLocal();
    } catch (_) {}
    DateTime? chkAt;
    try {
      if (j.checkedAt != null) chkAt = DateTime.parse(j.checkedAt!).toLocal();
    } catch (_) {}

    if (dt != null && (lastActive == null || dt.isAfter(lastActive!))) {
      lastActive = dt;
    }

    String? tName;
    if (taskId.isNotEmpty) {
      tName = taskNameMap[taskId] ?? 'Task ถูกลบ/ไม่พบ';
    } else if (j.documentRef?.toString().isNotEmpty == true) {
      tName = '(Manual)';
    } else {
      tName = '(ไม่ได้บันทึกจากรูป)';
    }

    final amt = (j.apiAmount ?? 0.0) is double
        ? (j.apiAmount ?? 0.0) as double
        : ((j.apiAmount ?? 0.0) as num).toDouble();

    final detail = KpiJournalDetail(
      docNo: j.docNo ?? '',
      docDate: dt,
      bookCode: bk,
      debit: d,
      credit: c,
      amount: amt,
      shopName: shopName,
      accountDescription: j.description,
      checkedBy: j.checkedBy?.toString().trim(),
      checkedAt: chkAt,
      updatedBy: j.updatedBy?.toString().trim(),
      createdBy: j.createdBy?.toString().trim(),
      createdAt: creAt,
      updatedAt: updAt,
      taskName: tName,
    );

    details.add(detail);

    // per-shop tracking
    if (shopName.isNotEmpty) {
      _shopAccums.putIfAbsent(shopName, () => _ShopAccum(shopName));
      final sa = _shopAccums[shopName]!;
      sa.count++;

      if (bk.isNotEmpty) sa.byBookCode[bk] = (sa.byBookCode[bk] ?? 0) + 1;
      if (dt != null && (sa.lastActive == null || dt.isAfter(sa.lastActive!))) {
        sa.lastActive = dt;
      }
      sa.details.add(detail);

      // Only count when THIS employee (the keyer) is also the checker/updater
      final checked = (j.checkedBy ?? '').trim();
      if (checked == name) sa.totalChecked++;
      final updated = (j.updatedBy ?? '').trim();
      if (updated == name) sa.totalUpdated++;
    }
  }

  KpiJournalEmployee build(Map<String, int> shopTotalDocsMap) {
    final shopStats = _shopAccums.values.map((sa) {
      final st = sa.build();
      return KpiJournalShopStat(
        shopName: st.shopName,
        count: st.count,
        totalDocument: shopTotalDocsMap[st.shopName] ?? 0,
        byBookCode: st.byBookCode,
        lastActive: st.lastActive,
        details: st.details,
        totalChecked: st.totalChecked,
        totalUpdated: st.totalUpdated,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    details.sort((a, b) {
      if (a.docDate == null && b.docDate == null) return 0;
      if (a.docDate == null) return 1;
      if (b.docDate == null) return -1;
      return b.docDate!.compareTo(a.docDate!); // จับคู่ใหม่ -> เก่า
    });

    int empTotalDoc = 0;
    for (final s in shopStats) {
      empTotalDoc += s.totalDocument;
    }

    return KpiJournalEmployee(
      name: name,
      totalJournals: totalJournals,
      totalLinkedJournals: totalLinkedJournals,
      totalDocument: empTotalDoc,
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

