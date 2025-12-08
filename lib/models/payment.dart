import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@JsonSerializable()
class Payment {
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

  // Vendor/Customer Information
  @JsonKey(name: 'vendor_code')
  final String? vendorCode;
  @JsonKey(name: 'vendor_name')
  final String? vendorName;

  // Payment Information
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'payment_type')
  final String? paymentType;
  @JsonKey(name: 'reference_no')
  final String? referenceNo;

  // Transaction Amounts
  @JsonKey(name: 'payment_amount')
  final double? paymentAmount;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'net_amount')
  final double? netAmount;

  // Status
  final String? status;

  // Branch Information
  @JsonKey(name: 'branch_code')
  final String? branchCode;
  @JsonKey(name: 'branch_name')
  final String? branchName;

  // Account Information
  @JsonKey(name: 'account_code')
  final String? accountCode;
  @JsonKey(name: 'account_name')
  final String? accountName;

  // Timestamps
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Payment({
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
    this.paymentMethod,
    this.paymentType,
    this.referenceNo,
    this.paymentAmount,
    this.discountAmount,
    this.netAmount,
    this.status,
    this.branchCode,
    this.branchName,
    this.accountCode,
    this.accountName,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  // Helper getters
  String get displayDate {
    if (docDatetime == null) return '-';
    try {
      final date = DateTime.parse(docDatetime!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return docDatetime ?? '-';
    }
  }

  String get statusDisplay {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return 'Paid';
      case 'PENDING':
        return 'Pending';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status ?? 'Unknown';
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod?.toUpperCase()) {
      case 'CASH':
        return 'Cash';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return paymentMethod ?? 'Unknown';
    }
  }

  bool get isPaid => status?.toUpperCase() == 'PAID';
  bool get isPending => status?.toUpperCase() == 'PENDING';
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';
  bool get isRefunded => status?.toUpperCase() == 'REFUNDED';
}

@JsonSerializable()
class PaymentResponse {
  final List<Payment>? payments;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  PaymentResponse({
    this.payments,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}

@JsonSerializable()
class PaymentSummary {
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'branch_name')
  final String? branchName;
  @JsonKey(name: 'total_payment_amount')
  final double? totalPaymentAmount;
  @JsonKey(name: 'total_discount_amount')
  final double? totalDiscountAmount;
  @JsonKey(name: 'total_net_amount')
  final double? totalNetAmount;
  @JsonKey(name: 'transaction_count')
  final int? transactionCount;

  PaymentSummary({
    this.branchSync,
    this.branchName,
    this.totalPaymentAmount,
    this.totalDiscountAmount,
    this.totalNetAmount,
    this.transactionCount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      _$PaymentSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSummaryToJson(this);
}