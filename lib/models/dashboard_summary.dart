import 'package:json_annotation/json_annotation.dart';

part 'dashboard_summary.g.dart';

@JsonSerializable()
class DashboardSummary {
  @JsonKey(name: 'totalshop')
  final int totalShop;

  @JsonKey(name: 'doctotal')
  final int docTotal;

  @JsonKey(name: 'docsuccess')
  final int docSuccess;

  @JsonKey(name: 'docwarning')
  final int docWarning;

  @JsonKey(name: 'docerror')
  final int docError;

  @JsonKey(name: 'timestamp', defaultValue: '')
  final String? timestamp;

  @JsonKey(name: 'success_rate')
  final double successRate;

  @JsonKey(name: 'warning_rate')
  final double warningRate;

  @JsonKey(name: 'error_rate')
  final double errorRate;

  DashboardSummary({
    required this.totalShop,
    required this.docTotal,
    required this.docSuccess,
    required this.docWarning,
    required this.docError,
    this.timestamp,
    required this.successRate,
    required this.warningRate,
    required this.errorRate,
  });

  // Getters for compatibility if needed elsewhere
  int get completedCount => docSuccess;
  int get pendingCount => docWarning;
  int get failedCount => docError;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}
