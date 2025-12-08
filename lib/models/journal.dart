import 'package:json_annotation/json_annotation.dart';

part 'journal.g.dart';

@JsonSerializable()
class Journal {
  final int? id;

  // Document Information
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'doc_datetime')
  final String? docDatetime;
  @JsonKey(name: 'doc_no')
  final String? docNo;
  @JsonKey(name: 'period_number')
  final String? periodNumber;
  @JsonKey(name: 'account_year')
  final String? accountYear;

  // Book Information
  @JsonKey(name: 'book_code')
  final String? bookCode;
  @JsonKey(name: 'book_name')
  final String? bookName;

  // Account Information
  @JsonKey(name: 'account_code')
  final String? accountCode;
  @JsonKey(name: 'account_name')
  final String? accountName;
  @JsonKey(name: 'account_type')
  final String? accountType; // ASSETS, EXPENSES, LIABILITIES, INCOME

  // Transaction Amounts
  final double? debit;
  final double? credit;

  // Branch Information
  @JsonKey(name: 'branch_code')
  final String? branchCode;
  @JsonKey(name: 'branch_name')
  final String? branchName;

  Journal({
    this.id,
    this.branchSync,
    this.docDatetime,
    this.docNo,
    this.periodNumber,
    this.accountYear,
    this.bookCode,
    this.bookName,
    this.accountCode,
    this.accountName,
    this.accountType,
    this.debit,
    this.credit,
    this.branchCode,
    this.branchName,
  });

  // Helper getters
  double get amount => (debit ?? 0) + (credit ?? 0);
  double get income {
    final accountType = this.accountType?.toUpperCase();
    if (accountType == 'INCOME') {
      // รายได้ = sum credit - sum debit
      return (credit ?? 0) - (debit ?? 0);
    } else if (accountType == 'EXPENSES') {
      // รายจ่าย = sum debit - sum credit (เป็นค่าลบเมื่อมีค่าใช้จ่าย)
      return (debit ?? 0) - (credit ?? 0);
    }
    return 0.0; // ถ้าไม่ใช่ INCOME หรือ EXPENSES
  }

  bool get isDebit => (debit ?? 0) > 0;
  bool get isCredit => (credit ?? 0) > 0;

  // Compatibility getters for backward compatibility
  String? get shopId => branchSync;
  String? get shopName => branchName;
  String? get transactionDate => docDatetime;
  String? get referenceNumber => docNo;

  // Account type display
  String get accountTypeDisplay {
    switch (accountType?.toUpperCase()) {
      case 'ASSETS':
        return 'สินทรัพย์';
      case 'EXPENSES':
        return 'ค่าใช้จ่าย';
      case 'LIABILITIES':
        return 'หนี้สิน';
      case 'INCOME':
        return 'รายได้';
      default:
        return accountType ?? 'ไม่ระบุ';
    }
  }

  // Transaction type based on account type
  String get transactionType {
    if (isDebit) {
      return accountType == 'INCOME' || accountType == 'LIABILITIES'
          ? 'decrease'
          : 'increase';
    } else if (isCredit) {
      return accountType == 'INCOME' || accountType == 'LIABILITIES'
          ? 'increase'
          : 'decrease';
    }
    return 'none';
  }

  String get transactionTypeDisplay {
    if (accountType == 'INCOME') {
      return 'รายรับ';
    } else if (accountType == 'EXPENSES') {
      return 'รายจ่าย';
    } else if (accountType == 'ASSETS') {
      return isDebit ? 'เพิ่มสินทรัพย์' : 'ลดสินทรัพย์';
    } else if (accountType == 'LIABILITIES') {
      return isDebit ? 'ลดหนี้สิน' : 'เพิ่มหนี้สิน';
    }
    return 'ไม่ระบุ';
  }

  // Date parsing
  DateTime? get dateTime {
    if (docDatetime == null) return null;
    try {
      return DateTime.parse(docDatetime!);
    } catch (e) {
      return null;
    }
  }

  // Format display
  String get displayDate {
    if (docDatetime == null) return '-';
    try {
      final date = DateTime.parse(docDatetime!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return docDatetime ?? '-';
    }
  }

  String get displayAmount {
    final amt = amount;
    if (amt >= 1000000) {
      return '${(amt / 1000000).toStringAsFixed(2)}M';
    } else if (amt >= 1000) {
      return '${(amt / 1000).toStringAsFixed(2)}K';
    }
    return amt.toStringAsFixed(2);
  }

  factory Journal.fromJson(Map<String, dynamic> json) =>
      _$JournalFromJson(json);
  Map<String, dynamic> toJson() => _$JournalToJson(this);
}

@JsonSerializable()
class JournalSummary {
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'branch_code')
  final String? branchCode;
  @JsonKey(name: 'branch_name')
  final String? branchName;
  @JsonKey(name: 'account_year')
  final String? accountYear;
  @JsonKey(name: 'total_debit')
  final double? totalDebit;
  @JsonKey(name: 'total_credit')
  final double? totalCredit;
  @JsonKey(name: 'current_balance')
  final double? currentBalance;
  @JsonKey(name: 'transaction_count')
  final int? transactionCount;
  @JsonKey(name: 'last_transaction_date')
  final String? lastTransactionDate;
  @JsonKey(name: 'monthly_summary')
  final Map<String, MonthlyJournalData>? monthlySummary;

  JournalSummary({
    this.branchSync,
    this.branchCode,
    this.branchName,
    this.accountYear,
    this.totalDebit,
    this.totalCredit,
    this.currentBalance,
    this.transactionCount,
    this.lastTransactionDate,
    this.monthlySummary,
  });

  double get netAmount => (totalDebit ?? 0) - (totalCredit ?? 0);
  double get totalIncome =>
      (totalCredit ?? 0) -
      (totalDebit ?? 0); // รายได้รวม = เครดิต - เดบิต (สำหรับ INCOME)

  // Compatibility getters for backward compatibility
  String? get shopId => branchSync;
  String? get shopName => branchName;

  factory JournalSummary.fromJson(Map<String, dynamic> json) =>
      _$JournalSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$JournalSummaryToJson(this);
}

@JsonSerializable()
class MonthlyJournalData {
  final String? month;
  final double? debit;
  final double? credit;
  final double? balance;
  @JsonKey(name: 'transaction_count')
  final int? transactionCount;

  MonthlyJournalData({
    this.month,
    this.debit,
    this.credit,
    this.balance,
    this.transactionCount,
  });

  double get netAmount => (debit ?? 0) - (credit ?? 0);
  double get monthlyIncome =>
      (credit ?? 0) -
      (debit ?? 0); // รายได้รายเดือน = เครดิต - เดบิต (สำหรับ INCOME)

  factory MonthlyJournalData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyJournalDataFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyJournalDataToJson(this);
}

@JsonSerializable()
class JournalResponse {
  final bool? success;
  @JsonKey(name: 'data')
  final List<Journal>? journals;
  final JournalSummary? summary;
  final Pagination? pagination;

  JournalResponse({this.success, this.journals, this.summary, this.pagination});

  factory JournalResponse.fromJson(Map<String, dynamic> json) =>
      _$JournalResponseFromJson(json);
  Map<String, dynamic> toJson() => _$JournalResponseToJson(this);
}

@JsonSerializable()
class Pagination {
  final int? page;
  final int? limit;
  @JsonKey(name: 'current_page')
  final int? currentPage;
  @JsonKey(name: 'per_page')
  final int? perPage;
  final int? total;
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.currentPage,
    this.perPage,
    this.total,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
