part of 'sale_invoice_detail_bloc.dart';

@immutable
sealed class SaleInvoiceDetailEvent {}

class LoadSaleInvoiceDetailsEvent extends SaleInvoiceDetailEvent {
  final int? page;
  final int? limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;
  final String? productCode;
  final String? invoiceNo;

  LoadSaleInvoiceDetailsEvent({
    this.page,
    this.limit,
    this.branchSync,
    this.startDate,
    this.endDate,
    this.productCode,
    this.invoiceNo,
  });
}

class LoadSaleInvoiceDetailsByBranchEvent extends SaleInvoiceDetailEvent {
  final String branchSync;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadSaleInvoiceDetailsByBranchEvent({
    required this.branchSync,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadSaleInvoiceDetailsByProductEvent extends SaleInvoiceDetailEvent {
  final String productCode;
  final int? page;
  final int? limit;
  final String? startDate;
  final String? endDate;

  LoadSaleInvoiceDetailsByProductEvent({
    required this.productCode,
    this.page,
    this.limit,
    this.startDate,
    this.endDate,
  });
}

class LoadSaleInvoiceDetailSummaryEvent extends SaleInvoiceDetailEvent {
  final String branchSync;

  LoadSaleInvoiceDetailSummaryEvent({required this.branchSync});
}

class LoadDashboardSaleInvoiceDetailDataEvent extends SaleInvoiceDetailEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardSaleInvoiceDetailDataEvent({
    this.startDate,
    this.endDate,
  });
}

class RefreshSaleInvoiceDetailsEvent extends SaleInvoiceDetailEvent {}

class ClearSaleInvoiceDetailsEvent extends SaleInvoiceDetailEvent {}