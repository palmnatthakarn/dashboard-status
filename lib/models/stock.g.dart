// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stock _$StockFromJson(Map<String, dynamic> json) => Stock(
  id: (json['id'] as num?)?.toInt(),
  branchSync: json['branch_sync'] as String?,
  docDatetime: json['doc_datetime'] as String?,
  docNo: json['doc_no'] as String?,
  periodNumber: json['period_number'] as String?,
  accountYear: json['account_year'] as String?,
  bookCode: json['book_code'] as String?,
  bookName: json['book_name'] as String?,
  itemCode: json['item_code'] as String?,
  itemName: json['item_name'] as String?,
  itemDescription: json['item_description'] as String?,
  unitCode: json['unit_code'] as String?,
  unitName: json['unit_name'] as String?,
  movementType: json['movement_type'] as String?,
  quantityIn: (json['quantity_in'] as num?)?.toDouble(),
  quantityOut: (json['quantity_out'] as num?)?.toDouble(),
  quantityBalance: (json['quantity_balance'] as num?)?.toDouble(),
  unitCost: (json['unit_cost'] as num?)?.toDouble(),
  totalCost: (json['total_cost'] as num?)?.toDouble(),
  averageCost: (json['average_cost'] as num?)?.toDouble(),
  warehouseCode: json['warehouse_code'] as String?,
  warehouseName: json['warehouse_name'] as String?,
  locationCode: json['location_code'] as String?,
  locationName: json['location_name'] as String?,
  referenceDocNo: json['reference_doc_no'] as String?,
  referenceType: json['reference_type'] as String?,
  branchCode: json['branch_code'] as String?,
  branchName: json['branch_name'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$StockToJson(Stock instance) => <String, dynamic>{
  'id': instance.id,
  'branch_sync': instance.branchSync,
  'doc_datetime': instance.docDatetime,
  'doc_no': instance.docNo,
  'period_number': instance.periodNumber,
  'account_year': instance.accountYear,
  'book_code': instance.bookCode,
  'book_name': instance.bookName,
  'item_code': instance.itemCode,
  'item_name': instance.itemName,
  'item_description': instance.itemDescription,
  'unit_code': instance.unitCode,
  'unit_name': instance.unitName,
  'movement_type': instance.movementType,
  'quantity_in': instance.quantityIn,
  'quantity_out': instance.quantityOut,
  'quantity_balance': instance.quantityBalance,
  'unit_cost': instance.unitCost,
  'total_cost': instance.totalCost,
  'average_cost': instance.averageCost,
  'warehouse_code': instance.warehouseCode,
  'warehouse_name': instance.warehouseName,
  'location_code': instance.locationCode,
  'location_name': instance.locationName,
  'reference_doc_no': instance.referenceDocNo,
  'reference_type': instance.referenceType,
  'branch_code': instance.branchCode,
  'branch_name': instance.branchName,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

StockResponse _$StockResponseFromJson(Map<String, dynamic> json) =>
    StockResponse(
      stocks: (json['stocks'] as List<dynamic>?)
          ?.map((e) => Stock.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      currentPage: (json['currentPage'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StockResponseToJson(StockResponse instance) =>
    <String, dynamic>{
      'stocks': instance.stocks,
      'totalCount': instance.totalCount,
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
    };

StockSummary _$StockSummaryFromJson(Map<String, dynamic> json) => StockSummary(
  branchSync: json['branch_sync'] as String?,
  branchName: json['branch_name'] as String?,
  itemCode: json['item_code'] as String?,
  itemName: json['item_name'] as String?,
  totalQuantityIn: (json['total_quantity_in'] as num?)?.toDouble(),
  totalQuantityOut: (json['total_quantity_out'] as num?)?.toDouble(),
  currentBalance: (json['current_balance'] as num?)?.toDouble(),
  totalCostValue: (json['total_cost_value'] as num?)?.toDouble(),
  averageUnitCost: (json['average_unit_cost'] as num?)?.toDouble(),
  movementCount: (json['movement_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$StockSummaryToJson(StockSummary instance) =>
    <String, dynamic>{
      'branch_sync': instance.branchSync,
      'branch_name': instance.branchName,
      'item_code': instance.itemCode,
      'item_name': instance.itemName,
      'total_quantity_in': instance.totalQuantityIn,
      'total_quantity_out': instance.totalQuantityOut,
      'current_balance': instance.currentBalance,
      'total_cost_value': instance.totalCostValue,
      'average_unit_cost': instance.averageUnitCost,
      'movement_count': instance.movementCount,
    };
