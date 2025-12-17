import '../models/stock.dart';

class StockHelper {
  /// Format stock quantity for display
  static String formatQuantity(double? quantity) {
    if (quantity == null) return '0';
    
    // If quantity is a whole number, show without decimals
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    
    return quantity.toStringAsFixed(2);
  }

  /// Format cost per unit for display
  static String formatCostPerUnit(double? cost) {
    if (cost == null) return '0.00';
    return cost.toStringAsFixed(2);
  }

  /// Calculate total stock value (quantity * cost per unit)
  static double calculateStockValue(Stock stock) {
    final quantity = stock.quantityBalance ?? 0.0;
    final costPerUnit = stock.unitCost ?? 0.0;
    return quantity * costPerUnit;
  }

  /// Format stock display text
  static String formatStockDisplay(Stock stock) {
    final productName = stock.itemName ?? 'Unknown Product';
    final quantity = formatQuantity(stock.quantityBalance);
    final unit = stock.unitName ?? '';
    
    return '$productName ($quantity $unit)';
  }

  /// Get stock status based on quantity
  static StockStatus getStockStatus(Stock stock) {
    final quantity = stock.quantityBalance ?? 0.0;
    final minStockLevel = 0.0; // Default minimum stock level
    final maxStockLevel = double.infinity; // Default maximum stock level
    
    if (quantity <= 0) {
      return StockStatus.outOfStock;
    } else if (quantity <= minStockLevel) {
      return StockStatus.lowStock;
    } else if (quantity >= maxStockLevel) {
      return StockStatus.overStock;
    } else {
      return StockStatus.normal;
    }
  }

  /// Get status color based on stock status
  static String getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return '#F44336'; // Red
      case StockStatus.lowStock:
        return '#FF9800'; // Orange
      case StockStatus.overStock:
        return '#9C27B0'; // Purple
      case StockStatus.normal:
        return '#4CAF50'; // Green
    }
  }

  /// Get status text
  static String getStatusText(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return 'สินค้าหมด';
      case StockStatus.lowStock:
        return 'สต็อกต่ำ';
      case StockStatus.overStock:
        return 'สต็อกเกิน';
      case StockStatus.normal:
        return 'ปกติ';
    }
  }

  /// Check if stock needs reorder
  static bool needsReorder(Stock stock) {
    return getStockStatus(stock) == StockStatus.lowStock || 
           getStockStatus(stock) == StockStatus.outOfStock;
  }

  /// Group stocks by product category
  static Map<String, List<Stock>> groupByCategory(List<Stock> stocks) {
    final Map<String, List<Stock>> grouped = {};
    
    for (final stock in stocks) {
      final categoryKey = stock.itemDescription ?? 'Uncategorized';
      grouped[categoryKey] ??= [];
      grouped[categoryKey]!.add(stock);
    }
    
    return grouped;
  }

  /// Group stocks by branch
  static Map<String, List<Stock>> groupByBranch(List<Stock> stocks) {
    final Map<String, List<Stock>> grouped = {};
    
    for (final stock in stocks) {
      final branchKey = stock.branchSync ?? 'Unknown';
      grouped[branchKey] ??= [];
      grouped[branchKey]!.add(stock);
    }
    
    return grouped;
  }

  /// Calculate summary statistics for stocks
  static StockSummaryStats calculateSummary(List<Stock> stocks) {
    double totalQuantity = 0.0;
    double totalValue = 0.0;
    int totalCount = stocks.length;
    int outOfStockCount = 0;
    int lowStockCount = 0;
    
    for (final stock in stocks) {
      totalQuantity += stock.quantityBalance ?? 0.0;
      totalValue += calculateStockValue(stock);
      
      final status = getStockStatus(stock);
      if (status == StockStatus.outOfStock) outOfStockCount++;
      if (status == StockStatus.lowStock) lowStockCount++;
    }
    
    return StockSummaryStats(
      totalQuantity: totalQuantity,
      totalValue: totalValue,
      totalCount: totalCount,
      outOfStockCount: outOfStockCount,
      lowStockCount: lowStockCount,
      averageQuantity: totalCount > 0 ? totalQuantity / totalCount : 0.0,
      averageValue: totalCount > 0 ? totalValue / totalCount : 0.0,
    );
  }

  /// Filter stocks by status
  static List<Stock> filterByStatus(List<Stock> stocks, StockStatus status) {
    return stocks.where((stock) => getStockStatus(stock) == status).toList();
  }

  /// Filter stocks by quantity range
  static List<Stock> filterByQuantityRange(
    List<Stock> stocks,
    double? minQuantity,
    double? maxQuantity,
  ) {
    return stocks.where((stock) {
      final quantity = stock.quantityBalance ?? 0.0;
      
      if (minQuantity != null && quantity < minQuantity) return false;
      if (maxQuantity != null && quantity > maxQuantity) return false;
      
      return true;
    }).toList();
  }

  /// Get stocks that need attention (out of stock or low stock)
  static List<Stock> getStocksNeedingAttention(List<Stock> stocks) {
    return stocks.where((stock) {
      final status = getStockStatus(stock);
      return status == StockStatus.outOfStock || status == StockStatus.lowStock;
    }).toList();
  }

  /// Get top valuable stocks
  static List<Stock> getTopValueStocks(List<Stock> stocks, {int limit = 10}) {
    final sortedStocks = List<Stock>.from(stocks);
    sortedStocks.sort((a, b) {
      final valueA = calculateStockValue(a);
      final valueB = calculateStockValue(b);
      return valueB.compareTo(valueA);
    });
    
    return sortedStocks.take(limit).toList();
  }

  /// Sort stocks by various criteria
  static List<Stock> sortStocks(
    List<Stock> stocks,
    StockSortCriteria criteria, {
    bool ascending = true,
  }) {
    final sortedList = List<Stock>.from(stocks);
    
    switch (criteria) {
      case StockSortCriteria.productName:
        sortedList.sort((a, b) => ascending 
          ? (a.itemName ?? '').compareTo(b.itemName ?? '')
          : (b.itemName ?? '').compareTo(a.itemName ?? ''));
        break;
      case StockSortCriteria.quantity:
        sortedList.sort((a, b) => ascending
          ? (a.quantityBalance ?? 0).compareTo(b.quantityBalance ?? 0)
          : (b.quantityBalance ?? 0).compareTo(a.quantityBalance ?? 0));
        break;
      case StockSortCriteria.costPerUnit:
        sortedList.sort((a, b) => ascending
          ? (a.unitCost ?? 0).compareTo(b.unitCost ?? 0)
          : (b.unitCost ?? 0).compareTo(a.unitCost ?? 0));
        break;
      case StockSortCriteria.totalValue:
        sortedList.sort((a, b) {
          final valueA = calculateStockValue(a);
          final valueB = calculateStockValue(b);
          return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
        });
        break;
      case StockSortCriteria.status:
        sortedList.sort((a, b) {
          final statusA = getStockStatus(a).index;
          final statusB = getStockStatus(b).index;
          return ascending ? statusA.compareTo(statusB) : statusB.compareTo(statusA);
        });
        break;
    }
    
    return sortedList;
  }
}

class StockSummaryStats {
  final double totalQuantity;
  final double totalValue;
  final int totalCount;
  final int outOfStockCount;
  final int lowStockCount;
  final double averageQuantity;
  final double averageValue;

  StockSummaryStats({
    required this.totalQuantity,
    required this.totalValue,
    required this.totalCount,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.averageQuantity,
    required this.averageValue,
  });
}

enum StockStatus {
  outOfStock,
  lowStock,
  normal,
  overStock,
}

enum StockSortCriteria {
  productName,
  quantity,
  costPerUnit,
  totalValue,
  status,
}
