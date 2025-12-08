import '../models/sale_invoice.dart';

class SaleInvoiceHelper {
  /// Format sale invoice amount for display
  static String formatAmount(double? amount) {
    if (amount == null) return '0.00';
    return amount.toStringAsFixed(2);
  }

  /// Format sale invoice display text
  static String formatSaleInvoiceDisplay(SaleInvoice saleInvoice) {
    final docNo = saleInvoice.docNo ?? 'N/A';
    final customerName = saleInvoice.customerName ?? 'Unknown Customer';
    final amount = formatAmount(saleInvoice.totalAmount);
    
    return '$docNo - $customerName (฿$amount)';
  }

  /// Calculate total amount including VAT
  static double calculateTotalWithVat(SaleInvoice saleInvoice) {
    final netAmount = saleInvoice.netAmount ?? 0.0;
    final vatAmount = saleInvoice.vatAmount ?? 0.0;
    return netAmount + vatAmount;
  }

  /// Get status color based on sale invoice status
  static String getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'completed':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      case 'draft':
        return '#9E9E9E'; // Gray
      default:
        return '#2196F3'; // Blue
    }
  }

  /// Check if sale invoice is overdue (example: 30 days from doc date)
  static bool isOverdue(SaleInvoice saleInvoice) {
    if (saleInvoice.docDatetime == null) return false;
    
    try {
      final docDate = DateTime.parse(saleInvoice.docDatetime!);
      final now = DateTime.now();
      final difference = now.difference(docDate).inDays;
      
      return difference > 30; // Assuming 30 days payment term
    } catch (e) {
      return false;
    }
  }

  /// Group sale invoices by customer
  static Map<String, List<SaleInvoice>> groupByCustomer(List<SaleInvoice> saleInvoices) {
    final Map<String, List<SaleInvoice>> grouped = {};
    
    for (final saleInvoice in saleInvoices) {
      final customerKey = saleInvoice.customerCode ?? 'Unknown';
      grouped[customerKey] ??= [];
      grouped[customerKey]!.add(saleInvoice);
    }
    
    return grouped;
  }

  /// Calculate summary statistics for sale invoices
  static SaleInvoiceSummaryStats calculateSummary(List<SaleInvoice> saleInvoices) {
    double totalAmount = 0.0;
    double totalNetAmount = 0.0;
    double totalVatAmount = 0.0;
    int totalCount = saleInvoices.length;
    
    for (final saleInvoice in saleInvoices) {
      totalAmount += saleInvoice.totalAmount ?? 0.0;
      totalNetAmount += saleInvoice.netAmount ?? 0.0;
      totalVatAmount += saleInvoice.vatAmount ?? 0.0;
    }
    
    return SaleInvoiceSummaryStats(
      totalAmount: totalAmount,
      totalNetAmount: totalNetAmount,
      totalVatAmount: totalVatAmount,
      totalCount: totalCount,
      averageAmount: totalCount > 0 ? totalAmount / totalCount : 0.0,
    );
  }

  /// Filter sale invoices by date range
  static List<SaleInvoice> filterByDateRange(
    List<SaleInvoice> saleInvoices,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return saleInvoices;
    
    return saleInvoices.where((saleInvoice) {
      if (saleInvoice.docDatetime == null) return false;
      
      try {
        final docDate = DateTime.parse(saleInvoice.docDatetime!);
        
        if (startDate != null && docDate.isBefore(startDate)) return false;
        if (endDate != null && docDate.isAfter(endDate)) return false;
        
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Sort sale invoices by various criteria
  static List<SaleInvoice> sortSaleInvoices(
    List<SaleInvoice> saleInvoices,
    SaleInvoiceSortCriteria criteria, {
    bool ascending = true,
  }) {
    final sortedList = List<SaleInvoice>.from(saleInvoices);
    
    switch (criteria) {
      case SaleInvoiceSortCriteria.docNo:
        sortedList.sort((a, b) => ascending 
          ? (a.docNo ?? '').compareTo(b.docNo ?? '')
          : (b.docNo ?? '').compareTo(a.docNo ?? ''));
        break;
      case SaleInvoiceSortCriteria.customerName:
        sortedList.sort((a, b) => ascending
          ? (a.customerName ?? '').compareTo(b.customerName ?? '')
          : (b.customerName ?? '').compareTo(a.customerName ?? ''));
        break;
      case SaleInvoiceSortCriteria.totalAmount:
        sortedList.sort((a, b) => ascending
          ? (a.totalAmount ?? 0).compareTo(b.totalAmount ?? 0)
          : (b.totalAmount ?? 0).compareTo(a.totalAmount ?? 0));
        break;
      case SaleInvoiceSortCriteria.docDatetime:
        sortedList.sort((a, b) {
          final dateA = DateTime.tryParse(a.docDatetime ?? '');
          final dateB = DateTime.tryParse(b.docDatetime ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return ascending ? -1 : 1;
          if (dateB == null) return ascending ? 1 : -1;
          return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
    }
    
    return sortedList;
  }
}

class SaleInvoiceSummaryStats {
  final double totalAmount;
  final double totalNetAmount;
  final double totalVatAmount;
  final int totalCount;
  final double averageAmount;

  SaleInvoiceSummaryStats({
    required this.totalAmount,
    required this.totalNetAmount,
    required this.totalVatAmount,
    required this.totalCount,
    required this.averageAmount,
  });
}

enum SaleInvoiceSortCriteria {
  docNo,
  customerName,
  totalAmount,
  docDatetime,
}