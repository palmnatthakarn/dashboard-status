import 'package:json_annotation/json_annotation.dart';

part 'purchase_detail.g.dart';

@JsonSerializable()
class PurchaseDetail {
  final int? id;
  
  // Document Information
  @JsonKey(name: 'purchase_id')
  final int? purchaseId;
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'doc_no')
  final String? docNo;

  // Item Information
  @JsonKey(name: 'item_code')
  final String? itemCode;
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;

  // Quantity & Pricing
  final double? quantity;
  @JsonKey(name: 'unit_price')
  final double? unitPrice;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'line_total')
  final double? lineTotal;

  // VAT Information
  @JsonKey(name: 'vat_rate')
  final double? vatRate;
  @JsonKey(name: 'vat_amount')
  final double? vatAmount;

  // Unit Information
  @JsonKey(name: 'unit_code')
  final String? unitCode;
  @JsonKey(name: 'unit_name')
  final String? unitName;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  PurchaseDetail({
    this.id,
    this.purchaseId,
    this.branchSync,
    this.docNo,
    this.itemCode,
    this.itemName,
    this.itemDescription,
    this.quantity,
    this.unitPrice,
    this.discountAmount,
    this.lineTotal,
    this.vatRate,
    this.vatAmount,
    this.unitCode,
    this.unitName,
    this.createdAt,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) =>
      _$PurchaseDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseDetailToJson(this);

  // Getter methods
  double get totalWithVat => (lineTotal ?? 0) + (vatAmount ?? 0);
  
  String get formattedQuantity {
    if (quantity == null) return '0';
    return quantity! % 1 == 0 ? quantity!.toInt().toString() : quantity!.toStringAsFixed(2);
  }

  String get formattedUnitPrice {
    if (unitPrice == null) return '0.00';
    return unitPrice!.toStringAsFixed(2);
  }

  String get displayUnit => unitName ?? unitCode ?? '-';
}

@JsonSerializable()
class PurchaseDetailResponse {
  @JsonKey(name: 'purchase_details')
  final List<PurchaseDetail>? purchaseDetails;
  final int? total;
  @JsonKey(name: 'current_page')
  final int? currentPage;
  @JsonKey(name: 'per_page')
  final int? perPage;

  PurchaseDetailResponse({
    this.purchaseDetails,
    this.total,
    this.currentPage,
    this.perPage,
  });

  factory PurchaseDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseDetailResponseToJson(this);
}