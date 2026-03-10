import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/doc_details.dart';
import '../core/constants/app_constants.dart';
import '../repositories/shop_repository.dart';
import '../services/auth_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ShopRepository _shopRepository;

  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 2);
  bool _isFetching = false;

  DashboardBloc({ShopRepository? shopRepository})
      : _shopRepository = shopRepository ?? ShopRepository(),
        super(DashboardInitial()) {
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

        shops = await _shopRepository.fetchShopsSummary();

        log('✅ Shops loaded: ${shops.length} branches');

        // คำนวณสถิติจากข้อมูล
        final totalShops = shops.length;
        final successShops = shops
            .where((s) => s.totalDeposit > AppConstants.successDepositThreshold)
            .length;
        final warningShops = shops
            .where(
              (s) =>
                  s.totalDeposit >= AppConstants.warningDepositMin &&
                  s.totalDeposit <= AppConstants.warningDepositMax,
            )
            .length;
        final errorShops = shops
            .where((s) => s.totalDeposit < AppConstants.warningDepositMin)
            .length;

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
        final shopDailyImages = await _shopRepository.fetchShopDaily(event.shopId);
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
        // Re-fetch data with new date range when authenticated
        if (event.dateRange != null && AuthRepository.isAuthenticated) {
          try {
            log('📅 Date range changed: ${event.dateRange!.start} → ${event.dateRange!.end}');

            final startDate =
                '${event.dateRange!.start.year}-${event.dateRange!.start.month.toString().padLeft(2, '0')}-${event.dateRange!.start.day.toString().padLeft(2, '0')}';
            final endDate =
                '${event.dateRange!.end.year}-${event.dateRange!.end.month.toString().padLeft(2, '0')}-${event.dateRange!.end.day.toString().padLeft(2, '0')}';

            log('  API range: $startDate → $endDate');

            final updatedShops = await _shopRepository.fetchShopsSummary(
              startDate: startDate,
              endDate: endDate,
            );

            if (updatedShops.isNotEmpty) {
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

              log('✅ Data updated with new date range');
              return;
            }
          } catch (e) {
            log('❌ Error fetching data with new date range: $e');
          }
        }

        // Fallback: filter existing data with new date range
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
          return income < AppConstants.safeIncomeMax && matchesSearch;
        case 'warning':
          return income >= AppConstants.warningIncomeMin &&
              income <= AppConstants.warningIncomeMax &&
              matchesSearch;
        case 'exceeded':
          return income > AppConstants.exceededIncomeMin && matchesSearch;
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
