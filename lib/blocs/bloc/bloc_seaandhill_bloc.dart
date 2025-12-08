import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'dart:developer';
import '../../models/journal.dart';
import '../../services/journal_service.dart';

part 'bloc_seaandhill_event.dart';
part 'bloc_seaandhill_state.dart';

class BlocSeaandhillBloc
    extends Bloc<BlocSeaandhillEvent, BlocSeaandhillState> {
  BlocSeaandhillBloc() : super(BlocSeaandhillInitial()) {
    on<LoadJournalsEvent>(_onLoadJournals);
    on<LoadJournalByIdEvent>(_onLoadJournalById);
    on<LoadJournalsByShopEvent>(_onLoadJournalsByShop);
    on<LoadJournalSummaryEvent>(_onLoadJournalSummary);
    on<LoadAccountBalanceEvent>(_onLoadAccountBalance);
    on<LoadDashboardJournalDataEvent>(_onLoadDashboardJournalData);
    on<RefreshJournalsEvent>(_onRefreshJournals);
    on<FilterJournalsEvent>(_onFilterJournals);
  }

  Future<void> _onLoadJournals(
    LoadJournalsEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log(
        '📊 Loading journals with filters: shopId=${event.shopId}, type=${event.transactionType}',
      );

      final response = await JournalService.getAllJournals(
        page: event.page,
        limit: event.limit,
        shopId: event.shopId,
        startDate: event.startDate,
        endDate: event.endDate,
        transactionType: event.transactionType,
        status: event.status,
      );

      emit(
        JournalLoadedState(
          journals: response.journals ?? [],
          summary: response.summary,
          pagination: response.pagination,
        ),
      );

      log('✅ Loaded ${response.journals?.length ?? 0} journals');
    } catch (e) {
      log('💥 Error loading journals: $e');
      emit(JournalErrorState(message: 'Failed to load journals: $e'));
    }
  }

  Future<void> _onLoadJournalById(
    LoadJournalByIdEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log('📊 Loading journal by ID: ${event.journalId}');

      final journal = await JournalService.getJournalById(event.journalId);

      if (journal != null) {
        emit(JournalLoadedState(journals: [journal]));
        log('✅ Loaded journal: ${journal.id}');
      } else {
        emit(JournalErrorState(message: 'Journal not found'));
      }
    } catch (e) {
      log('💥 Error loading journal by ID: $e');
      emit(JournalErrorState(message: 'Failed to load journal: $e'));
    }
  }

  Future<void> _onLoadJournalsByShop(
    LoadJournalsByShopEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log('📊 Loading journals for shop: ${event.shopId}');

      final response = await JournalService.getJournalsByShop(
        event.shopId,
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        JournalLoadedState(
          journals: response.journals ?? [],
          summary: response.summary,
          pagination: response.pagination,
        ),
      );

      log(
        '✅ Loaded ${response.journals?.length ?? 0} journals for shop ${event.shopId}',
      );
    } catch (e) {
      log('💥 Error loading journals by shop: $e');
      emit(JournalErrorState(message: 'Failed to load shop journals: $e'));
    }
  }

  Future<void> _onLoadJournalSummary(
    LoadJournalSummaryEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log('📊 Loading journal summary for shop: ${event.shopId}');

      final summary = await JournalService.getJournalSummaryByShop(
        event.shopId,
      );

      if (summary != null) {
        emit(JournalSummaryLoadedState(summary: summary, shopId: event.shopId));
        log('✅ Loaded journal summary for shop ${event.shopId}');
      } else {
        emit(JournalErrorState(message: 'Journal summary not found'));
      }
    } catch (e) {
      log('💥 Error loading journal summary: $e');
      emit(JournalErrorState(message: 'Failed to load journal summary: $e'));
    }
  }

  Future<void> _onLoadAccountBalance(
    LoadAccountBalanceEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log('📊 Loading account balance for: ${event.accountId}');

      final balance = await JournalService.getAccountBalance(event.accountId);

      emit(
        AccountBalanceLoadedState(balance: balance, accountId: event.accountId),
      );

      log('✅ Loaded account balance: $balance for ${event.accountId}');
    } catch (e) {
      log('💥 Error loading account balance: $e');
      emit(JournalErrorState(message: 'Failed to load account balance: $e'));
    }
  }

  Future<void> _onLoadDashboardJournalData(
    LoadDashboardJournalDataEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    emit(JournalLoadingState());

    try {
      log('📊 Loading dashboard journal data');

      final dashboardData = await JournalService.getDashboardJournalData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        DashboardJournalDataLoadedState(
          dashboardData: dashboardData,
          journals: dashboardData['journals'] as List<Journal>,
          shopSummaries: (dashboardData['shop_summaries'] as List)
              .cast<Map<String, dynamic>>(),
        ),
      );

      log(
        '✅ Loaded dashboard journal data: ${dashboardData['total_journals']} journals',
      );
    } catch (e) {
      log('💥 Error loading dashboard journal data: $e');
      emit(JournalErrorState(message: 'Failed to load dashboard data: $e'));
    }
  }

  Future<void> _onRefreshJournals(
    RefreshJournalsEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    // Reload current data
    add(LoadJournalsEvent());
  }

  Future<void> _onFilterJournals(
    FilterJournalsEvent event,
    Emitter<BlocSeaandhillState> emit,
  ) async {
    // Apply filters and reload
    add(
      LoadJournalsEvent(
        shopId: event.shopId,
        transactionType: event.transactionType,
        status: event.status,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );
  }
}
