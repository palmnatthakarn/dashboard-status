// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doc_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocDetails _$DocDetailsFromJson(Map<String, dynamic> json) => DocDetails(
  shopid: json['shopid'] as String?,
  shopname: json['shopname'] as String?,
  monthlySummary: (json['monthly_summary'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, MonthlyData.fromJson(e as Map<String, dynamic>)),
  ),
  daily: (json['daily'] as List<dynamic>?)
      ?.map((e) => DailyTransaction.fromJson(e as Map<String, dynamic>))
      .toList(),
  responsible: json['responsible'] == null
      ? null
      : ResponsiblePerson.fromJson(json['responsible'] as Map<String, dynamic>),
  backupResponsible: json['backup_responsible'] == null
      ? null
      : ResponsiblePerson.fromJson(
          json['backup_responsible'] as Map<String, dynamic>,
        ),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  timezone: json['timezone'] as String?,
  dailyImages: (json['daily_images'] as List<dynamic>?)
      ?.map((e) => DailyImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  dailyTransactions: json['daily_transactions'] as List<dynamic>?,
);

Map<String, dynamic> _$DocDetailsToJson(DocDetails instance) =>
    <String, dynamic>{
      'shopid': instance.shopid,
      'shopname': instance.shopname,
      'monthly_summary': instance.monthlySummary,
      'daily': instance.daily,
      'responsible': instance.responsible,
      'backup_responsible': instance.backupResponsible,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'timezone': instance.timezone,
      'daily_images': instance.dailyImages,
      'daily_transactions': instance.dailyTransactions,
    };

MonthlyData _$MonthlyDataFromJson(Map<String, dynamic> json) => MonthlyData(
  deposit: (json['deposit'] as num?)?.toDouble(),
  withdraw: (json['withdraw'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MonthlyDataToJson(MonthlyData instance) =>
    <String, dynamic>{
      'deposit': instance.deposit,
      'withdraw': instance.withdraw,
    };

DailyTransaction _$DailyTransactionFromJson(Map<String, dynamic> json) =>
    DailyTransaction(
      timestamp: json['timestamp'] as String?,
      deposit: (json['deposit'] as num?)?.toDouble(),
      withdraw: (json['withdraw'] as num?)?.toDouble(),
      note: json['note'] as String?,
      ref: json['ref'] as String?,
      recordedBy: json['recorded_by'] == null
          ? null
          : RecordedBy.fromJson(json['recorded_by'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DailyTransactionToJson(DailyTransaction instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'deposit': instance.deposit,
      'withdraw': instance.withdraw,
      'note': instance.note,
      'ref': instance.ref,
      'recorded_by': instance.recordedBy,
    };

ResponsiblePerson _$ResponsiblePersonFromJson(Map<String, dynamic> json) =>
    ResponsiblePerson(
      name: json['name'] as String?,
      employeeId: json['employee_id'] as String?,
      role: json['role'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      lineId: json['line_id'] as String?,
    );

Map<String, dynamic> _$ResponsiblePersonToJson(ResponsiblePerson instance) =>
    <String, dynamic>{
      'name': instance.name,
      'employee_id': instance.employeeId,
      'role': instance.role,
      'email': instance.email,
      'phone': instance.phone,
      'line_id': instance.lineId,
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
