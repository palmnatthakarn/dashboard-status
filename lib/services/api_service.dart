import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/dashboard_summary.dart';
import '../models/shops_response.dart';
import '../models/daily_images.dart';
import '../models/daily_transaction.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<ShopsResponse> fetchShops({int page = 1, int size = 50}) async {
    final url = '$baseUrl/dashboard/shops?page=$page&size=$size';
    log('🌐 Fetching shops from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');
      log('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Successfully parsed shops data');
        log('🔍 Data structure: ${data.runtimeType}');
        log('🔍 Data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');

        // ตรวจสอบโครงสร้างข้อมูลก่อน parse
        if (data is Map<String, dynamic>) {
          // แปลง shops เป็น docdetails เพื่อความเข้ากันได้กับ model
          if (data['shops'] != null) {
            data['docdetails'] = data['shops'];
            log(
              '✅ Mapped shops to docdetails: ${data['docdetails'].length} items',
            );
          } else if (data['docdetails'] == null) {
            log('⚠️ No shops or docdetails found, using empty list');
            data['docdetails'] = [];
          }

          // ตรวจสอบว่ามี pagination หรือไม่
          if (data['pagination'] == null) {
            log('⚠️ pagination is null, using default');
            data['pagination'] = {
              'current_page': 1,
              'per_page': 50,
              'total': 0,
              'total_pages': 1,
            };
          }

          return ShopsResponse.fromJson(data);
        } else {
          log(
            '❌ Invalid response format: expected Map but got ${data.runtimeType}',
          );
          throw Exception('Invalid response format from shops API');
        }
      } else {
        log('❌ Failed to load shops - Status: ${response.statusCode}');
        throw Exception(
          'Failed to load shops - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching shops: $e');
      rethrow;
    }
  }

  static Future<DashboardSummary> fetchSummary() async {
    final url = '$baseUrl/dashboard/summary';
    log('🌐 Fetching summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');
      log('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Successfully parsed summary data');
        return DashboardSummary.fromJson(data);
      } else {
        log('❌ Failed to load summary - Status: ${response.statusCode}');
        throw Exception(
          'Failed to load summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching summary: $e');
      rethrow;
    }
  }

  static Future<List<DailyImage>> fetchDailyImages() async {
    final url = '$baseUrl/dashboard/daily-images';
    log('🌐 Fetching daily images from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');
      log('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed daily images response');

        // ดึงข้อมูล images array ออกมาจาก response
        final imagesList = responseData['images'] as List<dynamic>;
        log('🔍 Found ${imagesList.length} images in response');

        if (imagesList.isNotEmpty) {
          log('🔬 First image structure: ${imagesList.first}');
          log(
            '🔑 Keys in first image: ${(imagesList.first as Map).keys.toList()}',
          );
        }

        final images = imagesList.map((item) {
          log('🎯 Processing image: $item');
          return DailyImage.fromJson(item as Map<String, dynamic>);
        }).toList();

        log('🎉 Created ${images.length} DailyImage objects');
        for (final image in images) {
          log(
            '📸 DailyImage: shopid=${image.shopid}, imageUrl=${image.imageUrl}',
          );
        }

        return images;
      } else {
        log('❌ Failed to load daily images - Status: ${response.statusCode}');
        throw Exception(
          'Failed to load daily images - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching daily images: $e');
      rethrow;
    }
  }

  static Future<List<DailyImage>> fetchShopDaily(String shopId) async {
    final url = '$baseUrl/dashboard/shops/$shopId/daily';
    print('🌐 Fetching shop daily data from: $url');
    log('🌐 Fetching shop daily data from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      log('📡 Response status: ${response.statusCode}');
      log('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Successfully parsed shop daily response');
        print('🔍 Response type: ${responseData.runtimeType}');
        print('🔍 Full response data: $responseData');
        log('✅ Successfully parsed shop daily response');
        log('🔍 Response type: ${responseData.runtimeType}');

        // จัดการกรณีที่ response เป็น null
        if (responseData == null) {
          print('⚠️ Received null response for shop $shopId');
          log('⚠️ Received null response for shop $shopId');
          return [];
        }

        // ตรวจสอบโครงสร้างของ response
        print('🔍 Checking response structure for shop $shopId...');
        if (responseData is List) {
          print('✅ Response is a List with ${responseData.length} items');
          // ถ้า response เป็น array โดยตรง
          if (responseData.isEmpty) {
            log('📭 Empty array response for shop $shopId');
            return [];
          }

          final images = <DailyImage>[];
          for (int i = 0; i < responseData.length; i++) {
            try {
              final item = responseData[i];
              if (item != null && item is Map<String, dynamic>) {
                log('🎯 Processing daily item $i: $item');
                images.add(DailyImage.fromJson(item));
              } else {
                log('⚠️ Skipping null or invalid item at index $i');
              }
            } catch (e) {
              log('💥 Error parsing item $i for shop $shopId: $e');
              continue;
            }
          }

          log(
            '🎉 Created ${images.length} DailyImage objects for shop $shopId',
          );
          return images;
        } else if (responseData is Map<String, dynamic>) {
          print('✅ Response is a Map with keys: ${responseData.keys.toList()}');
          // ถ้า response เป็น object ที่มี daily transactions
          final dailyList = responseData['daily'] ?? [];

          print('🔍 Found daily list type: ${dailyList.runtimeType}');
          if (dailyList is List) {
            print('📝 Daily list has ${dailyList.length} items');
            if (dailyList.isEmpty) {
              print('📭 Empty daily list for shop $shopId');
              return [];
            }

            // เนื่องจาก daily data ไม่ใช่ images จึงส่งคืน empty list
            // ข้อมูล daily จะถูกใช้ในส่วนอื่นของระบบ
            print(
              '⚠️ Daily data found but no images in this endpoint for shop $shopId',
            );
            return [];
          } else {
            print(
              '⚠️ Daily list is not an array for shop $shopId: ${dailyList.runtimeType}',
            );
            return [];
          }
        } else {
          log(
            '⚠️ Unexpected response type for shop daily: ${responseData.runtimeType}',
          );
          return [];
        }
      } else if (response.statusCode == 404) {
        print('📭 No daily data found for shop $shopId (404)');
        log('📭 No daily data found for shop $shopId (404)');
        return [];
      } else {
        print('❌ Failed to load shop daily - Status: ${response.statusCode}');
        print('📄 Error response body: ${response.body}');
        log('❌ Failed to load shop daily - Status: ${response.statusCode}');
        throw Exception(
          'Failed to load shop daily for shop $shopId - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error fetching shop daily for shop $shopId: $e');
      log('💥 Error fetching shop daily for shop $shopId: $e');
      rethrow;
    }
  }

  static Future<ShopDailyResponse?> fetchShopDailyTransactions(
    String shopId,
  ) async {
    final url = '$baseUrl/dashboard/shops/$shopId/daily';
    print('🌐 Fetching shop daily transactions from: $url');
    log('🌐 Fetching shop daily transactions from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      log('📡 Response status: ${response.statusCode}');
      log('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Successfully parsed shop daily transactions response');
        log('✅ Successfully parsed shop daily transactions response');

        if (responseData == null) {
          print('⚠️ Received null response for shop $shopId');
          return null;
        }

        if (responseData is Map<String, dynamic>) {
          print('✅ Response is a Map with keys: ${responseData.keys.toList()}');

          try {
            final shopDailyResponse = ShopDailyResponse.fromJson(responseData);
            print(
              '🎉 Created ShopDailyResponse with ${shopDailyResponse.daily.length} transactions',
            );
            return shopDailyResponse;
          } catch (e) {
            print('💥 Error parsing ShopDailyResponse: $e');
            return null;
          }
        } else {
          print('⚠️ Unexpected response type: ${responseData.runtimeType}');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('📭 No daily transactions found for shop $shopId (404)');
        return null;
      } else {
        print(
          '❌ Failed to load shop daily transactions - Status: ${response.statusCode}',
        );
        print('📄 Error response body: ${response.body}');
        throw Exception(
          'Failed to load shop daily transactions for shop $shopId - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error fetching shop daily transactions for shop $shopId: $e');
      rethrow;
    }
  }
}
