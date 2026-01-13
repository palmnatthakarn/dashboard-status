import 'package:json_annotation/json_annotation.dart';

part 'dashboard_summary.g.dart';

@JsonSerializable()
class DashboardSummary {
  final int totalshop;
  final int doctotal;
  final int docsuccess;
  final int docwarning;
  final int docerror;
  final String timestamp;
  @JsonKey(name: 'success_rate')
  final int successRate;
  @JsonKey(name: 'warning_rate')
  final int warningRate;
  @JsonKey(name: 'error_rate')
  final int errorRate;

  DashboardSummary({
    required this.totalshop,
    required this.doctotal,
    required this.docsuccess,
    required this.docwarning,
    required this.docerror,
    required this.timestamp,
    required this.successRate,
    required this.warningRate,
    required this.errorRate,
  });

  int get completedCount => docsuccess;
  int get pendingCount => docwarning;
  int get failedCount => docerror;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}
