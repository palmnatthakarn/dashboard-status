import 'package:equatable/equatable.dart';

abstract class KpiJournalEvent extends Equatable {
  const KpiJournalEvent();

  @override
  List<Object?> get props => [];
}

class LoadKpiJournalData extends KpiJournalEvent {}

class SelectShopAndSearchJournal extends KpiJournalEvent {
  final String? shopId;
  final String? shopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? query;

  const SelectShopAndSearchJournal({
    this.shopId,
    this.shopName,
    this.startDate,
    this.endDate,
    this.query,
  });

  @override
  List<Object?> get props => [shopId, shopName, startDate, endDate, query];
}

class FilterKpiJournalByDateRange extends KpiJournalEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FilterKpiJournalByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class ResetKpiJournalFilters extends KpiJournalEvent {}
