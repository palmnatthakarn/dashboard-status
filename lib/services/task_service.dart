import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';
import 'multi_shop_service.dart';

/// Model for document status count
class DocumentStatusCount {
  final int status;
  final int total;

  DocumentStatusCount({required this.status, required this.total});

  factory DocumentStatusCount.fromJson(Map<String, dynamic> json) {
    return DocumentStatusCount(
      status: json['status'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// Model for task child reference
class TaskChild {
  final String guidfixed;
  final String code;
  final String name;
  final int status;

  TaskChild({
    required this.guidfixed,
    required this.code,
    required this.name,
    required this.status,
  });

  factory TaskChild.fromJson(Map<String, dynamic> json) {
    return TaskChild(
      guidfixed: json['guidfixed']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status'] ?? 0,
    );
  }
}

/// Model for task item from /task API
class TaskItem {
  final String guidfixed;
  final String code;
  final String name;
  final String module;
  final int status;
  final String parentGuidfixed;
  final String path;
  final bool isFavorit;
  final List<String>? tags;
  final String description;
  final int totalDocument;
  final List<DocumentStatusCount> totalDocumentStatus;
  final DateTime ownerAt;
  final String ownerBy;
  final int billCount;
  final int referenceCount;
  final int referenceBalance;
  final String rejectFromTaskGuid;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final TaskChild? taskChild;

  TaskItem({
    required this.guidfixed,
    required this.code,
    required this.name,
    required this.module,
    required this.status,
    required this.parentGuidfixed,
    required this.path,
    required this.isFavorit,
    this.tags,
    required this.description,
    required this.totalDocument,
    required this.totalDocumentStatus,
    required this.ownerAt,
    required this.ownerBy,
    required this.billCount,
    required this.referenceCount,
    required this.referenceBalance,
    required this.rejectFromTaskGuid,
    this.rejectedAt,
    this.rejectedBy,
    this.taskChild,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // Parse totalDocumentStatus
    List<DocumentStatusCount> statusList = [];
    if (json['totaldocumentstatus'] != null) {
      statusList = (json['totaldocumentstatus'] as List)
          .map((e) => DocumentStatusCount.fromJson(e))
          .toList();
    }

    // Parse taskChild
    TaskChild? child;
    if (json['taskchild'] != null &&
        json['taskchild']['guidfixed'] != null &&
        json['taskchild']['guidfixed'].toString().isNotEmpty) {
      child = TaskChild.fromJson(json['taskchild']);
    }

    // Parse dates
    DateTime ownerAt = DateTime.now();
    if (json['ownerat'] != null) {
      try {
        ownerAt = DateTime.parse(json['ownerat']);
      } catch (_) {}
    }

    DateTime? rejectedAt;
    if (json['rejectedat'] != null &&
        json['rejectedat'] != '0001-01-01T00:00:00Z') {
      try {
        rejectedAt = DateTime.parse(json['rejectedat']);
      } catch (_) {}
    }

    return TaskItem(
      guidfixed: json['guidfixed']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      status: json['status'] ?? 0,
      parentGuidfixed: json['parentguidfixed']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      isFavorit: json['isfavorit'] == true,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      description: json['description']?.toString() ?? '',
      totalDocument: json['totaldocument'] ?? 0,
      totalDocumentStatus: statusList,
      ownerAt: ownerAt,
      ownerBy: json['ownerby']?.toString() ?? '',
      billCount: json['billcount'] ?? 0,
      referenceCount: json['referencecount'] ?? 0,
      referenceBalance: json['referencebalance'] ?? 0,
      rejectFromTaskGuid: json['rejectfromtaskguid']?.toString() ?? '',
      rejectedAt: rejectedAt,
      rejectedBy: json['rejectedby']?.toString(),
      taskChild: child,
    );
  }

  /// Get count for a specific document status
  /// status 1 = อัปโหลด (uploaded)
  /// status 2 = รอบันทึกบัญชี (waiting accounting)
  /// status 3 = รอแก้ไข (waiting fix)
  /// status 4 = รอตรวจสอบ (waiting verify)
  int getStatusCount(int statusCode) {
    final found = totalDocumentStatus.where((s) => s.status == statusCode);
    return found.isNotEmpty ? found.first.total : 0;
  }

  /// Uploaded count (status 1)
  int get uploadedCount => getStatusCount(1);

  /// Waiting accounting count (status 2 - CHANGED: status 2 is now cancelled)
  /// Currently undefined what status code is waiting accounting if 2 is cancelled
  /// Returning 0 for now to avoid incorrect data
  int get waitingAccountingCount => 0;

  /// Waiting fix count (status 3)
  int get waitingFixCount => getStatusCount(3);

  /// Waiting verify count (status 4)
  int get waitingVerifyCount => getStatusCount(4);

  /// Cancelled count (status 2)
  int get cancelledCount => getStatusCount(2);
}

/// Pagination info for task response
class TaskPagination {
  final int total;
  final int page;
  final int perPage;
  final int prev;
  final int next;
  final int totalPage;

  TaskPagination({
    required this.total,
    required this.page,
    required this.perPage,
    required this.prev,
    required this.next,
    required this.totalPage,
  });

  factory TaskPagination.fromJson(Map<String, dynamic> json) {
    return TaskPagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['perPage'] ?? 20,
      prev: json['prev'] ?? 0,
      next: json['next'] ?? 0,
      totalPage: json['totalPage'] ?? 1,
    );
  }
}

/// Response wrapper for /task API
class TaskResponse {
  final bool success;
  final List<TaskItem> tasks;
  final TaskPagination? pagination;

  TaskResponse({required this.success, required this.tasks, this.pagination});

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    List<TaskItem> tasks = [];
    if (json['data'] is List) {
      tasks = (json['data'] as List).map((e) => TaskItem.fromJson(e)).toList();
    }

    TaskPagination? pagination;
    if (json['pagination'] != null) {
      pagination = TaskPagination.fromJson(json['pagination']);
    }

    return TaskResponse(
      success: json['success'] == true,
      tasks: tasks,
      pagination: pagination,
    );
  }
}

/// Service to fetch task data from the cloud API
class TaskService {
  static const String baseUrl = 'https://smlaicloudapi.dev.dedepos.com';

  /// Fetch tasks with optional filters
  /// status: 1=อัปโหลด, 2=รอบันทึกบัญชี, 3=รอแก้ไข, 4=รอตรวจสอบ
  static Future<TaskResponse> fetchTasks({
    int limit = 20,
    List<int> status = const [1, 2, 3, 4],
    int page = 1,
    bool isRetry = false,
    bool skipShopSelection = false,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      log('❌ No auth token available for task API');
      throw Exception('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่');
    }

    // Check if token is expired before making request
    if (AuthRepository.isTokenExpired && !isRetry) {
      log('⏰ Token is expiring soon, refreshing before request...');
      final authRepo = AuthRepository();
      final refreshed = await authRepo.refreshTokenWithCredentials();
      if (!refreshed) {
        throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }
    }

    // Only select shop if not already selected (skipShopSelection = false)
    if (!skipShopSelection) {
      log('🏪 Ensuring shop is selected before fetching tasks...');
      final shopSelected = await MultiShopService.selectShop();
      if (!shopSelected) {
        log('⚠️ Could not select shop, continuing anyway...');
      }
    } else {
      log('⏭️ Skipping shop selection (already selected)');
    }

    // Build URL with query parameters
    final statusParam = status.join(',');
    final url = '$baseUrl/task?limit=$limit&status=$statusParam&page=$page';
    log('🌐 Fetching tasks from: $url');

    try {
      log(
        '🔑 Using token for API: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log('📡 Response status: ${response.statusCode}');
      log(
        '📄 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Successfully fetched tasks');
        return TaskResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        log('❌ Unauthorized - attempting token refresh...');

        if (!isRetry) {
          final authRepo = AuthRepository();
          final refreshed = await authRepo.refreshTokenWithCredentials();

          if (refreshed) {
            log('✅ Token refreshed, retrying request...');
            return fetchTasks(
              limit: limit,
              status: status,
              page: page,
              isRetry: true,
              skipShopSelection: skipShopSelection,
            );
          }
        }

        throw Exception('Token หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      } else {
        log('❌ Failed to fetch tasks: ${response.statusCode}');
        throw Exception('เกิดข้อผิดพลาด: ${response.statusCode}');
      }
    } catch (e) {
      log('💥 Error fetching tasks: $e');
      rethrow;
    }
  }

  /// Fetch tasks for a specific shop
  static Future<TaskResponse> fetchTasksForShop({
    required String shopId,
    int limit = 20,
    List<int> status = const [1, 2, 3, 4],
    int page = 1,
  }) async {
    // Select the specific shop first
    log('🏪 Selecting shop $shopId before fetching tasks...');
    final shopSelected = await MultiShopService.selectShop(shopId: shopId);
    if (!shopSelected) {
      throw Exception('ไม่สามารถเลือกร้านได้');
    }

    // Call fetchTasks with skipShopSelection=true to avoid re-selecting shop
    return fetchTasks(
      limit: limit,
      status: status,
      page: page,
      skipShopSelection: true,
    );
  }
}
