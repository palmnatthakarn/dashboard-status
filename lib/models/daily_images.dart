import 'package:json_annotation/json_annotation.dart';

part 'daily_images.g.dart';

@JsonSerializable()
class DailyImage {
  @JsonKey(name: 'image_id')
  final String? imageid;
  final String? category;
  final String? subcategory;
  @JsonKey(name: 'uploaded_at')
  final String? uploadedAt;
  final String? description;
  final String? shopid;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  DailyImage({
    this.imageid,
    this.category,
    this.subcategory,
    this.uploadedAt,
    this.description,
    this.shopid,
    this.imageUrl,
  });

  factory DailyImage.fromJson(Map<String, dynamic> json) =>
      _$DailyImageFromJson(json);
  Map<String, dynamic> toJson() => _$DailyImageToJson(this);
}
