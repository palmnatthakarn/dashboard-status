part of 'payment_bloc.dart';

abstract class PaymentEvent {}

class LoadPaymentsEvent extends PaymentEvent {
  final int page;
  final int limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? paymentMethod;
  final String? vendorCode;

  LoadPaymentsEvent({
    this.page = 1,
    this.limit = 50,
    this.branchSync,
    this.startDate,
    this.endDate,
    this.status,
    this.paymentMethod,
    this.vendorCode,
  });
}

class LoadPaymentsByBranchEvent extends PaymentEvent {
  final String branchSync;
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;

  LoadPaymentsByBranchEvent({
    required this.branchSync,
    this.page = 1,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });
}

class LoadPaymentsByMethodEvent extends PaymentEvent {
  final String paymentMethod;
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;

  LoadPaymentsByMethodEvent({
    required this.paymentMethod,
    this.page = 1,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });
}

class LoadPaymentSummaryEvent extends PaymentEvent {
  final String branchSync;

  LoadPaymentSummaryEvent({required this.branchSync});
}

class LoadDashboardPaymentDataEvent extends PaymentEvent {
  final String? startDate;
  final String? endDate;

  LoadDashboardPaymentDataEvent({
    this.startDate,
    this.endDate,
  });
}

class RefreshPaymentsEvent extends PaymentEvent {}

class ClearPaymentsEvent extends PaymentEvent {}
