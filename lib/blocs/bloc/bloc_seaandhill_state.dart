part of 'bloc_seaandhill_bloc.dart';

@immutable
sealed class BlocSeaandhillState {}

final class BlocSeaandhillInitial extends BlocSeaandhillState {}

final class JournalLoadingState extends BlocSeaandhillState {}

final class JournalLoadedState extends BlocSeaandhillState {
  final List<Journal> journals;
  final JournalSummary? summary;
  final Pagination? pagination;
  final Map<String, dynamic>? dashboardData;

  JournalLoadedState({
    required this.journals,
    this.summary,
    this.pagination,
    this.dashboardData,
  });

  JournalLoadedState copyWith({
    List<Journal>? journals,
    JournalSummary? summary,
    Pagination? pagination,
    Map<String, dynamic>? dashboardData,
  }) {
    return JournalLoadedState(
      journals: journals ?? this.journals,
      summary: summary ?? this.summary,
      pagination: pagination ?? this.pagination,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }
}

final class JournalErrorState extends BlocSeaandhillState {
  final String message;
  final String? errorCode;

  JournalErrorState({required this.message, this.errorCode});
}

final class JournalSummaryLoadedState extends BlocSeaandhillState {
  final JournalSummary summary;
  final String shopId;

  JournalSummaryLoadedState({required this.summary, required this.shopId});
}

final class AccountBalanceLoadedState extends BlocSeaandhillState {
  final double balance;
  final String accountId;

  AccountBalanceLoadedState({required this.balance, required this.accountId});
}

final class DashboardJournalDataLoadedState extends BlocSeaandhillState {
  final Map<String, dynamic> dashboardData;
  final List<Journal> journals;
  final List<Map<String, dynamic>> shopSummaries;

  DashboardJournalDataLoadedState({
    required this.dashboardData,
    required this.journals,
    required this.shopSummaries,
  });
}
