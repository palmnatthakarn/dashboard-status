// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => Purchase(
  id: (json['id'] as num?)?.toInt(),
  branchSync: json['branch_sync'] as String?,
  docDatetime: json['doc_datetime'] as String?,
  docNo: json['doc_no'] as String?,
  periodNumber: json['period_number'] as String?,
  accountYear: json['account_year'] as String?,
  bookCode: json['book_code'] as String?,
  bookName: json['book_name'] as String?,
  vendorCode: json['vendor_code'] as String?,
  vendorName: json['vendor_name'] as String?,
  purchaseAmount: (json['purchase_amount'] as num?)?.toDouble(),
  vatAmount: (json['vat_amount'] as num?)?.toDouble(),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  status: json['status'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'branch_sync': instance.branchSync,
  'doc_datetime': instance.docDatetime,
  'doc_no': instance.docNo,
  'period_number': instance.periodNumber,
  'account_year': instance.accountYear,
  'book_code': instance.bookCode,
  'book_name': instance.bookName,
  'vendor_code': instance.vendorCode,
  'vendor_name': instance.vendorName,
  'purchase_amount': instance.purchaseAmount,
  'vat_amount': instance.vatAmount,
  'total_amount': instance.totalAmount,
  'status': instance.status,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      purchases: (json['purchases'] as List<dynamic>?)
          ?.map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total'] as num?)?.toInt(),
      currentPage: (json['current_page'] as num?)?.toInt(),
      perPage: (json['per_page'] as num?)?.toInt(),
      totalPages: (json['last_page'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'purchases': instance.purchases,
      'total': instance.totalCount,
      'current_page': instance.currentPage,
      'per_page': instance.perPage,
      'last_page': instance.totalPages,
    };

PurchaseSummary _$PurchaseSummaryFromJson(Map<String, dynamic> json) =>
    PurchaseSummary(
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      totalVat: (json['total_vat'] as num?)?.toDouble(),
      totalTransactions: (json['total_transactions'] as num?)?.toInt(),
      branchSync: json['branch_sync'] as String?,
    );

Map<String, dynamic> _$PurchaseSummaryToJson(PurchaseSummary instance) =>
    <String, dynamic>{
      'total_amount': instance.totalAmount,
      'total_vat': instance.totalVat,
      'total_transactions': instance.totalTransactions,
      'branch_sync': instance.branchSync,
    };
