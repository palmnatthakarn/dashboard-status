import 'package:json_annotation/json_annotation.dart';

part 'sale_invoice.g.dart';

@JsonSerializable()
class SaleInvoice {
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

  // Customer Information
  @JsonKey(name: 'customer_code')
  final String? customerCode;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'customer_tax_id')
  final String? customerTaxId;

  // Transaction Amounts
  @JsonKey(name: 'net_amount')
  final double? netAmount;
  @JsonKey(name: 'vat_amount')
  final double? vatAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;

  // Status and Type
  final String? status;
  @JsonKey(name: 'invoice_type')
  final String? invoiceType;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;

  // Branch Information
  @JsonKey(name: 'branch_code')
  final String? branchCode;
  @JsonKey(name: 'branch_name')
  final String? branchName;

  // Due Date
  @JsonKey(name: 'due_date')
  final String? dueDate;

  // Timestamps
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  SaleInvoice({
    this.id,
    this.branchSync,
    this.docDatetime,
    this.docNo,
    this.periodNumber,
    this.accountYear,
    this.bookCode,
    this.bookName,
    this.customerCode,
    this.customerName,
    this.customerTaxId,
    this.netAmount,
    this.vatAmount,
    this.totalAmount,
    this.discountAmount,
    this.status,
    this.invoiceType,
    this.paymentStatus,
    this.branchCode,
    this.branchName,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleInvoice.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceToJson(this);

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

  String get displayDueDate {
    if (dueDate == null) return '-';
    try {
      final date = DateTime.parse(dueDate!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dueDate ?? '-';
    }
  }

  String get statusDisplay {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'CANCELLED':
        return 'Cancelled';
      case 'DRAFT':
        return 'Draft';
      default:
        return status ?? 'Unknown';
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus?.toUpperCase()) {
      case 'PAID':
        return 'Paid';
      case 'UNPAID':
        return 'Unpaid';
      case 'PARTIAL':
        return 'Partial';
      case 'OVERDUE':
        return 'Overdue';
      default:
        return paymentStatus ?? 'Unknown';
    }
  }

  bool get isActive => status?.toUpperCase() == 'ACTIVE';
  bool get isCancelled => status?.toUpperCase() == 'CANCELLED';
  bool get isDraft => status?.toUpperCase() == 'DRAFT';
  bool get isPaid => paymentStatus?.toUpperCase() == 'PAID';
  bool get isUnpaid => paymentStatus?.toUpperCase() == 'UNPAID';
  bool get isOverdue => paymentStatus?.toUpperCase() == 'OVERDUE';
}

@JsonSerializable()
class SaleInvoiceResponse {
  @JsonKey(name: 'sale_invoices')
  final List<SaleInvoice>? saleInvoices;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  SaleInvoiceResponse({
    this.saleInvoices,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory SaleInvoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceResponseToJson(this);
}

@JsonSerializable()
class SaleInvoiceSummary {
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'branch_name')
  final String? branchName;
  @JsonKey(name: 'total_net_amount')
  final double? totalNetAmount;
  @JsonKey(name: 'total_vat_amount')
  final double? totalVatAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @JsonKey(name: 'total_discount_amount')
  final double? totalDiscountAmount;
  @JsonKey(name: 'invoice_count')
  final int? invoiceCount;

  SaleInvoiceSummary({
    this.branchSync,
    this.branchName,
    this.totalNetAmount,
    this.totalVatAmount,
    this.totalAmount,
    this.totalDiscountAmount,
    this.invoiceCount,
  });

  factory SaleInvoiceSummary.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceSummaryToJson(this);
}
