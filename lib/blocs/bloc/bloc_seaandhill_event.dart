part of 'bloc_seaandhill_bloc.dart';

@immutable
sealed class BlocSeaandhillEvent {}

// Load all journals
class LoadJournalsEvent extends BlocSeaandhillEvent {
  final int page;
  final int limit;
  final String? shopId;
  final String? startDate;
  final String? endDate;
  final String? transactionType;
  final String? status;

  LoadJournalsEvent({
    this.page = 1,
    this.limit = 50,
    this.shopId,
    this.startDate,
    this.endDate,
    this.transactionType,
    this.status,
  });
}

// Load journal by ID
class LoadJournalByIdEvent extends BlocSeaandhillEvent {
  final int journalId;

  LoadJournalByIdEvent(this.journalId);
}

// Load journals by shop
class LoadJournalsByShopEvent extends BlocSeaandhillEvent {
  final String shopId;
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;

  LoadJournalsByShopEvent({
    required this.shopId,
    this.page = 1,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });
}

// Load journal summary by shop
class LoadJournalSummaryEvent extends BlocSeaandhillEvent {
  final String shopId;

  LoadJournalSummaryEvent(this.shopId);
}

// Load account balance
class LoadAccountBalanceEvent extends BlocSeaandhillEvent {
  final String accountId;

  LoadAccountBalanceEvent(this.accountId);
}

// Load dashboard journal data
class LoadDashboardJournalDataEvent extends BlocSeaandhillEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardJournalDataEvent({this.startDate, this.endDate});
}

// Refresh journals
class RefreshJournalsEvent extends BlocSeaandhillEvent {}

// Filter journals
class FilterJournalsEvent extends BlocSeaandhillEvent {
  final String? shopId;
  final String? transactionType;
  final String? status;
  final String? startDate;
  final String? endDate;

  FilterJournalsEvent({
    this.shopId,
    this.transactionType,
    this.status,
    this.startDate,
    this.endDate,
  });
}
