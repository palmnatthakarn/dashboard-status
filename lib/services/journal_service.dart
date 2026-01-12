import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';
import '../models/journal.dart';
import '../models/journal_detail.dart';
import '../models/journal_book.dart';

class JournalService {
  static const String baseUrl = AuthRepository.baseUrl;

  /// GET /api/journals - Get all journals
  static Future<JournalResponse> getAllJournals({
    int page = 1,
    int limit = 50,
    String? shopId,
    String? startDate,
    String? endDate,
    String? transactionType,
    String? accountType,
    String? status,
    bool isRetry = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (shopId != null) queryParams['branch_sync'] = shopId;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (transactionType != null) {
      queryParams['transaction_type'] = transactionType;
    }
    if (accountType != null) queryParams['account_type'] = accountType;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/journals',
    ).replace(queryParameters: queryParams);
    log('🌐 Fetching journals from: $uri');

    try {
      final token = AuthRepository.token;

      // Check if token is expired before making request
      if (AuthRepository.isTokenExpired && !isRetry) {
        log('⏰ Token is expiring soon, refreshing before request...');
        final authRepo = AuthRepository();
        final refreshed = await authRepo.refreshTokenWithCredentials();
        if (!refreshed) {
          throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
        }
      }

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(uri, headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed journals data');
        return JournalResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        log('❌ Unauthorized - attempting token refresh...');

        if (!isRetry) {
          // Try to refresh token
          final authRepo = AuthRepository();
          final refreshed = await authRepo.refreshTokenWithCredentials();

          if (refreshed) {
            log('✅ Token refreshed, retrying request...');
            return getAllJournals(
              page: page,
              limit: limit,
              shopId: shopId,
              startDate: startDate,
              endDate: endDate,
              transactionType: transactionType,
              accountType: accountType,
              status: status,
              isRetry: true,
            );
          }
        }

        throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      } else {
        throw Exception(
          'Failed to load journals - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching journals: $e');
      rethrow;
    }
  }

  /// GET /api/journals/:id - Get journal by ID
  static Future<Journal?> getJournalById(int id) async {
    final url = '$baseUrl/journals/$id';
    log('🌐 Fetching journal by ID from: $url');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Journal.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load journal - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching journal by ID: $e');
      rethrow;
    }
  }

  /// GET /api/journals/branch/:branch_sync - Get journals by branch
  static Future<JournalResponse> getJournalsByShop(
    String shopId, {
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    return getAllJournals(
      page: page,
      limit: limit,
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/journals/summary/:branch_sync - Get journal summary by branch
  static Future<JournalSummary?> getJournalSummaryByShop(String shopId) async {
    final url = '$baseUrl/journals/summary/$shopId';
    log('🌐 Fetching journal summary from: $url');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return JournalSummary.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to load journal summary - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching journal summary: $e');
      rethrow;
    }
  }

  /// GET /api/journals/balance/:account_id - Get account balance
  static Future<double> getAccountBalance(String accountId) async {
    final url = '$baseUrl/journals/balance/$accountId';
    log('🌐 Fetching account balance from: $url');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        throw Exception(
          'Failed to load account balance - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching account balance: $e');
      rethrow;
    }
  }

  /// GET /api/journals/date-range/:start_date/:end_date - Get by date range
  static Future<JournalResponse> getJournalsByDateRange(
    String startDate,
    String endDate, {
    int page = 1,
    int limit = 50,
    String? shopId,
  }) async {
    return getAllJournals(
      page: page,
      limit: limit,
      shopId: shopId,
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

  /// Get journals for dashboard (summary data)
  static Future<Map<String, dynamic>> getDashboardJournalData({
    String? startDate,
    String? endDate,
  }) async {
    log('📊 Fetching dashboard journal data...');

    try {
      final response = await getAllJournals(
        limit: 1000, // Get more data for dashboard
        startDate: startDate,
        endDate: endDate,
      );

      final journals = response.journals ?? [];

      // Group by shop
      final shopSummaries = <String, Map<String, dynamic>>{};

      for (final journal in journals) {
        final shopId = journal.branchSync ?? 'unknown';
        final shopName = journal.branchName ?? 'Unknown Shop';

        if (!shopSummaries.containsKey(shopId)) {
          shopSummaries[shopId] = {
            'shop_id': shopId,
            'shop_name': shopName,
            'total_debit': 0.0,
            'total_credit': 0.0,
            'transaction_count': 0,
            'journals': <Journal>[],
          };
        }

        shopSummaries[shopId]!['total_debit'] =
            (shopSummaries[shopId]!['total_debit'] as double) +
            (journal.debit ?? 0);
        shopSummaries[shopId]!['total_credit'] =
            (shopSummaries[shopId]!['total_credit'] as double) +
            (journal.credit ?? 0);
        shopSummaries[shopId]!['transaction_count'] =
            (shopSummaries[shopId]!['transaction_count'] as int) + 1;
        (shopSummaries[shopId]!['journals'] as List<Journal>).add(journal);
      }

      return {
        'total_journals': journals.length,
        'total_debit': journals.fold(0.0, (sum, j) => sum + (j.debit ?? 0)),
        'total_credit': journals.fold(0.0, (sum, j) => sum + (j.credit ?? 0)),
        'shop_summaries': shopSummaries.values.toList(),
        'journals': journals,
      };
    } catch (e) {
      log('💥 Error fetching dashboard journal data: $e');
      rethrow;
    }
  }

  /// GET /gl/journal - Get GL journals
  static Future<JournalResponse> getAllGLJournals({
    int page = 1,
    int limit = 1000,
    String? shopId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (shopId != null)
      queryParams['shopids'] = shopId; // Changed from branch_sync to shopids

    final uri = Uri.parse(
      'https://smlaicloudapi.dev.dedepos.com/gl/journal',
    ).replace(queryParameters: queryParams);
    log('🌐 Fetching GL journals from: $uri');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(uri, headers: headers);
      log('📡 Response status: ${response.statusCode}');
      log(
        '📄 Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        log('✅ Successfully parsed JSON. Data keys: ${data.keys.toList()}');

        if (data['data'] != null) {
          final list = data['data'] as List;
          log('📊 Found ${list.length} items in data');
          if (list.isNotEmpty) {
            log('Example item: ${list.first}');
          }
        }

        return JournalResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load GL journals - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching GL journals: $e');
      rethrow;
    }
  }

  /// GET /gl/journal/docno/{docno} - Get journal detail by document number
  static Future<JournalDetail> getJournalDetailByDocNo(String docNo) async {
    final url = 'https://smlaicloudapi.dev.dedepos.com/gl/journal/docno/$docNo';
    log('🌐 Fetching journal detail from: $url');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['data'] != null) {
          return JournalDetail.fromJson(data['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
          'Failed to load journal detail - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching journal detail: $e');
      rethrow;
    }
  }

  /// GET /gl/journalbook - Get journal books
  static Future<List<JournalBook>> getJournalBooks() async {
    const url = 'https://smlaicloudapi.dev.dedepos.com/gl/journalbook';
    log('🌐 Fetching journal books from: $url');

    try {
      final token = AuthRepository.token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.get(Uri.parse(url), headers: headers);
      log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return JournalBookResponse.fromJson(data).data;
      } else {
        throw Exception(
          'Failed to load journal books - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('💥 Error fetching journal books: $e');
      rethrow;
    }
  }
}
