part of 'purchase_bloc.dart';

abstract class PurchaseState {}

class PurchaseInitialState extends PurchaseState {}

class PurchaseLoadingState extends PurchaseState {}

class PurchasesLoadedState extends PurchaseState {
  final List<Purchase> purchases;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  PurchasesLoadedState({
    required this.purchases,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class PurchaseSummaryLoadedState extends PurchaseState {
  final PurchaseSummary summary;

  PurchaseSummaryLoadedState({required this.summary});
}

class DashboardPurchaseDataLoadedState extends PurchaseState {
  final Map<String, dynamic> dashboardData;

  DashboardPurchaseDataLoadedState({required this.dashboardData});
}

class PurchaseErrorState extends PurchaseState {
  final String message;

  PurchaseErrorState({required this.message});
}
