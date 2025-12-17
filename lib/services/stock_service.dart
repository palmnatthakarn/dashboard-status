import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

class StockService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// GET /api/stock - Get all stocks (alias for getAllStock)
  static Future<StockResponse> getAllStocks({
    int? page,
    int? limit,
    String? branchSync,
    String? startDate,
    String? endDate,
    String? productCode,
    String? status,
  }) async {
    return getAllStock(
      page: page ?? 1,
      limit: limit ?? 20,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
      itemCode: productCode,
      movementType: status,
    );
  }

  /// GET /api/stock/branch/:branch_sync - Get stocks by branch
  static Future<StockResponse> getStocksByBranch(
    String branchSync, {
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    return getAllStock(
      page: page ?? 1,
      limit: limit ?? 20,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/stock/product/:product_code - Get stocks by product
  static Future<StockResponse> getStocksByProduct(
    String productCode, {
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    return getAllStock(
      page: page ?? 1,
      limit: limit ?? 20,
      itemCode: productCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/stock - Get all stock movements (original method)
  static Future<StockResponse> getAllStock({
    int page = 1,
    int limit = 50,
    String? branchSync,
    String? itemCode,
    String? movementType,
    String? startDate,
    String? endDate,
    String? warehouseCode,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (branchSync != null) queryParams['branch_sync'] = branchSync;
    if (itemCode != null) queryParams['item_code'] = itemCode;
    if (movementType != null) queryParams['movement_type'] = movementType;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (warehouseCode != null) queryParams['warehouse_code'] = warehouseCode;

    final uri = Uri.parse('$baseUrl/stock')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching stock movements from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed stock data');
        
        // Handle API response structure
        if (data['success'] == true && data['data'] != null) {
          return StockResponse(
            stocks: (data['data'] as List)
                .map((json) => Stock.fromJson(json))
                .toList(),
            totalCount: data['pagination']?['total'] ?? 0,
            currentPage: data['pagination']?['page'] ?? 1,
            totalPages: data['pagination']?['pages'] ?? 1,
          );
        } else {
          return StockResponse.fromJson(data);
        }
      } else {
        throw Exception(
          'Failed to load stock movements - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching stock movements: $e');
      rethrow;
    }
  }

  /// GET /api/stock/:id - Get stock movement by ID
  static Future<Stock?> getStockById(int id) async {
    final url = '$baseUrl/stock/$id';
    log('🌐 Fetching stock movement by ID from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Stock.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load stock movement - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching stock movement by ID: $e');
      rethrow;
    }
  }

  /// GET /api/stock/branch/:branch_sync - Get stock movements by branch
  static Future<StockResponse> getStockByBranch(
    String branchSync, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllStock(
      page: page,
      limit: limit,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/stock/item/:item_code - Get stock movements by item
  static Future<StockResponse> getStockByItem(
    String itemCode, {
    int page = 1,
    int limit = 50,
    String? branchSync,
    String? startDate,
    String? endDate,
  }) async {
    return getAllStock(
      page: page,
      limit: limit,
      itemCode: itemCode,
      branchSync: branchSync,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/stock/warehouse/:warehouse_code - Get stock movements by warehouse
  static Future<StockResponse> getStockByWarehouse(
    String warehouseCode, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllStock(
      page: page,
      limit: limit,
      warehouseCode: warehouseCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/stock/summary/:branch_sync - Get stock summary by branch
  static Future<List<StockSummary>> getStockSummaryByBranch(
      String branchSync) async {
    final url = '$baseUrl/stock/summary/$branchSync';
    log('🌐 Fetching stock summary from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List) {
          return data.map((json) => StockSummary.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => StockSummary.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          'Failed to load stock summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching stock summary: $e');
      rethrow;
    }
  }

  /// GET /api/stock/balance/:item_code - Get current stock balance for item
  static Future<double> getStockBalance(
    String itemCode, {
    String? branchSync,
    String? warehouseCode,
  }) async {
    final queryParams = <String, String>{};
    if (branchSync != null) queryParams['branch_sync'] = branchSync;
    if (warehouseCode != null) queryParams['warehouse_code'] = warehouseCode;

    final uri = Uri.parse('$baseUrl/stock/balance/$itemCode')
        .replace(queryParameters: queryParams);
    log('🌐 Fetching stock balance from: $uri');

    try {
      final response = await http.get(uri);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        throw Exception(
          'Failed to load stock balance - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching stock balance: $e');
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

  /// Get stock movements for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardStockData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard stock data...');

    try {
      final response = await getAllStock(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final stocks = response.stocks ?? [];

      // Group by branch
      final branchSummaries = <String, Map<String, dynamic>>{};
      // Group by item
      final itemSummaries = <String, Map<String, dynamic>>{};
      // Group by movement type
      final movementSummaries = <String, Map<String, dynamic>>{};

      for (final stock in stocks) {
        final branchId = stock.branchSync ?? 'unknown';
        final branchName = stock.branchName ?? 'Unknown Branch';
        final itemCode = stock.itemCode ?? 'unknown';
        final itemName = stock.itemName ?? 'Unknown Item';
        final movementType = stock.movementType ?? 'unknown';

        // Branch summaries
        if (!branchSummaries.containsKey(branchId)) {
          branchSummaries[branchId] = {
            'branch_id': branchId,
            'branch_name': branchName,
            'total_quantity_in': 0.0,
            'total_quantity_out': 0.0,
            'total_cost_value': 0.0,
            'movement_count': 0,
            'stocks': <Stock>[],
          };
        }

        branchSummaries[branchId]!['total_quantity_in'] =
            (branchSummaries[branchId]!['total_quantity_in'] as double) +
            (stock.quantityIn ?? 0);
        branchSummaries[branchId]!['total_quantity_out'] =
            (branchSummaries[branchId]!['total_quantity_out'] as double) +
            (stock.quantityOut ?? 0);
        branchSummaries[branchId]!['total_cost_value'] =
            (branchSummaries[branchId]!['total_cost_value'] as double) +
            (stock.totalCost ?? 0);
        branchSummaries[branchId]!['movement_count'] =
            (branchSummaries[branchId]!['movement_count'] as int) + 1;
        (branchSummaries[branchId]!['stocks'] as List<Stock>).add(stock);

        // Item summaries
        if (!itemSummaries.containsKey(itemCode)) {
          itemSummaries[itemCode] = {
            'item_code': itemCode,
            'item_name': itemName,
            'total_quantity_in': 0.0,
            'total_quantity_out': 0.0,
            'current_balance': 0.0,
            'movement_count': 0,
          };
        }

        itemSummaries[itemCode]!['total_quantity_in'] =
            (itemSummaries[itemCode]!['total_quantity_in'] as double) +
            (stock.quantityIn ?? 0);
        itemSummaries[itemCode]!['total_quantity_out'] =
            (itemSummaries[itemCode]!['total_quantity_out'] as double) +
            (stock.quantityOut ?? 0);
        itemSummaries[itemCode]!['current_balance'] =
            (itemSummaries[itemCode]!['current_balance'] as double) +
            ((stock.quantityIn ?? 0) - (stock.quantityOut ?? 0));
        itemSummaries[itemCode]!['movement_count'] =
            (itemSummaries[itemCode]!['movement_count'] as int) + 1;

        // Movement type summaries
        if (!movementSummaries.containsKey(movementType)) {
          movementSummaries[movementType] = {
            'movement_type': movementType,
            'total_quantity': 0.0,
            'total_cost': 0.0,
            'count': 0,
          };
        }

        movementSummaries[movementType]!['total_quantity'] =
            (movementSummaries[movementType]!['total_quantity'] as double) +
            ((stock.quantityIn ?? 0) + (stock.quantityOut ?? 0));
        movementSummaries[movementType]!['total_cost'] =
            (movementSummaries[movementType]!['total_cost'] as double) +
            (stock.totalCost ?? 0);
        movementSummaries[movementType]!['count'] =
            (movementSummaries[movementType]!['count'] as int) + 1;
      }

      return {
        'total_movements': stocks.length,
        'total_quantity_in': stocks.fold(0.0, (sum, s) => sum + (s.quantityIn ?? 0)),
        'total_quantity_out': stocks.fold(0.0, (sum, s) => sum + (s.quantityOut ?? 0)),
        'total_cost_value': stocks.fold(0.0, (sum, s) => sum + (s.totalCost ?? 0)),
        'branch_summaries': branchSummaries.values.toList(),
        'item_summaries': itemSummaries.values.toList(),
        'movement_summaries': movementSummaries.values.toList(),
        'stocks': stocks,
      };
    } catch (e) {
      log('💥 Error fetching dashboard stock data: $e');
      rethrow;
    }
  }
}
