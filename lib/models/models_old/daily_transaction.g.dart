// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyTransaction _$DailyTransactionFromJson(Map<String, dynamic> json) =>
    DailyTransaction(
      timestamp: json['timestamp'] as String?,
      deposit: (json['deposit'] as num?)?.toDouble(),
      withdraw: (json['withdraw'] as num?)?.toDouble(),
      ref: json['ref'] as String?,
      note: json['note'] as String?,
      recordedBy: json['recorded_by'] == null
          ? null
          : RecordedBy.fromJson(json['recorded_by'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DailyTransactionToJson(DailyTransaction instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'deposit': instance.deposit,
      'withdraw': instance.withdraw,
      'ref': instance.ref,
      'note': instance.note,
      'recorded_by': instance.recordedBy,
    };

RecordedBy _$RecordedByFromJson(Map<String, dynamic> json) => RecordedBy(
  name: json['name'] as String?,
  employeeId: json['employee_id'] as String?,
);

Map<String, dynamic> _$RecordedByToJson(RecordedBy instance) =>
    <String, dynamic>{
      'name': instance.name,
      'employee_id': instance.employeeId,
    };

ShopDailyResponse _$ShopDailyResponseFromJson(Map<String, dynamic> json) =>
    ShopDailyResponse(
      status: json['status'] as String?,
      timestamp: json['timestamp'] as String?,
      filters: json['filters'] as Map<String, dynamic>?,
      shopid: json['shopid'] as String?,
      shopname: json['shopname'] as String?,
      pagination: json['pagination'] as Map<String, dynamic>?,
      daily: (json['daily'] as List<dynamic>)
          .map((e) => DailyTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShopDailyResponseToJson(ShopDailyResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'timestamp': instance.timestamp,
      'filters': instance.filters,
      'shopid': instance.shopid,
      'shopname': instance.shopname,
      'pagination': instance.pagination,
      'daily': instance.daily,
    };
