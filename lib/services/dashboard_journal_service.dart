import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/journal.dart';
import '../models/models_old/dashboard_summary.dart';
import '../models/models_old/daily_images.dart';
import 'journal_service.dart';

/// Service สำหรับ Dashboard ที่ใช้ Journal แทน DocDetails
class DashboardJournalService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// ดึงข้อมูล Dashboard ครบชุดโดยใช้ Journal API
  static Future<DashboardJournalData> fetchDashboardData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard data using Journal API...');

    try {
      // ดึงข้อมูลแบบ parallel
      final results = await Future.wait([
        _fetchSummary(),
        _fetchDailyImages(),
        JournalService.getDashboardJournalData(
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      final summary = results[0] as DashboardSummary;
      final dailyImages = results[1] as List<DailyImage>;
      final journalData = results[2] as Map<String, dynamic>;

      // แปลง journal data เป็น shop summaries
      final shopSummaries = (journalData['shop_summaries'] as List)
          .cast<Map<String, dynamic>>();

      // สร้าง ShopJournalSummary objects
      final shops = <ShopJournalSummary>[];
      for (final shopData in shopSummaries) {
        final shopId = shopData['shop_id'] as String;
        final shopImages = dailyImages
            .where((image) => image.shopid == shopId)
            .toList();

        final shop = ShopJournalSummary(
          shopId: shopId,
          shopName: shopData['shop_name'] as String,
          totalDebit: (shopData['total_debit'] as num).toDouble(),
          totalCredit: (shopData['total_credit'] as num).toDouble(),
          transactionCount: shopData['transaction_count'] as int,
          journals: (shopData['journals'] as List<Journal>),
          dailyImages: shopImages,
        );

        shops.add(shop);
      }

      return DashboardJournalData(
        summary: summary,
        shops: shops,
        totalJournals: journalData['total_journals'] as int,
        totalDebit: (journalData['total_debit'] as num).toDouble(),
        totalCredit: (journalData['total_credit'] as num).toDouble(),
        dailyImages: dailyImages,
      );
    } catch (e) {
      log('💥 Error fetching dashboard data: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูล summary (ใช้ API เดิม)
  static Future<DashboardSummary> _fetchSummary() async {
    final url = '$baseUrl/dashboard/summary';
    log('🌐 Fetching summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Successfully parsed summary data');
        return DashboardSummary.fromJson(data);
      } else {
        throw Exception(
          'Failed to load summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching summary: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูล daily images (ใช้ API เดิม)
  static Future<List<DailyImage>> _fetchDailyImages() async {
    final url = '$baseUrl/dashboard/daily-images';
    log('🌐 Fetching daily images from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed daily images response');

        final imagesList = responseData['images'] as List<dynamic>;
        log('🔍 Found ${imagesList.length} images in response');

        final images = imagesList.map((item) {
          return DailyImage.fromJson(item as Map<String, dynamic>);
        }).toList();

        log('🎉 Created ${images.length} DailyImage objects');
        return images;
      } else {
        throw Exception(
          'Failed to load daily images - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching daily images: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูล journal สำหรับร้านเฉพาะ
  static Future<ShopJournalDetail> fetchShopJournalDetail(String shopId) async {
    log('🏪 Fetching journal detail for shop: $shopId');

    try {
      final results = await Future.wait([
        JournalService.getJournalsByShop(shopId, limit: 100),
        JournalService.getJournalSummaryByShop(shopId),
        _fetchShopDailyImages(shopId),
      ]);

      final journalResponse = results[0] as JournalResponse;
      final summary = results[1] as JournalSummary?;
      final dailyImages = results[2] as List<DailyImage>;

      return ShopJournalDetail(
        shopId: shopId,
        shopName: summary?.shopName ?? 'Unknown Shop',
        journals: journalResponse.journals ?? [],
        summary: summary,
        dailyImages: dailyImages,
        pagination: journalResponse.pagination,
      );
    } catch (e) {
      log('💥 Error fetching shop journal detail: $e');
      rethrow;
    }
  }

  /// ดึงข้อมูลรูปภาพสำหรับร้านเฉพาะ
  static Future<List<DailyImage>> _fetchShopDailyImages(String shopId) async {
    final url = '$baseUrl/dashboard/shops/$shopId/daily';
    log('🌐 Fetching shop daily images from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          final images = <DailyImage>[];
          for (final item in responseData) {
            if (item != null && item is Map<String, dynamic>) {
              images.add(DailyImage.fromJson(item));
            }
          }
          return images;
        }
        return [];
      } else if (response.statusCode == 404) {
        log('📭 No daily images found for shop $shopId');
        return [];
      } else {
        throw Exception(
          'Failed to load shop daily images - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching shop daily images: $e');
      return [];
    }
  }
}

/// Data class สำหรับ Dashboard ที่ใช้ Journal
class DashboardJournalData {
  final DashboardSummary summary;
  final List<ShopJournalSummary> shops;
  final int totalJournals;
  final double totalDebit;
  final double totalCredit;
  final List<DailyImage> dailyImages;

  DashboardJournalData({
    required this.summary,
    required this.shops,
    required this.totalJournals,
    required this.totalDebit,
    required this.totalCredit,
    required this.dailyImages,
  });

  double get totalNet => totalDebit - totalCredit;
}

/// Shop summary ที่ใช้ Journal แทน DocDetails
class ShopJournalSummary {
  final String shopId;
  final String shopName;
  final double totalDebit;
  final double totalCredit;
  final int transactionCount;
  final List<Journal> journals;
  final List<DailyImage> dailyImages;

  ShopJournalSummary({
    required this.shopId,
    required this.shopName,
    required this.totalDebit,
    required this.totalCredit,
    required this.transactionCount,
    required this.journals,
    required this.dailyImages,
  });

  double get totalNet => totalDebit - totalCredit;
  double get totalAmount => totalDebit + totalCredit;

  int get imageCount =>
      dailyImages.where((image) => image.imageUrl?.isNotEmpty == true).length;

  String get workSummary {
    if (dailyImages.isEmpty) return '-';

    final categories = <String>{};
    final subcategories = <String>{};

    for (final image in dailyImages) {
      if (image.category?.isNotEmpty == true) {
        categories.add(image.category!);
      }
      if (image.subcategory?.isNotEmpty == true) {
        subcategories.add(image.subcategory!);
      }
    }

    final parts = <String>[];
    if (categories.isNotEmpty) {
      parts.add(categories.join(', '));
    }
    if (subcategories.isNotEmpty) {
      parts.add('(${subcategories.join(', ')})');
    }

    return parts.isEmpty ? '-' : parts.join(' ');
  }

  // Helper สำหรับการจัดกลุ่มตามสถานะ
  String getStatusCategory() {
    if (totalAmount < 1000000) return 'safe';
    if (totalAmount <= 1800000) return 'warning';
    return 'exceeded';
  }
}

/// Detail ของร้านเฉพาะ
class ShopJournalDetail {
  final String shopId;
  final String shopName;
  final List<Journal> journals;
  final JournalSummary? summary;
  final List<DailyImage> dailyImages;
  final Pagination? pagination;

  ShopJournalDetail({
    required this.shopId,
    required this.shopName,
    required this.journals,
    this.summary,
    required this.dailyImages,
    this.pagination,
  });
}
