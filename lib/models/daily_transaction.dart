import 'package:json_annotation/json_annotation.dart';

part 'daily_transaction.g.dart';

@JsonSerializable()
class DailyTransaction {
  final String? timestamp;
  final double? deposit;
  final double? withdraw;
  final String? ref;
  final String? note;
  @JsonKey(name: 'recorded_by')
  final RecordedBy? recordedBy;

  DailyTransaction({
    this.timestamp,
    this.deposit,
    this.withdraw,
    this.ref,
    this.note,
    this.recordedBy,
  });

  factory DailyTransaction.fromJson(Map<String, dynamic> json) =>
      _$DailyTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$DailyTransactionToJson(this);
}

@JsonSerializable()
class RecordedBy {
  final String? name;
  @JsonKey(name: 'employee_id')
  final String? employeeId;

  RecordedBy({this.name, this.employeeId});

  factory RecordedBy.fromJson(Map<String, dynamic> json) =>
      _$RecordedByFromJson(json);
  Map<String, dynamic> toJson() => _$RecordedByToJson(this);
}

@JsonSerializable()
class ShopDailyResponse {
  final String? status;
  final String? timestamp;
  final Map<String, dynamic>? filters;
  final String? shopid;
  final String? shopname;
  final Map<String, dynamic>? pagination;
  final List<DailyTransaction> daily;

  ShopDailyResponse({
    this.status,
    this.timestamp,
    this.filters,
    this.shopid,
    this.shopname,
    this.pagination,
    required this.daily,
  });

  factory ShopDailyResponse.fromJson(Map<String, dynamic> json) =>
      _$ShopDailyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ShopDailyResponseToJson(this);
}
