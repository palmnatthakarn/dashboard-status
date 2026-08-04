import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'auth_repository.dart';
import 'multi_shop_service.dart';

/// Model for individual document image
class DocumentImage {
  final String? imageId;
  final String? shopId;
  final String? category;
  final String? subcategory;
  final String? description;
  final String? uploadedAt;
  final String? uploadedBy;
  final String? imageUrl;

  DocumentImage({
    this.imageId,
    this.shopId,
    this.category,
    this.subcategory,
    this.description,
    this.uploadedAt,
    this.uploadedBy,
    this.imageUrl,
  });

  factory DocumentImage.fromJson(Map<String, dynamic> json) {
    return DocumentImage(
      imageId: json['imageid']?.toString() ?? json['guidfixed']?.toString(),
      shopId: json['shopid']?.toString() ?? json['guidfixedid']?.toString(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      description: json['description']?.toString() ?? json['name']?.toString(),
      uploadedAt:
          json['uploadedat']?.toString() ??
          json['uploadedAt']?.toString() ??
          json['uploaded_at']?.toString() ??
          json['metafileat']?.toString(),
      uploadedBy:
          json['uploadedby']?.toString() ??
          json['uploadedBy']?.toString() ??
          json['uploaded_by']?.toString(),
      imageUrl:
          json['imageuri']?.toString() ??
          json['imageurl']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString(),
    );
  }
}

/// Model for document image group data
class DocumentImageGroup {
  final String shopId; // guidfixedid from API
  final String shopName;
  final int billCount; // billcount from API
  final int imageCount; // count of imagereferences array
  final List<Map<String, dynamic>>? imageReferences;

  DocumentImageGroup({
    required this.shopId,
    this.shopName = '',
    required this.billCount,
    required this.imageCount,
    this.imageReferences,
  });

  factory DocumentImageGroup.fromJson(Map<String, dynamic> json) {
    // Extract imagereferences array
    List<Map<String, dynamic>>? imgRefs;
    int imgCount = 0;

    if (json['imagereferences'] != null && json['imagereferences'] is List) {
      imgRefs = (json['imagereferences'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      imgCount = imgRefs.length;
    }

    return DocumentImageGroup(
      shopId:
          json['guidfixedid']?.toString() ??
          json['shopid']?.toString() ??
          json['shop_id']?.toString() ??
          '',
      shopName:
          json['shopname']?.toString() ??
          json['shop_name']?.toString() ??
          json['name']?.toString() ??
          '',
      billCount: _parseInt(
        json['billcount'] ?? json['bill_count'] ?? json['total'],
      ),
      imageCount: imgCount,
      imageReferences: imgRefs,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// One GL journal reference attached to a document image group — the
/// `references[]` entries seen on `/documentimagegroup`. `docNo` is what
/// lets a GL journal row (matched by its own `docno`) be traced back to
/// the document/task that produced it, entirely separately from
/// `jobguidfixed`.
class DocumentImageGroupReference {
  final String guidfixed;
  final String module;
  final String docNo;

  const DocumentImageGroupReference({
    required this.guidfixed,
    required this.module,
    required this.docNo,
  });

  factory DocumentImageGroupReference.fromJson(Map<String, dynamic> json) {
    return DocumentImageGroupReference(
      guidfixed: json['guidfixed']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      docNo: json['docno']?.toString() ?? '',
    );
  }
}

/// Service to fetch document image group data
class DocumentImageService {
  static const String baseUrl = AuthRepository.baseUrl;

  /// Fetch document images for a specific shop
  static Future<List<DocumentImage>> fetchShopImages({
    required String shopId,
    int limit = 9999,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimage');
      return [];
    }

    await MultiShopService.selectShop(shopId: shopId);

    final uri = Uri.parse('$baseUrl/documentimage').replace(
      queryParameters: {
        'shopid': shopId,
        'limit': limit.toString(),
      },
    );
    dLog('📸 Fetching shop images for ID: "$shopId"');
    dLog('📸 Full URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dLog('📡 Document image response status: ${response.statusCode}');
      dLog('📦 Response body: ${response.body}'); // Debug: see full response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        dLog('✨ Decoded data: $data'); // Debug: see decoded data
        dLog('✨ Success field: ${data['success']}'); // Debug
        dLog('✨ Data field type: ${data['data']?.runtimeType}'); // Debug
        dLog('✨ Data field: ${data['data']}'); // Debug

        if (data['success'] == true && data['data'] != null) {
          if (data['data'] is List) {
            final images = (data['data'] as List).map((item) {
              dLog('🖼️ Processing image item: $item'); // Debug each item
              return DocumentImage.fromJson(item);
            }).toList();
            final shopImages = _filterImagesByShop(images, shopId);

            dLog(
              '✅ Loaded ${shopImages.length}/${images.length} images for shop $shopId',
            );

            // Debug: log first image details
            if (shopImages.isNotEmpty) {
              final first = shopImages.first;
              dLog(
                '🔍 First image: id=${first.imageId}, shopId=${first.shopId}, url=${first.imageUrl}, category=${first.category}',
              );
            }

            return shopImages;
          } else {
            dLog('⚠️ Data is not a List, it is: ${data['data'].runtimeType}');
          }
        } else {
          dLog('⚠️ Success is false or data is null');
        }
      } else if (response.statusCode == 401) {
        dLog('❌ Unauthorized - token may be expired');
      } else {
        dLog('❌ Unexpected status code: ${response.statusCode}');
      }

      dLog('❌ Failed to get document images for shop $shopId');
      return [];
    } catch (e, stackTrace) {
      dLog('💥 Error fetching document images: $e');
      dLog('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  static List<DocumentImage> _filterImagesByShop(
    List<DocumentImage> images,
    String shopId,
  ) {
    final normalizedShopId = _normalizeShopId(shopId);
    final taggedImages = images
        .where((image) => (image.shopId ?? '').trim().isNotEmpty)
        .toList();
    if (taggedImages.isEmpty) return images;

    final matchedImages = taggedImages
        .where((image) => _normalizeShopId(image.shopId) == normalizedShopId)
        .toList();
    return matchedImages.isEmpty ? images : matchedImages;
  }

  static String _normalizeShopId(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  /// Fetch document image groups for all shops
  /// Returns map of shop identifier/name -> billCount
  static Future<Map<String, int>> fetchDocumentImageGroups({
    int page = 1,
    int perPage = 9999,
    String? fromDate,
    String? toDate,
    int ref = 1,
    String? shopId,
  }) async {
    final token = AuthRepository.token;

    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimagegroup');
      return {};
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
      'ref': ref.toString(),
    };
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['todate'] = toDate;
    }
    if (shopId != null && shopId.isNotEmpty) {
      queryParams['shopid'] = shopId;
    }

    final uri = Uri.parse(
      '$baseUrl/documentimagegroup',
    ).replace(queryParameters: queryParams);
    dLog('📸 Fetching document image groups from: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dLog('📡 Document image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final Map<String, int> billCountMap = {};

          final rawGroups = data['data'] is List
              ? data['data'] as List
              : data['data'] is Map && data['data']['items'] is List
              ? data['data']['items'] as List
              : data['data'] is Map && data['data']['data'] is List
              ? data['data']['data'] as List
              : const [];

          if (rawGroups.isNotEmpty) {
            final groups = rawGroups
                .map((item) => DocumentImageGroup.fromJson(item))
                .toList();

            // Build map of guidfixedid -> billCount
            for (var group in groups) {
              if (group.shopId.isNotEmpty) {
                billCountMap[group.shopId] = group.billCount;
              }
              if (group.shopName.isNotEmpty) {
                billCountMap[group.shopName] = group.billCount;
                billCountMap[group.shopName.trim().toLowerCase()] =
                    group.billCount;
              }
              if (group.shopId.isNotEmpty || group.shopName.isNotEmpty) {
                dLog(
                  '  📋 Shop ${group.shopId}/${group.shopName}: billCount=${group.billCount}, imageCount=${group.imageCount}',
                );
              }
            }

            dLog('✅ Loaded bill counts for ${billCountMap.length} shops');
          }

          return billCountMap;
        }
      } else if (response.statusCode == 401) {
        dLog('❌ Unauthorized - token may be expired');
      }

      dLog('❌ Failed to get document images');
      return {};
    } catch (e) {
      dLog('💥 Error fetching document images: $e');
      return {};
    }
  }

  /// Builds a docNo → taskGuid lookup from `/documentimagegroup`, covering
  /// a link between a task and a GL journal that never goes through
  /// `journal.jobguidfixed` at all: a document image group carries its own
  /// `taskguid` (confirmed via a real API response — GET
  /// `/documentimagegroup?taskguid={guid}` returns items shaped like
  /// `{guidfixed, title, billcount, references: [{module, docno}],
  /// taskguid, ...}`), and each item's `references[]` lists the GL journal
  /// rows (by `docno`) that were keyed FROM that image. So: task →
  /// (taskguid) → document image group → (references[].docno) → GL
  /// journal, entirely separate from the task → (jobguidfixed) → GL
  /// journal path the rest of this bloc already handles.
  ///
  /// Root-caused 2026-07: a GL journal recorded through the
  /// photo-upload/OCR flow had `jobguidfixed` completely empty, so the KPI
  /// page's "is this journal linked to a task" check had no way to trace
  /// it back to the task it visibly belonged to in the source system —
  /// it was flagged "ไม่ผูกงาน" (unlinked) even though a real task existed
  /// and owned the document that produced it.
  static Future<
    ({
      Map<String, String> docNoToTaskGuid,
      // taskGuid -> (uploader email -> image count), built from the SAME
      // /documentimagegroup pass as docNoToTaskGuid — each item's
      // `imagereferences[]` carries its own `uploadedby` per image, which
      // can legitimately differ from both the item's own top-level
      // `uploadedby` (whoever created the group/first image) and from the
      // task's `ownerby` (whoever opened the task) — see the "who actually
      // uploaded this photo" KPI request, 2026-08. Falls back to the
      // item-level `uploadedby` when `imagereferences` is empty/missing so
      // a group with no per-image breakdown still counts for someone.
      Map<String, Map<String, int>> taskUploaderCounts,
      int totalItemsSeen,
      int? apiReportedTotal,
    })
  >
  fetchDocNoToTaskGuidMap({
    int page = 1,
    int perPage = 9999,
    String? fromDate,
    String? toDate,
  }) async {
    final token = AuthRepository.token;
    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimagegroup (docno map)');
      return (
        docNoToTaskGuid: <String, String>{},
        taskUploaderCounts: <String, Map<String, int>>{},
        totalItemsSeen: 0,
        apiReportedTotal: null,
      );
    }

    // Sends BOTH `limit` and `perPage` for the page-size param — a real
    // request captured from the browser (GET /documentimagegroup?
    // limit=100&page=1&sort=...&taskguid=...) used `limit`, not `perPage`,
    // while the pre-existing fetchDocumentImageGroups() above (and this
    // method, originally) only ever sent `perPage`. If the API silently
    // ignores an unrecognized param name and falls back to its own small
    // default page size, a broad "every group in the date range" call
    // would quietly return only the first page and miss whichever group
    // isn't in it — exactly matching "the fix didn't do anything" being
    // reported after this was wired up. Sending both covers either name
    // without needing to confirm which one the backend actually reads.
    final queryParams = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
      'limit': perPage.toString(),
      // NOTE: previously sent 'sort': 'xorder:1,guidfixed:1' here to match
      // the confirmed-working scoped (taskguid=...) request exactly.
      // Reverted — adding it to this UNSCOPED bulk call collapsed the
      // result from 299 mapped docNo(s) down to 17, so the backend clearly
      // treats `sort` on this endpoint as more than cosmetic ordering when
      // there's no taskguid filter (likely re-scoping or erroring the
      // query rather than just re-ordering it). Whatever was causing the
      // two specific docnos to still be missing is NOT a pagination
      // ordering gap — see totalItemsSeen/apiReportedTotal below for the
      // actual diagnostic.
    };
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['todate'] = toDate;
    }

    final Map<String, String> docNoToTaskGuid = {};
    final Map<String, Map<String, int>> taskUploaderCounts = {};
    var totalItemsSeen = 0;
    int? apiReportedTotal;
    try {
      // Loops pages using the server's OWN reported page count/size, not
      // the perPage/limit value we merely requested. A prior version broke
      // out of this loop as soon as one page returned fewer than 9999
      // items — which is every page, since the backend evidently caps
      // page size well below that regardless of what's asked for (a real
      // captured response for this same endpoint showed
      // `"perPage": 100` even when the request used `limit=100`). That
      // made this loop silently stop after page 1 every time, exactly
      // reproducing the "map never contains the docNo I need" symptom
      // even after the fromDate/toDate and limit/perPage fixes — an
      // unscoped "every document ever" query can easily span many pages,
      // and task "mai"'s May-dated documents aren't guaranteed to be on
      // page 1 of however this endpoint sorts by default.
      var page = 1;
      var totalPages = 1;
      int? actualPageSize;
      // Hard cap so a miscomputed/garbage totalPage value can't spin this
      // into an unbounded loop.
      const maxPages = 500;
      do {
        final pagedParams = Map<String, String>.from(queryParams)
          ..['page'] = page.toString();
        final uri = Uri.parse(
          '$baseUrl/documentimagegroup',
        ).replace(queryParameters: pagedParams);
        dLog('🔗 Fetching docNo→taskGuid map page $page from: $uri');

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode != 200) {
          dLog(
            '❌ Failed to fetch documentimagegroup for docno map: '
            '${response.statusCode}',
          );
          break;
        }

        final data = json.decode(response.body);
        if (data['success'] != true || data['data'] is! List) break;

        final items = data['data'] as List;
        totalItemsSeen += items.length;
        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final taskGuid = map['taskguid']?.toString().trim() ?? '';
          if (taskGuid.isEmpty) continue;

          final refsRaw = map['references'];
          if (refsRaw is List) {
            for (final r in refsRaw) {
              if (r is! Map) continue;
              final ref = DocumentImageGroupReference.fromJson(
                Map<String, dynamic>.from(r),
              );
              final docNo = ref.docNo.trim();
              if (docNo.isNotEmpty) {
                docNoToTaskGuid[docNo] = taskGuid;
              }
            }
          }

          // Per-image uploader — one increment per image actually uploaded
          // by that person, not per group (a group can hold several images
          // from different uploaders). Falls back to the group's own
          // top-level `uploadedby` only when `imagereferences` is missing
          // entirely, so a group still counts toward SOMEONE rather than
          // silently vanishing from the uploader breakdown.
          final imgRefsRaw = map['imagereferences'];
          final uploaderCounts = taskUploaderCounts.putIfAbsent(
            taskGuid,
            () => <String, int>{},
          );
          if (imgRefsRaw is List && imgRefsRaw.isNotEmpty) {
            for (final ir in imgRefsRaw) {
              if (ir is! Map) continue;
              final uploader = ir['uploadedby']?.toString().trim() ?? '';
              if (uploader.isEmpty) continue;
              uploaderCounts.update(
                uploader,
                (c) => c + 1,
                ifAbsent: () => 1,
              );
            }
          } else {
            final uploader = map['uploadedby']?.toString().trim() ?? '';
            if (uploader.isNotEmpty) {
              uploaderCounts.update(
                uploader,
                (c) => c + 1,
                ifAbsent: () => 1,
              );
            }
          }
        }

        if (page == 1) {
          final p = data['pagination'];
          if (p is Map) {
            if (p['totalPage'] != null) {
              totalPages = int.tryParse(p['totalPage'].toString()) ?? 1;
            }
            if (p['perPage'] != null) {
              actualPageSize = int.tryParse(p['perPage'].toString());
            }
            if (p['total'] != null) {
              apiReportedTotal = int.tryParse(p['total'].toString());
            }
          }
          // Fall back to whatever this first page actually returned if the
          // response didn't declare its own page size.
          actualPageSize ??= items.length;
          dLog(
            '📄 documentimagegroup pagination: totalPage=$totalPages, '
            'actualPageSize=$actualPageSize (requested perPage/limit=$perPage)',
          );
        }

        // Stop once a page comes back short of a FULL page — using the
        // real observed/declared page size, not the (possibly ignored)
        // requested one.
        if (actualPageSize != null &&
            actualPageSize! > 0 &&
            items.length < actualPageSize!) {
          break;
        }
        page++;
      } while (page <= totalPages && page <= maxPages);

      dLog(
        '✅ Built docNo→taskGuid map with ${docNoToTaskGuid.length} entries '
        'from $totalItemsSeen raw item(s) across ${page.clamp(1, totalPages)} '
        'page(s) (API reports $apiReportedTotal total item(s) exist)',
      );
    } catch (e) {
      dLog('💥 Error building docNo→taskGuid map: $e');
      return (
        docNoToTaskGuid: docNoToTaskGuid,
        taskUploaderCounts: taskUploaderCounts,
        totalItemsSeen: totalItemsSeen,
        apiReportedTotal: apiReportedTotal,
      );
    }

    return (
      docNoToTaskGuid: docNoToTaskGuid,
      taskUploaderCounts: taskUploaderCounts,
      totalItemsSeen: totalItemsSeen,
      apiReportedTotal: apiReportedTotal,
    );
  }

  /// Total `billcount` across every `/documentimagegroup` item for the
  /// CURRENTLY SELECTED shop — feeds "ต้องบันทึก(รูปภาพ)" in the KPI page.
  ///
  /// Root-caused 2026-07: the pre-existing [fetchDocumentImageGroups] above
  /// tries to build a shop-keyed map by reading `guidfixedid`/`shopid`/
  /// `shop_id`/`shopname` off each response item — but a real captured
  /// response for this endpoint has NONE of those fields (only `guidfixed`,
  /// `title`, `billcount`, `references[]`, `taskguid`, ...), so that lookup
  /// has always silently produced an empty map and "ต้องบันทึก(รูปภาพ)" has
  /// always shown 0 for every shop. There is no shop identifier anywhere in
  /// the response to key a map by in the first place.
  ///
  /// Instead of trying to parse a shop out of the response, this mirrors
  /// [fetchDocNoToTaskGuidMap]'s fix for the exact same endpoint: call it
  /// ONCE PER SHOP, right after that shop is selected via
  /// [MultiShopService.selectShop] (already happens as a side effect of
  /// TaskService.fetchTasksForShop in the per-shop fetch loop), and let the
  /// CALLER attribute the returned total to whichever shop it just
  /// selected — the response never has to self-identify its shop, and
  /// /documentimagegroup evidently reads the session-selected shop the same
  /// way /gl/journal does (ignores query params, keyed off POST
  /// /select-shop instead).
  ///
  /// Also fixes the same pagination-early-exit bug [fetchDocNoToTaskGuidMap]
  /// had before its own fix: loops using the response's own declared
  /// `pagination.perPage`, not the (possibly ignored) requested `perPage`/
  /// `limit`.
  static Future<int> fetchShopBillCount({
    int perPage = 9999,
    String? fromDate,
    String? toDate,
    int ref = 1,
  }) async {
    final token = AuthRepository.token;
    if (token == null || token.isEmpty) {
      dLog('❌ No auth token available for documentimagegroup (bill count)');
      return 0;
    }

    final queryParams = <String, String>{
      'page': '1',
      'perPage': perPage.toString(),
      'limit': perPage.toString(),
      'ref': ref.toString(),
    };
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['todate'] = toDate;
    }

    var total = 0;
    try {
      var page = 1;
      var totalPages = 1;
      int? actualPageSize;
      const maxPages = 500;
      do {
        final pagedParams = Map<String, String>.from(queryParams)
          ..['page'] = page.toString();
        final uri = Uri.parse(
          '$baseUrl/documentimagegroup',
        ).replace(queryParameters: pagedParams);
        dLog('🔗 Fetching documentimagegroup bill count page $page from: $uri');

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode != 200) {
          dLog(
            '❌ Failed to fetch documentimagegroup for bill count: '
            '${response.statusCode}',
          );
          break;
        }

        final data = json.decode(response.body);
        if (data['success'] != true || data['data'] is! List) break;

        final items = data['data'] as List;
        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          total += DocumentImageGroup._parseInt(map['billcount']);
        }

        if (page == 1) {
          final p = data['pagination'];
          if (p is Map) {
            if (p['totalPage'] != null) {
              totalPages = int.tryParse(p['totalPage'].toString()) ?? 1;
            }
            if (p['perPage'] != null) {
              actualPageSize = int.tryParse(p['perPage'].toString());
            }
          }
          actualPageSize ??= items.length;
        }

        if (actualPageSize != null &&
            actualPageSize! > 0 &&
            items.length < actualPageSize!) {
          break;
        }
        page++;
      } while (page <= totalPages && page <= maxPages);

      dLog('✅ documentimagegroup bill count for current shop: $total');
    } catch (e) {
      dLog('💥 Error fetching documentimagegroup bill count: $e');
    }
    return total;
  }
}
