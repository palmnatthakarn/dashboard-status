// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalShop: (json['totalshop'] as num).toInt(),
      docTotal: (json['doctotal'] as num).toInt(),
      docSuccess: (json['docsuccess'] as num).toInt(),
      docWarning: (json['docwarning'] as num).toInt(),
      docError: (json['docerror'] as num).toInt(),
      timestamp: json['timestamp'] as String? ?? '',
      successRate: (json['success_rate'] as num).toDouble(),
      warningRate: (json['warning_rate'] as num).toDouble(),
      errorRate: (json['error_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'totalshop': instance.totalShop,
      'doctotal': instance.docTotal,
      'docsuccess': instance.docSuccess,
      'docwarning': instance.docWarning,
      'docerror': instance.docError,
      'timestamp': instance.timestamp,
      'success_rate': instance.successRate,
      'warning_rate': instance.warningRate,
      'error_rate': instance.errorRate,
    };
