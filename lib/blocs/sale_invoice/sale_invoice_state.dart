part of 'sale_invoice_bloc.dart';

@immutable
sealed class SaleInvoiceState {}

class SaleInvoiceInitialState extends SaleInvoiceState {}

class SaleInvoiceLoadingState extends SaleInvoiceState {}

class SaleInvoicesLoadedState extends SaleInvoiceState {
  final List<SaleInvoice> saleInvoices;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  SaleInvoicesLoadedState({
    required this.saleInvoices,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class SaleInvoiceSummaryLoadedState extends SaleInvoiceState {
  final SaleInvoiceSummary summary;

  SaleInvoiceSummaryLoadedState({required this.summary});
}

class DashboardSaleInvoiceDataLoadedState extends SaleInvoiceState {
  final List<SaleInvoiceSummary> dashboardData;

  DashboardSaleInvoiceDataLoadedState({required this.dashboardData});
}

class SaleInvoiceErrorState extends SaleInvoiceState {
  final String message;

  SaleInvoiceErrorState({required this.message});
}
