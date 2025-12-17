part of 'stock_bloc.dart';

@immutable
sealed class StockState {}

class StockInitialState extends StockState {}

class StockLoadingState extends StockState {}

class StocksLoadedState extends StockState {
  final List<Stock> stocks;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  StocksLoadedState({
    required this.stocks,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class StockSummaryLoadedState extends StockState {
  final StockSummary summary;

  StockSummaryLoadedState({required this.summary});
}

class DashboardStockDataLoadedState extends StockState {
  final List<StockSummary> dashboardData;

  DashboardStockDataLoadedState({required this.dashboardData});
}

class StockErrorState extends StockState {
  final String message;

  StockErrorState({required this.message});
}
