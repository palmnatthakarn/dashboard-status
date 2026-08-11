import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/journal.dart';
import '../../models/kpi_combined_employee.dart';
import '../../services/auth_repository.dart';
import '../../services/document_image_service.dart';
import '../../services/employee_mapping_service.dart';
import '../../services/journal_service.dart';
import '../../services/multi_shop_service.dart';
import '../../services/task_service.dart';
import '../../utils/app_logger.dart';
import 'kpi_combined_event.dart';
import 'kpi_fetch_scope.dart';
import 'kpi_combined_state.dart';

/// One shop's raw fetch result: every task and every GL journal row for
/// that shop, collected in a single sequential pass. This is the whole
/// point of the merge — the original separate KPI and KPI Journal pages
/// each independently selected the shop and fetched both tasks and GL
/// journals for it, so viewing both pages back to back meant doing that
/// work twice. Here it happens once per shop.
class _ShopRawData {
  final KpiCombinedShopItem shop;
  final List<TaskItem> tasks;
  final List<Journal> journals;

  _ShopRawData(this.shop, this.tasks, this.journals);
}

// Shared shape for the raw fetch result, named once so it doesn't have to
// be repeated identically across _fetchShopRawData / _doFetchShopRawData /
// _inFlightFetches (previously a bare record type duplicated in all three,
// which is how it's easy to update one and forget the others).
typedef _ShopFetchResult = ({
  List<_ShopRawData> raw,
  Map<String, int> imageGroupDocCounts,
  Map<String, String> docNoToTaskGuid,
  // taskGuid -> (uploader -> image count) — see
  // DocumentImageService.fetchDocNoToTaskGuidMap's taskUploaderCounts doc
  // comment. Piggybacks on the exact same /documentimagegroup fetch as
  // docNoToTaskGuid, so it's threaded through every spot that field is.
  Map<String, Map<String, int>> taskUploaderCounts,
  int docNoMapTotalItemsSeen,
  int? docNoMapApiReportedTotal,
});

class _FetchCacheEntry {
  final List<_ShopRawData> raw;
  final Map<String, int> imageGroupDocCounts;
  // docNo -> taskGuid, from /documentimagegroup's own `taskguid` +
  // `references[].docno` — a link between task and GL journal that never
  // goes through journal.jobguidfixed at all (the "recorded from photo"
  // path). See DocumentImageService.fetchDocNoToTaskGuidMap.
  final Map<String, String> docNoToTaskGuid;
  // taskGuid -> (uploader -> image count) — see _ShopFetchResult's field of
  // the same name.
  final Map<String, Map<String, int>> taskUploaderCounts;
  // Raw item count actually paged through, and what the API's own
  // pagination metadata says the true total is — kept alongside the map
  // itself (not just logged) so the UI can show "map has N entries, built
  // from X of Y total items" even when console/DevTools access isn't
  // available, which is the only way to tell "pagination stopped short"
  // apart from "this docNo genuinely isn't in the source data".
  final int docNoMapTotalItemsSeen;
  final int? docNoMapApiReportedTotal;
  final DateTime cachedAt;

  _FetchCacheEntry(
    this.raw,
    this.imageGroupDocCounts,
    this.docNoToTaskGuid,
    this.taskUploaderCounts,
    this.docNoMapTotalItemsSeen,
    this.docNoMapApiReportedTotal,
    this.cachedAt,
  );
}

/// Per-employee, per-shop running totals while merging task + journal data.
/// Converted to an immutable [KpiCombinedShopStat] once accumulation for a
/// shop is done.
class _ShopAcc {
  final String shopName;

  // เอกสาร (task workflow)
  int totalDocuments = 0;
  int waitingVerify = 0;
  int passed = 0;
  int cancelled = 0;
  int notRecorded = 0;
  int notRequiredApproval = 0;
  int requiredToRecord = 0;
  int recorded = 0;
  int remaining = 0;
  int completed = 0;

  // บันทึกบัญชี (GL journal)
  int journalRequiredDocs = 0;
  int journalCount = 0;
  // "คีย์" entries that couldn't be traced through EITHER link path at all
  // (no jobguidfixed, no documentimagegroup photo reference) — split out
  // of [journalCount] per 2026-07 request so a genuinely-untraceable
  // manual entry doesn't inflate the same number as one that at least has
  // a photo behind it, just an unresolved task.
  int journalCountNoPhoto = 0;
  int journalChecked = 0;
  int journalUpdated = 0;
  final Set<String> _journalDocKeys = {};
  final Set<String> _journalNoPhotoDocKeys = {};

  // รูปภาพที่อัปโหลด — see KpiCombinedShopStat.uploadedCount doc comment.
  int uploadedCount = 0;

  // The actual tasks behind the totals above — powers the drill-down UI.
  final List<KpiCombinedTaskItem> tasks = [];

  // GL journal rows counted into journalCount/journalChecked/journalUpdated
  // that couldn't be traced back to any task in [tasks] — see
  // KpiCombinedShopStat.orphanJournalEntries for why this exists.
  final List<KpiCombinedJournalItem> orphanJournals = [];

  _ShopAcc(this.shopName);

  void addKeyedJournal(Journal journal, {required bool noPhoto}) {
    final key = journalCountKey(journal);
    final targetSet = noPhoto ? _journalNoPhotoDocKeys : _journalDocKeys;
    if (!targetSet.add(key)) return;
    if (noPhoto) {
      journalCountNoPhoto++;
    } else {
      journalCount++;
    }
  }

  static String journalCountKey(Journal journal) {
    final docNo = (journal.docNo ?? '').trim();
    if (docNo.isNotEmpty) return 'doc:$docNo';

    final createdAt = (journal.createdAt ?? '').trim();
    final bookCode = (journal.bookCode ?? '').trim();
    final accountCode = (journal.accountCode ?? '').trim();
    final debit = journal.debit?.toString() ?? '';
    final credit = journal.credit?.toString() ?? '';
    return 'row:$createdAt|$bookCode|$accountCode|$debit|$credit';
  }

  KpiCombinedShopStat build() {
    final sortedTasks = [...tasks]
      ..sort((a, b) => b.ownerAt.compareTo(a.ownerAt));
    return KpiCombinedShopStat(
      shopName: shopName,
      totalDocuments: totalDocuments,
      waitingVerify: waitingVerify,
      passed: passed,
      cancelled: cancelled,
      notRecorded: notRecorded,
      notRequiredApproval: notRequiredApproval,
      requiredToRecord: requiredToRecord,
      recorded: recorded,
      remaining: remaining,
      completed: completed,
      journalRequiredDocs: journalRequiredDocs,
      journalCount: journalCount,
      journalCountNoPhoto: journalCountNoPhoto,
      journalChecked: journalChecked,
      journalUpdated: journalUpdated,
      uploadedCount: uploadedCount,
      tasks: sortedTasks,
      orphanJournalEntries: orphanJournals,
    );
  }
}

class KpiCombinedBloc extends Bloc<KpiCombinedEvent, KpiCombinedState> {
  /// How long a fetched (tasks + GL journals) result stays valid before a
  /// fresh fetch is triggered again for the same set of shops + date range.
  static const Duration _cacheTtl = Duration(minutes: 2);

  // NOTE: shop fetches are intentionally kept strictly SEQUENTIAL, one shop
  // fully at a time — confirmed by live testing against the real API
  // (2026-07) that /gl/journal ignores its own shopids query param entirely
  // and instead returns data for whichever shop was last selected via
  // POST /select-shop on this session/token. Running these concurrently
  // across shops would race on that shared session state and silently mix
  // up / drop data between shops. Do not parallelize without a backend
  // change that makes shop scoping stateless per-request. (Same constraint
  // documented in KpiBloc / KpiJournalBloc.)
  static const int _glJournalPageLimit = 1000;

  // static (not instance) so the cache survives KpiCombinedBloc being
  // disposed and recreated on page navigation, same reasoning as
  // KpiBloc._fetchCache / KpiJournalBloc._resultCache.
  static final Map<String, _FetchCacheEntry> _fetchCache = {};

  // Root-caused 2026-07: DashboardContent creates its OWN KpiCombinedBloc
  // (for the overview summary cards) and the standalone KPI page creates a
  // SEPARATE one — both fire LoadKpiCombinedData for "all shops, current
  // month" on mount. Disposing a bloc (e.g. switching tabs) does NOT cancel
  // its already-in-flight async fetch; the sequential per-shop select-shop
  // → fetch-tasks → fetch-journals loop keeps running in the background.
  // So if a user opens the Dashboard then switches to the KPI tab before
  // the Dashboard's fetch has finished, TWO independent sequential loops
  // end up hitting select-shop concurrently on the same session/token —
  // exactly the race the comment above warns about — and whichever shop
  // each loop THINKS it just selected can silently be wrong, cross-
  // contaminating data between shops. No exception is thrown anywhere
  // (each individual HTTP call still "succeeds"), so it only shows up as
  // numbers that mysteriously differ between runs depending on timing.
  // Keyed by the same cacheKey as _fetchCache so any second caller for the
  // identical shop-set + date-range awaits the FIRST call's single fetch
  // instead of starting a redundant, racing one of its own.
  static final Map<String, Future<_ShopFetchResult>> _inFlightFetches = {};

  /// Call this on logout / account switch so the next login doesn't briefly
  /// show a previous account's cached data.
  static void clearCache() => _fetchCache.clear();

  KpiCombinedBloc() : super(_initialLoadedState()) {
    on<LoadKpiCombinedData>(_onLoad);
    on<SelectShopAndSearchCombined>(_onSelectShopAndSearch);
    on<LoadKpiCombinedShopDetails>(_onLoadShopDetails);
  }

  static KpiCombinedLoaded _initialLoadedState() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    return KpiCombinedLoaded(
      employees: const [],
      filteredEmployees: const [],
      shops: const [],
      startDate: startDate,
      endDate: endDate,
      hasSearched: false,
    );
  }

  Future<void> _onLoad(
    LoadKpiCombinedData event,
    Emitter<KpiCombinedState> emit,
  ) async {
    emit(KpiCombinedLoading());
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      List<KpiCombinedShopItem> shops = [];
      List<KpiCombinedEmployee> employees = [];

      if (AuthRepository.isAuthenticated) {
        try {
          final shopList = await MultiShopService.listShops();
          shops = shopList.map(_parseShopItem).toList();

          final raw = <_ShopRawData>[];
          final imageGroupDocCounts = <String, int>{};
          final docNoToTaskGuid = <String, String>{};
          final taskUploaderCounts = <String, Map<String, int>>{};
          var docNoMapTotalItemsSeen = 0;
          int? docNoMapApiReportedTotal;
          for (final shop in shops) {
            final fetched = await _fetchShopRawData(
              [shop],
              startDate: startDate,
              endDate: endDate,
              forceRefresh: event.forceRefresh,
              includeDocNoMap: true,
            );
            raw.addAll(fetched.raw);
            imageGroupDocCounts.addAll(fetched.imageGroupDocCounts);
            docNoToTaskGuid.addAll(fetched.docNoToTaskGuid);
            _mergeTaskUploaderCounts(
              taskUploaderCounts,
              fetched.taskUploaderCounts,
            );
            docNoMapTotalItemsSeen += fetched.docNoMapTotalItemsSeen;
            if (fetched.docNoMapApiReportedTotal != null) {
              docNoMapApiReportedTotal =
                  (docNoMapApiReportedTotal ?? 0) +
                  fetched.docNoMapApiReportedTotal!;
            }
            employees = _buildCombinedEmployees(
              raw,
              imageGroupDocCounts,
              docNoToTaskGuid,
              taskUploaderCounts: taskUploaderCounts,
              docNoMapTotalItemsSeen: docNoMapTotalItemsSeen,
              docNoMapApiReportedTotal: docNoMapApiReportedTotal,
              startDate: startDate,
              endDate: endDate,
              includeDetails: false,
              resolveNoPhoto: true,
            );
            emit(
              KpiCombinedLoaded(
                employees: employees,
                filteredEmployees: await _applySearch(
                  employees,
                  null,
                  const [],
                ),
                shops: shops,
                startDate: startDate,
                endDate: endDate,
                summaryReady: false,
              ),
            );
          }

          employees = _buildCombinedEmployees(
            raw,
            imageGroupDocCounts,
            docNoToTaskGuid,
            taskUploaderCounts: taskUploaderCounts,
            docNoMapTotalItemsSeen: docNoMapTotalItemsSeen,
            docNoMapApiReportedTotal: docNoMapApiReportedTotal,
            startDate: startDate,
            endDate: endDate,
            includeDetails: false,
            resolveNoPhoto: true,
          );
        } catch (e) {
          dLog('⚠️ Failed to load combined KPI data: $e');
        }
      }

      emit(
        KpiCombinedLoaded(
          employees: employees,
          filteredEmployees: await _applySearch(employees, null, const []),
          shops: shops,
          startDate: startDate,
          endDate: endDate,
          summaryReady: true,
          hasSearched: true,
        ),
      );
    } catch (e) {
      emit(KpiCombinedError('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}'));
    }
  }

  Future<void> _onSelectShopAndSearch(
    SelectShopAndSearchCombined event,
    Emitter<KpiCombinedState> emit,
  ) async {
    if (state is! KpiCombinedLoaded) return;
    final current = state as KpiCombinedLoaded;

    emit(
      current.copyWith(
        isSearching: true,
        selectedShopIds: event.shopIds,
        selectedShopNames: event.shopNames,
      ),
    );

    try {
      var shops = current.shops;
      if (shops.isEmpty && AuthRepository.isAuthenticated) {
        final shopList = await MultiShopService.listShops();
        shops = shopList.map(_parseShopItem).toList();
      }

      final targetShops = event.shopIds.isEmpty
          ? shops
          : shops
                .where((s) => event.shopIds.contains(s.shopId))
                .toList();

      final startDate = event.startDate ?? current.startDate;
      final endDate = event.endDate ?? current.endDate;

      final fetched = await _fetchShopRawData(
        targetShops,
        startDate: startDate,
        endDate: endDate,
        includeDocNoMap: true,
      );
      final employees = _buildCombinedEmployees(
        fetched.raw,
        fetched.imageGroupDocCounts,
        fetched.docNoToTaskGuid,
        taskUploaderCounts: fetched.taskUploaderCounts,
        docNoMapTotalItemsSeen: fetched.docNoMapTotalItemsSeen,
        docNoMapApiReportedTotal: fetched.docNoMapApiReportedTotal,
        startDate: startDate,
        endDate: endDate,
        includeDetails: false,
        resolveNoPhoto: true,
      );

      final query = event.query ?? current.searchQuery;
      final employeeNames = event.employeeNames;

      emit(
        current.copyWith(
          employees: employees,
          filteredEmployees: await _applySearch(
            employees,
            query,
            employeeNames,
          ),
          shops: shops,
          selectedShopIds: event.shopIds,
          selectedShopNames: event.shopNames,
          startDate: startDate,
          endDate: endDate,
          searchQuery: query,
          selectedEmployeeNames: employeeNames,
          isSearching: false,
          detailLoadedShopNames: const [],
          detailLoadingShopNames: const [],
          detailErrorShopNames: const [],
          summaryReady: true,
          hasSearched: true,
        ),
      );
    } catch (e) {
      dLog('❌ Error fetching combined KPI data: $e');
      if (AuthRepository.isSessionExpiredError(e.toString())) {
        emit(KpiCombinedError('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}'));
        return;
      }
      emit(
        current.copyWith(
          isSearching: false,
          employees: const [],
          filteredEmployees: const [],
        ),
      );
    }
  }

  Future<void> _onLoadShopDetails(
    LoadKpiCombinedShopDetails event,
    Emitter<KpiCombinedState> emit,
  ) async {
    if (state is! KpiCombinedLoaded) return;
    final current = state as KpiCombinedLoaded;
    final shopName = event.shopName;
    if (current.detailLoadedShopNames.contains(shopName) ||
        current.detailLoadingShopNames.contains(shopName)) {
      return;
    }

    KpiCombinedShopItem? shop;
    for (final candidate in current.shops) {
      if (candidate.shopName == shopName) {
        shop = candidate;
        break;
      }
    }
    if (shop == null) return;

    emit(
      current.copyWith(
        detailLoadingShopNames: [...current.detailLoadingShopNames, shopName],
        detailErrorShopNames: current.detailErrorShopNames
            .where((s) => s != shopName)
            .toList(),
      ),
    );

    try {
      final fetched = await _fetchShopRawData(
        [shop],
        startDate: current.startDate,
        endDate: current.endDate,
        includeDocNoMap: true,
      );
      final detailedEmployees = _buildCombinedEmployees(
        fetched.raw,
        fetched.imageGroupDocCounts,
        fetched.docNoToTaskGuid,
        taskUploaderCounts: fetched.taskUploaderCounts,
        docNoMapTotalItemsSeen: fetched.docNoMapTotalItemsSeen,
        docNoMapApiReportedTotal: fetched.docNoMapApiReportedTotal,
        startDate: current.startDate,
        endDate: current.endDate,
        includeDetails: true,
      );
      final employees = _mergeDetailedShop(
        current.employees,
        detailedEmployees,
        shopName,
      );
      emit(
        current.copyWith(
          employees: employees,
          filteredEmployees: await _applySearch(
            employees,
            current.searchQuery,
            current.selectedEmployeeNames,
          ),
          detailLoadedShopNames: [...current.detailLoadedShopNames, shopName],
          detailLoadingShopNames: current.detailLoadingShopNames
              .where((s) => s != shopName)
              .toList(),
          detailErrorShopNames: current.detailErrorShopNames
              .where((s) => s != shopName)
              .toList(),
        ),
      );
    } catch (e) {
      dLog('❌ Error fetching combined KPI detail for $shopName: $e');
      emit(
        current.copyWith(
          detailLoadingShopNames: current.detailLoadingShopNames
              .where((s) => s != shopName)
              .toList(),
          detailErrorShopNames: [...current.detailErrorShopNames, shopName],
        ),
      );
    }
  }

  KpiCombinedShopItem _parseShopItem(dynamic shop) {
    final shopId =
        shop['shopid']?.toString() ??
        shop['shop_id']?.toString() ??
        shop['id']?.toString() ??
        '';
    String shopName =
        shop['shopname']?.toString() ?? shop['shop_name']?.toString() ?? shopId;
    if (shop['names'] != null && (shop['names'] as List).isNotEmpty) {
      shopName = (shop['names'] as List).first['name']?.toString() ?? shopName;
    }
    return KpiCombinedShopItem(shopId: shopId, shopName: shopName);
  }

  String _shopCacheKey(
    List<KpiCombinedShopItem> shops, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final s = startDate != null ? JournalService.formatDate(startDate) : '-';
    final e = endDate != null ? JournalService.formatDate(endDate) : '-';
    return KpiFetchScope.cacheKey(
      account: AuthRepository.username ?? '',
      shopIds: shops.map((shop) => shop.shopId),
      startDate: s,
      endDate: e,
    );
  }

  /// Fetches tasks + every GL journal page for [shops], one shop fully at a
  /// time (select-shop happens implicitly inside [TaskService.
  /// fetchTasksForShop]; the GL journal fetch immediately follows for that
  /// SAME shop while the session is still on it — no second select-shop
  /// call needed, unlike the original two separate pages which each did
  /// their own select-shop).
  Future<_ShopFetchResult> _fetchShopRawData(
    List<KpiCombinedShopItem> shops, {
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
    bool includeDocNoMap = true,
  }) async {
    final cacheKey =
        '${_shopCacheKey(shops, startDate: startDate, endDate: endDate)}|docmap:${includeDocNoMap ? 1 : 0}';
    final cached = forceRefresh ? null : _fetchCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      dLog(
        '📋 Using cached combined KPI data for ${shops.length} shop(s) '
        '(${DateTime.now().difference(cached.cachedAt).inSeconds}s old)',
      );
      return (
        raw: cached.raw,
        imageGroupDocCounts: cached.imageGroupDocCounts,
        docNoToTaskGuid: cached.docNoToTaskGuid,
        taskUploaderCounts: cached.taskUploaderCounts,
        docNoMapTotalItemsSeen: cached.docNoMapTotalItemsSeen,
        docNoMapApiReportedTotal: cached.docNoMapApiReportedTotal,
      );
    }

    // If another KpiCombinedBloc instance (e.g. DashboardContent's, or a
    // second KPI page) already has an identical fetch in flight, await
    // THAT one instead of starting a second sequential per-shop loop that
    // would race it on the backend's shared select-shop session state.
    final inFlight = _inFlightFetches[cacheKey];
    if (inFlight != null) {
      dLog(
        '⏳ Combined KPI fetch for ${shops.length} shop(s) already in '
        'flight (likely another page/bloc) — awaiting it instead of '
        'starting a duplicate, racing fetch.',
      );
      return inFlight;
    }

    final future = _doFetchShopRawData(
      shops,
      cacheKey: cacheKey,
      startDate: startDate,
      endDate: endDate,
      includeDocNoMap: includeDocNoMap,
    );
    _inFlightFetches[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightFetches.remove(cacheKey);
    }
  }

  Future<_ShopFetchResult> _doFetchShopRawData(
    List<KpiCombinedShopItem> shops, {
    required String cacheKey,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDocNoMap = true,
  }) async {
    final startStr = startDate != null
        ? JournalService.formatDate(startDate)
        : null;
    final endStr = endDate != null ? JournalService.formatDate(endDate) : null;

    // Document-image-group doc counts ("ต้องบันทึก(รูปภาพ)"), used for the
    // journal side's own "ต้องบันทึก" figure (a DIFFERENT source than the
    // task-based one — see KpiCombinedEmployee's doc comment).
    //
    // Root-caused 2026-07: this used to be ONE unscoped call up front
    // (DocumentImageService.fetchDocumentImageGroups), matching
    // KpiJournalBloc's pattern — but that function tries to build a
    // shop-keyed map from response fields (guidfixedid/shopid/shop_id/
    // shopname) that don't exist on the real /documentimagegroup response
    // at all, so the resulting map was ALWAYS empty and "ต้องบันทึก
    // (รูปภาพ)" showed 0 for every shop, unconditionally. Same root class
    // of bug as docNoToTaskGuid's (below): the endpoint has no way to
    // self-identify which shop a result belongs to, so it has to be called
    // ONCE PER SHOP right after that shop is selected instead — see
    // DocumentImageService.fetchShopBillCount's doc comment. Accumulated
    // into imageGroupDocCounts below, inside the per-shop loop.
    final Map<String, int> imageGroupDocCounts = {};

    // docNo -> taskGuid (see DocumentImageService.fetchDocNoToTaskGuidMap's
    // doc comment for the full chain: task -> taskguid -> document image
    // group -> references[].docno -> GL journal — a link that never goes
    // through journal.jobguidfixed at all). Deliberately UNDATED (no
    // fromDate/toDate) — has to resolve a GL journal regardless of when the
    // *document* was uploaded, only caring about when the journal itself
    // was keyed (handled separately via _isWithinRange(j.createdAt, ...)
    // below).
    //
    // Fetched INSIDE the per-shop loop, right after that shop is
    // selected — same as imageGroupDocCounts above (both hit
    // /documentimagegroup). Root-caused 2026-07: a single unscoped call
    // made before/parallel to shop selection paged through every item the
    // backend returned (confirmed
    // complete: totalItemsSeen == apiReportedTotal == 2332) and still never
    // saw JV690709-0012 / JV690710-0001, even though a manually captured
    // request scoped by taskguid — made from a browser session that
    // actually had shop "test" selected — proved that document exists.
    // /documentimagegroup evidently has the SAME session-based shop-scoping
    // quirk already documented below for /gl/journal (ignores any shopid
    // query param, reads whichever shop was last selected via POST
    // /select-shop): the unscoped call was silently reading whatever shop
    // happened to be selected in the session at that random moment — not
    // "all shops combined" — so it could page through thousands of real
    // items and still structurally never reach shop "test"'s groups at
    // all. Fetching per-shop, right after TaskService.fetchTasksForShop has
    // already selected that exact shop, is the same fix already applied to
    // tasks and GL journals for this identical class of bug.
    final Map<String, String> docNoToTaskGuid = {};
    // taskGuid -> (uploader -> image count), accumulated across shops the
    // same way docNoToTaskGuid is — see DocumentImageService.
    // fetchDocNoToTaskGuidMap's taskUploaderCounts doc comment.
    final Map<String, Map<String, int>> taskUploaderCounts = {};
    var docNoMapTotalItemsSeen = 0;
    int? docNoMapApiReportedTotal;

    final List<_ShopRawData> raw = [];
    // Whether EVERY shop's fetch fully completed — tasks AND GL journal
    // pagination. A single dropped page/request (transient network
    // hiccup, timeout, rate limit, or the wrong shop silently getting
    // selected due to the race noted above) used to be swallowed
    // silently — the loop just kept going with whatever partial data it
    // had as if it were the complete set. Since task inclusion now
    // depends on GL journal completeness too (a task can be pulled into
    // view purely because it has an in-range GL entry — see
    // taskHasInRangeJournal), a partial fetch doesn't just drop a few
    // rows, it can silently change which TASKS show up at all, producing
    // different "ยอดงาน" totals across two loads of otherwise unchanged
    // backend data (reported: hot restart twice in a row, no one touched
    // the backend in between, task totals still differed — then reported
    // AGAIN after this section grew two more sequential awaits, which
    // just gave the underlying race more time to land; the missing half
    // of the original fix was that a failed TASK fetch specifically was
    // never flagged here, only a failed GL journal page was). Track
    // completeness so a partial fetch is at least visible in logs and,
    // more importantly, never gets written to the 2-minute cache — a
    // failed fetch shouldn't poison every view for the next 2 minutes.
    var allComplete = true;

    for (final shop in shops) {
      final releaseShopSession = await MultiShopService.acquireShopSession();
      try {
        List<TaskItem> tasks = [];
        final response = await TaskService.fetchTasksForShop(
          shopId: shop.shopId,
          limit: 5000,
          status: const [0, 1, 2, 3, 4, 5, 6],
        );
        if (response.success) {
          tasks = response.tasks;
        } else {
          dLog(
            '⚠️ Task fetch for shop ${shop.shopName} returned success=false '
            '— treating as incomplete so this result never gets cached.',
          );
          allComplete = false;
        }
      // Kicked off CONCURRENTLY (not one `await` after another) —
      // performance fix requested 2026-07. All three of these are pure
      // reads against whichever shop TaskService.fetchTasksForShop just
      // selected above: verified none of JournalService.getAllGLJournals,
      // DocumentImageService.fetchDocNoToTaskGuidMap, or
      // fetchShopBillCount ever call MultiShopService.selectShop
      // themselves, so there's no race in running them side by side — the
      // session's selected shop doesn't change again until the NEXT loop
      // iteration's fetchTasksForShop call. Previously these ran strictly
      // sequentially for no correctness reason, roughly tripling the wait
      // per shop (each one can itself be several paginated requests) for
      // accounts with many shops.
      final journalFuture = _fetchAllGLJournalsForShop(
        shop,
        startStr: startStr,
        endStr: endStr,
      );
      final docNoFuture = includeDocNoMap
          ? DocumentImageService.fetchDocNoToTaskGuidMap(
              page: 1,
              perPage: 9999,
            ).catchError((e) {
              allComplete = false;
              dLog(
                '⚠️ Failed to fetch docNo→taskGuid map for shop ${shop.shopName}: $e',
              );
              return (
                docNoToTaskGuid: <String, String>{},
                taskUploaderCounts: <String, Map<String, int>>{},
                totalItemsSeen: 0,
                apiReportedTotal: null,
              );
            })
          : Future.value((
              docNoToTaskGuid: <String, String>{},
              taskUploaderCounts: <String, Map<String, int>>{},
              totalItemsSeen: 0,
              apiReportedTotal: null,
            ));
      // Scoped to the selected date range (unlike docNoFuture, which is
      // deliberately undated) since "ต้องบันทึก(รูปภาพ)" is meant to
      // reflect documents due within the period being viewed, matching how
      // the task-side "ต้องบันทึก(งาน)" figure is implicitly scoped too.
      final billCountFuture =
          DocumentImageService.fetchShopBillCount(
            fromDate: startStr,
            toDate: endStr,
          ).catchError((e) {
            allComplete = false;
            dLog(
              '⚠️ Failed to fetch documentimagegroup bill count for shop '
              '${shop.shopName}: $e',
            );
            return 0;
          });

      final result = await journalFuture;
      if (!result.complete) allComplete = false;
      raw.add(_ShopRawData(shop, tasks, result.journals));

      final shopDocNoResult = await docNoFuture;
      docNoToTaskGuid.addAll(shopDocNoResult.docNoToTaskGuid);
      _mergeTaskUploaderCounts(
        taskUploaderCounts,
        shopDocNoResult.taskUploaderCounts,
      );
      docNoMapTotalItemsSeen += shopDocNoResult.totalItemsSeen;
      if (shopDocNoResult.apiReportedTotal != null) {
        docNoMapApiReportedTotal =
            (docNoMapApiReportedTotal ?? 0) + shopDocNoResult.apiReportedTotal!;
      }
      dLog(
        '📄 [${shop.shopName}] docNo→taskGuid: '
        '${shopDocNoResult.docNoToTaskGuid.length} docNo(s) mapped from '
        '${shopDocNoResult.totalItemsSeen} raw item(s) (API reports '
        '${shopDocNoResult.apiReportedTotal} for this shop)',
      );

      final billCount = await billCountFuture;
      imageGroupDocCounts[shop.shopId] = billCount;
      dLog('📄 [${shop.shopName}] ต้องบันทึก(รูปภาพ): $billCount');
      } catch (e) {
        dLog('⚠️ Failed to load complete KPI data for ${shop.shopName}: $e');
        allComplete = false;
      } finally {
        releaseShopSession();
      }
    }

    // apiReportedTotal vs totalItemsSeen (now summed across every shop)
    // tells us whether the per-shop pagination loops actually reached
    // everything the backend says exists for each shop — if they're far
    // apart, a page fetch failed partway for some shop, and docNoToTaskGuid
    // is a PARTIAL map even though it's non-empty.
    dLog(
      '📄 docNo→taskGuid map (all shops): ${docNoToTaskGuid.length} docNo(s) '
      'mapped, $docNoMapTotalItemsSeen raw item(s) seen, API says '
      '$docNoMapApiReportedTotal exist in total',
    );

    if (allComplete) {
      _fetchCache[cacheKey] = _FetchCacheEntry(
        raw,
        imageGroupDocCounts,
        docNoToTaskGuid,
        taskUploaderCounts,
        docNoMapTotalItemsSeen,
        docNoMapApiReportedTotal,
        DateTime.now(),
      );
    } else {
      dLog(
        '⚠️ Combined KPI fetch for ${shops.length} shop(s) was incomplete '
        '(a GL journal page failed after retries) — not caching this '
        'result, next load will retry the full fetch instead of reusing '
        'partial data for 2 minutes.',
      );
    }
    return (
      raw: raw,
      imageGroupDocCounts: imageGroupDocCounts,
      docNoToTaskGuid: docNoToTaskGuid,
      taskUploaderCounts: taskUploaderCounts,
      docNoMapTotalItemsSeen: docNoMapTotalItemsSeen,
      docNoMapApiReportedTotal: docNoMapApiReportedTotal,
    );
  }

  /// Merges [src]'s per-task uploader counts into [dest] in place, summing
  /// counts when the same (taskGuid, uploader) pair appears in both — same
  /// shape of merge as `docNoToTaskGuid.addAll(...)` right next to every
  /// call site of this, just one level deeper since each value here is
  /// itself a map instead of a single string.
  void _mergeTaskUploaderCounts(
    Map<String, Map<String, int>> dest,
    Map<String, Map<String, int>> src,
  ) {
    src.forEach((taskGuid, uploaders) {
      final target = dest.putIfAbsent(taskGuid, () => <String, int>{});
      uploaders.forEach((uploader, count) {
        target.update(uploader, (c) => c + count, ifAbsent: () => count);
      });
    });
  }

  Future<({List<Journal> journals, bool complete})> _fetchAllGLJournalsForShop(
    KpiCombinedShopItem shop, {
    String? startStr,
    String? endStr,
  }) async {
    final List<Journal> allJournals = [];
    var complete = true;
    try {
      int page = 1;
      int totalPages = 1;

      do {
        // A single failed page used to end the whole fetch immediately and
        // silently return only what had been collected so far. Retry a
        // failed page a couple of times (brief backoff) before giving up —
        // most failures at this point are transient (timeout / rate limit),
        // not "this page genuinely doesn't exist".
        JournalResponse? resp;
        for (var attempt = 1; attempt <= 3; attempt++) {
          try {
            final candidate = await JournalService.getAllGLJournals(
              task: 'GL Journal',
              shopId: shop.shopId.isNotEmpty ? shop.shopId : null,
              page: page,
              limit: _glJournalPageLimit,
              startDate: startStr,
              endDate: endStr,
            );
            if (candidate.success == true && candidate.journals != null) {
              resp = candidate;
              break;
            }
          } catch (e) {
            dLog(
              '⚠️ GL journal page $page fetch failed for shop '
              '${shop.shopName} (attempt $attempt/3): $e',
            );
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
          }
        }

        if (resp == null) {
          dLog(
            '⚠️ Giving up on GL journal page $page for shop '
            '${shop.shopName} after 3 attempts — results for this shop are '
            'INCOMPLETE.',
          );
          complete = false;
          break;
        }

        final journals = resp.journals!;
        allJournals.addAll(journals);

        if (page == 1) {
          final p = resp.pagination;
          if (p != null) {
            totalPages =
                p.totalPages ??
                (p.total != null && p.total! > 0
                    ? ((p.total! + _glJournalPageLimit - 1) ~/
                          _glJournalPageLimit)
                    : 1);
          }
        }

        if (journals.length < _glJournalPageLimit) break;
        page++;
      } while (page <= totalPages);
    } catch (e) {
      dLog('⚠️ Failed to fetch GL journals for shop ${shop.shopName}: $e');
      complete = false;
    }
    return (journals: allJournals, complete: complete);
  }

  /// The core merge: for each shop's raw (tasks, journals), replays
  /// KpiBloc's task-workflow accounting AND KpiJournalBloc's journal-keying
  /// accounting on the SAME underlying data, keyed by (employee, shop) so
  /// the result is a genuine per-shop aggregate (KpiEmployee's original
  /// `companyDetails` was one row per TASK with a shop label attached, not
  /// actually summed per shop — this fixes that for the merged view).
  List<KpiCombinedEmployee> _buildCombinedEmployees(
    List<_ShopRawData> raw,
    Map<String, int> imageGroupDocCounts,
    Map<String, String> docNoToTaskGuid, {
    Map<String, Map<String, int>> taskUploaderCounts = const {},
    int docNoMapTotalItemsSeen = 0,
    int? docNoMapApiReportedTotal,
    DateTime? startDate,
    DateTime? endDate,
    bool includeDetails = true,
    bool? resolveNoPhoto,
  }) {
    final shouldResolveNoPhoto = resolveNoPhoto ?? includeDetails;
    final Map<String, Map<String, _ShopAcc>> employeeShopAcc = {};
    final Map<String, DateTime> lastActiveMap = {};

    final DateTime? start = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final DateTime? end = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        : null;

    _ShopAcc accFor(String employee, String shopName) => employeeShopAcc
        .putIfAbsent(employee, () => {})
        .putIfAbsent(shopName, () => _ShopAcc(shopName));

    // Every guid a journal's jobguidfixed could resolve to a real task
    // through, gathered across EVERY shop in this fetch — not just
    // whichever shop the journal itself is filed under. Built once, up
    // front, instead of per-shop: a first attempt scoped this set to only
    // the current shop's own /task response and a real task ("mai") still
    // came back false-orphan even after fixing GUID trim/casing, which
    // means the lookup itself was too narrow, not just the string
    // comparison — plausibly the task legitimately surfaces under a
    // different shop entry than the one its GL journal is filed under
    // (matches the documented /gl/journal shop-scoping quirk noted below
    // in _fetchAllGLJournalsForShop). Normalized (trim + lowercase) for
    // the same reason as before — TaskItem.guidfixed and
    // Journal.jobGuidfixed are both parsed with zero trimming.
    String normalizeGuid(String g) => g.trim().toLowerCase();
    final Set<String> knownTaskGuids = {
      for (final shopData in raw)
        for (final t in shopData.tasks)
          if (t.guidfixed.isNotEmpty) normalizeGuid(t.guidfixed),
      for (final shopData in raw)
        for (final t in shopData.tasks)
          if (t.taskChild != null && t.taskChild!.guidfixed.isNotEmpty)
            normalizeGuid(t.taskChild!.guidfixed),
    };
    // Normalized docNo -> taskGuid lookup, same map passed in but keyed
    // consistently with how journal.docNo gets compared below.
    final Map<String, String> normalizedDocNoToTaskGuid = {
      for (final entry in docNoToTaskGuid.entries)
        if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value,
    };
    // taskGuid -> (uploader -> count), keyed the same normalized way as
    // knownTaskGuids above so a lookup by task.guidfixed always matches
    // regardless of casing/whitespace differences between /task and
    // /documentimagegroup.
    final Map<String, Map<String, int>> normalizedTaskUploaderCounts = {
      for (final entry in taskUploaderCounts.entries)
        if (entry.key.trim().isNotEmpty) normalizeGuid(entry.key): entry.value,
    };

    // A journal's real task guid, resolving through BOTH known link paths:
    // (1) jobguidfixed — the direct task -> GL link most journals use, and
    // (2) docNo -> taskGuid via /documentimagegroup — the "recorded from
    // photo" path root-caused 2026-07, where a journal's jobguidfixed is
    // completely empty but the task IS traceable through the document
    // image group that produced it (task.guidfixed ==
    // documentimagegroup.taskguid, and documentimagegroup.references[]
    // lists the GL docno). Falls back to (2) only when (1) is empty, since
    // jobguidfixed is the more direct/authoritative link when present.
    String? resolveTaskGuid(Journal j) {
      final direct = j.jobGuidfixed;
      if (direct != null && direct.trim().isNotEmpty) return direct.trim();
      final docNo = (j.docNo ?? '').trim();
      if (docNo.isEmpty) return null;
      return normalizedDocNoToTaskGuid[docNo];
    }

    bool isOrphanJournal(Journal j) {
      final guid = resolveTaskGuid(j);
      if (guid == null || guid.isEmpty) return true;
      final known = knownTaskGuids.contains(normalizeGuid(guid));
      if (!known) {
        // Left in deliberately (not behind a flag) — this is exactly the
        // kind of mismatch that's impossible to diagnose from the UI
        // alone (a real task exists, the app just can't match the two
        // GUIDs). If this still fires for an entry the user says IS
        // task-linked, the printed guid is what to compare byte-for-byte
        // against that task's own guidfixed from the /task response.
        //
        // Uses plain print() (not just dLog/dart:developer.log) because
        // `flutter run -d web-server` doesn't auto-attach a debug session
        // the way `-d chrome` does — dart:developer.log() only reaches a
        // terminal/DevTools Logging tab if a browser tab is actively
        // connected as a debug client, which is easy to not have when
        // running headless. print() output is captured by the Flutter
        // tool's stdout relay regardless, so it always lands in whichever
        // terminal `flutter run` itself is running in. Still guarded by
        // kDebugMode directly so it's a no-op in release builds.
        if (kDebugMode) {
          final viaPhoto =
              (j.jobGuidfixed == null || j.jobGuidfixed!.trim().isEmpty) &&
              guid.isNotEmpty;
          // ignore: avoid_print
          print(
            '🔗 [ORPHAN-GL] docNo=${j.docNo ?? "(no docno)"} '
            'jobguidfixed="${j.jobGuidfixed}" '
            'resolvedGuid="$guid"${viaPhoto ? " (via documentimagegroup docNo match)" : ""} '
            '— no matching task guid found among ${knownTaskGuids.length} '
            'known task guids checked across all fetched shops. Treating '
            'as orphan (ไม่ผูกงาน).',
          );
        }
      }
      return !known;
    }

    for (final shopData in raw) {
      final shopName = shopData.shop.shopName;

      // Journal rows for this shop, grouped by the task guid they're linked
      // to — via jobguidfixed OR (falling back) the docNo -> taskGuid
      // photo-upload link resolved above, so a journal recorded through
      // that flow ends up attached to the SAME task row as one linked the
      // "normal" jobguidfixed way, instead of only ever showing up in the
      // orphan bucket. Kept as raw lists — NOT date-filtered here — so
      // both the "does this task belong in the selected range" test below
      // and the per-task merge apply the exact same date rule instead of
      // two slightly different copies of it.
      final Map<String, List<Journal>> journalListByTask = {};
      for (final j in shopData.journals) {
        final guid = resolveTaskGuid(j);
        if (guid != null && guid.isNotEmpty) {
          journalListByTask.putIfAbsent(guid, () => []).add(j);
        }
      }

      // A journal entry belongs to the selected range if it was actually
      // KEYED (created) inside it — same rule the "คีย์" aggregate counter
      // below uses, not the document's own docDatetime (see the
      // docDatetime-vs-action-timestamp note further down — that was the
      // original "test2" bug).
      bool journalInRange(Journal j) => _isWithinRange(j.createdAt, start, end);

      List<Journal> inRangeJournalsForGuid(String guid) =>
          (journalListByTask[guid] ?? const []).where(journalInRange).toList();

      // Built from EVERY task in the shop (not just the ones that end up
      // passing the date filter below) so a task whose GL entries were
      // keyed inside the selected range — but whose own ownerAt falls in a
      // different month — can still be found via its children/taskChild
      // guids when deciding whether to include it.
      final Map<String, List<String>> parentToChildren = {};
      for (final task in shopData.tasks) {
        if (task.parentGuidfixed.isNotEmpty) {
          parentToChildren
              .putIfAbsent(task.parentGuidfixed, () => [])
              .add(task.guidfixed);
        }
      }

      bool taskHasInRangeJournal(TaskItem task) {
        if (inRangeJournalsForGuid(task.guidfixed).isNotEmpty) return true;
        for (final childGuid in parentToChildren[task.guidfixed] ?? const []) {
          if (inRangeJournalsForGuid(childGuid).isNotEmpty) return true;
        }
        if (task.taskChild != null && task.taskChild!.guidfixed.isNotEmpty) {
          if (inRangeJournalsForGuid(task.taskChild!.guidfixed).isNotEmpty) {
            return true;
          }
        }
        return false;
      }

      bool ownerAtInRange(TaskItem task) =>
          start == null ||
          end == null ||
          (task.ownerAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
              task.ownerAt.isBefore(end));

      // ── TASK SIDE: date-filtered, contributor-row splitting ───────────
      // A task is included if EITHER its own ownerAt falls in the selected
      // range, OR it has GL journal entries that were actually keyed inside
      // the range even though ownerAt doesn't. Without the second
      // condition, a task opened in a different month than the one
      // selected would vanish from the view entirely, silently dropping
      // real keying activity that happened during the selected month from
      // the task/GL drill-down (reported: a task opened outside the
      // selected month, but with photos keyed into GL during the selected
      // month, should still surface based on the GL date).
      final filteredTasks = (start != null && end != null)
          ? shopData.tasks
                .where((t) => ownerAtInRange(t) || taskHasInRangeJournal(t))
                .toList()
          : shopData.tasks;

      for (final task in filteredTasks) {
        // Child tasks don't get their own row — their journal entries are
        // merged into the parent task below, same as the original KpiBloc.
        if (task.parentGuidfixed.isNotEmpty) continue;

        // Trimmed once here and reused for every map key / comparison below
        // — task.ownerBy comes from the /task API untrimmed, while journal
        // creator names are trimmed below, so comparing the raw values
        // could silently treat one real employee as two (e.g. "ownerBy "
        // never matching a trimmed "ownerBy" from combinedKeyerMap).
        final ownerBy = task.ownerBy.trim();

        // Journals linked to this task (incl. children), filtered to the
        // selected range by their OWN keyed-at date — not gated by the
        // task's ownerAt. This is what lets an out-of-range task still
        // surface its in-range GL activity, and symmetrically keeps an
        // in-range task from showing GL entries that were actually keyed
        // in some other month ("แสดงเฉพาะ gl ที่กรองเท่านั้น").
        final List<Journal> mergedJournals = [
          ...inRangeJournalsForGuid(task.guidfixed),
          for (final childGuid in parentToChildren[task.guidfixed] ?? const [])
            ...inRangeJournalsForGuid(childGuid),
          if (task.taskChild != null && task.taskChild!.guidfixed.isNotEmpty)
            ...inRangeJournalsForGuid(task.taskChild!.guidfixed),
        ];

        final Map<String, Set<String>> combinedKeyerDocKeys = {};
        for (final j in mergedJournals) {
          final creator = (j.createdBy ?? '').trim();
          if (creator.isEmpty) continue;
          combinedKeyerDocKeys
              .putIfAbsent(creator, () => <String>{})
              .add(_ShopAcc.journalCountKey(j));
        }
        final Map<String, int> combinedKeyerMap = {
          for (final entry in combinedKeyerDocKeys.entries)
            entry.key: entry.value.length,
        };

        int totalKeyedByOthers = 0;
        combinedKeyerMap.forEach((keyer, count) {
          if (keyer != ownerBy) totalKeyedByOthers += count;
        });

        // Who actually uploaded the IMAGES behind this task, from
        // /documentimagegroup's imagereferences[].uploadedby — a
        // completely separate action from opening the task (ownerBy) or
        // keying the GL journal (combinedKeyerMap above). Requested 2026-08:
        // "the person who opens a task and the person who puts the photo
        // into it are sometimes different people, and we need to see who
        // uploaded" — this is the map that answers that, per task.
        final Map<String, int> uploaderMapForTask =
            normalizedTaskUploaderCounts[normalizeGuid(task.guidfixed)] ??
            const {};
        final int ownerUploadedCount = uploaderMapForTask[ownerBy] ?? 0;

        // Owner row ("Row A") — full task context, referenceCount excludes
        // whatever other people already keyed. Shown with EVERY in-range
        // journal entry linked to the task, since the owner is the task's
        // context. The task's own status/document columns always reflect
        // its real current state (not zeroed for tasks pulled in only via
        // an in-range GL entry) — a task's ผ่าน/ต้องบันทึก/คงเหลือ figures
        // are facts about the task itself, not something scoped to
        // whichever date range happens to be selected.
        _applyTaskToShopAcc(
          accFor(ownerBy, shopName),
          task,
          isContributorRow: false,
          keyedDocumentCount: 0,
          totalKeyedByOthers: totalKeyedByOthers,
          uploadedByThisEmployee: ownerUploadedCount,
          journalEntries: mergedJournals,
          includeDetails: includeDetails,
        );
        final ownerLast = lastActiveMap[ownerBy];
        if (ownerLast == null || task.ownerAt.isAfter(ownerLast)) {
          lastActiveMap[ownerBy] = task.ownerAt;
        }

        // Contributor rows ("Row B") — someone else keyed and/or uploaded
        // part of this task's documents; they get credit for exactly what
        // they did, and their journal drill-down is scoped to just the
        // entries THEY created (not the whole task's entries, which would
        // misleadingly suggest they touched documents they never keyed).
        // Keyer and uploader are merged onto ONE row per (employee, task)
        // — union of both maps' keys, minus the owner (already handled
        // above) — so an employee who both keyed AND uploaded for this
        // task doesn't show up as two separate confusing rows.
        final Set<String> contributors = {
          ...combinedKeyerMap.keys,
          ...uploaderMapForTask.keys,
        }..remove(ownerBy);
        for (final contributor in contributors) {
          final keyedCount = combinedKeyerMap[contributor] ?? 0;
          final uploadedCount = uploaderMapForTask[contributor] ?? 0;
          if (keyedCount == 0 && uploadedCount == 0) continue;
          final contributorJournals = mergedJournals
              .where((j) => (j.createdBy ?? '').trim() == contributor)
              .toList();
          _applyTaskToShopAcc(
            accFor(contributor, shopName),
            task,
            isContributorRow: true,
            keyedDocumentCount: keyedCount,
            totalKeyedByOthers: 0,
            uploadedByThisEmployee: uploadedCount,
            journalEntries: contributorJournals,
            includeDetails: includeDetails,
          );
          final contributorLast = lastActiveMap[contributor];
          if (contributorLast == null || task.ownerAt.isAfter(contributorLast)) {
            lastActiveMap[contributor] = task.ownerAt;
          }
        }
      }

      // ── JOURNAL SIDE: creator = คีย์, checkedBy = ตรวจสอบ, updatedBy = แก้ไข ──
      // Each action is scoped to the selected date range using the
      // timestamp of THAT action (createdat/checkedat/updatedat) — not
      // docDatetime (the document's own dated period, e.g. an invoice's
      // printed date). A document dated inside the selected month but
      // actually keyed in a different month must not be counted as
      // "keyed this month" — that mismatch was reported as a bug (an
      // employee with zero keying activity in July showing 1 keyed record,
      // because the underlying document happened to be dated in July).
      for (final j in shopData.journals) {
        final orphan = isOrphanJournal(j);
        final creator = (j.createdBy ?? '').trim();
        final checked = (j.checkedBy ?? '').trim();
        final updated = (j.updatedBy ?? '').trim();

        // Recomputed (cheap, no network) rather than threaded out of
        // isOrphanJournal() — lets an orphan row's on-screen debug text
        // say WHY it's still orphan: no link at all vs. a link was found
        // but that task guid isn't among the ones /task actually returned.
        KpiCombinedJournalItem orphanItem() {
          final guid = resolveTaskGuid(j);
          final found =
              guid != null &&
              guid.isNotEmpty &&
              knownTaskGuids.contains(normalizeGuid(guid));
          return _toJournalItem(
            j,
            resolvedTaskGuid: guid,
            resolvedTaskGuidFound: found,
            docNoMapSize: normalizedDocNoToTaskGuid.length,
            docNoMapTotalItemsSeen: docNoMapTotalItemsSeen,
            docNoMapApiReportedTotal: docNoMapApiReportedTotal,
          );
        }

        // Requested split (2026-07): an orphan journal can still be orphan
        // for two very different reasons — (1) it WAS recorded from a
        // photo but that photo's task isn't among the tasks /task
        // returned, or (2) there's no trace of it anywhere, meaning it was
        // keyed directly with nothing behind it. Case (1) stays counted in
        // the normal "คีย์" figure (a real source document exists, we just
        // couldn't resolve which task it belongs to). Case (2) is pulled
        // OUT into its own "คีย์(ไม่มีรูป)" figure instead.
        //
        // "was recorded from a photo" is NOT just resolveTaskGuid(j) being
        // non-null (jobguidfixed OR the docNo→taskGuid documentimagegroup
        // map) — journal.documentRef is a THIRD, simpler, already-existing
        // signal for exactly this, and the one this app's original (pre-
        // merge) KpiJournalBloc.add() already used: `taskId.isEmpty &&
        // documentRef.isEmpty` was its own definition of "(ไม่ได้บันทึกจากรูป)"
        // (not recorded from photo). Root-caused 2026-07: a GL journal
        // (JV690710-0002) with documentRef set but NOT present (yet, or at
        // all) in the documentimagegroup docNo→taskGuid map was being
        // misclassified as "no photo" purely because that ONE derived
        // signal missed it — documentRef being non-empty is direct,
        // per-row evidence a photo/manual reference exists and needs no
        // extra network fetch to see, so it's checked first/independently
        // rather than relying solely on resolveTaskGuid's derived map.
        final resolvedGuid = resolveTaskGuid(j);
        final hasDocumentRef = (j.documentRef ?? '').trim().isNotEmpty;
        final noPhotoAtAll =
            (resolvedGuid == null || resolvedGuid.isEmpty) && !hasDocumentRef;

        if (creator.isNotEmpty && _isWithinRange(j.createdAt, start, end)) {
          final acc = accFor(creator, shopName);
          acc.addKeyedJournal(
            j,
            noPhoto: noPhotoAtAll && shouldResolveNoPhoto,
          );
          if (orphan) {
            // Requested 2026-07: an orphan journal backed by a real photo/
            // reference (jobguidfixed, documentimagegroup, OR documentRef —
            // i.e. !noPhotoAtAll) represents an actual document that isn't
            // attributed to any task's own totalDocument count (it has no
            // task at all), so it was invisible in "จำนวน" even though a
            // real document exists behind it. Adding it here — once per
            // journal, in the same (creator, shop) bucket its "คีย์" count
            // just landed in — brings "จำนวน" in line with "คีย์" for this
            // case. A no-photo orphan (noPhotoAtAll) is NOT counted here:
            // there's no actual document/photo evidence to count.
            if (!noPhotoAtAll) acc.totalDocuments++;
            if (includeDetails) {
              acc.orphanJournals.add(orphanItem());
            }
          }
        }
        if (checked.isNotEmpty && _isWithinRange(j.checkedAt, start, end)) {
          final acc = accFor(checked, shopName);
          acc.journalChecked++;
          // Avoid adding the same entry twice under the same employee when
          // they're also the creator (already added above).
          if (orphan && checked != creator && includeDetails) {
            acc.orphanJournals.add(orphanItem());
          }
        }
        if (updated.isNotEmpty && _isWithinRange(j.updatedAt, start, end)) {
          final acc = accFor(updated, shopName);
          acc.journalUpdated++;
          if (orphan &&
              updated != creator &&
              updated != checked &&
              includeDetails) {
            acc.orphanJournals.add(orphanItem());
          }
        }
      }

      // The image-group doc count is a SHOP total (not per employee) —
      // attribute it to every employee who has any activity in this shop,
      // same as KpiJournalBloc's shopTotalDocsMap does for each employee's
      // shopStats entry. imageGroupDocCounts is now built keyed by
      // shop.shopId exclusively (see the per-shop fetchShopBillCount call
      // above), so the first lookup always hits — the shopName fallbacks
      // are just defensive leftovers from when this map's keys were
      // unreliable (built from response fields that didn't exist).
      final journalRequiredForShop =
          imageGroupDocCounts[shopData.shop.shopId] ??
          imageGroupDocCounts[shopName] ??
          imageGroupDocCounts[shopName.trim().toLowerCase()] ??
          0;
      for (final shopsForEmp in employeeShopAcc.values) {
        final acc = shopsForEmp[shopName];
        if (acc != null) acc.journalRequiredDocs = journalRequiredForShop;
      }
    }

    final result = <KpiCombinedEmployee>[];
    for (final entry in employeeShopAcc.entries) {
      final name = entry.key;
      final shopStats = entry.value.values.map((a) => a.build()).toList()
        ..sort((a, b) => b.totalDocuments.compareTo(a.totalDocuments));

      int sum(int Function(KpiCombinedShopStat) f) =>
          shopStats.fold(0, (s, e) => s + f(e));

      result.add(
        KpiCombinedEmployee(
          name: name,
          lastActive: lastActiveMap[name],
          totalDocuments: sum((s) => s.totalDocuments),
          waitingVerify: sum((s) => s.waitingVerify),
          passedDocuments: sum((s) => s.passed),
          cancelledDocuments: sum((s) => s.cancelled),
          notRecordedDocuments: sum((s) => s.notRecorded),
          notRequiredApprovalDocuments: sum((s) => s.notRequiredApproval),
          requiredToRecordDocuments: sum((s) => s.requiredToRecord),
          recordedDocuments: sum((s) => s.recorded),
          remainingDocuments: sum((s) => s.remaining),
          completedDocuments: sum((s) => s.completed),
          journalRequiredDocs: sum((s) => s.journalRequiredDocs),
          totalJournals: sum((s) => s.journalCount),
          totalJournalsNoPhoto: sum((s) => s.journalCountNoPhoto),
          totalChecked: sum((s) => s.journalChecked),
          totalUpdated: sum((s) => s.journalUpdated),
          totalUploaded: sum((s) => s.uploadedCount),
          shopStats: shopStats,
        ),
      );
    }

    result.sort(
      (a, b) => (b.totalDocuments + b.totalJournals).compareTo(
        a.totalDocuments + a.totalJournals,
      ),
    );

    _cacheKnownEmployees(result.map((e) => e.name).toList());

    return result;
  }

  void _applyTaskToShopAcc(
    _ShopAcc acc,
    TaskItem task, {
    required bool isContributorRow,
    required int keyedDocumentCount,
    required int totalKeyedByOthers,
    int uploadedByThisEmployee = 0,
    List<Journal> journalEntries = const [],
    bool includeDetails = true,
  }) {
    final int docCount = task.totalDocument;
    final int glRecordedCount = isContributorRow ? keyedDocumentCount : 0;

    if (!isContributorRow) {
      acc.totalDocuments += docCount;
    }

    // Personal action count, independent of task ownership/contributor
    // status — rolls into this row's own employee/shop total either way,
    // same as journalCount does for keying (see the separate "JOURNAL
    // SIDE" loop below).
    acc.uploadedCount += uploadedByThisEmployee;

    int taskWaitingVerify = 0;
    int taskCompleted = 0;

    final int passedStatusCount = task.getStatusCount(1);
    final int taskPassed = passedStatusCount;
    final int taskRequiredToRecord = passedStatusCount;
    final int taskRecordedCount = isContributorRow
        ? glRecordedCount
        : _ownerRecordedCount(task, totalKeyedByOthers);
    final int taskNotRecorded = task.getStatusCount(3);
    // "คงเหลือ" = how many of the documents that actually NEED recording
    // (ต้องบันทึก, i.e. status "ผ่าน") haven't been recorded yet (บันทึกแล้ว).
    // Previously this used the backend's own task.referenceBalance field,
    // which turned out to be some other running total (roughly totalDocument
    // minus an all-time recorded count) — completely unrelated to this
    // task's ต้องบันทึก/บันทึกแล้ว split, so it showed huge, meaningless
    // numbers (e.g. 28 remaining on a task where only 4 documents were even
    // in "ผ่าน" status and 1 of those was already recorded — should read 3,
    // not 28). Deriving it locally from requiredToRecord - recorded keeps
    // it consistent with the two columns sitting right next to it.
    final int taskRemaining = (taskRequiredToRecord - taskRecordedCount) > 0
        ? taskRequiredToRecord - taskRecordedCount
        : 0;
    final int taskCancelled = task.cancelledCount;
    int taskNotRequiredApproval = task.status == 6
        ? task.totalDocument
        : task.notRequiredApprovalCount;

    switch (task.status) {
      case 4:
        taskCompleted = task.totalDocument;
        break;
      case 1:
        taskWaitingVerify = task.totalDocument;
        break;
      case 6:
        taskWaitingVerify = task.getStatusCount(0);
        taskNotRequiredApproval = task.totalDocument;
        break;
      default:
        break;
    }

    if (!isContributorRow) {
      // recorded now rolls up here too (was unconditional before) — the
      // task drill-down row (_taskWorkCell in kpi_combined_page.dart)
      // already tells the viewer a contributor row's "บันทึกแล้ว" is just
      // context from the owner and isn't counted into this employee's
      // total, so the aggregate needs to actually honor that instead of
      // silently adding the contributor's glRecordedCount on top of what
      // the owner's row already contributes.
      acc.recorded += taskRecordedCount;
      acc.passed += taskPassed;
      acc.requiredToRecord += taskRequiredToRecord;
      acc.remaining += taskRemaining;
      acc.notRecorded += taskNotRecorded;
      acc.cancelled += taskCancelled;
      acc.notRequiredApproval += taskNotRequiredApproval;
      acc.completed += taskCompleted;
      acc.waitingVerify += taskWaitingVerify;
    }

    if (!includeDetails) return;

    acc.tasks.add(
      KpiCombinedTaskItem(
        taskName: task.name,
        taskCode: task.code,
        status: task.status,
        totalDocument: task.totalDocument,
        ownerAt: task.ownerAt,
        ownerBy: task.ownerBy.trim(),
        isOwner: !isContributorRow,
        keyedByThisEmployee: isContributorRow ? keyedDocumentCount : 0,
        uploadedByThisEmployee: uploadedByThisEmployee,
        // Task-status breakdown for the drill-down row's own สถานะการตรวจสอบ
        // / สถานะการบันทึกบัญชี columns — same values as what gets rolled
        // into acc above (full task context on every row, owner or
        // contributor, matching how totalDocument already works), except
        // recorded which stays row-specific. Always the task's real current
        // status regardless of whether it was pulled in via ownerAt or via
        // an in-range GL entry — reported: showing 0/blank here for a
        // GL-matched task hid real, correct backend data (a task with 4
        // documents marked ผ่าน should show ต้องบันทึก=4 etc. even when the
        // task's own ownerAt is a different month than the one selected).
        waitingVerify: taskWaitingVerify,
        passed: taskPassed,
        cancelled: taskCancelled,
        notRecorded: taskNotRecorded,
        notRequiredApproval: taskNotRequiredApproval,
        requiredToRecord: taskRequiredToRecord,
        recorded: taskRecordedCount,
        remaining: taskRemaining,
        completed: taskCompleted,
        journalEntries: journalEntries.map(_toJournalItem).toList()
          ..sort((a, b) {
            if (a.docDate == null && b.docDate == null) return 0;
            if (a.docDate == null) return 1;
            if (b.docDate == null) return -1;
            return b.docDate!.compareTo(a.docDate!);
          }),
      ),
    );
  }

  /// True if [isoDate] falls within [start, end] (inclusive on both ends).
  /// No range selected (start/end null) means "don't filter" → true.
  /// A range IS selected but the record has no timestamp for this specific
  /// action → treated as out-of-range rather than guessed, since we can't
  /// actually confirm the action happened in the selected period.
  bool _isWithinRange(String? isoDate, DateTime? start, DateTime? end) {
    if (start == null || end == null) return true;
    if (isoDate == null || isoDate.isEmpty) return false;
    try {
      final dt = DateTime.parse(isoDate);
      return !dt.isBefore(start) && !dt.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  /// Converts a raw [Journal] row into the lightweight display model used
  /// by the task-level GL drill-down.
  KpiCombinedJournalItem _toJournalItem(
    Journal j, {
    String? resolvedTaskGuid,
    bool resolvedTaskGuidFound = false,
    int docNoMapSize = 0,
    int docNoMapTotalItemsSeen = 0,
    int? docNoMapApiReportedTotal,
  }) {
    DateTime? docDate;
    if (j.docDatetime != null && j.docDatetime!.isNotEmpty) {
      try {
        docDate = DateTime.parse(j.docDatetime!);
      } catch (_) {}
    }
    DateTime? keyedAt;
    if (j.createdAt != null && j.createdAt!.isNotEmpty) {
      try {
        keyedAt = DateTime.parse(j.createdAt!);
      } catch (_) {}
    }
    return KpiCombinedJournalItem(
      docNo: (j.docNo ?? '').trim().isNotEmpty ? j.docNo!.trim() : '-',
      accountName: (j.accountName ?? j.description ?? '-').trim().isEmpty
          ? '-'
          : (j.accountName ?? j.description ?? '-').trim(),
      debit: j.debit ?? 0,
      credit: j.credit ?? 0,
      docDate: docDate,
      keyedAt: keyedAt,
      createdBy: (j.createdBy ?? '').trim(),
      checkedBy: (j.checkedBy ?? '').trim(),
      updatedBy: (j.updatedBy ?? '').trim(),
      jobGuidfixed: j.jobGuidfixed,
      documentRef: j.documentRef,
      resolvedTaskGuid: resolvedTaskGuid,
      resolvedTaskGuidFound: resolvedTaskGuidFound,
      docNoMapSize: docNoMapSize,
      docNoMapTotalItemsSeen: docNoMapTotalItemsSeen,
      docNoMapApiReportedTotal: docNoMapApiReportedTotal,
    );
  }

  int _ownerRecordedCount(TaskItem task, int totalKeyedByOthers) {
    if (task.status == 6) return task.referenceCount;
    final value = task.referenceCount - totalKeyedByOthers;
    return value > 0 ? value : 0;
  }

  void _cacheKnownEmployees(List<String> names) {
    final unique = names.where((n) => n.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) return;
    unawaited(
      EmployeeMappingService.saveKnownEmployees(unique).catchError(
        (e) => dLog('Failed to cache combined KPI employee names: $e'),
      ),
    );
  }

  List<KpiCombinedEmployee> _mergeDetailedShop(
    List<KpiCombinedEmployee> currentEmployees,
    List<KpiCombinedEmployee> detailedEmployees,
    String shopName,
  ) {
    final byName = {for (final e in currentEmployees) e.name: e};

    for (final detailed in detailedEmployees) {
      final detailedShop = detailed.shopStats
          .where((s) => s.shopName == shopName)
          .toList();
      if (detailedShop.isEmpty) continue;

      final existing = byName[detailed.name];
      final shops = [
        if (existing != null)
          ...existing.shopStats.where((s) => s.shopName != shopName),
        detailedShop.first,
      ]..sort((a, b) => b.totalDocuments.compareTo(a.totalDocuments));

      byName[detailed.name] = _employeeFromShops(
        existing ?? detailed,
        shops,
        lastActive: existing?.lastActive ?? detailed.lastActive,
      );
    }

    final result = byName.values.toList()
      ..sort(
        (a, b) => (b.totalDocuments + b.totalJournals).compareTo(
          a.totalDocuments + a.totalJournals,
        ),
      );
    return result;
  }

  KpiCombinedEmployee _employeeFromShops(
    KpiCombinedEmployee base,
    List<KpiCombinedShopStat> shopStats, {
    DateTime? lastActive,
  }) {
    int sum(int Function(KpiCombinedShopStat) f) =>
        shopStats.fold(0, (s, e) => s + f(e));

    return base.copyWith(
      lastActive: lastActive,
      totalDocuments: sum((s) => s.totalDocuments),
      waitingVerify: sum((s) => s.waitingVerify),
      passedDocuments: sum((s) => s.passed),
      cancelledDocuments: sum((s) => s.cancelled),
      notRecordedDocuments: sum((s) => s.notRecorded),
      notRequiredApprovalDocuments: sum((s) => s.notRequiredApproval),
      requiredToRecordDocuments: sum((s) => s.requiredToRecord),
      recordedDocuments: sum((s) => s.recorded),
      remainingDocuments: sum((s) => s.remaining),
      completedDocuments: sum((s) => s.completed),
      journalRequiredDocs: sum((s) => s.journalRequiredDocs),
      totalJournals: sum((s) => s.journalCount),
      totalJournalsNoPhoto: sum((s) => s.journalCountNoPhoto),
      totalChecked: sum((s) => s.journalChecked),
      totalUpdated: sum((s) => s.journalUpdated),
      totalUploaded: sum((s) => s.uploadedCount),
      shopStats: shopStats,
    );
  }

  // Root-caused 2026-07: the table displays each employee's friendly
  // display name (via EmployeeMappingService's saved mappings, applied in
  // the page's UI layer), but this only ever matched against `e.name` —
  // the raw account name/email underneath. A user typing the exact Thai
  // name they see rendered on screen into the search box got zero
  // results, because that name never appeared anywhere in the data this
  // was comparing against. Now checks both.
  //
  // [selectedEmployeeNames] (2026-07) is the newer multi-select filter —
  // an explicit "show exactly these people" picklist, sourced directly
  // from the known employee list (so it's always e.name, no display-name
  // ambiguity to resolve). Takes priority over [query] when both are
  // given, though in practice the UI only ever sends one or the other.
  Future<List<KpiCombinedEmployee>> _applySearch(
    List<KpiCombinedEmployee> employees,
    String? query,
    List<String> selectedEmployeeNames,
  ) async {
    if (selectedEmployeeNames.isNotEmpty) {
      final selected = selectedEmployeeNames.toSet();
      return employees.where((e) => selected.contains(e.name)).toList();
    }
    if (query == null || query.trim().isEmpty) return employees;
    final q = query.trim().toLowerCase();
    final nameMappings = await EmployeeMappingService.getAllMappings();
    return employees.where((e) {
      if (e.name.toLowerCase().contains(q)) return true;
      final displayName = nameMappings[e.name];
      return displayName != null && displayName.toLowerCase().contains(q);
    }).toList();
  }
}
