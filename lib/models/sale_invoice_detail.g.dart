// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_invoice_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleInvoiceDetail _$SaleInvoiceDetailFromJson(Map<String, dynamic> json) =>
    SaleInvoiceDetail(
      id: (json['id'] as num?)?.toInt(),
      invoiceId: (json['invoice_id'] as num?)?.toInt(),
      invoiceDocNo: json['invoice_doc_no'] as String?,
      itemCode: json['item_code'] as String?,
      itemName: json['item_name'] as String?,
      itemDescription: json['item_description'] as String?,
      unitCode: json['unit_code'] as String?,
      unitName: json['unit_name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      lineTotal: (json['line_total'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      netAmount: (json['net_amount'] as num?)?.toDouble(),
      vatRate: (json['vat_rate'] as num?)?.toDouble(),
      vatAmount: (json['vat_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      branchSync: json['branch_sync'] as String?,
      branchName: json['branch_name'] as String?,
      lineNo: (json['line_no'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$SaleInvoiceDetailToJson(SaleInvoiceDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_id': instance.invoiceId,
      'invoice_doc_no': instance.invoiceDocNo,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'item_description': instance.itemDescription,
      'unit_code': instance.unitCode,
      'unit_name': instance.unitName,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'line_total': instance.lineTotal,
      'discount_amount': instance.discountAmount,
      'net_amount': instance.netAmount,
      'vat_rate': instance.vatRate,
      'vat_amount': instance.vatAmount,
      'total_amount': instance.totalAmount,
      'branch_sync': instance.branchSync,
      'branch_name': instance.branchName,
      'line_no': instance.lineNo,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

SaleInvoiceDetailResponse _$SaleInvoiceDetailResponseFromJson(
  Map<String, dynamic> json,
) => SaleInvoiceDetailResponse(
  saleInvoiceDetails: (json['sale_invoice_details'] as List<dynamic>?)
      ?.map((e) => SaleInvoiceDetail.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['totalCount'] as num?)?.toInt(),
  currentPage: (json['currentPage'] as num?)?.toInt(),
  totalPages: (json['totalPages'] as num?)?.toInt(),
);

Map<String, dynamic> _$SaleInvoiceDetailResponseToJson(
  SaleInvoiceDetailResponse instance,
) => <String, dynamic>{
  'sale_invoice_details': instance.saleInvoiceDetails,
  'totalCount': instance.totalCount,
  'currentPage': instance.currentPage,
  'totalPages': instance.totalPages,
};

SaleInvoiceDetailSummary _$SaleInvoiceDetailSummaryFromJson(
  Map<String, dynamic> json,
) => SaleInvoiceDetailSummary(
  invoiceId: (json['invoice_id'] as num?)?.toInt(),
  invoiceDocNo: json['invoice_doc_no'] as String?,
  totalQuantity: (json['total_quantity'] as num?)?.toDouble(),
  totalLineAmount: (json['total_line_amount'] as num?)?.toDouble(),
  totalDiscountAmount: (json['total_discount_amount'] as num?)?.toDouble(),
  totalNetAmount: (json['total_net_amount'] as num?)?.toDouble(),
  totalVatAmount: (json['total_vat_amount'] as num?)?.toDouble(),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  lineCount: (json['line_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$SaleInvoiceDetailSummaryToJson(
  SaleInvoiceDetailSummary instance,
) => <String, dynamic>{
  'invoice_id': instance.invoiceId,
  'invoice_doc_no': instance.invoiceDocNo,
  'total_quantity': instance.totalQuantity,
  'total_line_amount': instance.totalLineAmount,
  'total_discount_amount': instance.totalDiscountAmount,
  'total_net_amount': instance.totalNetAmount,
  'total_vat_amount': instance.totalVatAmount,
  'total_amount': instance.totalAmount,
  'line_count': instance.lineCount,
};
