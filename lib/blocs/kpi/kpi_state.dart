import 'package:equatable/equatable.dart';
import '../../models/kpi_employee.dart';

abstract class KpiState extends Equatable {
  const KpiState();

  @override
  List<Object?> get props => [];
}

class KpiInitial extends KpiState {}

class KpiLoading extends KpiState {}

class KpiLoaded extends KpiState {
  final List<KpiEmployee> employees;
  final List<KpiEmployee> filteredEmployees;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedBranch;
  final String? selectedStatus;
  final String searchQuery;
  // Advanced filters
  final String? taxId;
  final DateTime? previousDateStart;
  final DateTime? previousDateEnd;
  final DateTime? statusCheckDateStart;
  final DateTime? statusCheckDateEnd;

  const KpiLoaded({
    required this.employees,
    required this.filteredEmployees,
    required this.startDate,
    required this.endDate,
    this.selectedBranch,
    this.selectedStatus,
    this.searchQuery = '',
    this.taxId,
    this.previousDateStart,
    this.previousDateEnd,
    this.statusCheckDateStart,
    this.statusCheckDateEnd,
  });

  int get totalDocuments =>
      employees.fold(0, (sum, e) => sum + e.totalDocuments);
  int get assignedDocuments =>
      employees.fold(0, (sum, e) => sum + e.assignedDocuments);
  int get pendingDocuments =>
      employees.fold(0, (sum, e) => sum + e.pendingDocuments);
  int get completedDocuments =>
      employees.fold(0, (sum, e) => sum + e.completedDocuments);

  // Detailed status breakdown aggregates
  int get cancelledDocuments =>
      employees.fold(0, (sum, e) => sum + e.cancelledDocuments);
  int get waitingKey => employees.fold(0, (sum, e) => sum + e.waitingKey);
  int get waitingVerify => employees.fold(0, (sum, e) => sum + e.waitingVerify);
  int get waitingFix => employees.fold(0, (sum, e) => sum + e.waitingFix);

  KpiLoaded copyWith({
    List<KpiEmployee>? employees,
    List<KpiEmployee>? filteredEmployees,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedBranch,
    String? selectedStatus,
    String? searchQuery,
    String? taxId,
    DateTime? previousDateStart,
    DateTime? previousDateEnd,
    DateTime? statusCheckDateStart,
    DateTime? statusCheckDateEnd,
  }) {
    return KpiLoaded(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedBranch: selectedBranch,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      taxId: taxId ?? this.taxId,
      previousDateStart: previousDateStart ?? this.previousDateStart,
      previousDateEnd: previousDateEnd ?? this.previousDateEnd,
      statusCheckDateStart: statusCheckDateStart ?? this.statusCheckDateStart,
      statusCheckDateEnd: statusCheckDateEnd ?? this.statusCheckDateEnd,
    );
  }

  @override
  List<Object?> get props => [
    employees,
    filteredEmployees,
    startDate,
    endDate,
    selectedBranch,
    selectedStatus,
    searchQuery,
    taxId,
    previousDateStart,
    previousDateEnd,
    statusCheckDateStart,
    statusCheckDateEnd,
  ];
}

class KpiError extends KpiState {
  final String message;

  const KpiError(this.message);

  @override
  List<Object?> get props => [message];
}
