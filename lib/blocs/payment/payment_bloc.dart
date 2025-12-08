import 'package:bloc/bloc.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(PaymentInitialState()) {
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<LoadPaymentsByBranchEvent>(_onLoadPaymentsByBranch);
    on<LoadPaymentsByMethodEvent>(_onLoadPaymentsByMethod);
    on<LoadPaymentSummaryEvent>(_onLoadPaymentSummary);
    on<LoadDashboardPaymentDataEvent>(_onLoadDashboardPaymentData);
    on<RefreshPaymentsEvent>(_onRefreshPayments);
    on<ClearPaymentsEvent>(_onClearPayments);
  }

  Future<void> _onLoadPayments(
    LoadPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final response = await PaymentService.getAllPayments(
        page: event.page,
        limit: event.limit,
        branchSync: event.branchSync,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
        paymentMethod: event.paymentMethod,
        vendorCode: event.vendorCode,
      );

      emit(
        PaymentsLoadedState(
          payments: response.payments ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PaymentErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentsByBranch(
    LoadPaymentsByBranchEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final response = await PaymentService.getPaymentsByBranch(
        event.branchSync,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        PaymentsLoadedState(
          payments: response.payments ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PaymentErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentsByMethod(
    LoadPaymentsByMethodEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final response = await PaymentService.getPaymentsByMethod(
        event.paymentMethod,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        PaymentsLoadedState(
          payments: response.payments ?? [],
          totalCount: response.totalCount ?? 0,
          currentPage: response.currentPage ?? 1,
          totalPages: response.totalPages ?? 1,
        ),
      );
    } catch (e) {
      emit(PaymentErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentSummary(
    LoadPaymentSummaryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final summary = await PaymentService.getPaymentSummaryByBranch(
        event.branchSync,
      );

      if (summary != null) {
        emit(PaymentSummaryLoadedState(summary: summary));
      } else {
        emit(PaymentErrorState(message: 'Payment summary not found'));
      }
    } catch (e) {
      emit(PaymentErrorState(message: e.toString()));
    }
  }

  Future<void> _onLoadDashboardPaymentData(
    LoadDashboardPaymentDataEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoadingState());
    try {
      final dashboardData = await PaymentService.getDashboardPaymentData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(DashboardPaymentDataLoadedState(dashboardData: dashboardData));
    } catch (e) {
      emit(PaymentErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefreshPayments(
    RefreshPaymentsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is PaymentsLoadedState) {
      add(LoadPaymentsEvent());
    } else if (state is DashboardPaymentDataLoadedState) {
      add(LoadDashboardPaymentDataEvent());
    }
  }

  void _onClearPayments(ClearPaymentsEvent event, Emitter<PaymentState> emit) {
    emit(PaymentInitialState());
  }
}
