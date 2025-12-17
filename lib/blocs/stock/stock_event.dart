part of 'stock_bloc.dart';

@immutable
sealed class StockEvent {}

class LoadStocksEvent extends StockEvent {
  final int? page;
  final int? limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;
  final String? productCode;
  final String? status;

  LoadStocksEvent({
    this.page,
    this.limit,
    this.branchSync,
    this.startDate,
    this.endDate,
    this.productCode,
    this.status,
  });
}

class LoadStocksByBranchEvent extends StockEvent {
  final String branchSync;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadStocksByBranchEvent({
    required this.branchSync,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadStocksByProductEvent extends StockEvent {
  final String productCode;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadStocksByProductEvent({
    required this.productCode,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadStockSummaryEvent extends StockEvent {
  final String branchSync;

  LoadStockSummaryEvent({required this.branchSync});
}

class LoadDashboardStockDataEvent extends StockEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardStockDataEvent({
    this.startDate,
    this.endDate,
  });
}

class RefreshStocksEvent extends StockEvent {}

class ClearStocksEvent extends StockEvent {}
