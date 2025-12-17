part of 'payment_bloc.dart';

abstract class PaymentState {}

class PaymentInitialState extends PaymentState {}

class PaymentLoadingState extends PaymentState {}

class PaymentsLoadedState extends PaymentState {
  final List<Payment> payments;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  PaymentsLoadedState({
    required this.payments,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class PaymentSummaryLoadedState extends PaymentState {
  final PaymentSummary summary;

  PaymentSummaryLoadedState({required this.summary});
}

class DashboardPaymentDataLoadedState extends PaymentState {
  final Map<String, dynamic> dashboardData;

  DashboardPaymentDataLoadedState({required this.dashboardData});
}

class PaymentErrorState extends PaymentState {
  final String message;

  PaymentErrorState({required this.message});
}
