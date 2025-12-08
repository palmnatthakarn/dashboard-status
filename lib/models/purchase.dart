import 'package:json_annotation/json_annotation.dart';

part 'purchase.g.dart';

@JsonSerializable()
class Purchase {
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

  // Purchase Information
  @JsonKey(name: 'vendor_code')
  final String? vendorCode;
  @JsonKey(name: 'vendor_name')
  final String? vendorName;
  @JsonKey(name: 'purchase_amount')
  final double? purchaseAmount;
  @JsonKey(name: 'vat_amount')
  final double? vatAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;

  // Status
  final String? status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Purchase({
    this.id,
    this.branchSync,
    this.docDatetime,
    this.docNo,
    this.periodNumber,
    this.accountYear,
    this.bookCode,
    this.bookName,
    this.vendorCode,
    this.vendorName,
    this.purchaseAmount,
    this.vatAmount,
    this.totalAmount,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseToJson(this);

  // Getter methods
  String get displayDate {
    if (docDatetime == null) return '-';
    try {
      final date = DateTime.parse(docDatetime!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return docDatetime ?? '-';
    }
  }

  String get formattedAmount {
    if (totalAmount == null) return '0.00';
    return totalAmount!.toStringAsFixed(2);
  }

  bool get hasVat => (vatAmount ?? 0) > 0;
}

@JsonSerializable()
class PurchaseResponse {
  final List<Purchase>? purchases;
  @JsonKey(name: 'total')
  final int? totalCount;
  @JsonKey(name: 'current_page')
  final int? currentPage;
  @JsonKey(name: 'per_page')
  final int? perPage;
  @JsonKey(name: 'last_page')
  final int? totalPages;

  PurchaseResponse({
    this.purchases,
    this.totalCount,
    this.currentPage,
    this.perPage,
    this.totalPages,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
}

@JsonSerializable()
class PurchaseSummary {
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @JsonKey(name: 'total_vat')
  final double? totalVat;
  @JsonKey(name: 'total_transactions')
  final int? totalTransactions;
  @JsonKey(name: 'branch_sync')
  final String? branchSync;

  PurchaseSummary({
    this.totalAmount,
    this.totalVat,
    this.totalTransactions,
    this.branchSync,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) =>
      _$PurchaseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseSummaryToJson(this);
}