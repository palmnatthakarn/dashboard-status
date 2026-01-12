// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Journal _$JournalFromJson(Map<String, dynamic> json) => Journal(
  id: (json['id'] as num?)?.toInt(),
  branchSync: json['branch_sync'] as String?,
  docDatetime: json['docdate'] as String?,
  docNo: json['docno'] as String?,
  periodNumber: (json['accountperiod'] as num?)?.toInt(),
  accountYear: (json['accountyear'] as num?)?.toInt(),
  bookCode: json['bookcode'] as String?,
  bookName: json['bookname'] as String?,
  accountCode: json['accountcode'] as String?,
  accountName: json['accountname'] as String?,
  accountType: json['accounttype'] as String?,
  debit: (json['debit'] as num?)?.toDouble(),
  credit: (json['credit'] as num?)?.toDouble(),
  apiAmount: (json['amount'] as num?)?.toDouble(),
  branchCode: json['branchcode'] as String?,
  branchName: json['branchname'] as String?,
  description: json['accountdescription'] as String?,
);

Map<String, dynamic> _$JournalToJson(Journal instance) => <String, dynamic>{
  'id': instance.id,
  'branch_sync': instance.branchSync,
  'docdate': instance.docDatetime,
  'docno': instance.docNo,
  'accountperiod': instance.periodNumber,
  'accountyear': instance.accountYear,
  'bookcode': instance.bookCode,
  'bookname': instance.bookName,
  'accountcode': instance.accountCode,
  'accountname': instance.accountName,
  'accounttype': instance.accountType,
  'debit': instance.debit,
  'credit': instance.credit,
  'amount': instance.apiAmount,
  'branchcode': instance.branchCode,
  'branchname': instance.branchName,
  'accountdescription': instance.description,
};

JournalSummary _$JournalSummaryFromJson(Map<String, dynamic> json) =>
    JournalSummary(
      branchSync: json['branch_sync'] as String?,
      branchCode: json['branch_code'] as String?,
      branchName: json['branch_name'] as String?,
      accountYear: json['account_year'] as String?,
      totalDebit: (json['total_debit'] as num?)?.toDouble(),
      totalCredit: (json['total_credit'] as num?)?.toDouble(),
      currentBalance: (json['current_balance'] as num?)?.toDouble(),
      transactionCount: (json['transaction_count'] as num?)?.toInt(),
      lastTransactionDate: json['last_transaction_date'] as String?,
      monthlySummary: (json['monthly_summary'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, MonthlyJournalData.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$JournalSummaryToJson(JournalSummary instance) =>
    <String, dynamic>{
      'branch_sync': instance.branchSync,
      'branch_code': instance.branchCode,
      'branch_name': instance.branchName,
      'account_year': instance.accountYear,
      'total_debit': instance.totalDebit,
      'total_credit': instance.totalCredit,
      'current_balance': instance.currentBalance,
      'transaction_count': instance.transactionCount,
      'last_transaction_date': instance.lastTransactionDate,
      'monthly_summary': instance.monthlySummary,
    };

MonthlyJournalData _$MonthlyJournalDataFromJson(Map<String, dynamic> json) =>
    MonthlyJournalData(
      month: json['month'] as String?,
      debit: (json['debit'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
      transactionCount: (json['transaction_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MonthlyJournalDataToJson(MonthlyJournalData instance) =>
    <String, dynamic>{
      'month': instance.month,
      'debit': instance.debit,
      'credit': instance.credit,
      'balance': instance.balance,
      'transaction_count': instance.transactionCount,
    };

JournalResponse _$JournalResponseFromJson(Map<String, dynamic> json) =>
    JournalResponse(
      success: json['success'] as bool?,
      journals: (json['data'] as List<dynamic>?)
          ?.map((e) => Journal.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] == null
          ? null
          : JournalSummary.fromJson(json['summary'] as Map<String, dynamic>),
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JournalResponseToJson(JournalResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.journals,
      'summary': instance.summary,
      'pagination': instance.pagination,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  page: (json['page'] as num?)?.toInt(),
  limit: (json['limit'] as num?)?.toInt(),
  currentPage: (json['current_page'] as num?)?.toInt(),
  perPage: (json['per_page'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toInt(),
  totalPages: (json['total_pages'] as num?)?.toInt(),
);

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'current_page': instance.currentPage,
      'per_page': instance.perPage,
      'total': instance.total,
      'total_pages': instance.totalPages,
    };
