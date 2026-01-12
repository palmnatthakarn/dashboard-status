class JournalBook {
  final String? guidfixed;
  final String? code;
  final String? name1;
  final String? name2;
  final String? name3;
  final String? name4;
  final String? name5;

  JournalBook({
    this.guidfixed,
    this.code,
    this.name1,
    this.name2,
    this.name3,
    this.name4,
    this.name5,
  });

  factory JournalBook.fromJson(Map<String, dynamic> json) {
    return JournalBook(
      guidfixed: json['guidfixed'] as String?,
      code: json['code'] as String?,
      name1: json['name1'] as String?,
      name2: json['name2'] as String?,
      name3: json['name3'] as String?,
      name4: json['name4'] as String?,
      name5: json['name5'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guidfixed': guidfixed,
      'code': code,
      'name1': name1,
      'name2': name2,
      'name3': name3,
      'name4': name4,
      'name5': name5,
    };
  }
}

class JournalBookResponse {
  final bool success;
  final List<JournalBook> data;
  final Map<String, dynamic>? pagination;

  JournalBookResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory JournalBookResponse.fromJson(Map<String, dynamic> json) {
    return JournalBookResponse(
      success: json['success'] as bool? ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => JournalBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] as Map<String, dynamic>?,
    );
  }
}
