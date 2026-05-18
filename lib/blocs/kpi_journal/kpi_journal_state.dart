import 'package:equatable/equatable.dart';

class KpiJournalShopStat {
  final String shopName;
  final int count;
  final int totalDocument;
  final Map<String, int> byBookCode;
  final DateTime? lastActive;
  final List<KpiJournalDetail> details;
  final int totalChecked;
  final int totalUpdated;

  const KpiJournalShopStat({
    required this.shopName,
    required this.count,
    this.totalDocument = 0,
    required this.byBookCode,
    this.lastActive,
    this.details = const [],
    this.totalChecked = 0,
    this.totalUpdated = 0,
  });
}

class KpiJournalEmployee {
  final String name; // createdBy email/username
  final int totalJournals;
  final int totalLinkedJournals;
  final int totalDocument;
  final double totalDebit;
  final double totalCredit;
  final Map<String, int> byBookCode;
  final DateTime? lastActive;
  final List<KpiJournalDetail> details;
  final List<String> shopNames;
  /// สรุปต่อร้านสำหรับ expand level 1
  final List<KpiJournalShopStat> shopStats;
  /// จำนวนรายการที่คนนี้ตรวจสอบ (checkedBy = name)
  final int totalChecked;
  /// จำนวนรายการที่คนนี้แก้ไข (updatedBy = name)
  final int totalUpdated;

  const KpiJournalEmployee({
    required this.name,
    required this.totalJournals,
    this.totalLinkedJournals = 0,
    this.totalDocument = 0,
    required this.totalDebit,
    required this.totalCredit,
    required this.byBookCode,
    this.lastActive,
    this.details = const [],
    this.shopNames = const [],
    this.shopStats = const [],
    this.totalChecked = 0,
    this.totalUpdated = 0,
  });

  double get totalNet => totalCredit - totalDebit;
}

class KpiJournalDetail {
  final String docNo;
  final DateTime? docDate;
  final String bookCode;
  final double debit;
  final double credit;
  final double amount;
  final String? shopName;
  final String? accountDescription;
  final String? checkedBy;
  final DateTime? checkedAt;
  final String? updatedBy;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? taskName;

  const KpiJournalDetail({
    required this.docNo,
    this.docDate,
    required this.bookCode,
    required this.debit,
    required this.credit,
    required this.amount,
    this.shopName,
    this.accountDescription,
    this.checkedBy,
    this.checkedAt,
    this.updatedBy,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.taskName,
  });
}

class KpiJournalShopItem {
  final String shopId;
  final String shopName;
  const KpiJournalShopItem({required this.shopId, required this.shopName});
}

abstract class KpiJournalState extends Equatable {
  const KpiJournalState();

  @override
  List<Object?> get props => [];
}

class KpiJournalInitial extends KpiJournalState {}

class KpiJournalLoading extends KpiJournalState {}

class KpiJournalLoaded extends KpiJournalState {
  final List<KpiJournalEmployee> employees;
  final List<KpiJournalEmployee> filteredEmployees;
  final List<KpiJournalShopItem> shops;
  final String? selectedShopId;
  final String? selectedShopName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final bool isSearching;
  /// Grand totals from initial load — never change with filtering
  final int grandTotalJournals;
  final int grandTotalEmployees;
  /// รายชื่อผู้ตรวจสอบทั้งหมดที่พบในข้อมูล
  final List<String> allCheckers;
  /// รายชื่อผู้แก้ไขทั้งหมดที่พบในข้อมูล
  final List<String> allUpdaters;

  const KpiJournalLoaded({
    required this.employees,
    required this.filteredEmployees,
    required this.shops,
    this.selectedShopId,
    this.selectedShopName,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.isSearching = false,
    this.grandTotalJournals = 0,
    this.grandTotalEmployees = 0,
    this.allCheckers = const [],
    this.allUpdaters = const [],
  });

  int get totalJournals => employees.fold(0, (s, e) => s + e.totalJournals);
  int get totalLinkedJournals =>
      employees.fold(0, (s, e) => s + e.totalLinkedJournals);
  int get totalDocuments => _sumUniqueShopDocuments(employees);
  int get filteredTotalJournals =>
      filteredEmployees.fold(0, (s, e) => s + e.totalJournals);
  int get filteredTotalLinkedJournals =>
      filteredEmployees.fold(0, (s, e) => s + e.totalLinkedJournals);
  int get filteredTotalDocuments => _sumUniqueShopDocuments(filteredEmployees);
  int get filteredTotalEmployees => filteredEmployees.length;

  static int _sumUniqueShopDocuments(List<KpiJournalEmployee> employees) {
    final documentsByShop = <String, int>{};
    for (final employee in employees) {
      for (final stat in employee.shopStats) {
        if (stat.shopName.isEmpty || stat.totalDocument <= 0) continue;
        final current = documentsByShop[stat.shopName] ?? 0;
        if (stat.totalDocument > current) {
          documentsByShop[stat.shopName] = stat.totalDocument;
        }
      }
    }
    return documentsByShop.values.fold(0, (sum, count) => sum + count);
  }

  double get totalDebit => employees.fold(0.0, (s, e) => s + e.totalDebit);
  double get totalCredit => employees.fold(0.0, (s, e) => s + e.totalCredit);
  double get totalNet => totalCredit - totalDebit;

  KpiJournalLoaded copyWith({
    List<KpiJournalEmployee>? employees,
    List<KpiJournalEmployee>? filteredEmployees,
    List<KpiJournalShopItem>? shops,
    String? selectedShopId,
    String? selectedShopName,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool? isSearching,
    int? grandTotalJournals,
    int? grandTotalEmployees,
    List<String>? allCheckers,
    List<String>? allUpdaters,
  }) {
    return KpiJournalLoaded(
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      shops: shops ?? this.shops,
      selectedShopId: selectedShopId ?? this.selectedShopId,
      selectedShopName: selectedShopName ?? this.selectedShopName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      grandTotalJournals: grandTotalJournals ?? this.grandTotalJournals,
      grandTotalEmployees: grandTotalEmployees ?? this.grandTotalEmployees,
      allCheckers: allCheckers ?? this.allCheckers,
      allUpdaters: allUpdaters ?? this.allUpdaters,
    );
  }

  @override
  List<Object?> get props => [
    employees,
    filteredEmployees,
    shops,
    selectedShopId,
    selectedShopName,
    startDate,
    endDate,
    searchQuery,
    isSearching,
    grandTotalJournals,
    grandTotalEmployees,
    allCheckers,
    allUpdaters,
  ];
}

class KpiJournalError extends KpiJournalState {
  final String message;

  const KpiJournalError(this.message);

  @override
  List<Object?> get props => [message];
}
