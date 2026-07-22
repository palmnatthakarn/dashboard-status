import 'package:equatable/equatable.dart';
import '../../models/kpi_combined_employee.dart';

abstract class KpiCombinedState extends Equatable {
  const KpiCombinedState();

  @override
  List<Object?> get props => [];
}

class KpiCombinedInitial extends KpiCombinedState {}

class KpiCombinedLoading extends KpiCombinedState {}

class KpiCombinedError extends KpiCombinedState {
  final String message;

  const KpiCombinedError(this.message);

  @override
  List<Object?> get props => [message];
}

class KpiCombinedLoaded extends KpiCombinedState {
  final List<KpiCombinedEmployee> employees;
  final List<KpiCombinedEmployee> filteredEmployees;
  final List<KpiCombinedShopItem> shops;
  final List<String> selectedShopIds;
  final List<String> selectedShopNames;
  final DateTime startDate;
  final DateTime endDate;
  final String searchQuery;
  // Multi-select employee filter (2026-07) — see
  // SelectShopAndSearchCombined.employeeNames doc comment.
  final List<String> selectedEmployeeNames;
  final bool isSearching;
  final List<String> detailLoadedShopNames;
  final List<String> detailLoadingShopNames;
  final List<String> detailErrorShopNames;
  final bool summaryReady;

  const KpiCombinedLoaded({
    required this.employees,
    required this.filteredEmployees,
    required this.shops,
    this.selectedShopIds = const [],
    this.selectedShopNames = const [],
    required this.startDate,
    required this.endDate,
    this.searchQuery = '',
    this.selectedEmployeeNames = const [],
    this.isSearching = false,
    this.detailLoadedShopNames = const [],
    this.detailLoadingShopNames = const [],
    this.detailErrorShopNames = const [],
    this.summaryReady = true,
  });

  /// Aggregate totals across ALL fetched employees (not just filtered) —
  /// used by DashboardStatisticsGrid on the Overview page, matching what
  /// KpiLoaded's equivalent getters used to provide.
  int get totalDocuments =>
      employees.fold(0, (sum, e) => sum + e.totalDocuments);
  int get requiredToRecordDocuments =>
      employees.fold(0, (sum, e) => sum + e.requiredToRecordDocuments);
  int get recordedDocuments =>
      employees.fold(0, (sum, e) => sum + e.recordedDocuments);

  /// Matches the visible table's "คงเหลือ" column for the active filters.
  int get filteredRemainingDocuments =>
      filteredEmployees.fold(0, (sum, e) => sum + e.remainingDocuments);

  KpiCombinedLoaded copyWith({
    List<KpiCombinedEmployee>? employees,
    List<KpiCombinedEmployee>? filteredEmployees,
    List<KpiCombinedShopItem>? shops,
    List<String>? selectedShopIds,
    List<String>? selectedShopNames,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    List<String>? selectedEmployeeNames,
    bool? isSearching,
    List<String>? detailLoadedShopNames,
    List<String>? detailLoadingShopNames,
    List<String>? detailErrorShopNames,
    bool? summaryReady,
  }) {
    return KpiCombinedLoaded(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      shops: shops ?? this.shops,
      selectedShopIds: selectedShopIds ?? this.selectedShopIds,
      selectedShopNames: selectedShopNames ?? this.selectedShopNames,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEmployeeNames:
          selectedEmployeeNames ?? this.selectedEmployeeNames,
      isSearching: isSearching ?? this.isSearching,
      detailLoadedShopNames:
          detailLoadedShopNames ?? this.detailLoadedShopNames,
      detailLoadingShopNames:
          detailLoadingShopNames ?? this.detailLoadingShopNames,
      detailErrorShopNames: detailErrorShopNames ?? this.detailErrorShopNames,
      summaryReady: summaryReady ?? this.summaryReady,
    );
  }

  @override
  List<Object?> get props => [
    employees,
    filteredEmployees,
    shops,
    selectedShopIds,
    selectedShopNames,
    startDate,
    endDate,
    searchQuery,
    selectedEmployeeNames,
    isSearching,
    detailLoadedShopNames,
    detailLoadingShopNames,
    detailErrorShopNames,
    summaryReady,
  ];
}
