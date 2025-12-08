part of 'journal_bloc.dart';

@immutable
sealed class JournalEvent {}

class LoadJournals extends JournalEvent {
  final int? page;
  final int? limit;
  final String? branchSync;
  final String? startDate;
  final String? endDate;

  LoadJournals({
    this.page,
    this.limit,
    this.branchSync,
    this.startDate,
    this.endDate,
  });
}

class LoadJournalsByBranch extends JournalEvent {
  final String branchSync;
  final int? page;
  final int? limit;

  LoadJournalsByBranch({required this.branchSync, this.page, this.limit});
}

class RefreshJournals extends JournalEvent {}
