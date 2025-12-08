import 'package:json_annotation/json_annotation.dart';

part 'stock.g.dart';

@JsonSerializable()
class Stock {
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

  // Stock Movement
  @JsonKey(name: 'movement_type')
  final String? movementType; // IN, OUT, ADJUST
  @JsonKey(name: 'quantity_in')
  final double? quantityIn;
  @JsonKey(name: 'quantity_out')
  final double? quantityOut;
  @JsonKey(name: 'quantity_balance')
  final double? quantityBalance;

  // Cost Information
  @JsonKey(name: 'unit_cost')
  final double? unitCost;
  @JsonKey(name: 'total_cost')
  final double? totalCost;
  @JsonKey(name: 'average_cost')
  final double? averageCost;

  // Location Information
  @JsonKey(name: 'warehouse_code')
  final String? warehouseCode;
  @JsonKey(name: 'warehouse_name')
  final String? warehouseName;
  @JsonKey(name: 'location_code')
  final String? locationCode;
  @JsonKey(name: 'location_name')
  final String? locationName;

  // Reference
  @JsonKey(name: 'reference_doc_no')
  final String? referenceDocNo;
  @JsonKey(name: 'reference_type')
  final String? referenceType;

  // Branch Information
  @JsonKey(name: 'branch_code')
  final String? branchCode;
  @JsonKey(name: 'branch_name')
  final String? branchName;

  // Timestamps
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Stock({
    this.id,
    this.branchSync,
    this.docDatetime,
    this.docNo,
    this.periodNumber,
    this.accountYear,
    this.bookCode,
    this.bookName,
    this.itemCode,
    this.itemName,
    this.itemDescription,
    this.unitCode,
    this.unitName,
    this.movementType,
    this.quantityIn,
    this.quantityOut,
    this.quantityBalance,
    this.unitCost,
    this.totalCost,
    this.averageCost,
    this.warehouseCode,
    this.warehouseName,
    this.locationCode,
    this.locationName,
    this.referenceDocNo,
    this.referenceType,
    this.branchCode,
    this.branchName,
    this.createdAt,
    this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) =>
      _$StockFromJson(json);

  Map<String, dynamic> toJson() => _$StockToJson(this);

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

  String get movementTypeDisplay {
    switch (movementType?.toUpperCase()) {
      case 'IN':
        return 'Stock In';
      case 'OUT':
        return 'Stock Out';
      case 'ADJUST':
        return 'Adjustment';
      case 'TRANSFER':
        return 'Transfer';
      default:
        return movementType ?? 'Unknown';
    }
  }

  String get displayQuantity {
    if (movementType?.toUpperCase() == 'IN' && quantityIn != null) {
      return '+${quantityIn!.toStringAsFixed(2)} ${unitName ?? ''}';
    } else if (movementType?.toUpperCase() == 'OUT' && quantityOut != null) {
      return '-${quantityOut!.toStringAsFixed(2)} ${unitName ?? ''}';
    } else {
      return '${(quantityIn ?? 0) - (quantityOut ?? 0)} ${unitName ?? ''}';
    }
  }

  String get displayBalance {
    if (quantityBalance == null) return '-';
    return '${quantityBalance!.toStringAsFixed(2)} ${unitName ?? ''}';
  }

  bool get isStockIn => movementType?.toUpperCase() == 'IN';
  bool get isStockOut => movementType?.toUpperCase() == 'OUT';
  bool get isAdjustment => movementType?.toUpperCase() == 'ADJUST';
  bool get isTransfer => movementType?.toUpperCase() == 'TRANSFER';
  
  double get effectiveQuantity => (quantityIn ?? 0) - (quantityOut ?? 0);
  double get effectiveCost => totalCost ?? 0.0;
  double get effectiveBalance => quantityBalance ?? 0.0;
}

@JsonSerializable()
class StockResponse {
  final List<Stock>? stocks;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  StockResponse({
    this.stocks,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory StockResponse.fromJson(Map<String, dynamic> json) =>
      _$StockResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StockResponseToJson(this);
}

@JsonSerializable()
class StockSummary {
  @JsonKey(name: 'branch_sync')
  final String? branchSync;
  @JsonKey(name: 'branch_name')
  final String? branchName;
  @JsonKey(name: 'item_code')
  final String? itemCode;
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'total_quantity_in')
  final double? totalQuantityIn;
  @JsonKey(name: 'total_quantity_out')
  final double? totalQuantityOut;
  @JsonKey(name: 'current_balance')
  final double? currentBalance;
  @JsonKey(name: 'total_cost_value')
  final double? totalCostValue;
  @JsonKey(name: 'average_unit_cost')
  final double? averageUnitCost;
  @JsonKey(name: 'movement_count')
  final int? movementCount;

  StockSummary({
    this.branchSync,
    this.branchName,
    this.itemCode,
    this.itemName,
    this.totalQuantityIn,
    this.totalQuantityOut,
    this.currentBalance,
    this.totalCostValue,
    this.averageUnitCost,
    this.movementCount,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) =>
      _$StockSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$StockSummaryToJson(this);
}