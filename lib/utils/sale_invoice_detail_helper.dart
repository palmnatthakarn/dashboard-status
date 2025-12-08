import '../models/sale_invoice_detail.dart';

class SaleInvoiceDetailHelper {
  /// Format quantity for display
  static String formatQuantity(double? quantity) {
    if (quantity == null) return '0';
    
    // If quantity is a whole number, show without decimals
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    
    return quantity.toStringAsFixed(2);
  }

  /// Format unit price for display
  static String formatUnitPrice(double? unitPrice) {
    if (unitPrice == null) return '0.00';
    return unitPrice.toStringAsFixed(2);
  }

  /// Calculate line total (quantity * unit price)
  static double calculateLineTotal(SaleInvoiceDetail detail) {
    final quantity = detail.quantity ?? 0.0;
    final unitPrice = detail.unitPrice ?? 0.0;
    return quantity * unitPrice;
  }

  /// Calculate line total with discount
  static double calculateLineTotalWithDiscount(SaleInvoiceDetail detail) {
    final lineTotal = calculateLineTotal(detail);
    final discountAmount = detail.discountAmount ?? 0.0;
    return lineTotal - discountAmount;
  }

  /// Format sale invoice detail display text
  static String formatDetailDisplay(SaleInvoiceDetail detail) {
    final productName = detail.itemName ?? 'Unknown Product';
    final quantity = formatQuantity(detail.quantity);
    final unitPrice = formatUnitPrice(detail.unitPrice);
    
    return '$productName (${quantity} x ฿${unitPrice})';
  }

  /// Get discount percentage
  static double getDiscountPercentage(SaleInvoiceDetail detail) {
    final lineTotal = calculateLineTotal(detail);
    final discountAmount = detail.discountAmount ?? 0.0;
    
    if (lineTotal == 0) return 0.0;
    
    return (discountAmount / lineTotal) * 100;
  }

  /// Group sale invoice details by product
  static Map<String, List<SaleInvoiceDetail>> groupByProduct(List<SaleInvoiceDetail> details) {
    final Map<String, List<SaleInvoiceDetail>> grouped = {};
    
    for (final detail in details) {
      final productKey = detail.itemCode ?? 'Unknown';
      grouped[productKey] ??= [];
      grouped[productKey]!.add(detail);
    }
    
    return grouped;
  }

  /// Group sale invoice details by invoice
  static Map<String, List<SaleInvoiceDetail>> groupByInvoice(List<SaleInvoiceDetail> details) {
    final Map<String, List<SaleInvoiceDetail>> grouped = {};
    
    for (final detail in details) {
      final invoiceKey = detail.invoiceDocNo ?? 'Unknown';
      grouped[invoiceKey] ??= [];
      grouped[invoiceKey]!.add(detail);
    }
    
    return grouped;
  }

  /// Calculate summary statistics for sale invoice details
  static SaleInvoiceDetailSummaryStats calculateSummary(List<SaleInvoiceDetail> details) {
    double totalQuantity = 0.0;
    double totalAmount = 0.0;
    double totalDiscountAmount = 0.0;
    int totalCount = details.length;
    
    for (final detail in details) {
      totalQuantity += detail.quantity ?? 0.0;
      totalAmount += calculateLineTotal(detail);
      totalDiscountAmount += detail.discountAmount ?? 0.0;
    }
    
    final totalNetAmount = totalAmount - totalDiscountAmount;
    
    return SaleInvoiceDetailSummaryStats(
      totalQuantity: totalQuantity,
      totalAmount: totalAmount,
      totalDiscountAmount: totalDiscountAmount,
      totalNetAmount: totalNetAmount,
      totalCount: totalCount,
      averageQuantity: totalCount > 0 ? totalQuantity / totalCount : 0.0,
      averageAmount: totalCount > 0 ? totalAmount / totalCount : 0.0,
    );
  }

  /// Filter details by product
  static List<SaleInvoiceDetail> filterByProduct(
    List<SaleInvoiceDetail> details,
    String productCode,
  ) {
    return details.where((detail) => 
      detail.itemCode?.toLowerCase() == productCode.toLowerCase()
    ).toList();
  }

  /// Filter details by quantity range
  static List<SaleInvoiceDetail> filterByQuantityRange(
    List<SaleInvoiceDetail> details,
    double? minQuantity,
    double? maxQuantity,
  ) {
    return details.where((detail) {
      final quantity = detail.quantity ?? 0.0;
      
      if (minQuantity != null && quantity < minQuantity) return false;
      if (maxQuantity != null && quantity > maxQuantity) return false;
      
      return true;
    }).toList();
  }

  /// Get top selling products from details
  static List<ProductSales> getTopSellingProducts(
    List<SaleInvoiceDetail> details, {
    int limit = 10,
  }) {
    final Map<String, ProductSales> productSales = {};
    
    for (final detail in details) {
      final productCode = detail.itemCode ?? 'Unknown';
      final productName = detail.itemName ?? 'Unknown Product';
      final quantity = detail.quantity ?? 0.0;
      final amount = calculateLineTotal(detail);
      
      if (productSales.containsKey(productCode)) {
        productSales[productCode] = ProductSales(
          productCode: productCode,
          productName: productName,
          totalQuantity: productSales[productCode]!.totalQuantity + quantity,
          totalAmount: productSales[productCode]!.totalAmount + amount,
          transactionCount: productSales[productCode]!.transactionCount + 1,
        );
      } else {
        productSales[productCode] = ProductSales(
          productCode: productCode,
          productName: productName,
          totalQuantity: quantity,
          totalAmount: amount,
          transactionCount: 1,
        );
      }
    }
    
    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    
    return sortedProducts.take(limit).toList();
  }

  /// Sort sale invoice details by various criteria
  static List<SaleInvoiceDetail> sortDetails(
    List<SaleInvoiceDetail> details,
    SaleInvoiceDetailSortCriteria criteria, {
    bool ascending = true,
  }) {
    final sortedList = List<SaleInvoiceDetail>.from(details);
    
    switch (criteria) {
      case SaleInvoiceDetailSortCriteria.productName:
        sortedList.sort((a, b) => ascending 
          ? (a.itemName ?? '').compareTo(b.itemName ?? '')
          : (b.itemName ?? '').compareTo(a.itemName ?? ''));
        break;
      case SaleInvoiceDetailSortCriteria.quantity:
        sortedList.sort((a, b) => ascending
          ? (a.quantity ?? 0).compareTo(b.quantity ?? 0)
          : (b.quantity ?? 0).compareTo(a.quantity ?? 0));
        break;
      case SaleInvoiceDetailSortCriteria.unitPrice:
        sortedList.sort((a, b) => ascending
          ? (a.unitPrice ?? 0).compareTo(b.unitPrice ?? 0)
          : (b.unitPrice ?? 0).compareTo(a.unitPrice ?? 0));
        break;
      case SaleInvoiceDetailSortCriteria.lineTotal:
        sortedList.sort((a, b) {
          final totalA = calculateLineTotal(a);
          final totalB = calculateLineTotal(b);
          return ascending ? totalA.compareTo(totalB) : totalB.compareTo(totalA);
        });
        break;
    }
    
    return sortedList;
  }
}

class SaleInvoiceDetailSummaryStats {
  final double totalQuantity;
  final double totalAmount;
  final double totalDiscountAmount;
  final double totalNetAmount;
  final int totalCount;
  final double averageQuantity;
  final double averageAmount;

  SaleInvoiceDetailSummaryStats({
    required this.totalQuantity,
    required this.totalAmount,
    required this.totalDiscountAmount,
    required this.totalNetAmount,
    required this.totalCount,
    required this.averageQuantity,
    required this.averageAmount,
  });
}

class ProductSales {
  final String productCode;
  final String productName;
  final double totalQuantity;
  final double totalAmount;
  final int transactionCount;

  ProductSales({
    required this.productCode,
    required this.productName,
    required this.totalQuantity,
    required this.totalAmount,
    required this.transactionCount,
  });
}

enum SaleInvoiceDetailSortCriteria {
  productName,
  quantity,
  unitPrice,
  lineTotal,
}