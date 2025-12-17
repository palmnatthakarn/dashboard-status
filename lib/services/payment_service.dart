import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/payment.dart';

class PaymentService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// GET /api/payments - Get all payments
  static Future<PaymentResponse> getAllPayments({
    int page = 1,
    int limit = 50,
    String? branchSync,
    String? startDate,
    String? endDate,
    String? status,
    String? paymentMethod,
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
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (vendorCode != null) queryParams['vendor_code'] = vendorCode;

    final uri = Uri.parse('$baseUrl/payments')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching payments from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed payments data');
        
        // Handle API response structure
        if (data['success'] == true && data['data'] != null) {
          return PaymentResponse(
            payments: (data['data'] as List)
                .map((json) => Payment.fromJson(json))
                .toList(),
            totalCount: data['pagination']?['total'] ?? 0,
            currentPage: data['pagination']?['page'] ?? 1,
            totalPages: data['pagination']?['pages'] ?? 1,
          );
        } else {
          return PaymentResponse.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to load payments - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching payments: $e');
      rethrow;
    }
  }

  /// GET /api/payments/:id - Get payment by ID
  static Future<Payment?> getPaymentById(int id) async {
    final url = '$baseUrl/payments/$id';
    log('🌐 Fetching payment by ID from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load payment - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching payment by ID: $e');
      rethrow;
    }
  }

  /// GET /api/payments/branch/:branch_sync - Get payments by branch
  static Future<PaymentResponse> getPaymentsByBranch(
    String branchSync, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllPayments(
      page: page,
      limit: limit,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/payments/summary/:branch_sync - Get payment summary by branch
  static Future<PaymentSummary?> getPaymentSummaryByBranch(
      String branchSync) async {
    final url = '$baseUrl/payments/summary/$branchSync';
    log('🌐 Fetching payment summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PaymentSummary.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load payment summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching payment summary: $e');
      rethrow;
    }
  }

  /// GET /api/payments/method/:payment_method - Get payments by payment method
  static Future<PaymentResponse> getPaymentsByMethod(
    String paymentMethod, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllPayments(
      page: page,
      limit: limit,
      paymentMethod: paymentMethod,
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

  /// Get payments for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardPaymentData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard payment data...');

    try {
      final response = await getAllPayments(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final payments = response.payments ?? [];

      // Group by branch
      final branchSummaries = <String, Map<String, dynamic>>{};
      final methodSummaries = <String, Map<String, dynamic>>{};

      for (final payment in payments) {
        final branchId = payment.branchSync ?? 'unknown';
        final branchName = payment.branchName ?? 'Unknown Branch';
        final method = payment.paymentMethod ?? 'unknown';

        // Branch summaries
        if (!branchSummaries.containsKey(branchId)) {
          branchSummaries[branchId] = {
            'branch_id': branchId,
            'branch_name': branchName,
            'total_payment_amount': 0.0,
            'total_discount_amount': 0.0,
            'total_net_amount': 0.0,
            'payment_count': 0,
            'payments': <Payment>[],
          };
        }

        branchSummaries[branchId]!['total_payment_amount'] =
            (branchSummaries[branchId]!['total_payment_amount'] as double) +
            (payment.paymentAmount ?? 0);
        branchSummaries[branchId]!['total_discount_amount'] =
            (branchSummaries[branchId]!['total_discount_amount'] as double) +
            (payment.discountAmount ?? 0);
        branchSummaries[branchId]!['total_net_amount'] =
            (branchSummaries[branchId]!['total_net_amount'] as double) +
            (payment.netAmount ?? 0);
        branchSummaries[branchId]!['payment_count'] =
            (branchSummaries[branchId]!['payment_count'] as int) + 1;
        (branchSummaries[branchId]!['payments'] as List<Payment>)
            .add(payment);

        // Method summaries
        if (!methodSummaries.containsKey(method)) {
          methodSummaries[method] = {
            'method': method,
            'total_amount': 0.0,
            'count': 0,
          };
        }

        methodSummaries[method]!['total_amount'] =
            (methodSummaries[method]!['total_amount'] as double) +
            (payment.paymentAmount ?? 0);
        methodSummaries[method]!['count'] =
            (methodSummaries[method]!['count'] as int) + 1;
      }

      return {
        'total_payments': payments.length,
        'total_payment_amount':
            payments.fold(0.0, (sum, p) => sum + (p.paymentAmount ?? 0)),
        'total_discount_amount':
            payments.fold(0.0, (sum, p) => sum + (p.discountAmount ?? 0)),
        'total_net_amount':
            payments.fold(0.0, (sum, p) => sum + (p.netAmount ?? 0)),
        'branch_summaries': branchSummaries.values.toList(),
        'method_summaries': methodSummaries.values.toList(),
        'payments': payments,
      };
    } catch (e) {
      log('💥 Error fetching dashboard payment data: $e');
      rethrow;
    }
  }
}
