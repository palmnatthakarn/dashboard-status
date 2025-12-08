import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/purchase.dart';

class PurchaseService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// GET /api/purchases - Get all purchases
  static Future<PurchaseResponse> getAllPurchases({
    int page = 1,
    int limit = 50,
    String? branchSync,
    String? startDate,
    String? endDate,
    String? status,
    String? vendorCode,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (branchSync != null) queryParams['branch_sync'] = branchSync;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (status != null) queryParams['status'] = status;
    if (vendorCode != null) queryParams['vendor_code'] = vendorCode;

    final uri = Uri.parse('$baseUrl/purchases')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching purchases from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed purchases data');
        
        // Handle API response structure
        if (data['success'] == true && data['data'] != null) {
          return PurchaseResponse(
            purchases: (data['data'] as List)
                .map((json) => Purchase.fromJson(json))
                .toList(),
            totalCount: data['pagination']?['total'] ?? 0,
            currentPage: data['pagination']?['page'] ?? 1,
            totalPages: data['pagination']?['pages'] ?? 1,
          );
        } else {
          return PurchaseResponse.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to load purchases - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching purchases: $e');
      rethrow;
    }
  }

  /// GET /api/purchases/:id - Get purchase by ID
  static Future<Purchase?> getPurchaseById(int id) async {
    final url = '$baseUrl/purchases/$id';
    log('🌐 Fetching purchase by ID from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Purchase.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load purchase - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching purchase by ID: $e');
      rethrow;
    }
  }

  /// GET /api/purchases/branch/:branch_sync - Get purchases by branch
  static Future<PurchaseResponse> getPurchasesByBranch(
    String branchSync, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllPurchases(
      page: page,
      limit: limit,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/purchases/summary/:branch_sync - Get purchase summary by branch
  static Future<PurchaseSummary?> getPurchaseSummaryByBranch(
      String branchSync) async {
    final url = '$baseUrl/purchases/summary/$branchSync';
    log('🌐 Fetching purchase summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PurchaseSummary.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load purchase summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching purchase summary: $e');
      rethrow;
    }
  }

  /// GET /api/purchases/vendor/:vendor_code - Get purchases by vendor
  static Future<PurchaseResponse> getPurchasesByVendor(
    String vendorCode, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllPurchases(
      page: page,
      limit: limit,
      vendorCode: vendorCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Helper method สำหรับ format date
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Helper method สำหรับ parse date
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      log('💥 Error parsing date: $dateString');
      return null;
    }
  }

  /// Get purchases for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardPurchaseData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard purchase data...');

    try {
      final response = await getAllPurchases(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final purchases = response.purchases ?? [];

      // Group by branch
      final branchSummaries = <String, Map<String, dynamic>>{};

      for (final purchase in purchases) {
        final branchId = purchase.branchSync ?? 'unknown';
        final branchName = purchase.branchSync ?? 'Unknown Branch';

        if (!branchSummaries.containsKey(branchId)) {
          branchSummaries[branchId] = {
            'branch_id': branchId,
            'branch_name': branchName,
            'total_net_amount': 0.0,
            'total_vat_amount': 0.0,
            'total_amount': 0.0,
            'purchase_count': 0,
            'purchases': <Purchase>[],
          };
        }

        branchSummaries[branchId]!['total_net_amount'] =
            (branchSummaries[branchId]!['total_net_amount'] as double) +
            (purchase.purchaseAmount ?? 0);
        branchSummaries[branchId]!['total_vat_amount'] =
            (branchSummaries[branchId]!['total_vat_amount'] as double) +
            (purchase.vatAmount ?? 0);
        branchSummaries[branchId]!['total_amount'] =
            (branchSummaries[branchId]!['total_amount'] as double) +
            (purchase.totalAmount ?? 0);
        branchSummaries[branchId]!['purchase_count'] =
            (branchSummaries[branchId]!['purchase_count'] as int) + 1;
        (branchSummaries[branchId]!['purchases'] as List<Purchase>)
            .add(purchase);
      }

      return {
        'total_purchases': purchases.length,
        'total_net_amount':
            purchases.fold(0.0, (sum, p) => sum + (p.purchaseAmount ?? 0)),
        'total_vat_amount':
            purchases.fold(0.0, (sum, p) => sum + (p.vatAmount ?? 0)),
        'total_amount':
            purchases.fold(0.0, (sum, p) => sum + (p.totalAmount ?? 0)),
        'branch_summaries': branchSummaries.values.toList(),
        'purchases': purchases,
      };
    } catch (e) {
      log('💥 Error fetching dashboard purchase data: $e');
      rethrow;
    }
  }
}