import 'package:json_annotation/json_annotation.dart';
import 'pagination.dart';
import 'doc_details.dart';

part 'shops_response.g.dart';

@JsonSerializable()
class ShopsResponse {
  final Pagination? pagination;
  final List<DocDetails> docdetails;

  ShopsResponse({this.pagination, required this.docdetails});

  factory ShopsResponse.fromJson(Map<String, dynamic> json) {
    try {
      return _$ShopsResponseFromJson(json);
    } catch (e) {
      // ถ้า parse ไม่ได้ ให้สร้างข้อมูลเริ่มต้น
      return ShopsResponse(pagination: null, docdetails: []);
    }
  }
  Map<String, dynamic> toJson() => _$ShopsResponseToJson(this);
}
