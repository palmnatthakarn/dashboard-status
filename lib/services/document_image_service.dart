import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';

/// Model for individual document image
class DocumentImage {
  final String? imageId;
  final String? shopId;
  final String? category;
  final String? subcategory;
  final String? description;
  final String? uploadedAt;
  final String? uploadedBy;
  final String? imageUrl;

  DocumentImage({
    this.imageId,
    this.shopId,
    this.category,
    this.subcategory,
    this.description,
    this.uploadedAt,
    this.uploadedBy,
    this.imageUrl,
  });

  factory DocumentImage.fromJson(Map<String, dynamic> json) {
    return DocumentImage(
      imageId: json['imageid']?.toString() ?? json['guidfixed']?.toString(),
      shopId: json['shopid']?.toString() ?? json['guidfixedid']?.toString(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      description: json['description']?.toString() ?? json['name']?.toString(),
      uploadedAt:
          json['uploadedat']?.toString() ??
          json['uploadedAt']?.toString() ??
          json['uploaded_at']?.toString() ??
          json['metafileat']?.toString(),
      uploadedBy:
          json['uploadedby']?.toString() ??
          json['uploadedBy']?.toString() ??
          json['uploaded_by']?.toString(),
      imageUrl:
          json['imageuri']?.toString() ??
          json['imageurl']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString(),
    );
  }
}

/// Model for document image group data
class DocumentImageGroup {
  final String shopId; // guidfixedid from API
  final int billCount; // billcount from API
  final int imageCount; // count of imagereferences array
  final List<Map<String, dynamic>>? imageReferences;

  DocumentImageGroup({
    required this.shopId,
    required this.billCount,
    required this.imageCount,
    this.imageReferences,
  });

  factory DocumentImageGroup.fromJson(Map<String, dynamic> json) {
    // Extract imagereferences array
    List<Map<String, dynamic>>? imgRefs;
    int imgCount = 0;

    if (json['imagereferences'] != null && json['imagereferences'] is List) {
      imgRefs = (json['imagereferences'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      imgCount = imgRefs.length;
    }

    return DocumentImageGroup(
      shopId: json['guidfixedid']?.toString() ?? '',
      billCount: _parseInt(json['billcount']),
      imageCount: imgCount,
      imageReferences: imgRefs,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// Service to fetch document image group data
class DocumentImageService {
  static const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';

  /// Fetch document images for a specific shop
  static Future<List<DocumentImage>> fetchShopImages({
    required String shopId,
    int limit = 9999,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      print('❌ No auth token available for documentimage');
      return [];
    }

    final url = '$baseUrl/documentimage?shopid=$shopId&limit=$limit';
    print('📸 Fetching shop images for ID: "$shopId"');
    print('📸 Full URL: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Document image response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}'); // Debug: see full response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✨ Decoded data: $data'); // Debug: see decoded data
        print('✨ Success field: ${data['success']}'); // Debug
        print('✨ Data field type: ${data['data']?.runtimeType}'); // Debug
        print('✨ Data field: ${data['data']}'); // Debug

        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            final images = (data['data'] as List).map((item) {
              print('🖼️ Processing image item: $item'); // Debug each item
              return DocumentImage.fromJson(item);
            }).toList();

            print('✅ Loaded ${images.length} images for shop $shopId');

            // Debug: log first image details
            if (images.isNotEmpty) {
              final first = images.first;
              print(
                '🔍 First image: id=${first.imageId}, url=${first.imageUrl}, category=${first.category}',
              );
            }

            return images;
          } else {
            print('⚠️ Data is not a List, it is: ${data['data'].runtimeType}');
          }
        } else {
          print('⚠️ Success is false or data is null');
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - token may be expired');
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }

      print('❌ Failed to get document images for shop $shopId');
      return [];
    } catch (e, stackTrace) {
      print('💥 Error fetching document images: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch document image groups for all shops
  /// Returns map of shopId -> billCount
  static Future<Map<String, int>> fetchDocumentImageGroups({
    int limit = 9999,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      log('❌ No auth token available for documentimagegroup');
      return {};
    }

    final url = '$baseUrl/documentimagegroup?limit=$limit';
    log('📸 Fetching document images from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📡 Document image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final Map<String, int> billCountMap = {};

          if (data['data'] is List) {
            final groups = (data['data'] as List)
                .map((item) => DocumentImageGroup.fromJson(item))
                .toList();

            // Build map of guidfixedid -> billCount
            for (var group in groups) {
              if (group.shopId.isNotEmpty) {
                billCountMap[group.shopId] = group.billCount;
                log(
                  '  📋 Shop ${group.shopId}: billCount=${group.billCount}, imageCount=${group.imageCount}',
                );
              }
            }

            log('✅ Loaded bill counts for ${billCountMap.length} shops');
          }

          return billCountMap;
        }
      } else if (response.statusCode == 401) {
        log('❌ Unauthorized - token may be expired');
      }

      log('❌ Failed to get document images');
      return {};
    } catch (e) {
      log('💥 Error fetching document images: $e');
      return {};
    }
  }
}
