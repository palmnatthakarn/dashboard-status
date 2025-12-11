// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shops_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopsResponse _$ShopsResponseFromJson(Map<String, dynamic> json) =>
    ShopsResponse(
      pagination: json['pagination'] == null
          ? null
          : Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
      docdetails: (json['docdetails'] as List<dynamic>)
          .map((e) => DocDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShopsResponseToJson(ShopsResponse instance) =>
    <String, dynamic>{
      'pagination': instance.pagination,
      'docdetails': instance.docdetails,
    };
