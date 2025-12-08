part of 'sale_invoice_detail_bloc.dart';

@immutable
sealed class SaleInvoiceDetailState {}

class SaleInvoiceDetailInitialState extends SaleInvoiceDetailState {}

class SaleInvoiceDetailLoadingState extends SaleInvoiceDetailState {}

class SaleInvoiceDetailsLoadedState extends SaleInvoiceDetailState {
  final List<SaleInvoiceDetail> saleInvoiceDetails;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  SaleInvoiceDetailsLoadedState({
    required this.saleInvoiceDetails,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class SaleInvoiceDetailSummaryLoadedState extends SaleInvoiceDetailState {
  final SaleInvoiceDetailSummary summary;

  SaleInvoiceDetailSummaryLoadedState({required this.summary});
}

class DashboardSaleInvoiceDetailDataLoadedState extends SaleInvoiceDetailState {
  final List<SaleInvoiceDetailSummary> dashboardData;

  DashboardSaleInvoiceDetailDataLoadedState({required this.dashboardData});
}

class SaleInvoiceDetailErrorState extends SaleInvoiceDetailState {
  final String message;

  SaleInvoiceDetailErrorState({required this.message});
}