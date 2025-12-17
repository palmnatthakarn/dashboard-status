import '../models/models_exports.dart';

class PaymentHelper {
  /// Calculate total payment amount
  static double calculateTotalPaymentAmount(List<Payment> payments) {
    return payments.fold(0.0, (sum, payment) => sum + (payment.paymentAmount ?? 0.0));
  }

  /// Calculate total discount amount
  static double calculateTotalDiscountAmount(List<Payment> payments) {
    return payments.fold(0.0, (sum, payment) => sum + (payment.discountAmount ?? 0.0));
  }

  /// Calculate total net amount
  static double calculateTotalNetAmount(List<Payment> payments) {
    return payments.fold(0.0, (sum, payment) => sum + (payment.netAmount ?? 0.0));
  }

  /// Group payments by branch
  static Map<String, List<Payment>> groupPaymentsByBranch(List<Payment> payments) {
    final Map<String, List<Payment>> grouped = {};
    
    for (final payment in payments) {
      final branchId = payment.branchSync ?? 'unknown';
      if (!grouped.containsKey(branchId)) {
        grouped[branchId] = [];
      }
      grouped[branchId]!.add(payment);
    }
    
    return grouped;
  }

  /// Group payments by payment method
  static Map<String, List<Payment>> groupPaymentsByMethod(List<Payment> payments) {
    final Map<String, List<Payment>> grouped = {};
    
    for (final payment in payments) {
      final method = payment.paymentMethod ?? 'unknown';
      if (!grouped.containsKey(method)) {
        grouped[method] = [];
      }
      grouped[method]!.add(payment);
    }
    
    return grouped;
  }

  /// Group payments by status
  static Map<String, List<Payment>> groupPaymentsByStatus(List<Payment> payments) {
    final Map<String, List<Payment>> grouped = {};
    
    for (final payment in payments) {
      final status = payment.status ?? 'unknown';
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(payment);
    }
    
    return grouped;
  }

  /// Filter payments by date range
  static List<Payment> filterPaymentsByDateRange(
    List<Payment> payments,
    DateTime startDate,
    DateTime endDate,
  ) {
    return payments.where((payment) {
      if (payment.docDatetime == null) return false;
      
      try {
        final docDate = DateTime.parse(payment.docDatetime!);
        return docDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               docDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Get payment count by status
  static int getPaymentCountByStatus(List<Payment> payments, String status) {
    return payments.where((payment) => 
      payment.status?.toUpperCase() == status.toUpperCase()
    ).length;
  }

  /// Get payment count by method
  static int getPaymentCountByMethod(List<Payment> payments, String method) {
    return payments.where((payment) => 
      payment.paymentMethod?.toUpperCase() == method.toUpperCase()
    ).length;
  }

  /// Calculate average payment amount
  static double calculateAveragePaymentAmount(List<Payment> payments) {
    if (payments.isEmpty) return 0.0;
    final totalAmount = calculateTotalPaymentAmount(payments);
    return totalAmount / payments.length;
  }

  /// Get payment method statistics
  static Map<String, dynamic> getPaymentMethodStatistics(List<Payment> payments) {
    final methodStats = <String, Map<String, dynamic>>{};
    
    for (final payment in payments) {
      final method = payment.paymentMethod ?? 'unknown';
      
      if (!methodStats.containsKey(method)) {
        methodStats[method] = {
          'method': method,
          'count': 0,
          'total_amount': 0.0,
          'total_discount': 0.0,
        };
      }
      
      methodStats[method]!['count']++;
      methodStats[method]!['total_amount'] += (payment.paymentAmount ?? 0.0);
      methodStats[method]!['total_discount'] += (payment.discountAmount ?? 0.0);
    }
    
    return {
      'methods': methodStats.values.toList(),
      'total_methods': methodStats.length,
    };
  }

  /// Get top vendors by payment amount
  static List<Map<String, dynamic>> getTopVendorsByPaymentAmount(
    List<Payment> payments, {
    int limit = 10,
  }) {
    final vendorTotals = <String, Map<String, dynamic>>{};
    
    for (final payment in payments) {
      final vendorCode = payment.vendorCode ?? 'unknown';
      final vendorName = payment.vendorName ?? 'Unknown Vendor';
      
      if (!vendorTotals.containsKey(vendorCode)) {
        vendorTotals[vendorCode] = {
          'vendor_code': vendorCode,
          'vendor_name': vendorName,
          'total_payment_amount': 0.0,
          'payment_count': 0,
        };
      }
      
      vendorTotals[vendorCode]!['total_payment_amount'] += (payment.paymentAmount ?? 0.0);
      vendorTotals[vendorCode]!['payment_count']++;
    }
    
    final sortedVendors = vendorTotals.values.toList()
      ..sort((a, b) => b['total_payment_amount'].compareTo(a['total_payment_amount']));
    
    return sortedVendors.take(limit).toList();
  }

  /// Get payment statistics
  static Map<String, dynamic> getPaymentStatistics(List<Payment> payments) {
    final paidPayments = payments.where((p) => p.isPaid).toList();
    final pendingPayments = payments.where((p) => p.isPending).toList();
    final cancelledPayments = payments.where((p) => p.isCancelled).toList();
    final refundedPayments = payments.where((p) => p.isRefunded).toList();
    
    return {
      'total_payments': payments.length,
      'paid_payments': paidPayments.length,
      'pending_payments': pendingPayments.length,
      'cancelled_payments': cancelledPayments.length,
      'refunded_payments': refundedPayments.length,
      'total_payment_amount': calculateTotalPaymentAmount(payments),
      'total_discount_amount': calculateTotalDiscountAmount(payments),
      'total_net_amount': calculateTotalNetAmount(payments),
      'average_payment_amount': calculateAveragePaymentAmount(payments),
      'method_statistics': getPaymentMethodStatistics(payments),
    };
  }

  /// Format currency for display
  static String formatCurrency(double amount, {String symbol = '฿'}) {
    return '$symbol${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Parse date string
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
