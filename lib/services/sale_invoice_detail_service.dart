import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/sale_invoice_detail.dart';

class SaleInvoiceDetailService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// GET /api/sale-invoice-details - Get all sale invoice details
  static Future<SaleInvoiceDetailResponse> getAllSaleInvoiceDetails({
    int page = 1,
    int limit = 50,
    String? branchSync,
    int? invoiceId,
    String? itemCode,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (branchSync != null) queryParams['branch_sync'] = branchSync;
    if (invoiceId != null) queryParams['invoice_id'] = invoiceId.toString();
    if (itemCode != null) queryParams['item_code'] = itemCode;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/sale-invoice-details')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching sale invoice details from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed sale invoice details data');
        
        // Handle API response structure
        if (data['success'] == true && data['data'] != null) {
          return SaleInvoiceDetailResponse(
            saleInvoiceDetails: (data['data'] as List)
                .map((json) => SaleInvoiceDetail.fromJson(json))
                .toList(),
            totalCount: data['pagination']?['total'] ?? 0,
            currentPage: data['pagination']?['page'] ?? 1,
            totalPages: data['pagination']?['pages'] ?? 1,
          );
        } else {
          return SaleInvoiceDetailResponse.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to load sale invoice details - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoice details: $e');
      rethrow;
    }
  }

  /// GET /api/sale-invoice-details/:id - Get sale invoice detail by ID
  static Future<SaleInvoiceDetail?> getSaleInvoiceDetailById(int id) async {
    final url = '$baseUrl/sale-invoice-details/$id';
    log('🌐 Fetching sale invoice detail by ID from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SaleInvoiceDetail.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load sale invoice detail - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoice detail by ID: $e');
      rethrow;
    }
  }

  /// GET /api/sale-invoice-details/branch/:branch_sync - Get details by branch
  static Future<SaleInvoiceDetailResponse> getSaleInvoiceDetailsByBranch(
    String branchSync, {
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoiceDetails(
      page: page ?? 1,
      limit: limit ?? 20,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoice-details/product/:product_code - Get details by product
  static Future<SaleInvoiceDetailResponse> getSaleInvoiceDetailsByProduct(
    String productCode, {
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoiceDetails(
      page: page ?? 1,
      limit: limit ?? 20,
      itemCode: productCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoice-details/summary/:branch_sync - Get summary by branch
  static Future<SaleInvoiceDetailSummary?> getSaleInvoiceDetailSummaryByBranch(
    String branchSync,
  ) async {
    final uri = Uri.parse('$baseUrl/sale-invoice-details/summary/$branchSync');
    log('🌐 Fetching sale invoice detail summary from: $uri');

    try {
      final response = await http.get(uri);
      log('📥 Sale invoice detail summary response status: ${response.statusCode}');
      log('📥 Sale invoice detail summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SaleInvoiceDetailSummary.fromJson(data);
      } else {
        log('❌ Failed to fetch sale invoice detail summary: ${response.statusCode}');
        throw Exception('Failed to load sale invoice detail summary: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Error fetching sale invoice detail summary: $e');
      throw Exception('Error fetching sale invoice detail summary: $e');
    }
  }

  /// GET /api/sale-invoice-details/invoice/:invoice_id - Get details by invoice ID
  static Future<SaleInvoiceDetailResponse> getDetailsByInvoiceId(
    int invoiceId, {
    int page = 1,
    int limit = 50,
  }) async {
    return getAllSaleInvoiceDetails(
      page: page,
      limit: limit,
      invoiceId: invoiceId,
    );
  }

  /// GET /api/sale-invoice-details/branch/:branch_sync - Get details by branch
  static Future<SaleInvoiceDetailResponse> getDetailsByBranch(
    String branchSync, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoiceDetails(
      page: page,
      limit: limit,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoice-details/item/:item_code - Get details by item
  static Future<SaleInvoiceDetailResponse> getDetailsByItem(
    String itemCode, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoiceDetails(
      page: page,
      limit: limit,
      itemCode: itemCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoice-details/summary/:invoice_id - Get summary for invoice
  static Future<SaleInvoiceDetailSummary?> getSummaryByInvoiceId(
      int invoiceId) async {
    final url = '$baseUrl/sale-invoice-details/summary/$invoiceId';
    log('🌐 Fetching sale invoice detail summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SaleInvoiceDetailSummary.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load sale invoice detail summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoice detail summary: $e');
      rethrow;
    }
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

  /// Get sale invoice details for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardSaleInvoiceDetailData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard sale invoice detail data...');

    try {
      final response = await getAllSaleInvoiceDetails(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final details = response.saleInvoiceDetails ?? [];

      // Group by branch
      final branchSummaries = <String, Map<String, dynamic>>{};
      // Group by item
      final itemSummaries = <String, Map<String, dynamic>>{};

      for (final detail in details) {
        final branchId = detail.branchSync ?? 'unknown';
        final branchName = detail.branchName ?? 'Unknown Branch';
        final itemCode = detail.itemCode ?? 'unknown';
        final itemName = detail.itemName ?? 'Unknown Item';

        // Branch summaries
        if (!branchSummaries.containsKey(branchId)) {
          branchSummaries[branchId] = {
            'branch_id': branchId,
            'branch_name': branchName,
            'total_quantity': 0.0,
            'total_line_amount': 0.0,
            'total_discount_amount': 0.0,
            'total_net_amount': 0.0,
            'total_vat_amount': 0.0,
            'total_amount': 0.0,
            'line_count': 0,
            'details': <SaleInvoiceDetail>[],
          };
        }

        branchSummaries[branchId]!['total_quantity'] =
            (branchSummaries[branchId]!['total_quantity'] as double) +
            (detail.quantity ?? 0);
        branchSummaries[branchId]!['total_line_amount'] =
            (branchSummaries[branchId]!['total_line_amount'] as double) +
            (detail.lineTotal ?? 0);
        branchSummaries[branchId]!['total_discount_amount'] =
            (branchSummaries[branchId]!['total_discount_amount'] as double) +
            (detail.discountAmount ?? 0);
        branchSummaries[branchId]!['total_net_amount'] =
            (branchSummaries[branchId]!['total_net_amount'] as double) +
            (detail.netAmount ?? 0);
        branchSummaries[branchId]!['total_vat_amount'] =
            (branchSummaries[branchId]!['total_vat_amount'] as double) +
            (detail.vatAmount ?? 0);
        branchSummaries[branchId]!['total_amount'] =
            (branchSummaries[branchId]!['total_amount'] as double) +
            (detail.totalAmount ?? 0);
        branchSummaries[branchId]!['line_count'] =
            (branchSummaries[branchId]!['line_count'] as int) + 1;
        (branchSummaries[branchId]!['details'] as List<SaleInvoiceDetail>)
            .add(detail);

        // Item summaries
        if (!itemSummaries.containsKey(itemCode)) {
          itemSummaries[itemCode] = {
            'item_code': itemCode,
            'item_name': itemName,
            'total_quantity': 0.0,
            'total_amount': 0.0,
            'sale_count': 0,
          };
        }

        itemSummaries[itemCode]!['total_quantity'] =
            (itemSummaries[itemCode]!['total_quantity'] as double) +
            (detail.quantity ?? 0);
        itemSummaries[itemCode]!['total_amount'] =
            (itemSummaries[itemCode]!['total_amount'] as double) +
            (detail.totalAmount ?? 0);
        itemSummaries[itemCode]!['sale_count'] =
            (itemSummaries[itemCode]!['sale_count'] as int) + 1;
      }

      return {
        'total_lines': details.length,
        'total_quantity': details.fold(0.0, (sum, d) => sum + (d.quantity ?? 0)),
        'total_line_amount': details.fold(0.0, (sum, d) => sum + (d.lineTotal ?? 0)),
        'total_discount_amount': details.fold(0.0, (sum, d) => sum + (d.discountAmount ?? 0)),
        'total_net_amount': details.fold(0.0, (sum, d) => sum + (d.netAmount ?? 0)),
        'total_vat_amount': details.fold(0.0, (sum, d) => sum + (d.vatAmount ?? 0)),
        'total_amount': details.fold(0.0, (sum, d) => sum + (d.totalAmount ?? 0)),
        'branch_summaries': branchSummaries.values.toList(),
        'item_summaries': itemSummaries.values.toList(),
        'details': details,
      };
    } catch (e) {
      log('💥 Error fetching dashboard sale invoice detail data: $e');
      rethrow;
    }
  }
}