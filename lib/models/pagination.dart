import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class Pagination {
  final int currentpage;
  final int pagesize;
  final int totalpages;
  final int totalrecords;
  final bool hasnext;
  final bool hasprevious;

  Pagination({
    required this.currentpage,
    required this.pagesize,
    required this.totalpages,
    required this.totalrecords,
    required this.hasnext,
    required this.hasprevious,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationToJson(this);
}
