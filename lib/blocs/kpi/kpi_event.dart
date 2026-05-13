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
  final List<String> shopIds;
  final List<String> shopNames;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? query;
  final List<String>? selectedEmployeeIds;

  const SelectShopAndSearch({
    this.shopIds = const [],
    this.shopNames = const [],
    this.startDate,
    this.endDate,
    this.query,
    this.selectedEmployeeIds,
  });

  /// Convenience getter: single shopId for backward compat (first selected, or '')
  String? get shopId => shopIds.isEmpty ? null : shopIds.first;
  String? get shopName => shopNames.isEmpty ? null : shopNames.join(', ');

  @override
  List<Object?> get props => [
    shopIds,
    shopNames,
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

