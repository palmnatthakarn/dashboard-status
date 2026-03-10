import 'package:equatable/equatable.dart';

abstract class KpiEvent extends Equatable {
  const KpiEvent();

  @override
  List<Object?> get props => [];
}

class LoadKpiData extends KpiEvent {}

/// Load shop list from /list-shop API
class LoadShops extends KpiEvent {}

/// Select shop and fetch tasks
class SelectShopAndSearch extends KpiEvent {
  final String? shopId;
  final String? shopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? query;

  const SelectShopAndSearch({
    this.shopId,
    this.shopName,
    this.startDate,
    this.endDate,
    this.query,
    this.selectedEmployeeIds,
  });

  final List<String>? selectedEmployeeIds;

  @override
  List<Object?> get props => [
    shopId,
    shopName,
    startDate,
    endDate,
    query,
    selectedEmployeeIds,
  ];
}

class FilterByDateRange extends KpiEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FilterByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class FilterByBranch extends KpiEvent {
  final String branch;

  const FilterByBranch(this.branch);

  @override
  List<Object?> get props => [branch];
}

class FilterByStatus extends KpiEvent {
  final String status;

  const FilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class UpdateEmployeeFilter extends KpiEvent {
  final List<String> selectedEmployeeIds;
  final String query;

  const UpdateEmployeeFilter({
    this.selectedEmployeeIds = const [],
    this.query = '',
  });

  @override
  List<Object?> get props => [selectedEmployeeIds, query];
}

class FilterByAdvancedOptions extends KpiEvent {
  final String? taxId;
  final DateTime? previousDateStart;
  final DateTime? previousDateEnd;
  final DateTime? statusCheckDateStart;
  final DateTime? statusCheckDateEnd;

  const FilterByAdvancedOptions({
    this.taxId,
    this.previousDateStart,
    this.previousDateEnd,
    this.statusCheckDateStart,
    this.statusCheckDateEnd,
  });

  @override
  List<Object?> get props => [
    taxId,
    previousDateStart,
    previousDateEnd,
    statusCheckDateStart,
    statusCheckDateEnd,
  ];
}

class ApplyAllFilters extends KpiEvent {
  final String query;
  final String? branch;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? taxId;
  final DateTime? previousDateStart;
  final DateTime? previousDateEnd;
  final DateTime? statusCheckDateStart;
  final DateTime? statusCheckDateEnd;

  const ApplyAllFilters({
    this.query = '',
    this.branch,
    this.startDate,
    this.endDate,
    this.taxId,
    this.previousDateStart,
    this.previousDateEnd,
    this.statusCheckDateStart,
    this.statusCheckDateEnd,
    this.selectedEmployeeIds,
  });

  final List<String>? selectedEmployeeIds;

  @override
  List<Object?> get props => [
    query,
    branch,
    startDate,
    endDate,
    taxId,
    previousDateStart,
    previousDateEnd,
    statusCheckDateStart,
    statusCheckDateEnd,
    selectedEmployeeIds,
  ];
}

class ResetFilters extends KpiEvent {}
