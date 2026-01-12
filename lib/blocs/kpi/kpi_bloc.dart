import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;
import 'dart:math';
import 'kpi_event.dart';
import 'kpi_state.dart';
import '../../models/kpi_employee.dart';
import '../../services/task_service.dart';
import '../../services/auth_repository.dart';
import '../../services/multi_shop_service.dart';

class TaskWithShop {
  final TaskItem task;
  final String shopName;

  TaskWithShop(this.task, this.shopName);
}

class KpiBloc extends Bloc<KpiEvent, KpiState> {
  KpiBloc() : super(KpiInitial()) {
    on<LoadKpiData>(_onLoadKpiData);
    on<LoadShops>(_onLoadShops);
    on<SelectShopAndSearch>(_onSelectShopAndSearch);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<FilterByBranch>(_onFilterByBranch);
    on<FilterByStatus>(_onFilterByStatus);
    on<SearchEmployee>(_onSearchEmployee);
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
          dev.log('🏪 Loading shop list from API...');
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

            dev.log('✅ Loaded ${shops.length} shops');

            // Auto-select "All Shops" by default
            if (shops.isNotEmpty) {
              selectedShopId = '';
              selectedShopName = 'ทุกร้าน';

              dev.log('🏪 Auto-selecting All Shops');

              try {
                final List<TaskWithShop> allTasks = [];

                // Fetch tasks for ALL shops on initial load
                for (final shop in shops) {
                  try {
                    final response = await TaskService.fetchTasksForShop(
                      shopId: shop.shopId,
                      limit: 20,
                      status: [0, 1, 2, 3, 4],
                    );

                    if (response.success && response.tasks.isNotEmpty) {
                      allTasks.addAll(
                        response.tasks.map(
                          (t) => TaskWithShop(t, shop.shopName),
                        ),
                      );
                    }
                  } catch (e) {
                    dev.log(
                      '⚠️ Failed to load tasks for shop ${shop.shopName}: $e',
                    );
                  }
                }

                if (allTasks.isNotEmpty) {
                  employees = _groupTasksByOwner(allTasks);
                  dev.log(
                    '✅ Loaded ${employees.length} employees (grouped) for all shops',
                  );
                }
              } catch (e) {
                dev.log('⚠️ Failed to load tasks for all shops: $e');
              }
            }
          }
        } catch (e) {
          dev.log('⚠️ Failed to load shop list: $e');
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
      dev.log('🏪 Refreshing shop list...');
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
      dev.log('✅ Shop list refreshed: ${shops.length} shops');
    } catch (e) {
      dev.log('❌ Failed to refresh shop list: $e');
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

      if (event.shopId == null ||
          event.shopId!.isEmpty ||
          event.shopId == 'all') {
        dev.log('🏪 Fetching tasks for ALL shops...');

        // Iterate all shops
        for (final shop in currentState.shops) {
          try {
            final response = await TaskService.fetchTasksForShop(
              shopId: shop.shopId,
              limit: 20,
              status: [0, 1, 2, 3, 4],
            );

            if (response.success && response.tasks.isNotEmpty) {
              allTasks.addAll(
                response.tasks.map((t) => TaskWithShop(t, shop.shopName)),
              );
            }
          } catch (e) {
            dev.log('⚠️ Failed to load tasks for shop ${shop.shopName}: $e');
          }
        }
      } else {
        // Fetch for single shop
        dev.log('🏪 Fetching tasks for shop ${event.shopId}...');
        final response = await TaskService.fetchTasksForShop(
          shopId: event.shopId!,
          limit: 20,
          status: [0, 1, 2, 3, 4],
        );

        if (response.success && response.tasks.isNotEmpty) {
          allTasks.addAll(
            response.tasks.map((t) => TaskWithShop(t, event.shopName!)),
          );
        }
      }

      if (allTasks.isNotEmpty) {
        // Filter tasks by ownerAt
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

        // Group tasks by ownerBy
        employees = _groupTasksByOwner(filteredTasks);
        dev.log('✅ Loaded ${employees.length} employees (grouped)');
      } else {
        dev.log('📋 No shop selected, showing empty list');
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
        ),
      );
    } catch (e) {
      dev.log('❌ Error fetching tasks: $e');
      emit(
        currentState.copyWith(
          isSearching: false,
          employees: [],
          filteredEmployees: [],
        ),
      );
    }
  }

  /// Helper class to associate task with shop name
  List<KpiEmployee> _groupTasksByOwner(List<TaskWithShop> tasks) {
    // Group tasks by ownerBy
    final Map<String, List<TaskWithShop>> groupedTasks = {};
    for (final item in tasks) {
      final owner = item.task.ownerBy;
      if (!groupedTasks.containsKey(owner)) {
        groupedTasks[owner] = [];
      }
      groupedTasks[owner]!.add(item);
    }

    // Convert grouped tasks to KpiEmployee list
    return groupedTasks.entries.map((entry) {
      final ownerBy = entry.key;
      final ownerItems = entry.value;
      final ownerTasks = ownerItems.map((e) => e.task).toList();

      // Aggregate totals from all tasks for this owner
      int totalDocCount = 0; // จำนวน - from totalDocument
      int totalRefBalance = 0; // referenceBalance
      int totalRefCount = 0; // referenceCount

      int totalPending = 0; // Pending Record (status 3)
      int totalWaitingVerify = 0; // Waiting Verify (status 1)
      int totalCompleted = 0; // Completed (status 4)
      int totalPassed = 0; // Passed (Status 1 from totaldocumentstatus)
      int totalRemaining = 0; // Remaining (Status 0 from totaldocumentstatus)
      int totalCancelled = 0; // Cancelled (status 2 from totaldocumentstatus)
      DateTime? latestActive;

      // Create companyDetails from each task
      final companyDetails = ownerItems.map((item) {
        final task = item.task;
        final shopName = item.shopName;

        totalDocCount += task.totalDocument; // Use totalDocument for "จำนวน"
        totalRefBalance += task.referenceBalance;
        totalRefCount += task.referenceCount;

        // Count based on status
        // status 1 = รอตรวจสอบ, status 3 = รอบันทึก, status 4 = เสร็จสิ้น
        // Cancelled always from granular status 2
        int taskWaitingVerify = 0;
        int taskPending = 0;
        int taskCompleted = 0;
        int taskPassed = task.getStatusCount(
          1,
        ); // Status 1 = Passed/Uploaded/Correct
        int taskRemaining =
            task.referenceBalance; // Use referenceBalance for remaining
        int taskCancelled = task.cancelledCount;

        totalPassed += taskPassed;
        totalRemaining += taskRemaining;
        totalCancelled += task.cancelledCount;

        switch (task.status) {
          case 4: // Completed
            taskCompleted = task.totalDocument;
            // If status is 4, we assume it's fully completed
            totalCompleted += taskCompleted;
            break;
          case 3: // Pending Record
            taskPending = task.totalDocument;
            totalPending += taskPending;
            break;
          case 1: // Waiting Verify
            taskWaitingVerify = task.totalDocument;
            totalWaitingVerify += taskWaitingVerify;
            break;
          default:
            // Other statuses if needed
            break;
        }

        // Calculate delay step
        String taskDelayStep = 'none';

        if (latestActive == null || (task.ownerAt.isAfter(latestActive!))) {
          latestActive = task.ownerAt;
        }

        if (taskWaitingVerify > 0) {
          taskDelayStep = 'รอตรวจสอบ';
        } else if (taskPending > 0) {
          taskDelayStep = 'รอบันทึก';
        } else if (task.status == 0) {
          taskDelayStep = 'รออัปโหลด';
        }

        // Calculate delay only for specific steps
        final now = DateTime.now();
        int daysDiff = 0;

        if (['รอตรวจสอบ', 'รอบันทึก', 'รออัปโหลด'].contains(taskDelayStep)) {
          daysDiff = now.difference(task.ownerAt).inDays;
        }

        return KpiCompanyDetail(
          company: task.name,
          employee: task.ownerBy,
          recordingDate: task.ownerAt,
          totalBillCount: task
              .totalDocument, // Use totalDocument for "จำนวน" column in sub-table
          assigned: task.billCount,
          completed: taskCompleted,
          cancelled: taskCancelled,
          pending: taskPending,
          waitingKey: 0,
          waitingVerify: taskWaitingVerify,
          waitingFix: 0,
          passed: taskPassed,
          remaining: taskRemaining,
          referenceCount: task.referenceCount,
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

      // Calculate delay step and days
      String delayStep = 'none';
      int delayDays = 0;
      final now = DateTime.now();
      // Will determine days after step is picked

      // Determine which step has delay (priority: Verify > Record)
      // Determine which step has delay (priority: Verify > Record > Completed)
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

      // Calculate incentive status
      final int billsNeeded = totalDocCount - totalCompleted;
      final bool incentivePassed = billsNeeded <= 0 && totalDocCount > 0;

      return KpiEmployee(
        id: ownerBy,
        name: ownerBy,
        branch: '${ownerTasks.length} เอกสาร',
        documentStartDate: latestActive ?? DateTime.now(),
        documentEndDate: latestActive ?? DateTime.now(),
        dueDate: (latestActive ?? DateTime.now()).add(const Duration(days: 30)),
        totalDocuments: totalDocCount, // Use totalDocument for "จำนวน" column
        assignedDocuments: 0,
        pendingDocuments: totalPending,
        completedDocuments: totalCompleted,
        passedDocuments: totalPassed,
        remainingDocuments: totalRemaining,
        cancelledDocuments: totalCancelled,
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

  void _onSearchEmployee(SearchEmployee event, Emitter<KpiState> emit) {
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
      );

      emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredEmployees: filtered,
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
  }) {
    var filtered = employees;

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

    if (query != null && query.isNotEmpty) {
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
