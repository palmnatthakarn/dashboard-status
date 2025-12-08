import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../models/journal.dart';
import '../services/journal_service.dart';

part 'journal_event.dart';
part 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc() : super(JournalInitial()) {
    on<LoadJournals>(_onLoadJournals);
    on<LoadJournalsByBranch>(_onLoadJournalsByBranch);
    on<RefreshJournals>(_onRefreshJournals);
  }

  Future<void> _onLoadJournals(
    LoadJournals event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());
    try {
      // เรียก API แยกตาม account_type เพื่อให้ได้ข้อมูลครบถ้วน
      final accountTypes = ['INCOME', 'EXPENSES', 'LIABILITIES', 'ASSETS'];
      final allJournals = <Journal>[];
      int totalCount = 0;
      int totalPages = 1;

      for (final accountType in accountTypes) {
        try {
          final response = await JournalService.getAllJournals(
            page: event.page ?? 1,
            limit: event.limit ?? 100,
            shopId: event.branchSync,
            startDate: event.startDate,
            endDate: event.endDate,
            accountType: accountType, // ใช้ accountType parameter
          );

          if (response.journals != null) {
            allJournals.addAll(response.journals!);
          }
          totalCount += response.pagination?.total ?? 0;
          if (response.pagination?.totalPages != null &&
              response.pagination!.totalPages! > totalPages) {
            totalPages = response.pagination!.totalPages!;
          }
        } catch (e) {
          // หาก account_type ใดไม่มีข้อมูล ก็ข้ามไป
          print('No data for account_type: $accountType - $e');
        }
      }

      emit(
        JournalLoaded(
          journals: allJournals,
          totalCount: totalCount,
          currentPage: event.page ?? 1,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onLoadJournalsByBranch(
    LoadJournalsByBranch event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());
    try {
      // เรียก API แยกตาม account_type สำหรับสาขาเฉพาะ
      final accountTypes = ['INCOME', 'EXPENSES', 'LIABILITIES', 'ASSETS'];
      final allJournals = <Journal>[];
      int totalCount = 0;
      int totalPages = 1;

      for (final accountType in accountTypes) {
        try {
          final response = await JournalService.getAllJournals(
            shopId: event.branchSync,
            page: event.page ?? 1,
            limit: event.limit ?? 100,
            accountType: accountType,
          );

          if (response.journals != null) {
            allJournals.addAll(response.journals!);
          }
          totalCount += response.pagination?.total ?? 0;
          if (response.pagination?.totalPages != null &&
              response.pagination!.totalPages! > totalPages) {
            totalPages = response.pagination!.totalPages!;
          }
        } catch (e) {
          // หาก account_type ใดไม่มีข้อมูล ก็ข้ามไป
          print('No data for account_type: $accountType - $e');
        }
      }

      emit(
        JournalLoaded(
          journals: allJournals,
          totalCount: totalCount,
          currentPage: event.page ?? 1,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onRefreshJournals(
    RefreshJournals event,
    Emitter<JournalState> emit,
  ) async {
    // Keep current state while refreshing
    if (state is JournalLoaded) {
      final currentState = state as JournalLoaded;
      emit(JournalLoading());

      try {
        // เรียก API แยกตาม account_type เพื่อ refresh ข้อมูล
        final accountTypes = ['INCOME', 'EXPENSES', 'LIABILITIES', 'ASSETS'];
        final allJournals = <Journal>[];
        int totalCount = 0;
        int totalPages = 1;

        for (final accountType in accountTypes) {
          try {
            final response = await JournalService.getAllJournals(
              accountType: accountType,
            );

            if (response.journals != null) {
              allJournals.addAll(response.journals!);
            }
            totalCount += response.pagination?.total ?? 0;
            if (response.pagination?.totalPages != null &&
                response.pagination!.totalPages! > totalPages) {
              totalPages = response.pagination!.totalPages!;
            }
          } catch (e) {
            print('No data for account_type: $accountType - $e');
          }
        }

        emit(
          JournalLoaded(
            journals: allJournals,
            totalCount: totalCount,
            currentPage: 1,
            totalPages: totalPages,
          ),
        );
      } catch (e) {
        // Restore previous state on error
        emit(currentState);
        emit(JournalError(message: e.toString()));
      }
    } else {
      add(LoadJournals());
    }
  }
}
