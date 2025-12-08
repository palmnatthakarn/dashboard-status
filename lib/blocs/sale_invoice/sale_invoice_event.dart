part of 'sale_invoice_bloc.dart';

@immutable
sealed class SaleInvoiceEvent {}

class LoadSaleInvoicesEvent extends SaleInvoiceEvent {
  final int? page;
  final int? limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? customerCode;

  LoadSaleInvoicesEvent({
    this.page,
    this.limit,
    this.branchSync,
    this.startDate,
    this.endDate,
    this.status,
    this.customerCode,
  });
}

class LoadSaleInvoicesByBranchEvent extends SaleInvoiceEvent {
  final String branchSync;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadSaleInvoicesByBranchEvent({
    required this.branchSync,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadSaleInvoicesByCustomerEvent extends SaleInvoiceEvent {
  final String customerCode;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadSaleInvoicesByCustomerEvent({
    required this.customerCode,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadSaleInvoiceSummaryEvent extends SaleInvoiceEvent {
  final String branchSync;

  LoadSaleInvoiceSummaryEvent({required this.branchSync});
}

class LoadDashboardSaleInvoiceDataEvent extends SaleInvoiceEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardSaleInvoiceDataEvent({
    this.startDate,
    this.endDate,
  });
}

class RefreshSaleInvoicesEvent extends SaleInvoiceEvent {}

class ClearSaleInvoicesEvent extends SaleInvoiceEvent {}