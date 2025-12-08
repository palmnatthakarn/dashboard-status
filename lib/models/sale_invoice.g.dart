// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleInvoice _$SaleInvoiceFromJson(Map<String, dynamic> json) => SaleInvoice(
  id: (json['id'] as num?)?.toInt(),
  branchSync: json['branch_sync'] as String?,
  docDatetime: json['doc_datetime'] as String?,
  docNo: json['doc_no'] as String?,
  periodNumber: json['period_number'] as String?,
  accountYear: json['account_year'] as String?,
  bookCode: json['book_code'] as String?,
  bookName: json['book_name'] as String?,
  customerCode: json['customer_code'] as String?,
  customerName: json['customer_name'] as String?,
  customerTaxId: json['customer_tax_id'] as String?,
  netAmount: (json['net_amount'] as num?)?.toDouble(),
  vatAmount: (json['vat_amount'] as num?)?.toDouble(),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  status: json['status'] as String?,
  invoiceType: json['invoice_type'] as String?,
  paymentStatus: json['payment_status'] as String?,
  branchCode: json['branch_code'] as String?,
  branchName: json['branch_name'] as String?,
  dueDate: json['due_date'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$SaleInvoiceToJson(SaleInvoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'branch_sync': instance.branchSync,
      'doc_datetime': instance.docDatetime,
      'doc_no': instance.docNo,
      'period_number': instance.periodNumber,
      'account_year': instance.accountYear,
      'book_code': instance.bookCode,
      'book_name': instance.bookName,
      'customer_code': instance.customerCode,
      'customer_name': instance.customerName,
      'customer_tax_id': instance.customerTaxId,
      'net_amount': instance.netAmount,
      'vat_amount': instance.vatAmount,
      'total_amount': instance.totalAmount,
      'discount_amount': instance.discountAmount,
      'status': instance.status,
      'invoice_type': instance.invoiceType,
      'payment_status': instance.paymentStatus,
      'branch_code': instance.branchCode,
      'branch_name': instance.branchName,
      'due_date': instance.dueDate,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

SaleInvoiceResponse _$SaleInvoiceResponseFromJson(Map<String, dynamic> json) =>
    SaleInvoiceResponse(
      saleInvoices: (json['sale_invoices'] as List<dynamic>?)
          ?.map((e) => SaleInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      currentPage: (json['currentPage'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SaleInvoiceResponseToJson(
  SaleInvoiceResponse instance,
) => <String, dynamic>{
  'sale_invoices': instance.saleInvoices,
  'totalCount': instance.totalCount,
  'currentPage': instance.currentPage,
  'totalPages': instance.totalPages,
};

SaleInvoiceSummary _$SaleInvoiceSummaryFromJson(Map<String, dynamic> json) =>
    SaleInvoiceSummary(
      branchSync: json['branch_sync'] as String?,
      branchName: json['branch_name'] as String?,
      totalNetAmount: (json['total_net_amount'] as num?)?.toDouble(),
      totalVatAmount: (json['total_vat_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      totalDiscountAmount: (json['total_discount_amount'] as num?)?.toDouble(),
      invoiceCount: (json['invoice_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SaleInvoiceSummaryToJson(SaleInvoiceSummary instance) =>
    <String, dynamic>{
      'branch_sync': instance.branchSync,
      'branch_name': instance.branchName,
      'total_net_amount': instance.totalNetAmount,
      'total_vat_amount': instance.totalVatAmount,
      'total_amount': instance.totalAmount,
      'total_discount_amount': instance.totalDiscountAmount,
      'invoice_count': instance.invoiceCount,
    };
