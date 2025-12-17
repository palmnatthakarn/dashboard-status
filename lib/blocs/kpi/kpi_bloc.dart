import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import 'kpi_event.dart';
import 'kpi_state.dart';
import '../../models/kpi_employee.dart';

class KpiBloc extends Bloc<KpiEvent, KpiState> {
  KpiBloc() : super(KpiInitial()) {
    on<LoadKpiData>(_onLoadKpiData);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<FilterByBranch>(_onFilterByBranch);
    on<FilterByStatus>(_onFilterByStatus);
    on<SearchEmployee>(_onSearchEmployee);
    on<FilterByAdvancedOptions>(_onFilterByAdvancedOptions);
    on<ApplyAllFilters>(_onApplyAllFilters);
    on<ResetFilters>(_onResetFilters);
  }

  Future<void> _onLoadKpiData(LoadKpiData event, Emitter<KpiState> emit) async {
    emit(KpiLoading());

    try {
      // Simulate API call - replace with actual data fetching
      await Future.delayed(const Duration(seconds: 1));

      final employees = _generateMockData();
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      emit(
        KpiLoaded(
          employees: employees,
          filteredEmployees: employees,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      emit(KpiError('ไม่สามารถโหลดข้อมูลได้: ${e.toString()}'));
    }
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
      if (branch == 'all' || branch == 'ทุกสาขา') branch = null;

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

  List<KpiEmployee> _generateMockData() {
    final fixedEmployees = [
      KpiEmployee(
        id: '1',
        name: 'สมชาย ใจดี',
        branch: 'สาขา01',
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: null,
        totalDocuments: 150,
        assignedDocuments: 120,
        pendingDocuments: 20,
        completedDocuments: 100,
        cancelledDocuments: 10,
        waitingKey: 12,
        waitingVerify: 5,
        waitingFix: 3,
        status: 'assigned',
        taxId: '1234567890123',
        previousDate: DateTime(2025, 11, 15),
        statusCheckDate: DateTime(2025, 11, 20),
        companyDetails: _generateMockCompanyDetails('สมชาย ใจดี'),
      ),
      KpiEmployee(
        id: '2',
        name: 'สมหญิง รักงาน',
        branch: 'สาขา02',
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: DateTime(2025, 12, 4),
        totalDocuments: 200,
        assignedDocuments: 180,
        pendingDocuments: 10,
        completedDocuments: 170,
        cancelledDocuments: 20,
        waitingKey: 5,
        waitingVerify: 3,
        waitingFix: 2,
        status: 'completed',
        taxId: '9876543210987',
        previousDate: DateTime(2025, 11, 10),
        statusCheckDate: DateTime(2025, 11, 25),
        companyDetails: _generateMockCompanyDetails('สมหญิง รักงาน'),
      ),
      KpiEmployee(
        id: '3',
        name: 'วิชัย ขยัน',
        branch: 'สาขา01',
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: null,
        totalDocuments: 100,
        assignedDocuments: 80,
        pendingDocuments: 50,
        completedDocuments: 30,
        cancelledDocuments: 20,
        waitingKey: 30,
        waitingVerify: 12,
        waitingFix: 8,
        status: 'pending',
        taxId: '1111122222333',
        previousDate: DateTime(2025, 11, 5),
        statusCheckDate: DateTime(2025, 11, 18),
        companyDetails: _generateMockCompanyDetails('วิชัย ขยัน'),
      ),
      KpiEmployee(
        id: '4',
        name: 'สุดา มานะ',
        branch: 'สาขา03',
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: null,
        totalDocuments: 180,
        assignedDocuments: 150,
        pendingDocuments: 15,
        completedDocuments: 135,
        cancelledDocuments: 30,
        waitingKey: 8,
        waitingVerify: 4,
        waitingFix: 3,
        status: 'assigned',
        taxId: '5555566666777',
        previousDate: DateTime(2025, 11, 12),
        statusCheckDate: DateTime(2025, 11, 22),
        companyDetails: _generateMockCompanyDetails('สุดา มานะ'),
      ),
      KpiEmployee(
        id: '5',
        name: 'ประยุทธ์ ทำดี',
        branch: 'สาขา02',
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: DateTime(2025, 12, 4),
        totalDocuments: 220,
        assignedDocuments: 220,
        pendingDocuments: 0,
        completedDocuments: 220,
        cancelledDocuments: 0,
        waitingKey: 0,
        waitingVerify: 0,
        waitingFix: 0,
        status: 'completed',
        taxId: '9999988888777',
        previousDate: DateTime(2025, 11, 28),
        statusCheckDate: DateTime(2025, 11, 29),
        companyDetails: _generateMockCompanyDetails('ประยุทธ์ ทำดี'),
      ),
    ];

    final random = Random();
    final branches = ['สาขา01', 'สาขา02', 'สาขา03', 'สาขา04', 'สาขา05'];
    final statuses = ['assigned', 'pending', 'completed'];

    final extraEmployees = List.generate(50, (index) {
      final i = index + 6;
      final assigned = 50 + random.nextInt(200);
      final completed = random.nextInt(assigned);
      final pending = assigned - completed;
      final waitingKey = pending > 0 ? random.nextInt(pending + 1) : 0;
      final remainingAfterKey = pending - waitingKey;
      final waitingVerify = remainingAfterKey > 0
          ? random.nextInt(remainingAfterKey + 1)
          : 0;
      final waitingFix = remainingAfterKey - waitingVerify;

      // Status logic based on pending/completed
      String status = statuses[random.nextInt(statuses.length)];
      if (pending == 0) {
        status = 'completed';
      } else if (pending > assigned / 2)
        status = 'pending';

      return KpiEmployee(
        id: '$i',
        name: 'พนักงาน $i',
        branch: branches[random.nextInt(branches.length)],
        documentStartDate: DateTime(2025, 11, 1),
        documentEndDate: DateTime(2025, 11, 30),
        dueDate: DateTime(2025, 12, 30),
        submittedDate: random.nextBool()
            ? DateTime(2025, 12, 1 + random.nextInt(10))
            : null,
        totalDocuments: assigned + random.nextInt(20),
        assignedDocuments: assigned,
        pendingDocuments: pending,
        completedDocuments: completed,
        cancelledDocuments: random.nextInt(10),
        waitingKey: waitingKey,
        waitingVerify: waitingVerify,
        waitingFix: waitingFix,
        status: status,
        taxId: '${1000000000000 + i}',
        previousDate: DateTime(2025, 11, 1 + random.nextInt(20)),
        statusCheckDate: DateTime(2025, 11, 15 + random.nextInt(15)),
        companyDetails: _generateMockCompanyDetails('พนักงาน $i'),
      );
    });

    return [...fixedEmployees, ...extraEmployees];
  }

  List<KpiCompanyDetail> _generateMockCompanyDetails(String employeeName) {
    final random = Random(employeeName.hashCode);
    final companies = [
      'บริษัท ABC จำกัด',
      'บริษัท XYZ จำกัด',
      'บริษัท DEF จำกัด',
      'บริษัท GHI จำกัด',
      'บริษัท JKL จำกัด',
    ];
    final teamMembers = ['นาย ก.', 'นาง ข.', 'นาย ค.', 'นาง ง.'];

    final count = 2 + random.nextInt(3);
    return List.generate(count, (index) {
      final assigned = random.nextInt(50);
      final completed = random.nextInt(assigned + 1);
      final pending = assigned - completed;
      final waitingKey = pending > 0 ? random.nextInt(pending + 1) : 0;
      final remaining = pending - waitingKey;
      final waitingVerify = remaining > 0 ? random.nextInt(remaining + 1) : 0;
      final waitingFix = remaining - waitingVerify;

      // Ensure consistent statuses
      String status = 'r';
      final statusList = ['รอดำเนินการ', 'กำลังดำเนินการ', 'เสร็จสมบูรณ์'];
      status = statusList[random.nextInt(3)];

      return KpiCompanyDetail(
        company: companies[index % companies.length],
        employee: teamMembers[random.nextInt(teamMembers.length)],
        recordingDate: DateTime(
          2025,
          11,
          1,
        ).add(Duration(days: random.nextInt(30))),
        assigned: assigned,
        pending: pending,
        waitingKey: waitingKey,
        waitingVerify: waitingVerify,
        waitingFix: waitingFix,
        completed: completed,
        cancelled: random.nextInt(5),
        status: status,
      );
    });
  }
}
