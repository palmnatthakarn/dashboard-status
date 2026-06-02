import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';
import 'multi_shop_service.dart';

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
  final String shopName;
  final int billCount; // billcount from API
  final int imageCount; // count of imagereferences array
  final List<Map<String, dynamic>>? imageReferences;

  DocumentImageGroup({
    required this.shopId,
    this.shopName = '',
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
      shopId:
          json['guidfixedid']?.toString() ??
          json['shopid']?.toString() ??
          json['shop_id']?.toString() ??
          '',
      shopName:
          json['shopname']?.toString() ??
          json['shop_name']?.toString() ??
          json['name']?.toString() ??
          '',
      billCount: _parseInt(
        json['billcount'] ?? json['bill_count'] ?? json['total'],
      ),
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
  static const String baseUrl = AuthRepository.baseUrl;

  /// Fetch document images for a specific shop
  static Future<List<DocumentImage>> fetchShopImages({
    required String shopId,
    int limit = 9999,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimage');
      return [];
    }

    await MultiShopService.selectShop(shopId: shopId);

    final uri = Uri.parse('$baseUrl/documentimage').replace(
      queryParameters: {
        'shopid': shopId,
        'limit': limit.toString(),
      },
    );
    dLog('📸 Fetching shop images for ID: "$shopId"');
    dLog('📸 Full URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dLog('📡 Document image response status: ${response.statusCode}');
      dLog('📦 Response body: ${response.body}'); // Debug: see full response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        dLog('✨ Decoded data: $data'); // Debug: see decoded data
        dLog('✨ Success field: ${data['success']}'); // Debug
        dLog('✨ Data field type: ${data['data']?.runtimeType}'); // Debug
        dLog('✨ Data field: ${data['data']}'); // Debug

        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            final images = (data['data'] as List).map((item) {
              dLog('🖼️ Processing image item: $item'); // Debug each item
              return DocumentImage.fromJson(item);
            }).toList();
            final shopImages = _filterImagesByShop(images, shopId);

            dLog(
              '✅ Loaded ${shopImages.length}/${images.length} images for shop $shopId',
            );

            // Debug: log first image details
            if (shopImages.isNotEmpty) {
              final first = shopImages.first;
              dLog(
                '🔍 First image: id=${first.imageId}, shopId=${first.shopId}, url=${first.imageUrl}, category=${first.category}',
              );
            }

            return shopImages;
          } else {
            dLog('⚠️ Data is not a List, it is: ${data['data'].runtimeType}');
          }
        } else {
          dLog('⚠️ Success is false or data is null');
        }
      } else if (response.statusCode == 401) {
        dLog('❌ Unauthorized - token may be expired');
      } else {
        dLog('❌ Unexpected status code: ${response.statusCode}');
      }

      dLog('❌ Failed to get document images for shop $shopId');
      return [];
    } catch (e, stackTrace) {
      dLog('💥 Error fetching document images: $e');
      dLog('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  static List<DocumentImage> _filterImagesByShop(
    List<DocumentImage> images,
    String shopId,
  ) {
    final normalizedShopId = _normalizeShopId(shopId);
    final taggedImages = images
        .where((image) => (image.shopId ?? '').trim().isNotEmpty)
        .toList();
    if (taggedImages.isEmpty) return images;

    final matchedImages = taggedImages
        .where((image) => _normalizeShopId(image.shopId) == normalizedShopId)
        .toList();
    return matchedImages.isEmpty ? images : matchedImages;
  }

  static String _normalizeShopId(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  /// Fetch document image groups for all shops
  /// Returns map of shop identifier/name -> billCount
  static Future<Map<String, int>> fetchDocumentImageGroups({
    int page = 1,
    int perPage = 9999,
    String? fromDate,
    String? toDate,
    int ref = 1,
    String? shopId,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimagegroup');
      return {};
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
      'ref': ref.toString(),
    };
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['todate'] = toDate;
    }
    if (shopId != null && shopId.isNotEmpty) {
      queryParams['shopid'] = shopId;
    }

    final uri = Uri.parse(
      '$baseUrl/documentimagegroup',
    ).replace(queryParameters: queryParams);
    dLog('📸 Fetching document image groups from: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dLog('📡 Document image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final Map<String, int> billCountMap = {};

          final rawGroups = data['data'] is List
              ? data['data'] as List
              : data['data'] is Map && data['data']['items'] is List
              ? data['data']['items'] as List
              : data['data'] is Map && data['data']['data'] is List
              ? data['data']['data'] as List
              : const [];

          if (rawGroups.isNotEmpty) {
            final groups = rawGroups
                .map((item) => DocumentImageGroup.fromJson(item))
                .toList();

            // Build map of guidfixedid -> billCount
            for (var group in groups) {
              if (group.shopId.isNotEmpty) {
                billCountMap[group.shopId] = group.billCount;
              }
              if (group.shopName.isNotEmpty) {
                billCountMap[group.shopName] = group.billCount;
                billCountMap[group.shopName.trim().toLowerCase()] =
                    group.billCount;
              }
              if (group.shopId.isNotEmpty || group.shopName.isNotEmpty) {
                dLog(
                  '  📋 Shop ${group.shopId}/${group.shopName}: billCount=${group.billCount}, imageCount=${group.imageCount}',
                );
              }
            }

            dLog('✅ Loaded bill counts for ${billCountMap.length} shops');
          }

          return billCountMap;
        }
      } else if (response.statusCode == 401) {
        dLog('❌ Unauthorized - token may be expired');
      }

      dLog('❌ Failed to get document images');
      return {};
    } catch (e) {
      dLog('💥 Error fetching document images: $e');
      return {};
    }
  }
}
