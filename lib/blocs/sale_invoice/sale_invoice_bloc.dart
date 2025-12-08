import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/sale_invoice.dart';
import '../../services/sale_invoice_service.dart';

part 'sale_invoice_event.dart';
part 'sale_invoice_state.dart';

class SaleInvoiceBloc extends Bloc<SaleInvoiceEvent, SaleInvoiceState> {
  SaleInvoiceBloc() : super(SaleInvoiceInitialState()) {
    on<LoadSaleInvoicesEvent>(_onLoadSaleInvoices);
    on<LoadSaleInvoicesByBranchEvent>(_onLoadSaleInvoicesByBranch);
    on<LoadSaleInvoicesByCustomerEvent>(_onLoadSaleInvoicesByCustomer);
    on<LoadSaleInvoiceSummaryEvent>(_onLoadSaleInvoiceSummary);
    on<LoadDashboardSaleInvoiceDataEvent>(_onLoadDashboardSaleInvoiceData);
    on<RefreshSaleInvoicesEvent>(_onRefreshSaleInvoices);
    on<ClearSaleInvoicesEvent>(_onClearSaleInvoices);
  }

  Future<void> _onLoadSaleInvoices(
    LoadSaleInvoicesEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    emit(SaleInvoiceLoadingState());
    try {
      final response = await SaleInvoiceService.getAllSaleInvoices(
        page: event.page ?? 1,
        limit: event.limit ?? 20,
        branchSync: event.branchSync,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
        customerCode: event.customerCode,
      );

      emit(
        SaleInvoicesLoadedState(
          saleInvoices: response.saleInvoices ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoicesByBranch(
    LoadSaleInvoicesByBranchEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    emit(SaleInvoiceLoadingState());
    try {
      final response = await SaleInvoiceService.getSaleInvoicesByBranch(
        event.branchSync,
        page: event.page ?? 1,
        limit: event.limit ?? 20,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        SaleInvoicesLoadedState(
          saleInvoices: response.saleInvoices ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoicesByCustomer(
    LoadSaleInvoicesByCustomerEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    emit(SaleInvoiceLoadingState());
    try {
      final response = await SaleInvoiceService.getSaleInvoicesByCustomer(
        event.customerCode,
        page: event.page ?? 1,
        limit: event.limit ?? 20,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        SaleInvoicesLoadedState(
          saleInvoices: response.saleInvoices ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(SaleInvoiceErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadSaleInvoiceSummary(
    LoadSaleInvoiceSummaryEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    emit(SaleInvoiceLoadingState());
    try {
      final summary = await SaleInvoiceService.getSaleInvoiceSummaryByBranch(
        event.branchSync,
      );

      if (summary != null) {
        emit(SaleInvoiceSummaryLoadedState(summary: summary));
      } else {
        emit(SaleInvoiceErrorState(message: 'Sale invoice summary not found'));
      }
    } catch (e) {
      emit(SaleInvoiceErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadDashboardSaleInvoiceData(
    LoadDashboardSaleInvoiceDataEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    emit(SaleInvoiceLoadingState());
    try {
      await SaleInvoiceService.getDashboardSaleInvoiceData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(DashboardSaleInvoiceDataLoadedState(dashboardData: []));
    } catch (e) {
      emit(SaleInvoiceErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefreshSaleInvoices(
    RefreshSaleInvoicesEvent event,
    Emitter<SaleInvoiceState> emit,
  ) async {
    if (state is SaleInvoicesLoadedState) {
      add(LoadSaleInvoicesEvent());
    } else if (state is DashboardSaleInvoiceDataLoadedState) {
      add(LoadDashboardSaleInvoiceDataEvent());
    }
  }

  void _onClearSaleInvoices(
    ClearSaleInvoicesEvent event,
    Emitter<SaleInvoiceState> emit,
  ) {
    emit(SaleInvoiceInitialState());
  }
}
