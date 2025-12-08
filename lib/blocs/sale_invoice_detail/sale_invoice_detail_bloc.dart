import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/sale_invoice_detail.dart';
import '../../services/sale_invoice_detail_service.dart';

part 'sale_invoice_detail_event.dart';
part 'sale_invoice_detail_state.dart';

class SaleInvoiceDetailBloc
    extends Bloc<SaleInvoiceDetailEvent, SaleInvoiceDetailState> {
  SaleInvoiceDetailBloc() : super(SaleInvoiceDetailInitialState()) {
    on<LoadSaleInvoiceDetailsEvent>(_onLoadSaleInvoiceDetails);
    on<LoadSaleInvoiceDetailsByBranchEvent>(_onLoadSaleInvoiceDetailsByBranch);
    on<LoadSaleInvoiceDetailsByProductEvent>(
      _onLoadSaleInvoiceDetailsByProduct,
    );
    on<LoadSaleInvoiceDetailSummaryEvent>(_onLoadSaleInvoiceDetailSummary);
    on<LoadDashboardSaleInvoiceDetailDataEvent>(
      _onLoadDashboardSaleInvoiceDetailData,
    );
    on<RefreshSaleInvoiceDetailsEvent>(_onRefreshSaleInvoiceDetails);
    on<ClearSaleInvoiceDetailsEvent>(_onClearSaleInvoiceDetails);
  }

  Future<void> _onLoadSaleInvoiceDetails(
    LoadSaleInvoiceDetailsEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    emit(SaleInvoiceDetailLoadingState());
    try {
      final response = await SaleInvoiceDetailService.getAllSaleInvoiceDetails(
        page: event.page ?? 1,
        limit: event.limit ?? 20,
        branchSync: event.branchSync,
        startDate: event.startDate,
        endDate: event.endDate,
        itemCode: event.productCode,
        invoiceId: null,
      );

      emit(
        SaleInvoiceDetailsLoadedState(
          saleInvoiceDetails: response.saleInvoiceDetails ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoiceDetailsByBranch(
    LoadSaleInvoiceDetailsByBranchEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    emit(SaleInvoiceDetailLoadingState());
    try {
      final response =
          await SaleInvoiceDetailService.getSaleInvoiceDetailsByBranch(
            event.branchSync,
            page: event.page,
            limit: event.limit,
            startDate: event.startDate,
            endDate: event.endDate,
          );

      emit(
        SaleInvoiceDetailsLoadedState(
          saleInvoiceDetails: response.saleInvoiceDetails ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoiceDetailsByProduct(
    LoadSaleInvoiceDetailsByProductEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    emit(SaleInvoiceDetailLoadingState());
    try {
      final response =
          await SaleInvoiceDetailService.getSaleInvoiceDetailsByProduct(
            event.productCode,
            page: event.page,
            limit: event.limit,
            startDate: event.startDate,
            endDate: event.endDate,
          );

      emit(
        SaleInvoiceDetailsLoadedState(
          saleInvoiceDetails: response.saleInvoiceDetails ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoiceDetailSummary(
    LoadSaleInvoiceDetailSummaryEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    emit(SaleInvoiceDetailLoadingState());
    try {
      final summary =
          await SaleInvoiceDetailService.getSaleInvoiceDetailSummaryByBranch(
            event.branchSync,
          );

      if (summary != null) {
        emit(SaleInvoiceDetailSummaryLoadedState(summary: summary));
      } else {
        emit(
          SaleInvoiceDetailErrorState(
            message: 'Sale invoice detail summary not found',
          ),
        );
      }
    } catch (e) {
      emit(SaleInvoiceDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadDashboardSaleInvoiceDetailData(
    LoadDashboardSaleInvoiceDetailDataEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    emit(SaleInvoiceDetailLoadingState());
    try {
      await SaleInvoiceDetailService.getDashboardSaleInvoiceDetailData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(DashboardSaleInvoiceDetailDataLoadedState(dashboardData: []));
    } catch (e) {
      emit(SaleInvoiceDetailErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefreshSaleInvoiceDetails(
    RefreshSaleInvoiceDetailsEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) async {
    if (state is SaleInvoiceDetailsLoadedState) {
      add(LoadSaleInvoiceDetailsEvent());
    } else if (state is DashboardSaleInvoiceDetailDataLoadedState) {
      add(LoadDashboardSaleInvoiceDetailDataEvent());
    }
  }

  void _onClearSaleInvoiceDetails(
    ClearSaleInvoiceDetailsEvent event,
    Emitter<SaleInvoiceDetailState> emit,
  ) {
    emit(SaleInvoiceDetailInitialState());
  }
}
