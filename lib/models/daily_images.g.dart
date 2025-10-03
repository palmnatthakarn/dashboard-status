// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_images.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyImage _$DailyImageFromJson(Map<String, dynamic> json) => DailyImage(
  imageid: json['image_id'] as String?,
  category: json['category'] as String?,
  subcategory: json['subcategory'] as String?,
  uploadedAt: json['uploaded_at'] as String?,
  description: json['description'] as String?,
  shopid: json['shopid'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$DailyImageToJson(DailyImage instance) =>
    <String, dynamic>{
      'image_id': instance.imageid,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'uploaded_at': instance.uploadedAt,
      'description': instance.description,
      'shopid': instance.shopid,
      'image_url': instance.imageUrl,
    };
