// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalshop: (json['totalshop'] as num).toInt(),
      doctotal: (json['doctotal'] as num).toInt(),
      docsuccess: (json['docsuccess'] as num).toInt(),
      docwarning: (json['docwarning'] as num).toInt(),
      docerror: (json['docerror'] as num).toInt(),
      timestamp: json['timestamp'] as String,
      success_rate: (json['success_rate'] as num).toInt(),
      warning_rate: (json['warning_rate'] as num).toInt(),
      error_rate: (json['error_rate'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'totalshop': instance.totalshop,
      'doctotal': instance.doctotal,
      'docsuccess': instance.docsuccess,
      'docwarning': instance.docwarning,
      'docerror': instance.docerror,
      'timestamp': instance.timestamp,
      'success_rate': instance.success_rate,
      'warning_rate': instance.warning_rate,
      'error_rate': instance.error_rate,
    };
