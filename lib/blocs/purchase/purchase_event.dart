part of 'purchase_bloc.dart';

abstract class PurchaseEvent {}

class LoadPurchasesEvent extends PurchaseEvent {
  final int page;
  final int limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? vendorCode;

  LoadPurchasesEvent({
    this.page = 1,
    this.limit = 50,
    this.branchSync,
    this.startDate,
    this.endDate,
    this.status,
    this.vendorCode,
  });
}

class LoadPurchasesByBranchEvent extends PurchaseEvent {
  final String branchSync;
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;

  LoadPurchasesByBranchEvent({
    required this.branchSync,
    this.page = 1,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });
}

class LoadPurchasesByVendorEvent extends PurchaseEvent {
  final String vendorCode;
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;

  LoadPurchasesByVendorEvent({
    required this.vendorCode,
    this.page = 1,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });
}

class LoadPurchaseSummaryEvent extends PurchaseEvent {
  final String branchSync;

  LoadPurchaseSummaryEvent({required this.branchSync});
}

class LoadDashboardPurchaseDataEvent extends PurchaseEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardPurchaseDataEvent({
    this.startDate,
    this.endDate,
  });
}

class RefreshPurchasesEvent extends PurchaseEvent {}

class ClearPurchasesEvent extends PurchaseEvent {}