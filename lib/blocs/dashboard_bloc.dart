import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/doc_details.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';
import '../services/multi_shop_service.dart';
import '../services/auth_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 2);
  bool _isFetching = false;

  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboardData>((event, emit) async {
      // ป้องกันการเรียกซ้ำ ๆ
      if (_isFetching) {
        log('⏳ Already fetching data, ignoring request');
        return;
      }

      // ตรวจสอบ cache
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        log(
          '📋 Using cached data (${DateTime.now().difference(_lastFetchTime!).inSeconds}s ago)',
        );
        return;
      }

      _isFetching = true;
      log('🚀 Starting dashboard data fetch...');
      emit(DashboardLoading());

      try {
        log('🏪 Fetching data from API...');

        List<DocDetails> shops = [];

        // Try MultiShopService first if authenticated
        if (AuthRepository.isAuthenticated) {
          try {
            log('🔐 Using authenticated API (multi-shop-summary)...');

            // Step 1: Fetch shop list to get names array
            log('📋 Fetching shop list for names...');
            final shopList = await MultiShopService.listShops();
            final shopNamesMap = <String, List<ShopName>>{};

            // Build a map of shopid -> names array
            for (final shop in shopList) {
              final shopId =
                  shop['shopid']?.toString() ??
                  shop['shop_id']?.toString() ??
                  shop['id']?.toString();
              if (shopId != null && shop['names'] != null) {
                try {
                  final namesList = (shop['names'] as List)
                      .map((n) => ShopName.fromJson(n as Map<String, dynamic>))
                      .toList();
                  shopNamesMap[shopId] = namesList;
                  log('📝 Loaded names for shop $shopId');
                } catch (e) {
                  log('⚠️ Error parsing names for shop $shopId: $e');
                }
              }
            }

            // Fetch multi-shop-summary for statistics
            final dateRange = MultiShopService.getCurrentYearDateRange();
            final response = await MultiShopService.fetchMultiShopSummary(
              startDate: dateRange['startDate']!,
              endDate: dateRange['endDate']!,
            );

            if (response.success && response.shops.isNotEmpty) {
              // Convert ShopSummary to DocDetails format with names from list-shop
              shops = response.shops.map((shop) {
                // Debug logging
                print('🏪 Shop: ${shop.shopCode}');
                print('  dailyAverage: ${shop.dailyAverage}');
                print('  monthlyAverage: ${shop.monthlyAverage}');
                print('  yearlyAverage: ${shop.yearlyAverage}');
                print('  imageCount: ${shop.imageCount}');

                return DocDetails(
                  shopid: shop.shopCode,
                  shopname: shop.shopName,
                  names: shopNamesMap[shop.shopCode], // Add names array
                  daily: [],
                  monthlySummary: {
                    'total': MonthlyData(
                      deposit: shop.totalCredit,
                      withdraw: shop.totalDebit,
                    ),
                  },
                  responsible: ResponsiblePerson(name: 'ระบบ', role: 'system'),
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                  timezone: 'Asia/Bangkok',
                  dailyImages: [],
                  dailyTransactions: [],
                  // Map new fields from multi-shop-summary API
                  dailyAverage: shop.dailyAverage,
                  monthlyAverage: shop.monthlyAverage,
                  yearlyAverage: shop.yearlyAverage,
                  // Use imagecount from multi-shop-summary API
                  localImageCount: shop.imageCount,
                );
              }).toList();

              log(
                '✅ Loaded ${shops.length} shops from cloud API with names and bill counts',
              );
            }
          } catch (e) {
            log('⚠️ Cloud API failed, falling back to local: $e');
          }
        }

        // Fallback to local DashboardService if no data from cloud
        if (shops.isEmpty) {
          log('📦 Using local DashboardService...');
          shops = await DashboardService.fetchDashboardData();
        }

        log('✅ Shops loaded: ${shops.length} branches');

        // คำนวณสถิติจากข้อมูล
        final totalShops = shops.length;
        final successShops = shops
            .where((s) => s.totalDeposit > 1000000)
            .length;
        final warningShops = shops
            .where((s) => s.totalDeposit >= 500000 && s.totalDeposit <= 1000000)
            .length;
        final errorShops = shops.where((s) => s.totalDeposit < 500000).length;

        emit(
          DashboardLoaded(
            doctotal: totalShops * 10,
            docsuccess: successShops * 10,
            docwarning: warningShops * 10,
            docerror: errorShops * 10,
            successRate: totalShops > 0
                ? ((successShops / totalShops) * 100).roundToDouble()
                : 0.0,
            warningRate: totalShops > 0
                ? ((warningShops / totalShops) * 100).roundToDouble()
                : 0.0,
            errorRate: totalShops > 0
                ? ((errorShops / totalShops) * 100).roundToDouble()
                : 0.0,
            totalshop: totalShops,
            shops: shops,
            filteredShops: shops,
            searchQuery: '',
            selectedFilter: 'all',
            selectedDateRange: DateTimeRange(
              start: DateUtils.dateOnly(DateTime.now()),
              end: DateUtils.dateOnly(DateTime.now()),
            ),
          ),
        );

        _lastFetchTime = DateTime.now();
        log('🎉 Dashboard data loaded successfully!');
      } catch (e) {
        log('💥 Error loading dashboard data: $e');
        emit(DashboardError(e.toString()));
      } finally {
        _isFetching = false;
      }
    });

    on<FetchShopDaily>((event, emit) async {
      log('🏪 Fetching daily data for shop: ${event.shopId}');

      try {
        final shopDailyImages = await ApiService.fetchShopDaily(event.shopId);
        log('✅ Shop daily data received: ${shopDailyImages.length} images');

        emit(
          ShopDailyLoaded(shopId: event.shopId, dailyImages: shopDailyImages),
        );

        log('🎉 Shop ${event.shopId} daily data loaded successfully!');
      } catch (e) {
        log('💥 Error loading shop daily data for ${event.shopId}: $e');
        emit(
          DashboardError('Failed to load daily data for shop ${event.shopId}'),
        );
      }
    });

    on<UpdateSearchQuery>((event, emit) {
      final currentState = state;
      if (currentState is DashboardLoaded) {
        final filteredShops = _filterShops(
          currentState.shops,
          event.query,
          currentState.selectedFilter,
          currentState.selectedDateRange,
        );
        emit(
          currentState.copyWith(
            searchQuery: event.query,
            filteredShops: filteredShops,
          ),
        );
      }
    });

    on<UpdateFilter>((event, emit) {
      final currentState = state;
      if (currentState is DashboardLoaded) {
        final filteredShops = _filterShops(
          currentState.shops,
          currentState.searchQuery,
          event.filter,
          currentState.selectedDateRange,
        );
        emit(
          currentState.copyWith(
            selectedFilter: event.filter,
            filteredShops: filteredShops,
          ),
        );
      }
    });

    on<UpdateSelectedDate>((event, emit) async {
      final currentState = state;
      if (currentState is DashboardLoaded) {
        // Re-fetch data with new date range
        if (event.dateRange != null && AuthRepository.isAuthenticated) {
          try {
            print('📅 Date range changed, re-fetching data...');
            print('  Start: ${event.dateRange!.start}');
            print('  End: ${event.dateRange!.end}');

            // Format dates for API
            final startDate =
                '${event.dateRange!.start.year}-${event.dateRange!.start.month.toString().padLeft(2, '0')}-${event.dateRange!.start.day.toString().padLeft(2, '0')}';
            final endDate =
                '${event.dateRange!.end.year}-${event.dateRange!.end.month.toString().padLeft(2, '0')}-${event.dateRange!.end.day.toString().padLeft(2, '0')}';

            print('  API startDate: $startDate');
            print('  API endDate: $endDate');

            // Fetch multi-shop-summary with new date range
            final response = await MultiShopService.fetchMultiShopSummary(
              startDate: startDate,
              endDate: endDate,
            );

            if (response.success && response.shops.isNotEmpty) {
              // Get shop names map from current state
              final shopNamesMap = <String, List<ShopName>>{};
              for (final shop in currentState.shops) {
                if (shop.shopid != null && shop.names != null) {
                  shopNamesMap[shop.shopid!] = shop.names!;
                }
              }

              // Convert to DocDetails
              final updatedShops = response.shops.map((shop) {
                print('🏪 Shop: ${shop.shopCode}');
                print('  dailyAverage: ${shop.dailyAverage}');
                print('  monthlyAverage: ${shop.monthlyAverage}');
                print('  yearlyAverage: ${shop.yearlyAverage}');
                print('  imageCount: ${shop.imageCount}');

                return DocDetails(
                  shopid: shop.shopCode,
                  shopname: shop.shopName,
                  names: shopNamesMap[shop.shopCode],
                  daily: [],
                  monthlySummary: {
                    'total': MonthlyData(
                      deposit: shop.totalCredit,
                      withdraw: shop.totalDebit,
                    ),
                  },
                  responsible: ResponsiblePerson(name: 'ระบบ', role: 'system'),
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                  timezone: 'Asia/Bangkok',
                  dailyImages: [],
                  dailyTransactions: [],
                  dailyAverage: shop.dailyAverage,
                  monthlyAverage: shop.monthlyAverage,
                  yearlyAverage: shop.yearlyAverage,
                  localImageCount: shop.imageCount,
                );
              }).toList();

              final filteredShops = _filterShops(
                updatedShops,
                currentState.searchQuery,
                currentState.selectedFilter,
                event.dateRange,
              );

              emit(
                currentState.copyWith(
                  shops: updatedShops,
                  selectedDateRange: event.dateRange,
                  filteredShops: filteredShops,
                ),
              );

              print('✅ Data updated with new date range');
              return;
            }
          } catch (e) {
            print('❌ Error fetching data with new date range: $e');
          }
        }

        // Fallback: just filter existing data
        final filteredShops = _filterShops(
          currentState.shops,
          currentState.searchQuery,
          currentState.selectedFilter,
          event.dateRange,
        );
        emit(
          currentState.copyWith(
            selectedDateRange: event.dateRange,
            filteredShops: filteredShops,
          ),
        );
      }
    });
  }

  List<DocDetails> _filterShops(
    List<DocDetails> shops,
    String searchQuery,
    String selectedFilter,
    DateTimeRange? selectedDateRange,
  ) {
    // Trim whitespace from search query
    final trimmedQuery = searchQuery.trim();

    log(
      '🔍 Filtering shops with query: "$trimmedQuery" (original: "$searchQuery")',
    );
    log('📊 Total shops to filter: ${shops.length}');

    final filtered = shops.where((shop) {
      final income = _getIncomeForPeriod(shop, selectedDateRange);

      // Enhanced search: search by shop ID, shop name, and names array
      bool matchesSearch = trimmedQuery.isEmpty;

      if (!matchesSearch && trimmedQuery.isNotEmpty) {
        final query = trimmedQuery.toLowerCase();

        // Debug: Log shop data for first few shops
        if (shops.indexOf(shop) < 3) {
          log('🏪 Shop ${shop.shopid}:');
          log('  - shopname: ${shop.shopname}');
          log('  - names array: ${shop.names?.map((n) => n.name).toList()}');
        }

        // Search by shop ID
        if (shop.shopid?.toLowerCase().contains(query) ?? false) {
          matchesSearch = true;
          log('✅ Match found in shopid: ${shop.shopid}');
        }

        // Search by shop name
        if (!matchesSearch &&
            (shop.shopname?.toLowerCase().contains(query) ?? false)) {
          matchesSearch = true;
          log('✅ Match found in shopname: ${shop.shopname}');
        }

        // Search by names array (Thai names)
        if (!matchesSearch && shop.names != null) {
          for (final name in shop.names!) {
            if (name.name?.toLowerCase().contains(query) ?? false) {
              matchesSearch = true;
              log('✅ Match found in names array: ${name.name}');
              break;
            }
          }
        }
      }

      switch (selectedFilter) {
        case 'safe':
          return income < 1000000 && matchesSearch;
        case 'warning':
          return income >= 1000000 && income <= 1800000 && matchesSearch;
        case 'exceeded':
          return income > 1800000 && matchesSearch;
        default:
          return matchesSearch;
      }
    }).toList();

    log('📋 Filtered results: ${filtered.length} shops');
    if (filtered.isNotEmpty && trimmedQuery.isNotEmpty) {
      log(
        '📝 Matched shops: ${filtered.map((s) => s.shopid).take(5).toList()}',
      );
    }

    return filtered;
  }

  double _getIncomeForPeriod(
    DocDetails shop,
    DateTimeRange? selectedDateRange,
  ) {
    // คำนวณยอดรายปีจาก monthly_summary
    if (shop.monthlySummary == null) return 0.0;

    double sum = 0.0;
    shop.monthlySummary!.forEach((String month, dynamic monthData) {
      if (monthData.deposit != null) {
        sum += monthData.deposit!;
      }
    });
    return sum;
  }
}
