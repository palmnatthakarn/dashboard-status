import '../models/models_exports.dart';

class PurchaseHelper {
  /// Calculate total net amount for purchases
  static double calculateTotalNetAmount(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, purchase) => sum + (purchase.purchaseAmount ?? 0.0));
  }

  /// Calculate total VAT amount for purchases
  static double calculateTotalVatAmount(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, purchase) => sum + (purchase.vatAmount ?? 0.0));
  }

  /// Calculate total amount for purchases
  static double calculateTotalAmount(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, purchase) => sum + (purchase.totalAmount ?? 0.0));
  }

  /// Group purchases by branch
  static Map<String, List<Purchase>> groupPurchasesByBranch(List<Purchase> purchases) {
    final Map<String, List<Purchase>> grouped = {};
    
    for (final purchase in purchases) {
      final branchId = purchase.branchSync ?? 'unknown';
      if (!grouped.containsKey(branchId)) {
        grouped[branchId] = [];
      }
      grouped[branchId]!.add(purchase);
    }
    
    return grouped;
  }

  /// Group purchases by vendor
  static Map<String, List<Purchase>> groupPurchasesByVendor(List<Purchase> purchases) {
    final Map<String, List<Purchase>> grouped = {};
    
    for (final purchase in purchases) {
      final vendorCode = purchase.vendorCode ?? 'unknown';
      if (!grouped.containsKey(vendorCode)) {
        grouped[vendorCode] = [];
      }
      grouped[vendorCode]!.add(purchase);
    }
    
    return grouped;
  }

  /// Group purchases by status
  static Map<String, List<Purchase>> groupPurchasesByStatus(List<Purchase> purchases) {
    final Map<String, List<Purchase>> grouped = {};
    
    for (final purchase in purchases) {
      final status = purchase.status ?? 'unknown';
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(purchase);
    }
    
    return grouped;
  }

  /// Filter purchases by date range
  static List<Purchase> filterPurchasesByDateRange(
    List<Purchase> purchases,
    DateTime startDate,
    DateTime endDate,
  ) {
    return purchases.where((purchase) {
      if (purchase.docDatetime == null) return false;
      
      try {
        final docDate = DateTime.parse(purchase.docDatetime!);
        return docDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               docDate.isBefore(endDate.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Get purchase count by status
  static int getPurchaseCountByStatus(List<Purchase> purchases, String status) {
    return purchases.where((purchase) => 
      purchase.status?.toUpperCase() == status.toUpperCase()
    ).length;
  }

  /// Calculate average purchase amount
  static double calculateAveragePurchaseAmount(List<Purchase> purchases) {
    if (purchases.isEmpty) return 0.0;
    final totalAmount = calculateTotalAmount(purchases);
    return totalAmount / purchases.length;
  }

  /// Get top vendors by amount
  static List<Map<String, dynamic>> getTopVendorsByAmount(
    List<Purchase> purchases, {
    int limit = 10,
  }) {
    final vendorTotals = <String, Map<String, dynamic>>{};
    
    for (final purchase in purchases) {
      final vendorCode = purchase.vendorCode ?? 'unknown';
      final vendorName = purchase.vendorName ?? 'Unknown Vendor';
      
      if (!vendorTotals.containsKey(vendorCode)) {
        vendorTotals[vendorCode] = {
          'vendor_code': vendorCode,
          'vendor_name': vendorName,
          'total_amount': 0.0,
          'purchase_count': 0,
        };
      }
      
      vendorTotals[vendorCode]!['total_amount'] += (purchase.totalAmount ?? 0.0);
      vendorTotals[vendorCode]!['purchase_count']++;
    }
    
    final sortedVendors = vendorTotals.values.toList()
      ..sort((a, b) => b['total_amount'].compareTo(a['total_amount']));
    
    return sortedVendors.take(limit).toList();
  }

  /// Get purchase statistics
  static Map<String, dynamic> getPurchaseStatistics(List<Purchase> purchases) {
    final activePurchases = purchases.where((p) => p.status?.toLowerCase() == 'active').toList();
    final cancelledPurchases = purchases.where((p) => p.status?.toLowerCase() == 'cancelled').toList();
    final pendingPurchases = purchases.where((p) => p.status?.toLowerCase() == 'pending').toList();
    
    return {
      'total_purchases': purchases.length,
      'active_purchases': activePurchases.length,
      'cancelled_purchases': cancelledPurchases.length,
      'pending_purchases': pendingPurchases.length,
      'total_purchase_amount': calculateTotalNetAmount(purchases),
      'total_vat_amount': calculateTotalVatAmount(purchases),
      'total_amount': calculateTotalAmount(purchases),
      'average_amount': calculateAveragePurchaseAmount(purchases),
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