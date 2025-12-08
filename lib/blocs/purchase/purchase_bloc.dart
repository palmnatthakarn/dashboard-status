import 'package:bloc/bloc.dart';
import '../../models/purchase.dart';
import '../../services/purchase_service.dart';

part 'purchase_event.dart';
part 'purchase_state.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  PurchaseBloc() : super(PurchaseInitialState()) {
    on<LoadPurchasesEvent>(_onLoadPurchases);
    on<LoadPurchasesByBranchEvent>(_onLoadPurchasesByBranch);
    on<LoadPurchasesByVendorEvent>(_onLoadPurchasesByVendor);
    on<LoadPurchaseSummaryEvent>(_onLoadPurchaseSummary);
    on<LoadDashboardPurchaseDataEvent>(_onLoadDashboardPurchaseData);
    on<RefreshPurchasesEvent>(_onRefreshPurchases);
    on<ClearPurchasesEvent>(_onClearPurchases);
  }

  Future<void> _onLoadPurchases(
    LoadPurchasesEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseLoadingState());
    try {
      final response = await PurchaseService.getAllPurchases(
        page: event.page,
        limit: event.limit,
        branchSync: event.branchSync,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
        vendorCode: event.vendorCode,
      );

      emit(
        PurchasesLoadedState(
          purchases: response.purchases ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PurchaseErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPurchasesByBranch(
    LoadPurchasesByBranchEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseLoadingState());
    try {
      final response = await PurchaseService.getPurchasesByBranch(
        event.branchSync,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        PurchasesLoadedState(
          purchases: response.purchases ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PurchaseErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPurchasesByVendor(
    LoadPurchasesByVendorEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseLoadingState());
    try {
      final response = await PurchaseService.getPurchasesByVendor(
        event.vendorCode,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        PurchasesLoadedState(
          purchases: response.purchases ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PurchaseErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPurchaseSummary(
    LoadPurchaseSummaryEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseLoadingState());
    try {
      final summary = await PurchaseService.getPurchaseSummaryByBranch(
        event.branchSync,
      );

      if (summary != null) {
        emit(PurchaseSummaryLoadedState(summary: summary));
      } else {
        emit(PurchaseErrorState(message: 'Purchase summary not found'));
      }
    } catch (e) {
      emit(PurchaseErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadDashboardPurchaseData(
    LoadDashboardPurchaseDataEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseLoadingState());
    try {
      final dashboardData = await PurchaseService.getDashboardPurchaseData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(DashboardPurchaseDataLoadedState(dashboardData: dashboardData));
    } catch (e) {
      emit(PurchaseErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefreshPurchases(
    RefreshPurchasesEvent event,
    Emitter<PurchaseState> emit,
  ) async {
    // Re-emit the current state or trigger a reload
    if (state is PurchasesLoadedState) {
      add(LoadPurchasesEvent());
    } else if (state is DashboardPurchaseDataLoadedState) {
      add(LoadDashboardPurchaseDataEvent());
    }
  }

  void _onClearPurchases(
    ClearPurchasesEvent event,
    Emitter<PurchaseState> emit,
  ) {
    emit(PurchaseInitialState());
  }
}
