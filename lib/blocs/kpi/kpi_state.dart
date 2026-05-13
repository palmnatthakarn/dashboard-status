import 'package:equatable/equatable.dart';
import '../../models/kpi_employee.dart';

/// Shop item for dropdown
class KpiShopItem {
  final String shopId;
  final String shopName;

  const KpiShopItem({required this.shopId, required this.shopName});
}

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
  // Shop list from /list-shop API
  final List<KpiShopItem> shops;
  // Multi-select shop support
  final List<String> selectedShopIds;
  final List<String> selectedShopNames;
  final bool isSearching;
  final List<String> selectedEmployeeIds;

  const KpiLoaded({
    required this.employees,
    required this.filteredEmployees,
    required this.startDate,
    required this.endDate,
    this.selectedBranch,
    this.selectedStatus,
    this.searchQuery = '',
    this.shops = const [],
    this.selectedShopIds = const [],
    this.selectedShopNames = const [],
    this.isSearching = false,
    this.selectedEmployeeIds = const [],
  });

  /// Backward-compat getters used by existing bloc code
  String? get selectedShopId =>
      selectedShopIds.isEmpty ? null : selectedShopIds.first;
  String? get selectedShopName =>
      selectedShopNames.isEmpty ? null : selectedShopNames.join(', ');

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
  int get waitingVerify =>
      employees.fold(0, (sum, e) => sum + e.waitingVerify);
  int get waitingFix => employees.fold(0, (sum, e) => sum + e.waitingFix);

  static const _absent = Object();

  KpiLoaded copyWith({
    List<KpiEmployee>? employees,
    List<KpiEmployee>? filteredEmployees,
    DateTime? startDate,
    DateTime? endDate,
    Object? selectedBranch = _absent,
    Object? selectedStatus = _absent,
    String? searchQuery,
    List<KpiShopItem>? shops,
    List<String>? selectedShopIds,
    List<String>? selectedShopNames,
    bool? isSearching,
    List<String>? selectedEmployeeIds,
  }) {
    return KpiLoaded(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedBranch: selectedBranch == _absent ? this.selectedBranch : selectedBranch as String?,
      selectedStatus: selectedStatus == _absent ? this.selectedStatus : selectedStatus as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      shops: shops ?? this.shops,
      selectedShopIds: selectedShopIds ?? this.selectedShopIds,
      selectedShopNames: selectedShopNames ?? this.selectedShopNames,
      isSearching: isSearching ?? this.isSearching,
      selectedEmployeeIds: selectedEmployeeIds ?? this.selectedEmployeeIds,
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
    shops,
    selectedShopIds,
    selectedShopNames,
    isSearching,
    selectedEmployeeIds,
  ];
}

class KpiError extends KpiState {
  final String message;

  const KpiError(this.message);

  @override
  List<Object?> get props => [message];
}
