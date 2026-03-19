import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_logger.dart';

import 'kpi_event.dart';
import 'kpi_state.dart';
import '../../models/kpi_employee.dart';
import '../../services/task_service.dart';
import '../../services/auth_repository.dart';
import '../../services/multi_shop_service.dart';
import '../../services/journal_service.dart';

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

class KpiBloc extends Bloc<KpiEvent, KpiState> {
  KpiBloc() : super(KpiInitial()) {
    on<LoadKpiData>(_onLoadKpiData);
    on<LoadShops>(_onLoadShops);
    on<SelectShopAndSearch>(_onSelectShopAndSearch);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<FilterByBranch>(_onFilterByBranch);
    on<FilterByStatus>(_onFilterByStatus);
    on<UpdateEmployeeFilter>(_onUpdateEmployeeFilter);
    on<FilterByAdvancedOptions>(_onFilterByAdvancedOptions);
    on<ApplyAllFilters>(_onApplyAllFilters);
    on<ResetFilters>(_onResetFilters);
  }

  /// Load shop list on initial page load and auto-select first shop
  Future<void> _onLoadKpiData(LoadKpiData event, Emitter<KpiState> emit) async {
    emit(KpiLoading());

    try {
      List<KpiShopItem> shops = [];
      List<KpiEmployee> employees = [];
      String? selectedShopId;
      String? selectedShopName;

      // Load shop list from /list-shop API
      if (AuthRepository.isAuthenticated) {
        try {
          dLog('🏪 Loading shop list from API...');
          final shopList = await MultiShopService.listShops();

          if (shopList.isNotEmpty) {
            shops = shopList.map((shop) {
              final shopId =
                  shop['shopid']?.toString() ??
                  shop['shop_id']?.toString() ??
                  shop['id']?.toString() ??
                  '';

              // Get shop name from names array if available
              String shopName =
                  shop['shopname']?.toString() ??
                  shop['shop_name']?.toString() ??
                  shopId;

              if (shop['names'] != null && (shop['names'] as List).isNotEmpty) {
                final firstName = (shop['names'] as List).first;
                shopName = firstName['name']?.toString() ?? shopName;
              }

              return KpiShopItem(shopId: shopId, shopName: shopName);
            }).toList();

            dLog('✅ Loaded ${shops.length} shops');

            // Auto-select "All Shops" by default
            if (shops.isNotEmpty) {
              selectedShopId = '';
              selectedShopName = 'ทุกร้าน';

              dLog('🏪 Auto-selecting All Shops');

              try {
                final List<TaskWithShop> allTasks = [];
                // Combined map: taskGuid → { createdBy → keyedCount } across all shops
                final Map<String, Map<String, int>> allJournalCountMap = {};

                // Fetch tasks AND GL Journals for each shop in the same shop context
                for (final shop in shops) {
                  try {
                    // fetchTasksForShop calls selectShop(shopId) first, then /task
                    final response = await TaskService.fetchTasksForShop(
                      shopId: shop.shopId,
                      limit: 20,
                      status: [0, 1, 2, 3, 4, 5, 6],
                    );

                    if (response.success && response.tasks.isNotEmpty) {
                      allTasks.addAll(
                        response.tasks.map(
                          (t) => TaskWithShop(t, shop.shopName),
                        ),
                      );
                    }

                    // Fetch GL Journals for this shop IMMEDIATELY after selectShop
                    // so the server returns journals in the correct shop context
                    try {
                      final glResp = await JournalService.getAllGLJournals(
                        task: 'GL Journal',
                      );
                      print('[KPI-DEBUG] 📋 GL Journals for shop ${shop.shopName}: ${glResp.journals?.length ?? 0}');
                      if (glResp.success == true && glResp.journals != null) {
                        // Debug: print first entry jobGuidfixed to confirm the link
                        if (glResp.journals!.isNotEmpty) {
                          final first = glResp.journals!.first;
                          print('[KPI-DEBUG] 🔑 First GL Journal: jobGuidfixed="${first.jobGuidfixed}", createdBy="${first.createdBy}"');
                        }
                        // Use jobGuidfixed (links directly to task.guidfixed) for matching
                        for (final journal in glResp.journals!) {
                          if (journal.jobGuidfixed != null &&
                              journal.jobGuidfixed!.isNotEmpty &&
                              journal.createdBy != null) {
                            allJournalCountMap
                                .putIfAbsent(journal.jobGuidfixed!, () => {})
                                .update(
                                  journal.createdBy!,
                                  (c) => c + 1,
                                  ifAbsent: () => 1,
                                );
                          }
                        }
                      }
                    } catch (e) {
                      dLog('⚠️ Failed to fetch GL Journals for shop ${shop.shopName}: $e');
                    }
                  } catch (e) {
                    dLog(
                      '⚠️ Failed to load tasks for shop ${shop.shopName}: $e',
                    );
                  }
                } // end for (shop in shops)

                print('[KPI-DEBUG] 📊 Tasks: ${allTasks.length}, JournalMap keys: ${allJournalCountMap.length}');
                print('[KPI-DEBUG] 🔍 Sample documentRef keys: ${allJournalCountMap.keys.take(5).toList()}');
                print('[KPI-DEBUG] 🔍 Task guidfixed (first 5): ${allTasks.map((t) => t.task.guidfixed).take(5).toList()}');

                if (allTasks.isNotEmpty) {
                  // Build maps for child→parent resolution
                  // GL Journal documentRef = child task guidfixed
                  // We need to walk up: documentRef → child task → parent task (for KPI row)
                  final Map<String, TaskWithShop> guidToTask = {};
                  final Map<String, List<String>> parentToChildren = {};

                  for (final item in allTasks) {
                    guidToTask[item.task.guidfixed] = item;
                    if (item.task.parentGuidfixed.isNotEmpty) {
                      parentToChildren
                          .putIfAbsent(item.task.parentGuidfixed, () => [])
                          .add(item.task.guidfixed);
                    }
                  }

                  // Debug: check how many documentRefs can be resolved through children
                  int directMatchCount = 0;
                  int childMatchCount = 0;
                  for (final docRef in allJournalCountMap.keys) {
                    final matchedTask = guidToTask[docRef];
                    if (matchedTask != null) {
                      if (matchedTask.task.parentGuidfixed.isEmpty) {
                        directMatchCount++;
                      } else {
                        childMatchCount++;
                      }
                    }
                  }
                  print('[KPI-DEBUG] 🔗 documentRef matches: direct=$directMatchCount, via-child=$childMatchCount out of ${allJournalCountMap.length}');

                  // Add extra TaskWithShop rows for each GL Journal keyer B:
                  // For each parent (top-level) task, accumulate keyers from:
                  //   1. Direct match (documentRef == parent task.guidfixed)
                  //   2. Child match (documentRef == child.guidfixed, child.parentGuidfixed == parent.guidfixed)
                  if (allJournalCountMap.isNotEmpty) {
                    final List<TaskWithShop> extras = [];

                    for (final item in allTasks) {
                      // Only process top-level tasks (parent tasks) for KPI rows
                      if (item.task.parentGuidfixed.isNotEmpty) continue;

                      // Collect combined keyer counts for this parent task
                      final Map<String, int> combinedKeyerMap = {};

                      // 1. Direct match: parent task.guidfixed in GL Journal
                      final directMatch = allJournalCountMap[item.task.guidfixed];
                      if (directMatch != null) {
                        for (final e in directMatch.entries) {
                          combinedKeyerMap.update(e.key, (c) => c + e.value, ifAbsent: () => e.value);
                        }
                      }

                      // 2. Child-task match: each child's guidfixed in GL Journal
                      final children = parentToChildren[item.task.guidfixed] ?? [];
                      for (final childGuid in children) {
                        final childMatch = allJournalCountMap[childGuid];
                        if (childMatch != null) {
                          for (final e in childMatch.entries) {
                            combinedKeyerMap.update(e.key, (c) => c + e.value, ifAbsent: () => e.value);
                          }
                        }
                      }

                      // 3. taskChild.guidfixed match (if API exposes a single child GUID)
                      if (item.task.taskChild != null && item.task.taskChild!.guidfixed.isNotEmpty) {
                        final taskChildMatch = allJournalCountMap[item.task.taskChild!.guidfixed];
                        if (taskChildMatch != null) {
                          for (final e in taskChildMatch.entries) {
                            combinedKeyerMap.update(e.key, (c) => c + e.value, ifAbsent: () => e.value);
                          }
                        }
                      }

                      if (combinedKeyerMap.isNotEmpty) {
                        print('[KPI-DEBUG] ✅ MATCH: task "${item.task.name}" ownerBy="${item.task.ownerBy}" keyers=${combinedKeyerMap.keys.toList()}');
                        int keyedByOthersSum = 0;
                        for (final entry in combinedKeyerMap.entries) {
                          final keyer = entry.key;
                          final count = entry.value;
                          if (keyer != item.task.ownerBy) {
                            keyedByOthersSum += count;
                            print('[KPI-DEBUG] ➕ Adding B row: keyer=$keyer count=$count');
                            extras.add(
                              TaskWithShop(
                                item.task,
                                item.shopName,
                                journalCreatedBy: keyer,
                                keyedDocumentCount: count,
                              ),
                            );
                          }
                        }
                        item.totalKeyedByOthers = keyedByOthersSum;
                      }
                    }

                    print('[KPI-DEBUG] 📊 B extras added: ${extras.length}');
                    allTasks.addAll(extras);
                  } else {
                    dLog('⚠️ allJournalCountMap EMPTY — no documentRef/createdBy found');
                  }

                  employees = _groupTasksByOwner(allTasks);
                  dLog(
                    '✅ Loaded ${employees.length} employees (grouped) for all shops',
                  );
                }
              } catch (e) {
                dLog('⚠️ Failed to load tasks for all shops: $e');
              }
            }
          }
        } catch (e) {
          dLog('⚠️ Failed to load shop list: $e');
        }
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      emit(
        KpiLoaded(
          employees: employees,
          filteredEmployees: employees,
          startDate: startDate,
          endDate: endDate,
          shops: shops,
          selectedShopId: selectedShopId,
          selectedShopName: selectedShopName,
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

      final shops = shopList.map((shop) {
        final shopId =
            shop['shopid']?.toString() ??
            shop['shop_id']?.toString() ??
            shop['id']?.toString() ??
            '';

        String shopName =
            shop['shopname']?.toString() ??
            shop['shop_name']?.toString() ??
            shopId;

        if (shop['names'] != null && (shop['names'] as List).isNotEmpty) {
          final firstName = (shop['names'] as List).first;
          shopName = firstName['name']?.toString() ?? shopName;
        }

        return KpiShopItem(shopId: shopId, shopName: shopName);
      }).toList();

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
        selectedShopId: event.shopId,
        selectedShopName: event.shopName,
      ),
    );

    try {
      List<KpiEmployee> employees = [];
      List<TaskWithShop> allTasks = [];
      final Map<String, Map<String, int>> allJournalCountMap = {};

      if (event.shopId == null ||
          event.shopId!.isEmpty ||
          event.shopId == 'all') {
        dLog('🏪 Fetching tasks for ALL shops...');

        // Iterate all shops — fetch tasks AND GL Journals per shop context
        for (final shop in currentState.shops) {
          try {
            // fetchTasksForShop calls selectShop(shopId) first, then /task
            final response = await TaskService.fetchTasksForShop(
              shopId: shop.shopId,
              limit: 20,
              status: [0, 1, 2, 3, 4, 5, 6],
            );

            if (response.success && response.tasks.isNotEmpty) {
              allTasks.addAll(
                response.tasks.map((t) => TaskWithShop(t, shop.shopName)),
              );
            }

            // Fetch GL Journals immediately after shop is selected
            try {
              final glResp = await JournalService.getAllGLJournals(
                task: 'GL Journal',
              );
              if (glResp.success == true && glResp.journals != null) {
                for (final journal in glResp.journals!) {
                  if (journal.jobGuidfixed != null &&
                      journal.jobGuidfixed!.isNotEmpty &&
                      journal.createdBy != null) {
                    allJournalCountMap
                        .putIfAbsent(journal.jobGuidfixed!, () => {})
                        .update(
                          journal.createdBy!,
                          (c) => c + 1,
                          ifAbsent: () => 1,
                        );
                  }
                }
              }
            } catch (e) {
              dLog('⚠️ Failed to fetch GL Journals for shop ${shop.shopName}: $e');
            }
          } catch (e) {
            dLog('⚠️ Failed to load tasks for shop ${shop.shopName}: $e');
          }
        }
      } else {
        // Fetch for single shop
        dLog('🏪 Fetching tasks for shop ${event.shopId}...');
        final response = await TaskService.fetchTasksForShop(
          shopId: event.shopId!,
          limit: 20,
          status: [0, 1, 2, 3, 4, 5, 6],
        );

        if (response.success && response.tasks.isNotEmpty) {
          allTasks.addAll(
            response.tasks.map((t) => TaskWithShop(t, event.shopName!)),
          );
        }

        // Fetch GL Journals for this single shop (already selected above)
        try {
          final glResp = await JournalService.getAllGLJournals(
            task: 'GL Journal',
          );
          if (glResp.success == true && glResp.journals != null) {
            for (final journal in glResp.journals!) {
              if (journal.jobGuidfixed != null &&
                  journal.jobGuidfixed!.isNotEmpty &&
                  journal.createdBy != null) {
                allJournalCountMap
                    .putIfAbsent(journal.jobGuidfixed!, () => {})
                    .update(
                      journal.createdBy!,
                      (c) => c + 1,
                      ifAbsent: () => 1,
                    );
              }
            }
          }
        } catch (e) {
          dLog('⚠️ Failed to fetch GL Journals for shop ${event.shopId}: $e');
        }
      }

      if (allTasks.isNotEmpty) {
        // Filter tasks by ownerAt date range
        List<TaskWithShop> filteredTasks = allTasks;

        if (event.startDate != null && event.endDate != null) {
          final start = DateTime(
            event.startDate!.year,
            event.startDate!.month,
            event.startDate!.day,
          );
          final end = DateTime(
            event.endDate!.year,
            event.endDate!.month,
            event.endDate!.day,
            23,
            59,
            59,
          );

          filteredTasks = allTasks.where((item) {
            return item.task.ownerAt.isAfter(
                  start.subtract(const Duration(seconds: 1)),
                ) &&
                item.task.ownerAt.isBefore(end);
          }).toList();
        }

        // Add extra TaskWithShop rows for GL Journal keyers (B)
        // while keeping original ownerBy (A) entries
        if (allJournalCountMap.isNotEmpty) {
          final List<TaskWithShop> extras = [];
          for (final item in filteredTasks) {
            final keyerMap = allJournalCountMap[item.task.guidfixed];
            if (keyerMap != null) {
              int keyedByOthersSum = 0;
              for (final entry in keyerMap.entries) {
                final keyer = entry.key;
                final count = entry.value;
                if (keyer != item.task.ownerBy) {
                  keyedByOthersSum += count;
                  extras.add(
                    TaskWithShop(
                      item.task,
                      item.shopName,
                      journalCreatedBy: keyer,
                      keyedDocumentCount: count,
                    ),
                  );
                }
              }
              item.totalKeyedByOthers = keyedByOthersSum;
            }
          }
          filteredTasks.addAll(extras);
        }

        // Group tasks by ownerBy (or effectively journalCreatedBy)
        employees = _groupTasksByOwner(filteredTasks);
        dLog('✅ Loaded ${employees.length} employees (grouped)');
      } else {
        dLog('📋 No shop selected, showing empty list');
      }

      // Apply filters (including search query)
      final query = event.query ?? currentState.searchQuery;
      final filteredEmployees = _applyFilters(
        employees,
        startDate: event.startDate,
        endDate: event.endDate,
        branch: currentState.selectedBranch,
        status: currentState.selectedStatus,
        query: query,
        taxId: currentState.taxId,
        previousDateStart: currentState.previousDateStart,
        previousDateEnd: currentState.previousDateEnd,
        statusCheckDateStart: currentState.statusCheckDateStart,
        statusCheckDateEnd: currentState.statusCheckDateEnd,
        selectedEmployeeIds: event.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          employees: employees,
          filteredEmployees: filteredEmployees,
          selectedShopId: event.shopId,
          selectedShopName: event.shopName,
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
        // Only B gets a recorded count, A gets 0
        final int taskRefCount = isContributorRow ? item.keyedDocumentCount : 0;
        
        // In the overall Employee summary (Main Row A), we accumulate the full counts.
        // We only add to the Employee total if it's NOT a contributor row, to avoid double-counting
        // the same task repeatedly in the Employee aggregated row.
        if (!isContributorRow) {
          totalDocCount += docCount;
          totalRefBalance += task.referenceBalance;
          totalRefCount += taskRefCount; // A's taskRefCount is 0, so employee recorded count comes from B separately
        } else {
          // Add B's recorded count to the master employee total
          totalRefCount += taskRefCount;
        }

        // Both A and B sub-rows show the full context of the task
        int taskWaitingVerify = 0;
        int taskPending = 0;
        int taskCompleted = 0;
        
        int taskPassed = task.getStatusCount(1);
        int taskRemaining = task.referenceBalance;
        int taskNotRecorded = task.getStatusCount(3);
        int taskCancelled = task.cancelledCount;
        int taskNotRequiredApproval = task.notRequiredApprovalCount;

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
          default:
            break;
        }

        // Only add to the Employee master totals if it's the A row to prevent double counting
        if (!isContributorRow) {
          totalPassed += taskPassed;
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
        if (taskWaitingVerify > 0) {
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
          cancelled: taskCancelled,
          notRequiredApproval: taskNotRequiredApproval,
          pending: taskPending,
          waitingKey: 0,
          waitingVerify: taskWaitingVerify,
          waitingFix: 0,
          passed: taskPassed,
          remaining: taskRemaining,
          notRecorded: taskNotRecorded,
          referenceCount: taskRefCount, // 0 for A, keyed amount for B
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
      if (totalWaitingVerify > 0) {
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
        taxId: ownerBy,
        previousDate: latestActive,
        statusCheckDate: latestActive,
        lastActive: latestActive,
        companyDetails: companyDetails,
      );
    }).toList();
  }

  void _onFilterByDateRange(FilterByDateRange event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      final filtered = _applyFilters(
        currentState.employees,
        startDate: event.startDate,
        endDate: event.endDate,
        branch: currentState.selectedBranch,
        status: currentState.selectedStatus,
        query: currentState.searchQuery,
        taxId: currentState.taxId,
        previousDateStart: currentState.previousDateStart,
        previousDateEnd: currentState.previousDateEnd,
        statusCheckDateStart: currentState.statusCheckDateStart,
        statusCheckDateEnd: currentState.statusCheckDateEnd,
      );

      emit(
        currentState.copyWith(
          startDate: event.startDate,
          endDate: event.endDate,
          filteredEmployees: filtered,
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
        taxId: currentState.taxId,
        previousDateStart: currentState.previousDateStart,
        previousDateEnd: currentState.previousDateEnd,
        statusCheckDateStart: currentState.statusCheckDateStart,
        statusCheckDateEnd: currentState.statusCheckDateEnd,
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
        taxId: currentState.taxId,
        previousDateStart: currentState.previousDateStart,
        previousDateEnd: currentState.previousDateEnd,
        statusCheckDateStart: currentState.statusCheckDateStart,
        statusCheckDateEnd: currentState.statusCheckDateEnd,
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
        taxId: currentState.taxId,
        previousDateStart: currentState.previousDateStart,
        previousDateEnd: currentState.previousDateEnd,
        statusCheckDateStart: currentState.statusCheckDateStart,
        statusCheckDateEnd: currentState.statusCheckDateEnd,
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

  void _onFilterByAdvancedOptions(
    FilterByAdvancedOptions event,
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
        query: currentState.searchQuery,
        taxId: event.taxId,
        previousDateStart: event.previousDateStart,
        previousDateEnd: event.previousDateEnd,
        statusCheckDateStart: event.statusCheckDateStart,
        statusCheckDateEnd: event.statusCheckDateEnd,
        selectedEmployeeIds: currentState.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          taxId: event.taxId,
          previousDateStart: event.previousDateStart,
          previousDateEnd: event.previousDateEnd,
          statusCheckDateStart: event.statusCheckDateStart,
          statusCheckDateEnd: event.statusCheckDateEnd,
          filteredEmployees: filtered,
        ),
      );
    }
  }

  void _onApplyAllFilters(ApplyAllFilters event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;

      String? branch = event.branch;
      if (branch == 'all' || branch == 'ทุกร้าน') branch = null;

      final filtered = _applyFilters(
        currentState.employees,
        startDate: event.startDate,
        endDate: event.endDate,
        branch: branch,
        status: currentState.selectedStatus,
        query: event.query,
        taxId: event.taxId,
        previousDateStart: event.previousDateStart,
        previousDateEnd: event.previousDateEnd,
        statusCheckDateStart: event.statusCheckDateStart,
        statusCheckDateEnd: event.statusCheckDateEnd,
        selectedEmployeeIds: event.selectedEmployeeIds,
      );

      emit(
        currentState.copyWith(
          searchQuery: event.query,
          selectedBranch: branch,
          startDate: event.startDate,
          endDate: event.endDate,
          taxId: event.taxId,
          previousDateStart: event.previousDateStart,
          previousDateEnd: event.previousDateEnd,
          statusCheckDateStart: event.statusCheckDateStart,
          statusCheckDateEnd: event.statusCheckDateEnd,
          filteredEmployees: filtered,
          selectedEmployeeIds: event.selectedEmployeeIds,
        ),
      );
    }
  }

  void _onResetFilters(ResetFilters event, Emitter<KpiState> emit) {
    if (state is KpiLoaded) {
      final currentState = state as KpiLoaded;
      emit(
        currentState.copyWith(
          filteredEmployees: currentState.employees,
          selectedBranch: null,
          selectedStatus: null,
          searchQuery: '',
          taxId: null,
          previousDateStart: null,
          previousDateEnd: null,
          statusCheckDateStart: null,
          statusCheckDateEnd: null,
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
    String? taxId,
    DateTime? previousDateStart,
    DateTime? previousDateEnd,
    DateTime? statusCheckDateStart,
    DateTime? statusCheckDateEnd,
    List<String>? selectedEmployeeIds,
  }) {
    var filtered = employees;

    // 1. Filter by Selected Employees (Tags)
    if (selectedEmployeeIds != null && selectedEmployeeIds.isNotEmpty) {
      // If tags are selected, SHOW ONLY those employees
      filtered = filtered
          .where((e) => selectedEmployeeIds.contains(e.id))
          .toList();
    }
    // 2. OR Filter by Search Query (if provided)
    // Note: If tags are present, query might be used to filter WITHIN tags or just for autocomplete.
    // Based on requirement "can still type to search", usually typing filters the list.
    // If selectedEmployeeIds is NOT empty, we already narrowed down to those.
    // If we type "Som" while "Emp A" is selected, usually we don't filter Key "Emp A" out unless "Emp A" doesn't match "Som".
    // But typically in multi-select, the text input is for ADDING new tags, not filtering the RESULT TABLE further (unless it's a separate filter).
    // However, the prompt says "select multiple... but still can type to search".
    // This implies the text field acts as a finder.
    // Let's assume:
    // - If selectedEmployeeIds is NOT EMPTY: The table shows those IDs.
    // - If selectedEmployeeIds IS EMPTY: The table shows results matching 'query'.
    else if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                e.id.toLowerCase().contains(q) ||
                (e.taxId != null && e.taxId!.toLowerCase().contains(q)) ||
                e.branch.toLowerCase().contains(q),
          )
          .toList();
    }

    if (startDate != null && endDate != null) {
      filtered = filtered.where((e) {
        // Normalize dates to ignore time if needed, or just compare
        // Assuming checks are inclusive
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );

        // Filter based on sub-table company details recording date
        if (e.companyDetails.isEmpty) return false;

        return e.companyDetails.any((detail) {
          return detail.recordingDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              detail.recordingDate.isBefore(end);
        });
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

    // Query filter moved to top to handle priority with selectedEmployeeIds

    if (taxId != null && taxId.isNotEmpty) {
      filtered = filtered
          .where((e) => e.taxId != null && e.taxId!.contains(taxId))
          .toList();
    }

    if (previousDateStart != null && previousDateEnd != null) {
      final start = DateTime(
        previousDateStart.year,
        previousDateStart.month,
        previousDateStart.day,
      );
      final end = DateTime(
        previousDateEnd.year,
        previousDateEnd.month,
        previousDateEnd.day,
        23,
        59,
        59,
      );

      filtered = filtered.where((e) {
        if (e.previousDate == null) return false;
        return e.previousDate!.isAfter(
              start.subtract(const Duration(seconds: 1)),
            ) &&
            e.previousDate!.isBefore(end);
      }).toList();
    }

    if (statusCheckDateStart != null && statusCheckDateEnd != null) {
      final start = DateTime(
        statusCheckDateStart.year,
        statusCheckDateStart.month,
        statusCheckDateStart.day,
      );
      final end = DateTime(
        statusCheckDateEnd.year,
        statusCheckDateEnd.month,
        statusCheckDateEnd.day,
        23,
        59,
        59,
      );

      filtered = filtered.where((e) {
        if (e.statusCheckDate == null) return false;
        return e.statusCheckDate!.isAfter(
              start.subtract(const Duration(seconds: 1)),
            ) &&
            e.statusCheckDate!.isBefore(end);
      }).toList();
    }

    return filtered;
  }
}
