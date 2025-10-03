// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  currentpage: (json['currentpage'] as num).toInt(),
  pagesize: (json['pagesize'] as num).toInt(),
  totalpages: (json['totalpages'] as num).toInt(),
  totalrecords: (json['totalrecords'] as num).toInt(),
  hasnext: json['hasnext'] as bool,
  hasprevious: json['hasprevious'] as bool,
);

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'currentpage': instance.currentpage,
      'pagesize': instance.pagesize,
      'totalpages': instance.totalpages,
      'totalrecords': instance.totalrecords,
      'hasnext': instance.hasnext,
      'hasprevious': instance.hasprevious,
    };
