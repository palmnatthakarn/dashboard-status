part of 'journal_bloc.dart';

@immutable
sealed class JournalState {}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<Journal> journals;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  JournalLoaded({
    required this.journals,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}

class JournalError extends JournalState {
  final String message;

  JournalError({required this.message});
}
