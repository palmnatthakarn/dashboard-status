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
  final int success_rate;
  final int warning_rate;
  final int error_rate;

  DashboardSummary({
    required this.totalshop,
    required this.doctotal,
    required this.docsuccess,
    required this.docwarning,
    required this.docerror,
    required this.timestamp,
    required this.success_rate,
    required this.warning_rate,
    required this.error_rate,
  });

  int get completedCount => docsuccess;
  int get pendingCount => docwarning;
  int get failedCount => docerror;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}
