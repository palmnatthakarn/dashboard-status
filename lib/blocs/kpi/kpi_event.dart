import 'package:equatable/equatable.dart';

abstract class KpiEvent extends Equatable {
  const KpiEvent();

  @override
  List<Object?> get props => [];
}

class LoadKpiData extends KpiEvent {}

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

class SearchEmployee extends KpiEvent {
  final String query;

  const SearchEmployee(this.query);

  @override
  List<Object?> get props => [query];
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
  });

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
  ];
}

class ResetFilters extends KpiEvent {}
