import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_logger.dart';

import 'kpi_event.dart';
import 'kpi_state.dart';
import '../../models/kpi_employee.dart';
import '../../services/task_service.dart';
import '../../services/auth_repository.dart';
import '../../services/multi_shop_service.dart';
import '../../services/journal_service.dart';
import '../../services/employee_mapping_service.dart';

class TaskWithShop {
  final TaskItem task;
  final String shopName;
  final String? journalCreatedBy; // GL Journal createdBy override for the KPI owner
  final int keyedDocumentCount; // Number of documents keyed by journalCreatedBy (For Row B)
  int totalKeyedByOthers; // Number of documents keyed by anyone else (For Row A)

  TaskWithShop(
    this.task,
    this.shopName, {
    this.journalCreatedBy,
    this.keyedDocumentCount = 0,
    this.totalKeyedByOthers = 0,
  });

  // effectiveOwner: use the GL Journal keyer if available, else the task owner
  String get effectiveOwner => journalCreatedBy ?? task.ownerBy;
}

/// Cached result of [KpiBloc._fetchShopTasksAndJournals] for a given set of
/// shops AND date range (the GL journal fetch is scoped to the date range
/// server-side, so the cache key includes it too — see _shopCacheKey).
/// Branch/status/search filters are still applied client-side on top of
/// this raw fetch and don't need a re-fetch of their own.
class _ShopFetchCacheEntry {
  final List<TaskWithShop> tasks;
  final Map<String, Map<String, int>> journalMap;
  final DateTime cachedAt;

  _ShopFetchCacheEntry(this.tasks, this.journalMap, this.cachedAt);
}

class KpiBloc extends Bloc<KpiEvent, KpiState> {
  /// How long a fetched (tasks + GL journals) result stays valid before a
  /// fresh fetch is triggered again for the same set of shops.
  static const Duration _cacheTtl = Duration(minutes: 2);

  // NOTE: shop fetches (both tasks AND GL journals) are intentionally kept
  // strictly SEQUENTIAL, one shop fully at a time. Confirmed by live testing
  // against the real API (2026-07) that /gl/journal ignores the `shopids`
  // query param entirely and instead returns data for whichever shop was
  // last selected via POST /select-shop on this session/token. Running
  // these concurrently across shops would race on that shared session state
  // and silently mix up / drop data between shops. Do not parallelize this
  // without a backend change that makes shop scoping stateless per-request.
  static const int _glJournalPageLimit = 1000;

  // static (not instance) so the cache survives KpiBloc being disposed and
  // recreated — which happens every time the user navigates away from the
  // KPI page and back, since KpiPage builds a brand-new BlocProvider/KpiBloc
  // each time. An instance field here would never actually get reused.
  static final Map<String, _ShopFetchCacheEntry> _fetchCache = {};

  /// Call this on logout / account switch so the next login doesn't briefly
  /// show a previous account's cached KPI data (the cache above is static
  /// and otherwise survives across BlocProvider recreation).
  static void clearCache() => _fetchCache.clear();

  KpiBloc() : super(KpiInitial()) {
    on<LoadKpiData>(_onLoadKpiData);
    on<LoadShops>(_onLoadShops);
    on<SelectShopAndSearch>(_onSelectShopAndSearch);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<FilterByBranch>(_onFilterByBranch);
    on<FilterByStatus>(_onFilterByStatus);
    on<UpdateEmployeeFilter>(_onUpdateEmployeeFilter);
  }

  /// Load shop list on initial page load and auto-select first shop
  Future<void> _onLoadKpiData(LoadKpiData event, Emitter<KpiState> emit) async {
    emit(KpiLoading());

    try {
      List<KpiShopItem> shops = [];
      List<KpiEmployee> employees = [];

      // Default view = current month, same as KPI Journal. Computed up
      // front so the GL journal fetch can be scoped to it (see
      // _fetchShopTasksAndJournals) instead of pulling every GL journal
      // row the shop has ever had.
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      // Load shop list from /list-shop API
      if (AuthRepository.isAuthenticated) {
        try {
          dLog('🏪 Loading shop list from API...');
          final shopList = await MultiShopService.listShops();

          if (shopList.isNotEmpty) {
            shops = shopList.map(_parseShopItem).toList();

            dLog('🏪 Loading tasks for all shops (default)...');
            try {
              final fetched = await _fetchShopTasksAndJournals(
                shops,
                startDate: startDate,
                endDate: endDate,
              );
              final allTasks = fetched.tasks;
              final allJournalCountMap = fetched.journalMap;

              dLog('📊 Tasks: ${allTasks.length}, JournalMap keys: ${allJournalCountMap.length}');

              // Same ownerAt-based filtering + grouping pipeline used by
              // _onSelectShopAndSearch, so the initial view is actually
              // scoped to [startDate, endDate] too — previously this step
              // was skipped on first load, so the date picker showed "this
              // month" while the table still showed every task ever (since
              // /task itself isn't date-scoped server-side).
              employees = _buildEmployees(
                allTasks,
                allJournalCountMap,
                startDate: startDate,
                endDate: endDate,
              );
              dLog('✅ Loaded ${employees.length} employees (grouped) for all shops');
            } catch (e) {
              dLog('⚠️ Failed to load tasks for all shops: $e');
            }
          } // end if (shopList.isNotEmpty)
        } catch (e) {
          dLog('⚠️ Failed to load shop list: $e');
        }
      } // end if (AuthRepository.isAuthenticated)

      final filteredEmployees = _applyFilters(
        employees,
        startDate: startDate,
        endDate: endDate,
      );

      emit(
        KpiLoaded(
          employees: employees,
          filteredEmployees: filteredEmployees,
          startDate: startDate,
          endDate: endDate,
          shops: shops,
          selectedShopIds: const [],
          selectedShopNames: const [],
        ),
      );
    } catch (e) {
      emit(KpiError('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}'));
    }
  }

  /// Load shops list (can be called to refresh)
  Future<void> _onLoadShops(LoadShops event, Emitter<KpiState> emit) async {
    if (state is! KpiLoaded) return;
    final currentState = state as KpiLoaded;

    try {
      dLog('🏪 Refreshing shop list...');
      final shopList = await MultiShopService.listShops();

      final shops = shopList.map(_parseShopItem).toList();

      emit(currentState.copyWith(shops: shops));
      dLog('✅ Shop list refreshed: ${shops.length} shops');
    } catch (e) {
      dLog('❌ Failed to refresh shop list: $e');
    }
  }

  /// Select shop and fetch tasks for that shop
  Future<void> _onSelectShopAndSearch(
    SelectShopAndSearch event,
    Emitter<KpiState> emit,
  ) async {
    if (state is! KpiLoaded) return;
    final currentState = state as KpiLoaded;

    // Show searching state
    emit(
      currentState.copyWith(
        isSearching: true,
        selectedShopIds: event.shopIds,
        selectedShopNames: event.shopNames,
      ),
    );

    try {
      List<KpiEmployee> employees = [];

      dLog('🏪 Fetching tasks for ${event.shopIds.isEmpty ? "ALL" : event.shopIds.length} shops...');

      final targetShops = event.shopIds.isEmpty
          ? currentState.shops
          : currentState.shops.where((s) => event.shopIds.contains(s.shopId)).toList();

      final fetched = await _fetchShopTasksAndJournals(
        targetShops,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final allTasks = fetched.tasks;
      final allJournalCountMap = fetched.journalMap;

      if (allTasks.isNotEmpty) {
        employees = _buildEmployees(
          allTasks,
          allJournalCountMap,
          startDate: event.startDate,
          endDate: event.endDate,
        );
        dLog('✅ Loaded ${employees.length} employees (grouped)');
      } else {
        dLog('📋 No tasks found for selected shops');
      }

      final query = event.query ?? currentState.searchQuery;

      final filteredEmployees = _applyFilters(
        employees,
        startDate: event.startDate,
        endDate: event.endDate,
        branch: currentState.selectedBranch,
        status: currentState.selectedStatus,
        query: query,
        selectedEmployeeIds: event.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          employees: employees,
          filteredEmployees: filteredEmployees,
          selectedShopIds: event.shopIds,
          selectedShopNames: event.shopNames,
          startDate: event.startDate,
          endDate: event.endDate,
          searchQuery: query,
          isSearching: false,
          selectedEmployeeIds: event.selectedEmployeeIds,
        ),
      );
    } catch (e) {
      dLog('❌ Error fetching tasks: $e');
      emit(
        currentState.copyWith(
          isSearching: false,
          employees: [],
          filteredEmployees: [],
        ),
      );
    }
  }

  KpiShopItem _parseShopItem(dynamic shop) {
    final shopId = shop['shopid']?.toString() ??
        shop['shop_id']?.toString() ??
        shop['id']?.toString() ??
        '';
    String shopName = shop['shopname']?.toString() ??
        shop['shop_name']?.toString() ??
        shopId;
    if (shop['names'] != null && (shop['names'] as List).isNotEmpty) {
      shopName = (shop['names'] as List).first['name']?.toString() ?? shopName;
    }
    return KpiShopItem(shopId: shopId, shopName: shopName);
  }

  /// Cache key for a set of shops + date range: sorted shop IDs joined
  /// together plus the date bounds, so different shop sets AND different
  /// date windows each get their own cache slot.
  String _shopCacheKey(
    List<KpiShopItem> shops, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final ids = shops.map((s) => s.shopId).toList()..sort();
    final s = startDate != null ? JournalService.formatDate(startDate) : '-';
    final e = endDate != null ? JournalService.formatDate(endDate) : '-';
    return '${ids.join(',')}|$s|$e';
  }

  /// Fetches tasks + GL journals for [shops]. When [startDate]/[endDate]
  /// are given, the GL journal fetch (which supports server-side date
  /// filtering) is scoped to that window instead of pulling a shop's
  /// entire GL journal history — pass null to fetch all-time (e.g. for
  /// callers that don't have a date filter yet). Note tasks themselves
  /// can't be date-scoped server-side; /task has no date param.
  Future<({List<TaskWithShop> tasks, Map<String, Map<String, int>> journalMap})>
      _fetchShopTasksAndJournals(
    List<KpiShopItem> shops, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey = _shopCacheKey(shops, startDate: startDate, endDate: endDate);
    final cached = _fetchCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      dLog(
        '📋 Using cached KPI data for ${shops.length} shop(s) '
        '(${DateTime.now().difference(cached.cachedAt).inSeconds}s old)',
      );
      return (tasks: cached.tasks, journalMap: cached.journalMap);
    }

    final startStr =
        startDate != null ? JournalService.formatDate(startDate) : null;
    final endStr = endDate != null ? JournalService.formatDate(endDate) : null;

    // Fetch each shop fully SEQUENTIALLY: select-shop (inside
    // fetchTasksForShop) -> fetch tasks -> fetch ALL GL journal pages for
    // THAT SAME shop, then move to the next shop. This ordering matters:
    // /gl/journal ignores its own shopId/shopids param and just returns
    // data for whatever shop the session currently has selected, so the GL
    // fetch for a shop must happen immediately after that shop was
    // selected, with nothing else touching the session in between.
    final List<TaskWithShop> allTasks = [];
    final Map<String, Map<String, int>> allJournalCountMap = {};

    for (final shop in shops) {
      final releaseShopSession = await MultiShopService.acquireShopSession();
      try {
        final response = await TaskService.fetchTasksForShop(
          shopId: shop.shopId,
          limit: 5000,
          status: [0, 1, 2, 3, 4, 5, 6],
        );
        if (response.success && response.tasks.isNotEmpty) {
          allTasks.addAll(
            response.tasks.map((t) => TaskWithShop(t, shop.shopName)),
          );
        }
        // GL fetch immediately follows while the shared session lease keeps
        // other KPI blocs from selecting a different shop.
        final journalMap = await _fetchAllGLJournalsForShop(
          shop,
          startStr: startStr,
          endStr: endStr,
        );
        journalMap.forEach((guid, keyers) {
          keyers.forEach((keyer, count) {
            allJournalCountMap
                .putIfAbsent(guid, () => {})
                .update(keyer, (c) => c + count, ifAbsent: () => count);
          });
        });
      } catch (e) {
        dLog('⚠️ Failed to load KPI data for shop ${shop.shopName}: $e');
      } finally {
        releaseShopSession();
      }
    }

    _fetchCache[cacheKey] =
        _ShopFetchCacheEntry(allTasks, allJournalCountMap, DateTime.now());

    return (tasks: allTasks, journalMap: allJournalCountMap);
  }

  /// Fetches every page of GL journals for a single shop and groups the
  /// result by (task guid → creator → count). Loops through all pages
  /// instead of only reading the first ~1000 rows. When [startStr]/[endStr]
  /// are given, scopes the fetch server-side to that date window.
  Future<Map<String, Map<String, int>>> _fetchAllGLJournalsForShop(
    KpiShopItem shop, {
    String? startStr,
    String? endStr,
  }) async {
    final Map<String, Map<String, int>> journalMap = {};

    try {
      int page = 1;
      int totalPages = 1;
      int fetchedCount = 0;

      do {
        final glResp = await JournalService.getAllGLJournals(
          task: 'GL Journal',
          shopId: shop.shopId.isNotEmpty ? shop.shopId : null,
          page: page,
          limit: _glJournalPageLimit,
          startDate: startStr,
          endDate: endStr,
        );

        if (glResp.success != true || glResp.journals == null) break;

        final journals = glResp.journals!;
        fetchedCount += journals.length;

        if (page == 1) {
          final p = glResp.pagination;
          if (p != null) {
            totalPages = p.totalPages ??
                (p.total != null && p.total! > 0
                    ? ((p.total! + _glJournalPageLimit - 1) ~/ _glJournalPageLimit)
                    : 1);
          }
        }

        for (final journal in journals) {
          if (journal.jobGuidfixed != null &&
              journal.jobGuidfixed!.isNotEmpty &&
              journal.createdBy != null) {
            journalMap
                .putIfAbsent(journal.jobGuidfixed!, () => {})
                .update(journal.createdBy!, (c) => c + 1, ifAbsent: () => 1);
          }
        }

        if (journals.length < _glJournalPageLimit) break;
        page++;
      } while (page <= totalPages);

      dLog(
        '📋 GL Journals for shop ${shop.shopName}: $fetchedCount row(s) '
        'across ${page.clamp(1, totalPages)} page(s)',
      );
    } catch (e) {
      dLog('⚠️ Failed to fetch GL Journals for shop ${shop.shopName}: $e');
    }

    return journalMap;
  }

  /// Filters [allTasks] by ownerAt within [startDate, endDate] (inclusive,
  /// when both given), merges in GL journal keyer extras, caches known
  /// employee names, and groups into KpiEmployee rows. Shared by the
  /// initial load (_onLoadKpiData) and the search/filter pipeline
  /// (_onSelectShopAndSearch) so both stay consistent — previously only the
  /// latter applied this filtering, so the very first load showed every
  /// task ever regardless of what the date picker displayed.
  List<KpiEmployee> _buildEmployees(
    List<TaskWithShop> allTasks,
    Map<String, Map<String, int>> journalMap, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (allTasks.isEmpty) return [];

    List<TaskWithShop> filteredTasks = allTasks;
    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filteredTasks = allTasks.where((item) {
        return item.task.ownerAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            item.task.ownerAt.isBefore(end);
      }).toList();
    }

    _applyJournalExtras(filteredTasks, journalMap);
    _cacheKnownEmployees(filteredTasks);
    return _groupTasksByOwner(filteredTasks);
  }

  void _cacheKnownEmployees(List<TaskWithShop> tasks) {
    final names = <String>{};
    for (final item in tasks) {
      final ownerBy = item.task.ownerBy.trim();
      final journalCreatedBy = item.journalCreatedBy?.trim();

      if (ownerBy.isNotEmpty) names.add(ownerBy);
      if (journalCreatedBy != null && journalCreatedBy.isNotEmpty) {
        names.add(journalCreatedBy);
      }
    }

    if (names.isEmpty) return;
    unawaited(
      EmployeeMappingService.saveKnownEmployees(
        names.toList(),
      ).catchError((e) => dLog('Failed to cache KPI employee names: $e')),
    );
    dLog('Cached ${names.length} known KPI employee names');
  }

  void _applyJournalExtras(
    List<TaskWithShop> tasks,
    Map<String, Map<String, int>> journalMap,
  ) {
    if (journalMap.isEmpty) {
      dLog('⚠️ journalMap EMPTY — no documentRef/createdBy found');
      return;
    }

    final Map<String, List<String>> parentToChildren = {};
    for (final item in tasks) {
      if (item.task.parentGuidfixed.isNotEmpty) {
        parentToChildren
            .putIfAbsent(item.task.parentGuidfixed, () => [])
            .add(item.task.guidfixed);
      }
    }

    final List<TaskWithShop> extras = [];
    for (final item in tasks) {
      if (item.task.parentGuidfixed.isNotEmpty) continue;

      final Map<String, int> combinedKeyerMap = {};

      void mergeMap(Map<String, int>? source) {
        source?.forEach((k, v) =>
            combinedKeyerMap.update(k, (c) => c + v, ifAbsent: () => v));
      }

      mergeMap(journalMap[item.task.guidfixed]);
      for (final childGuid in parentToChildren[item.task.guidfixed] ?? []) {
        mergeMap(journalMap[childGuid]);
      }
      if (item.task.taskChild != null && item.task.taskChild!.guidfixed.isNotEmpty) {
        mergeMap(journalMap[item.task.taskChild!.guidfixed]);
      }

      if (combinedKeyerMap.isNotEmpty) {
        int keyedByOthersSum = 0;
        for (final entry in combinedKeyerMap.entries) {
          if (entry.key != item.task.ownerBy) {
            keyedByOthersSum += entry.value;
            extras.add(TaskWithShop(
              item.task,
              item.shopName,
              journalCreatedBy: entry.key,
              keyedDocumentCount: entry.value,
            ));
          }
        }
        item.totalKeyedByOthers = keyedByOthersSum;
      }
    }

    dLog('📊 B extras added: ${extras.length}');
    tasks.addAll(extras);
  }

  /// Group tasks by the person who actually keyed the documents (createdBy from GL Journal).
  /// If a task has no GL Journal entries yet (not yet keyed), falls back to task.ownerBy.
  List<KpiEmployee> _groupTasksByOwner(List<TaskWithShop> tasks) {
    // --- Step 1: Build a map: taskGuid → List<Journal> keyed by createdBy ---
    // `effectiveOwner` is already set from GL Journal in the calling code (journalOwnerMap).
    // We use it directly as the KPI grouping key.

    // Group TaskWithShop items by effectiveOwner (createdBy if available, else ownerBy)
    final Map<String, List<TaskWithShop>> groupedTasks = {};
    for (final item in tasks) {
      final owner = item.effectiveOwner;
      groupedTasks.putIfAbsent(owner, () => []).add(item);
    }

    // --- Step 2: Build a KpiEmployee per owner ---
    return groupedTasks.entries.map((entry) {
      final ownerBy = entry.key;
      final ownerItems = entry.value;
      final ownerTasks = ownerItems.map((e) => e.task).toList();

      // Aggregate totals from all tasks for this owner
      int totalDocCount = 0;
      int totalRefBalance = 0;
      int totalRefCount = 0;
      int totalPending = 0;
      int totalWaitingVerify = 0;
      int totalCompleted = 0;
      int totalRequiredToRecord = 0;
      int totalPassed = 0;
      int totalRemaining = 0;
      int totalNotRecorded = 0;
      int totalCancelled = 0;
      int totalNotRequiredApproval = 0;
      DateTime? latestActive;

      // Create companyDetails from each task
      final companyDetails = ownerItems.map((item) {
        final task = item.task;
        final shopName = item.shopName;
        final bool isContributorRow = item.journalCreatedBy != null;
        
        // --- CUSTOM KPI DISPLAY LOGIC (REQ 2026-03-11 #2) --- 
        // Row A (Owner): Shows full task context for all columns EXCEPT "Recorded" (which is 0)
        // Row B (Keyer): Shows full task context for all columns EXCEPT "Recorded" (which is their keyed amount)
        
        // Both rows see the full document count
        final int docCount = task.totalDocument;
        // B rows use GL Journal keyed count. Owner rows keep the task's
        // referenceCount minus documents already assigned to other keyers.
        final int glRecordedCount = isContributorRow ? item.keyedDocumentCount : 0;
        
        // In the overall Employee summary (Main Row A), we accumulate the full counts.
        // We only add to the Employee total if it's NOT a contributor row, to avoid double-counting
        // the same task repeatedly in the Employee aggregated row.
        if (!isContributorRow) {
          totalDocCount += docCount;
          totalRefBalance += task.referenceBalance;
        }

        // Both A and B sub-rows show the full context of the task
        int taskWaitingVerify = 0;
        int taskPending = 0;
        int taskCompleted = 0;
        
        final int passedStatusCount = task.getStatusCount(1);
        int taskPassed = passedStatusCount;
        int taskRequiredToRecord = passedStatusCount;
        int taskRecordedCount = isContributorRow
            ? glRecordedCount
            : _ownerRecordedCount(item);
        int taskRemaining = task.referenceBalance;
        int taskNotRecorded = task.getStatusCount(3);
        int taskCancelled = task.cancelledCount;
        int taskNotRequiredApproval = task.status == 6
            ? task.totalDocument
            : task.notRequiredApprovalCount;

        switch (task.status) {
          case 4: // Completed
            taskCompleted = task.totalDocument;
            break;
          case 3: // Pending Record
            taskPending = task.totalDocument;
            break;
          case 1: // Waiting Verify
            taskWaitingVerify = task.totalDocument;
            break;
          case 6: // Not required approval / skip workflow
            taskWaitingVerify = task.getStatusCount(0);
            taskNotRequiredApproval = task.totalDocument;
            break;
          default:
            break;
        }

        // Only add to the Employee master totals if it's the A row to prevent double counting
        totalRefCount += taskRecordedCount;
        if (!isContributorRow) {
          totalPassed += taskPassed;
          totalRequiredToRecord += taskRequiredToRecord;
          totalRemaining += taskRemaining;
          totalNotRecorded += taskNotRecorded;
          totalCancelled += taskCancelled;
          totalNotRequiredApproval += taskNotRequiredApproval;
          totalCompleted += taskCompleted;
          totalPending += taskPending;
          totalWaitingVerify += taskWaitingVerify;
        }

        // Delay step
        String taskDelayStep = 'none';
        if (latestActive == null || task.ownerAt.isAfter(latestActive!)) {
          latestActive = task.ownerAt;
        }
        if (task.status == 6) {
          taskDelayStep = 'ปิดการอนุมัติ';
        } else if (taskWaitingVerify > 0) {
          taskDelayStep = 'รอตรวจสอบ';
        } else if (taskPending > 0) {
          taskDelayStep = 'รอบันทึก';
        } else if (task.status == 0) {
          taskDelayStep = 'รออัปโหลด';
        }

        final now = DateTime.now();
        int daysDiff = 0;
        if (['รอตรวจสอบ', 'รอบันทึก', 'รออัปโหลด'].contains(taskDelayStep)) {
          daysDiff = now.difference(task.ownerAt).inDays;
        }

        // Both rows show full task context, except for referenceCount
        return KpiCompanyDetail(
          company: task.name,
          employee: ownerBy,
          recordingDate: task.ownerAt,
          totalBillCount: task.totalDocument, // Full job count for both A and B
          assigned: task.billCount,
          completed: taskCompleted,
          requiredToRecord: taskRequiredToRecord,
          cancelled: taskCancelled,
          notRequiredApproval: taskNotRequiredApproval,
          pending: taskPending,
          waitingKey: 0,
          waitingVerify: taskWaitingVerify,
          waitingFix: 0,
          passed: taskPassed,
          remaining: taskRemaining,
          notRecorded: taskNotRecorded,
          referenceCount: taskRecordedCount,
          status: task.status.toString(),
          lastActive: task.ownerAt,
          delayStep: taskDelayStep,
          delayDays: daysDiff,
          shopName: shopName,
        );
      }).toList()..sort((a, b) => b.recordingDate.compareTo(a.recordingDate));

      // Determine overall status
      String overallStatus = 'assigned';
      if (totalCompleted == totalDocCount && totalDocCount > 0) {
        overallStatus = 'completed';
      } else if (totalPending > 0) {
        overallStatus = 'pending';
      }

      // Determine delay
      String delayStep = 'none';
      int delayDays = 0;
      final now = DateTime.now();
      if (totalNotRequiredApproval > 0) {
        delayStep = 'ปิดการอนุมัติ';
      } else if (totalWaitingVerify > 0) {
        delayStep = 'รอตรวจสอบ';
      } else if (totalPending > 0) {
        delayStep = 'รอบันทึก';
      } else if (totalRemaining > 0) {
        delayStep = 'รออัปโหลด';
      }
      if (['รอตรวจสอบ', 'รอบันทึก', 'รออัปโหลด'].contains(delayStep) &&
          latestActive != null) {
        delayDays = now.difference(latestActive!).inDays;
      }

      final int billsNeeded = totalDocCount - totalCompleted;
      final bool incentivePassed = billsNeeded <= 0 && totalDocCount > 0;

      return KpiEmployee(
        id: ownerBy,
        name: ownerBy,
        branch: '${ownerTasks.length} เอกสาร',
        documentStartDate: latestActive ?? DateTime.now(),
        documentEndDate: latestActive ?? DateTime.now(),
        dueDate: (latestActive ?? DateTime.now()).add(const Duration(days: 30)),
        totalDocuments: totalDocCount,
        assignedDocuments: 0,
        pendingDocuments: totalPending,
        completedDocuments: totalCompleted,
        requiredToRecordDocuments: totalRequiredToRecord,
        passedDocuments: totalPassed,
        remainingDocuments: totalRemaining,
        notRecordedDocuments: totalNotRecorded,
        cancelledDocuments: totalCancelled,
        notRequiredApprovalDocuments: totalNotRequiredApproval,
        waitingKey: 0,
        waitingVerify: totalWaitingVerify,
        waitingFix: 0,
        referenceBalance: totalRefBalance,
        referenceCount: totalRefCount,
        delayStep: delayStep,
        delayDays: delayDays,
        incentivePassed: incentivePassed,
        billsNeeded: billsNeeded > 0 ? billsNeeded : 0,
        status: overallStatus,
        lastActive: latestActive,
        companyDetails: companyDetails,
      );
    }).toList();
  }

  int _ownerRecordedCount(TaskWithShop item) {
    if (item.task.status == 6) return item.task.referenceCount;

    final value = item.task.referenceCount - item.totalKeyedByOthers;
    return value > 0 ? value : 0;
  }

  /// Changing the date range now re-fetches (scoped to the new range) rather
  /// than only re-filtering already-loaded data client-side, since GL
  /// journal fetches are date-scoped server-side (see
  /// _fetchShopTasksAndJournals). Reuses the SelectShopAndSearch pipeline
  /// with the current shop selection so there's only one fetch code path.
  void _onFilterByDateRange(FilterByDateRange event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      add(
        SelectShopAndSearch(
          shopIds: currentState.selectedShopIds,
          shopNames: currentState.selectedShopNames,
          startDate: event.startDate,
          endDate: event.endDate,
          query: currentState.searchQuery,
          selectedEmployeeIds: currentState.selectedEmployeeIds,
        ),
      );
    }
  }

  void _onFilterByBranch(FilterByBranch event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      final branch = event.branch == 'all' ? null : event.branch;
      final filtered = _applyFilters(
        currentState.employees,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
        branch: branch,
        status: currentState.selectedStatus,
        query: currentState.searchQuery,
        selectedEmployeeIds: currentState.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          selectedBranch: branch,
          filteredEmployees: filtered,
        ),
      );
    }
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      final status = event.status == 'all' ? null : event.status;
      final filtered = _applyFilters(
        currentState.employees,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
        branch: currentState.selectedBranch,
        status: status,
        query: currentState.searchQuery,
        selectedEmployeeIds: currentState.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          selectedStatus: status,
          filteredEmployees: filtered,
        ),
      );
    }
  }

  void _onUpdateEmployeeFilter(
    UpdateEmployeeFilter event,
    Emitter<KpiState> emit,
  ) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      final filtered = _applyFilters(
        currentState.employees,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
        branch: currentState.selectedBranch,
        status: currentState.selectedStatus,
        query: event.query,
        selectedEmployeeIds: event.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredEmployees: filtered,
          selectedEmployeeIds: event.selectedEmployeeIds,
        ),
      );
    }
  }

  List<KpiEmployee> _applyFilters(
    List<KpiEmployee> employees, {
    DateTime? startDate,
    DateTime? endDate,
    String? branch,
    String? status,
    String? query,
    List<String>? selectedEmployeeIds,
  }) {
    var filtered = employees;

    if (selectedEmployeeIds != null && selectedEmployeeIds.isNotEmpty) {
      filtered = filtered.where((e) => selectedEmployeeIds.contains(e.id)).toList();
    } else if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                e.id.toLowerCase().contains(q) ||
                e.branch.toLowerCase().contains(q),
          )
          .toList();
    }

    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((e) {
        if (e.companyDetails.isEmpty) return false;
        return e.companyDetails.any((detail) =>
            detail.recordingDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            detail.recordingDate.isBefore(end));
      }).toList();
    }

    if (branch != null) {
      filtered = filtered.where((e) => e.branch == branch).toList();
    }

    if (status != null) {
      switch (status) {
        case 'waiting_key':
          filtered = filtered.where((e) => e.waitingKey > 0).toList();
          break;
        case 'waiting_verify':
          filtered = filtered.where((e) => e.waitingVerify > 0).toList();
          break;
        case 'waiting_fix':
          filtered = filtered.where((e) => e.waitingFix > 0).toList();
          break;
        case 'completed':
          filtered = filtered
              .where((e) => e.completedDocuments > 0 || e.status == 'completed')
              .toList();
          break;
        default:
          filtered = filtered.where((e) => e.status == status).toList();
      }
    }

    return filtered;
  }
}
