import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';

/// Model for shop summary data from multi-shop-summary API
class ShopSummary {
  final String shopCode;
  final String shopName;
  final double totalDebit;
  final double totalCredit;
  final double netAmount;
  final int transactionCount;
  final String? lastTransactionDate;
  final double? dailyAverage;
  final double? monthlyAverage;
  final double? yearlyAverage;
  final int? imageCount;

  ShopSummary({
    required this.shopCode,
    required this.shopName,
    required this.totalDebit,
    required this.totalCredit,
    required this.netAmount,
    required this.transactionCount,
    this.lastTransactionDate,
    this.dailyAverage,
    this.monthlyAverage,
    this.yearlyAverage,
    this.imageCount,
  });

  factory ShopSummary.fromJson(Map<String, dynamic> json) {
    return ShopSummary(
      shopCode:
          json['shopid']?.toString() ??
          json['shop_code']?.toString() ??
          json['shopCode']?.toString() ??
          '',
      shopName:
          json['shopname']?.toString() ??
          json['shop_name']?.toString() ??
          json['shopName']?.toString() ??
          'ไม่ระบุชื่อ',
      totalDebit: _parseDouble(json['total_debit'] ?? json['totalDebit']),
      totalCredit: _parseDouble(json['total_credit'] ?? json['totalCredit']),
      netAmount: _parseDouble(json['net_amount'] ?? json['netAmount']),
      transactionCount: _parseInt(
        json['transaction_count'] ?? json['transactionCount'],
      ),
      lastTransactionDate:
          json['last_transaction_date']?.toString() ??
          json['lastTransactionDate']?.toString(),
      dailyAverage: _parseDouble(json['dailyaverage'] ?? json['daily_average']),
      monthlyAverage: _parseDouble(
        json['monthlyaverage'] ?? json['monthly_average'],
      ),
      yearlyAverage: _parseDouble(
        json['yearlyaverage'] ?? json['yearly_average'],
      ),
      imageCount: _parseInt(json['imagecount'] ?? json['image_count']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// Response wrapper for multi-shop summary API
class MultiShopSummaryResponse {
  final bool success;
  final String? message;
  final List<ShopSummary> shops;

  MultiShopSummaryResponse({
    required this.success,
    this.message,
    required this.shops,
  });

  factory MultiShopSummaryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<ShopSummary> shops = [];

    if (data is List) {
      shops = data.map((item) => ShopSummary.fromJson(item)).toList();
    } else if (data is Map<String, dynamic>) {
      // If data is an object with shops array
      final shopsList = data['shops'] ?? data['items'] ?? [];
      if (shopsList is List) {
        shops = shopsList.map((item) => ShopSummary.fromJson(item)).toList();
      }
    }

    return MultiShopSummaryResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      shops: shops,
    );
  }
}

/// Service to fetch multi-shop summary data from the cloud API
class MultiShopService {
  static const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';

  // Track if shop has been selected in this session
  static bool _shopSelected = false;

  // Store available shops
  static List<Map<String, dynamic>> _availableShops = [];

  /// Get list of available shops
  static Future<List<Map<String, dynamic>>> listShops() async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      log('❌ No auth token available for list-shop');
      return [];
    }

    final url = '$baseUrl/list-shop';
    log('📋 Fetching shop list from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📡 List shop response status: ${response.statusCode}');

      // Log full response for debugging (can be removed later)
      if (response.statusCode == 200) {
        log('📄 Full list shop response: ${response.body}');
      } else {
        log('❌ Error response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final shops = (data['data'] as List)
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _availableShops = shops;

          log('✅ Found ${shops.length} shops');

          // Log details of each shop for verification
          for (var i = 0; i < shops.length; i++) {
            final shop = shops[i];
            final shopId = shop['shopid'] ?? shop['shop_id'] ?? shop['id'];
            final hasNames = shop['names'] != null;
            final namesCount = hasNames ? (shop['names'] as List).length : 0;
            log(
              '  Shop $i: ID=$shopId, hasNames=$hasNames, namesCount=$namesCount',
            );

            if (hasNames && namesCount > 0) {
              final names = shop['names'] as List;
              for (var name in names) {
                log('    - code: ${name['code']}, name: ${name['name']}');
              }
            }
          }

          return shops;
        }
      }

      log('❌ Failed to get shop list');
      return [];
    } catch (e) {
      log('💥 Error fetching shop list: $e');
      return [];
    }
  }

  /// Select shop before calling other APIs
  static Future<bool> selectShop({String? shopId}) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      log('❌ No auth token available for select-shop');
      return false;
    }

    // If no shopId provided, get from list-shop first
    String? selectedShopId = shopId;
    if (selectedShopId == null || selectedShopId.isEmpty) {
      if (_availableShops.isEmpty) {
        await listShops();
      }
      if (_availableShops.isNotEmpty) {
        // Get first shop's ID - try different possible field names
        final firstShop = _availableShops.first;
        selectedShopId =
            firstShop['shopid']?.toString() ??
            firstShop['shop_id']?.toString() ??
            firstShop['id']?.toString();
        log('🏪 Using first shop: $selectedShopId');
      }
    }

    if (selectedShopId == null || selectedShopId.isEmpty) {
      log('❌ No shop ID available to select');
      return false;
    }

    final url = '$baseUrl/select-shop';
    log('🏪 Selecting shop $selectedShopId from: $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'shopid': selectedShopId}),
      );

      log('📡 Select shop response status: ${response.statusCode}');
      log('📄 Select shop response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _shopSelected = true;
          log('✅ Shop selected successfully');
          return true;
        }
      }

      log('❌ Failed to select shop');
      return false;
    } catch (e) {
      log('💥 Error selecting shop: $e');
      return false;
    }
  }

  /// Fetch multi-shop summary data
  static Future<MultiShopSummaryResponse> fetchMultiShopSummary({
    required String startDate,
    required String endDate,
    bool isRetry = false,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      log('❌ No auth token available for multi-shop API');
      throw Exception('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่');
    }

    // Check if token is expired before making request
    if (AuthRepository.isTokenExpired && !isRetry) {
      log('⏰ Token is expiring soon, refreshing before request...');
      final authRepo = AuthRepository();
      final refreshed = await authRepo.refreshTokenWithCredentials();
      if (!refreshed) {
        throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }
    }

    // Select shop first if not already selected
    if (!_shopSelected) {
      log('🏪 Shop not selected, calling select-shop first...');
      final shopSelected = await selectShop();
      if (!shopSelected) {
        log('⚠️ Could not select shop, continuing anyway...');
      }
    }

    final url =
        '$baseUrl/gl/dashboard/multi-shop-summary?startdate=$startDate&enddate=$endDate';
    log('🌐 Fetching multi-shop summary from: $url');

    try {
      log(
        '🔑 Using token for API: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📡 Response status: ${response.statusCode}');
      log(
        '📄 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if still getting "Shop not selected" error
        if (data['success'] == false &&
            data['message']?.toString().contains('Shop not selected') == true) {
          // Reset flag and retry once
          _shopSelected = false;
          log('⚠️ Shop selection expired, retrying...');
          await selectShop();
          return fetchMultiShopSummary(startDate: startDate, endDate: endDate);
        }

        log('✅ Successfully fetched multi-shop summary');
        return MultiShopSummaryResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        log('❌ Unauthorized - attempting token refresh...');

        if (!isRetry) {
          // Try to refresh token
          final authRepo = AuthRepository();
          final refreshed = await authRepo.refreshTokenWithCredentials();

          if (refreshed) {
            log('✅ Token refreshed, retrying request...');
            return fetchMultiShopSummary(
              startDate: startDate,
              endDate: endDate,
              isRetry: true,
            );
          }
        }

        throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      } else {
        log('❌ Failed to fetch multi-shop summary: ${response.statusCode}');
        throw Exception('เกิดข้อผิดพลาด: ${response.statusCode}');
      }
    } catch (e) {
      log('💥 Error fetching multi-shop summary: $e');
      rethrow;
    }
  }

  /// Reset shop selection (call on logout)
  static void resetShopSelection() {
    _shopSelected = false;
    log('🔄 Shop selection reset');
  }

  /// Get date range for current year
  static Map<String, String> getCurrentYearDateRange() {
    final now = DateTime.now();
    return {'startDate': '${now.year}-01-01', 'endDate': '${now.year}-12-31'};
  }

  /// Get date range for current month
  static Map<String, String> getCurrentMonthDateRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return {
      'startDate': _formatDate(startOfMonth),
      'endDate': _formatDate(endOfMonth),
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
