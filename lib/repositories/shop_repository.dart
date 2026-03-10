import 'dart:async';
import 'dart:developer';
import '../core/errors/app_exception.dart';
import '../models/daily_images.dart';
import '../models/doc_details.dart';
import '../services/api_service.dart';
import '../services/auth_repository.dart';
import '../services/dashboard_service.dart';
import '../services/multi_shop_service.dart';

/// Repository layer that abstracts all shop/dashboard data sources.
///
/// DashboardBloc must talk to this class — never to services directly.
/// This keeps the BLoC unit-testable by allowing the repository to be mocked.
class ShopRepository {
  /// Fetch all shops with summary stats.
  ///
  /// When [startDate]/[endDate] are provided, the multi-shop-summary API is
  /// called with that range; otherwise the current calendar year is used.
  ///
  /// Falls back to the local [DashboardService] when the cloud API is
  /// unavailable or when the user is not authenticated.
  Future<List<DocDetails>> fetchShopsSummary({
    String? startDate,
    String? endDate,
  }) async {
    if (!AuthRepository.isAuthenticated) {
      log('📦 Not authenticated → using local DashboardService');
      return _localFallback();
    }

    try {
      // Step 1: fetch shop names in parallel with nothing yet
      log('📋 Fetching shop name list...');
      final shopList = await MultiShopService.listShops();
      final shopNamesMap = _buildNamesMap(shopList);

      // Step 2: fetch summary
      final range = (startDate != null && endDate != null)
          ? {'startDate': startDate, 'endDate': endDate}
          : MultiShopService.getCurrentYearDateRange();

      log('📊 Fetching shop summary ${range['startDate']} → ${range['endDate']}');
      final response = await MultiShopService.fetchMultiShopSummary(
        startDate: range['startDate']!,
        endDate: range['endDate']!,
      );

      if (response.success && response.shops.isNotEmpty) {
        final shops = response.shops.map((shop) {
          return DocDetails(
            shopid: shop.shopCode,
            shopname: shop.shopName,
            names: shopNamesMap[shop.shopCode],
            daily: [],
            monthlySummary: {
              'total': MonthlyData(
                deposit: shop.totalCredit,
                withdraw: shop.totalDebit,
              ),
            },
            responsible: ResponsiblePerson(name: 'ระบบ', role: 'system'),
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            timezone: 'Asia/Bangkok',
            dailyImages: [],
            dailyTransactions: [],
            dailyAverage: shop.dailyAverage,
            monthlyAverage: shop.monthlyAverage,
            yearlyAverage: shop.yearlyAverage,
            localImageCount: shop.imageCount,
          );
        }).toList();

        log('✅ ShopRepository: loaded ${shops.length} shops from cloud API');
        return shops;
      }
    } on TimeoutException {
      log('⚠️ ShopRepository: cloud API timed out → local fallback');
    } catch (e) {
      log('⚠️ ShopRepository: cloud API error → local fallback: $e');
    }

    return _localFallback();
  }

  /// Fetch daily images for a specific shop.
  Future<List<DailyImage>> fetchShopDaily(String shopId) async {
    try {
      return await ApiService.fetchShopDaily(shopId);
    } catch (e) {
      throw wrapException(e);
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<List<DocDetails>> _localFallback() async {
    log('📦 ShopRepository: using local DashboardService');
    return DashboardService.fetchDashboardData();
  }

  Map<String, List<ShopName>> _buildNamesMap(
    List<Map<String, dynamic>> shopList,
  ) {
    final map = <String, List<ShopName>>{};
    for (final shop in shopList) {
      final shopId = shop['shopid']?.toString() ??
          shop['shop_id']?.toString() ??
          shop['id']?.toString();
      if (shopId != null && shop['names'] != null) {
        try {
          map[shopId] = (shop['names'] as List)
              .map((n) => ShopName.fromJson(n as Map<String, dynamic>))
              .toList();
        } catch (e) {
          log('⚠️ Error parsing names for shop $shopId: $e');
        }
      }
    }
    return map;
  }
}
