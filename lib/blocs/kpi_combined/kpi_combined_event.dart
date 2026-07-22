import 'package:equatable/equatable.dart';

abstract class KpiCombinedEvent extends Equatable {
  const KpiCombinedEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — defaults to the current month, same as KPI / KPI Journal.
class LoadKpiCombinedData extends KpiCombinedEvent {
  // When true, skips KpiCombinedBloc's 2-minute fetch cache and always
  // hits the backend fresh — added 2026-07 because the page's "รีเฟรชข้อมูล"
  // button and pull-to-refresh both just re-dispatched this event with no
  // way to bypass the cache, so refreshing within 2 minutes of the last
  // load silently returned the same stale data and looked like the button
  // didn't do anything.
  final bool forceRefresh;

  const LoadKpiCombinedData({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SelectShopAndSearchCombined extends KpiCombinedEvent {
  final List<String> shopIds;
  final List<String> shopNames;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? query;

  // Explicit multi-select employee filter (2026-07) — replaces the old
  // free-text `query` box in the UI, which only ever matched one
  // substring at a time and couldn't express "show these 3 specific
  // people". Empty list means "no employee filter" (show everyone),
  // matching how empty shopIds means "all shops". `query` is left in
  // place for backward compatibility / possible future free-text use, but
  // the page no longer sends it.
  final List<String> employeeNames;

  const SelectShopAndSearchCombined({
    this.shopIds = const [],
    this.shopNames = const [],
    this.startDate,
    this.endDate,
    this.query,
    this.employeeNames = const [],
  });

  @override
  List<Object?> get props => [
    shopIds,
    shopNames,
    startDate,
    endDate,
    query,
    employeeNames,
  ];
}

class LoadKpiCombinedShopDetails extends KpiCombinedEvent {
  final String shopName;

  const LoadKpiCombinedShopDetails({required this.shopName});

  @override
  List<Object?> get props => [shopName];
}
