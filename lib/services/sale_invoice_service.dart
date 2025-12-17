import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/sale_invoice.dart';

class SaleInvoiceService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// GET /api/sale-invoices - Get all sale invoices
  static Future<SaleInvoiceResponse> getAllSaleInvoices({
    int page = 1,
    int limit = 50,
    String? branchSync,
    String? startDate,
    String? endDate,
    String? status,
    String? paymentStatus,
    String? customerCode,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (branchSync != null) queryParams['branch_sync'] = branchSync;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (status != null) queryParams['status'] = status;
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (customerCode != null) queryParams['customer_code'] = customerCode;

    final uri = Uri.parse('$baseUrl/sale-invoices')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching sale invoices from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed sale invoices data');
        
        // Handle API response structure
        if (data['success'] == true && data['data'] != null) {
          return SaleInvoiceResponse(
            saleInvoices: (data['data'] as List)
                .map((json) => SaleInvoice.fromJson(json))
                .toList(),
            totalCount: data['pagination']?['total'] ?? 0,
            currentPage: data['pagination']?['page'] ?? 1,
            totalPages: data['pagination']?['pages'] ?? 1,
          );
        } else {
          return SaleInvoiceResponse.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to load sale invoices - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoices: $e');
      rethrow;
    }
  }

  /// GET /api/sale-invoices/:id - Get sale invoice by ID
  static Future<SaleInvoice?> getSaleInvoiceById(int id) async {
    final url = '$baseUrl/sale-invoices/$id';
    log('🌐 Fetching sale invoice by ID from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SaleInvoice.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load sale invoice - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoice by ID: $e');
      rethrow;
    }
  }

  /// GET /api/sale-invoices/branch/:branch_sync - Get sale invoices by branch
  static Future<SaleInvoiceResponse> getSaleInvoicesByBranch(
    String branchSync, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoices(
      page: page,
      limit: limit,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoices/summary/:branch_sync - Get sale invoice summary by branch
  static Future<SaleInvoiceSummary?> getSaleInvoiceSummaryByBranch(
      String branchSync) async {
    final url = '$baseUrl/sale-invoices/summary/$branchSync';
    log('🌐 Fetching sale invoice summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SaleInvoiceSummary.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load sale invoice summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching sale invoice summary: $e');
      rethrow;
    }
  }

  /// GET /api/sale-invoices/customer/:customer_code - Get sale invoices by customer
  static Future<SaleInvoiceResponse> getSaleInvoicesByCustomer(
    String customerCode, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllSaleInvoices(
      page: page,
      limit: limit,
      customerCode: customerCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/sale-invoices/overdue - Get overdue invoices
  static Future<SaleInvoiceResponse> getOverdueInvoices({
    int page = 1,
    int limit = 50,
    String? branchSync,
  }) async {
    return getAllSaleInvoices(
      page: page,
      limit: limit,
      branchSync: branchSync,
      paymentStatus: 'overdue',
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

  /// Get sale invoices for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardSaleInvoiceData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard sale invoice data...');

    try {
      final response = await getAllSaleInvoices(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final saleInvoices = response.saleInvoices ?? [];

      // Group by branch
      final branchSummaries = <String, Map<String, dynamic>>{};
      final statusSummaries = <String, Map<String, dynamic>>{};

      for (final invoice in saleInvoices) {
        final branchId = invoice.branchSync ?? 'unknown';
        final branchName = invoice.branchName ?? 'Unknown Branch';
        final paymentStatus = invoice.paymentStatus ?? 'unknown';

        // Branch summaries
        if (!branchSummaries.containsKey(branchId)) {
          branchSummaries[branchId] = {
            'branch_id': branchId,
            'branch_name': branchName,
            'total_net_amount': 0.0,
            'total_vat_amount': 0.0,
            'total_amount': 0.0,
            'total_discount_amount': 0.0,
            'invoice_count': 0,
            'invoices': <SaleInvoice>[],
          };
        }

        branchSummaries[branchId]!['total_net_amount'] =
            (branchSummaries[branchId]!['total_net_amount'] as double) +
            (invoice.netAmount ?? 0);
        branchSummaries[branchId]!['total_vat_amount'] =
            (branchSummaries[branchId]!['total_vat_amount'] as double) +
            (invoice.vatAmount ?? 0);
        branchSummaries[branchId]!['total_amount'] =
            (branchSummaries[branchId]!['total_amount'] as double) +
            (invoice.totalAmount ?? 0);
        branchSummaries[branchId]!['total_discount_amount'] =
            (branchSummaries[branchId]!['total_discount_amount'] as double) +
            (invoice.discountAmount ?? 0);
        branchSummaries[branchId]!['invoice_count'] =
            (branchSummaries[branchId]!['invoice_count'] as int) + 1;
        (branchSummaries[branchId]!['invoices'] as List<SaleInvoice>)
            .add(invoice);

        // Payment status summaries
        if (!statusSummaries.containsKey(paymentStatus)) {
          statusSummaries[paymentStatus] = {
            'status': paymentStatus,
            'total_amount': 0.0,
            'count': 0,
          };
        }

        statusSummaries[paymentStatus]!['total_amount'] =
            (statusSummaries[paymentStatus]!['total_amount'] as double) +
            (invoice.totalAmount ?? 0);
        statusSummaries[paymentStatus]!['count'] =
            (statusSummaries[paymentStatus]!['count'] as int) + 1;
      }

      return {
        'total_invoices': saleInvoices.length,
        'total_net_amount':
            saleInvoices.fold(0.0, (sum, i) => sum + (i.netAmount ?? 0)),
        'total_vat_amount':
            saleInvoices.fold(0.0, (sum, i) => sum + (i.vatAmount ?? 0)),
        'total_amount':
            saleInvoices.fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0)),
        'total_discount_amount':
            saleInvoices.fold(0.0, (sum, i) => sum + (i.discountAmount ?? 0)),
        'branch_summaries': branchSummaries.values.toList(),
        'status_summaries': statusSummaries.values.toList(),
        'sale_invoices': saleInvoices,
      };
    } catch (e) {
      log('💥 Error fetching dashboard sale invoice data: $e');
      rethrow;
    }
  }
}
