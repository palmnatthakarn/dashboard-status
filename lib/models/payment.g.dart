// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
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
  paymentMethod: json['payment_method'] as String?,
  paymentType: json['payment_type'] as String?,
  referenceNo: json['reference_no'] as String?,
  paymentAmount: (json['payment_amount'] as num?)?.toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  netAmount: (json['net_amount'] as num?)?.toDouble(),
  status: json['status'] as String?,
  branchCode: json['branch_code'] as String?,
  branchName: json['branch_name'] as String?,
  accountCode: json['account_code'] as String?,
  accountName: json['account_name'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
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
  'payment_method': instance.paymentMethod,
  'payment_type': instance.paymentType,
  'reference_no': instance.referenceNo,
  'payment_amount': instance.paymentAmount,
  'discount_amount': instance.discountAmount,
  'net_amount': instance.netAmount,
  'status': instance.status,
  'branch_code': instance.branchCode,
  'branch_name': instance.branchName,
  'account_code': instance.accountCode,
  'account_name': instance.accountName,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

PaymentResponse _$PaymentResponseFromJson(Map<String, dynamic> json) =>
    PaymentResponse(
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      currentPage: (json['currentPage'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaymentResponseToJson(PaymentResponse instance) =>
    <String, dynamic>{
      'payments': instance.payments,
      'totalCount': instance.totalCount,
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
    };

PaymentSummary _$PaymentSummaryFromJson(Map<String, dynamic> json) =>
    PaymentSummary(
      branchSync: json['branch_sync'] as String?,
      branchName: json['branch_name'] as String?,
      totalPaymentAmount: (json['total_payment_amount'] as num?)?.toDouble(),
      totalDiscountAmount: (json['total_discount_amount'] as num?)?.toDouble(),
      totalNetAmount: (json['total_net_amount'] as num?)?.toDouble(),
      transactionCount: (json['transaction_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaymentSummaryToJson(PaymentSummary instance) =>
    <String, dynamic>{
      'branch_sync': instance.branchSync,
      'branch_name': instance.branchName,
      'total_payment_amount': instance.totalPaymentAmount,
      'total_discount_amount': instance.totalDiscountAmount,
      'total_net_amount': instance.totalNetAmount,
      'transaction_count': instance.transactionCount,
    };
