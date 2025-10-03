import 'package:json_annotation/json_annotation.dart';
import 'daily_images.dart';

part 'doc_details.g.dart';

@JsonSerializable()
class DocDetails {
  final String? shopid;
  final String? shopname;
  @JsonKey(name: 'monthly_summary')
  final Map<String, MonthlyData>? monthlySummary;
  final List<DailyTransaction>? daily;
  final ResponsiblePerson? responsible;
  @JsonKey(name: 'backup_responsible')
  final ResponsiblePerson? backupResponsible;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final String? timezone;
  @JsonKey(name: 'daily_images')
  final List<DailyImage>? dailyImages;
  @JsonKey(name: 'daily_transactions')
  final List? dailyTransactions;

  DocDetails({
    this.shopid,
    this.shopname,
    this.monthlySummary,
    this.daily,
    this.responsible,
    this.backupResponsible,
    this.createdAt,
    this.updatedAt,
    this.timezone,
    this.dailyImages,
    this.dailyTransactions,
  });

  double get totalDeposit {
    if (monthlySummary == null) return 0.0;
    return monthlySummary!.values.fold(
      0.0,
      (sum, month) => sum + (month.deposit ?? 0),
    );
  }

  double get totalWithdraw {
    if (monthlySummary == null) return 0.0;
    return monthlySummary!.values.fold(
      0.0,
      (sum, month) => sum + (month.withdraw ?? 0),
    );
  }

  double get dailyTotal {
    if (dailyTransactions == null) return 0.0;
    return dailyTransactions!.fold(
      0.0,
      (sum, transaction) => sum + (transaction.deposit ?? 0),
    );
  }

  // คำนวณยอดรวม withdraw จาก daily transactions
  double get dailyTotalWithdraw {
    if (dailyTransactions == null) return 0.0;
    return dailyTransactions!.fold(
      0.0,
      (sum, transaction) => sum + (transaction.withdraw ?? 0),
    );
  }

  // คำนวณยอดรวมสุทธิ (deposit - withdraw)
  double get dailyNetTotal {
    return dailyTotal - dailyTotalWithdraw;
  }

  String get workSummary {
    if (dailyImages == null || dailyImages!.isEmpty) return '-';

    final categories = <String>{};
    final subcategories = <String>{};

    for (final image in dailyImages!) {
      if (image.category?.isNotEmpty == true) {
        categories.add(image.category!);
      }
      if (image.subcategory?.isNotEmpty == true) {
        subcategories.add(image.subcategory!);
      }
    }

    final parts = <String>[];
    if (categories.isNotEmpty) {
      parts.add(categories.join(', '));
    }
    if (subcategories.isNotEmpty && subcategories.isNotEmpty) {
      parts.add('(${subcategories.join(', ')})');
    }

    return parts.isEmpty ? '-' : parts.join(' ');
  }

  int get imageCount {
    if (dailyImages == null || dailyImages!.isEmpty) {
      print('🔍 No daily images for shop $shopid');
      return 0;
    }

    final count = dailyImages!
        .where((image) => image.imageUrl?.isNotEmpty == true)
        .length;

    print(
      '🔢 Shop $shopid has $count images with valid URLs out of ${dailyImages!.length} total',
    );
    return count;
  }

  factory DocDetails.fromJson(Map<String, dynamic> json) =>
      _$DocDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$DocDetailsToJson(this);
}

@JsonSerializable()
class MonthlyData {
  final double? deposit;
  final double? withdraw;

  MonthlyData({this.deposit, this.withdraw});

  factory MonthlyData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyDataFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyDataToJson(this);
}

@JsonSerializable()
class DailyTransaction {
  final String? timestamp;
  final double? deposit;
  final double? withdraw;
  final String? note;
  final String? ref;
  @JsonKey(name: 'recorded_by')
  final RecordedBy? recordedBy;

  DailyTransaction({
    this.timestamp,
    this.deposit,
    this.withdraw,
    this.note,
    this.ref,
    this.recordedBy,
  });

  factory DailyTransaction.fromJson(Map<String, dynamic> json) =>
      _$DailyTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$DailyTransactionToJson(this);
}

@JsonSerializable()
class ResponsiblePerson {
  final String? name;
  @JsonKey(name: 'employee_id')
  final String? employeeId;
  final String? role;
  final String? email;
  final String? phone;
  @JsonKey(name: 'line_id')
  final String? lineId;

  ResponsiblePerson({
    this.name,
    this.employeeId,
    this.role,
    this.email,
    this.phone,
    this.lineId,
  });

  factory ResponsiblePerson.fromJson(Map<String, dynamic> json) =>
      _$ResponsiblePersonFromJson(json);
  Map<String, dynamic> toJson() => _$ResponsiblePersonToJson(this);
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
