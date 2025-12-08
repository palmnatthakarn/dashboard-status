// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseDetail _$PurchaseDetailFromJson(Map<String, dynamic> json) =>
    PurchaseDetail(
      id: (json['id'] as num?)?.toInt(),
      purchaseId: (json['purchase_id'] as num?)?.toInt(),
      branchSync: json['branch_sync'] as String?,
      docNo: json['doc_no'] as String?,
      itemCode: json['item_code'] as String?,
      itemName: json['item_name'] as String?,
      itemDescription: json['item_description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      vatRate: (json['vat_rate'] as num?)?.toDouble(),
      vatAmount: (json['vat_amount'] as num?)?.toDouble(),
      unitCode: json['unit_code'] as String?,
      unitName: json['unit_name'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$PurchaseDetailToJson(PurchaseDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'purchase_id': instance.purchaseId,
      'branch_sync': instance.branchSync,
      'doc_no': instance.docNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'item_description': instance.itemDescription,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'discount_amount': instance.discountAmount,
      'line_total': instance.lineTotal,
      'vat_rate': instance.vatRate,
      'vat_amount': instance.vatAmount,
      'unit_code': instance.unitCode,
      'unit_name': instance.unitName,
      'created_at': instance.createdAt,
    };

PurchaseDetailResponse _$PurchaseDetailResponseFromJson(
  Map<String, dynamic> json,
) => PurchaseDetailResponse(
  purchaseDetails: (json['purchase_details'] as List<dynamic>?)
      ?.map((e) => PurchaseDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num?)?.toInt(),
  currentPage: (json['current_page'] as num?)?.toInt(),
  perPage: (json['per_page'] as num?)?.toInt(),
);

Map<String, dynamic> _$PurchaseDetailResponseToJson(
  PurchaseDetailResponse instance,
) => <String, dynamic>{
  'purchase_details': instance.purchaseDetails,
  'total': instance.total,
  'current_page': instance.currentPage,
  'per_page': instance.perPage,
};
