import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/stock.dart';
import '../../services/stock_service.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  StockBloc() : super(StockInitialState()) {
    on<LoadStocksEvent>(_onLoadStocks);
    on<LoadStocksByBranchEvent>(_onLoadStocksByBranch);
    on<LoadStocksByProductEvent>(_onLoadStocksByProduct);
    on<LoadStockSummaryEvent>(_onLoadStockSummary);
    on<LoadDashboardStockDataEvent>(_onLoadDashboardStockData);
    on<RefreshStocksEvent>(_onRefreshStocks);
    on<ClearStocksEvent>(_onClearStocks);
  }

  Future<void> _onLoadStocks(
    LoadStocksEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoadingState());
    try {
      final response = await StockService.getAllStocks(
        page: event.page,
        limit: event.limit,
        branchSync: event.branchSync,
        startDate: event.startDate,
        endDate: event.endDate,
        productCode: event.productCode,
        status: event.status,
      );

      emit(
        StocksLoadedState(
          stocks: response.stocks ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(StockErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadStocksByBranch(
    LoadStocksByBranchEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoadingState());
    try {
      final response = await StockService.getStocksByBranch(
        event.branchSync,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        StocksLoadedState(
          stocks: response.stocks ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(StockErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadStocksByProduct(
    LoadStocksByProductEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoadingState());
    try {
      final response = await StockService.getStocksByProduct(
        event.productCode,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        StocksLoadedState(
          stocks: response.stocks ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(StockErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadStockSummary(
    LoadStockSummaryEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoadingState());
    try {
      final summary = await StockService.getStockSummaryByBranch(
        event.branchSync,
      );

      if (summary.isNotEmpty) {
        emit(StockSummaryLoadedState(summary: summary.first));
      } else {
        emit(StockErrorState(message: 'Stock summary not found'));
      }
    } catch (e) {
      emit(StockErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadDashboardStockData(
    LoadDashboardStockDataEvent event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoadingState());
    try {
      await StockService.getDashboardStockData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(DashboardStockDataLoadedState(dashboardData: []));
    } catch (e) {
      emit(StockErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefreshStocks(
    RefreshStocksEvent event,
    Emitter<StockState> emit,
  ) async {
    if (state is StocksLoadedState) {
      add(LoadStocksEvent());
    } else if (state is DashboardStockDataLoadedState) {
      add(LoadDashboardStockDataEvent());
    }
  }

  void _onClearStocks(ClearStocksEvent event, Emitter<StockState> emit) {
    emit(StockInitialState());
  }
}
