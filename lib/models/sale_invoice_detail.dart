import 'package:json_annotation/json_annotation.dart';

part 'sale_invoice_detail.g.dart';

@JsonSerializable()
class SaleInvoiceDetail {
  final int? id;
  
  // Invoice Reference
  @JsonKey(name: 'invoice_id')
  final int? invoiceId;
  @JsonKey(name: 'invoice_doc_no')
  final String? invoiceDocNo;
  
  // Item Information
  @JsonKey(name: 'item_code')
  final String? itemCode;
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  
  // Unit Information
  @JsonKey(name: 'unit_code')
  final String? unitCode;
  @JsonKey(name: 'unit_name')
  final String? unitName;
  
  // Quantities
  final double? quantity;
  @JsonKey(name: 'unit_price')
  final double? unitPrice;
  
  // Amounts
  @JsonKey(name: 'line_total')
  final double? lineTotal;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'net_amount')
  final double? netAmount;
  @JsonKey(name: 'vat_rate')
  final double? vatRate;
  @JsonKey(name: 'vat_amount')
  final double? vatAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  
  // Branch Information
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'branch_name')
  final String? branchName;
  
  // Line Number
  @JsonKey(name: 'line_no')
  final int? lineNo;
  
  // Timestamps
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  SaleInvoiceDetail({
    this.id,
    this.invoiceId,
    this.invoiceDocNo,
    this.itemCode,
    this.itemName,
    this.itemDescription,
    this.unitCode,
    this.unitName,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.discountAmount,
    this.netAmount,
    this.vatRate,
    this.vatAmount,
    this.totalAmount,
    this.branchSync,
    this.branchName,
    this.lineNo,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleInvoiceDetail.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceDetailFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceDetailToJson(this);

  // Helper getters
  String get displayQuantity {
    if (quantity == null) return '-';
    return '${quantity!.toStringAsFixed(2)} ${unitName ?? ''}';
  }

  String get displayUnitPrice {
    if (unitPrice == null) return '-';
    return unitPrice!.toStringAsFixed(2);
  }

  String get displayVatRate {
    if (vatRate == null) return '-';
    return '${vatRate!.toStringAsFixed(2)}%';
  }

  double get effectiveTotal => totalAmount ?? 0.0;
  double get effectiveNet => netAmount ?? 0.0;
  double get effectiveVat => vatAmount ?? 0.0;
  double get effectiveDiscount => discountAmount ?? 0.0;
}

@JsonSerializable()
class SaleInvoiceDetailResponse {
  @JsonKey(name: 'sale_invoice_details')
  final List<SaleInvoiceDetail>? saleInvoiceDetails;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  SaleInvoiceDetailResponse({
    this.saleInvoiceDetails,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory SaleInvoiceDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceDetailResponseToJson(this);
}

@JsonSerializable()
class SaleInvoiceDetailSummary {
  @JsonKey(name: 'invoice_id')
  final int? invoiceId;
  @JsonKey(name: 'invoice_doc_no')
  final String? invoiceDocNo;
  @JsonKey(name: 'total_quantity')
  final double? totalQuantity;
  @JsonKey(name: 'total_line_amount')
  final double? totalLineAmount;
  @JsonKey(name: 'total_discount_amount')
  final double? totalDiscountAmount;
  @JsonKey(name: 'total_net_amount')
  final double? totalNetAmount;
  @JsonKey(name: 'total_vat_amount')
  final double? totalVatAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @JsonKey(name: 'line_count')
  final int? lineCount;

  SaleInvoiceDetailSummary({
    this.invoiceId,
    this.invoiceDocNo,
    this.totalQuantity,
    this.totalLineAmount,
    this.totalDiscountAmount,
    this.totalNetAmount,
    this.totalVatAmount,
    this.totalAmount,
    this.lineCount,
  });

  factory SaleInvoiceDetailSummary.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceDetailSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SaleInvoiceDetailSummaryToJson(this);
}