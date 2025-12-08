import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/models_old/doc_details.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';
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
        log('🏪 Fetching real data from API/journal...');

        // ใช้ DashboardService เพื่อดึงข้อมูลจริงจาก API
        final shops = await DashboardService.fetchDashboardData();

        log('✅ Real shops loaded: ${shops.length} branches');

        // คำนวณสถิติจากข้อมูลจริง
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
            doctotal: totalShops * 10, // จำนวนเอกสารประมาณ
            docsuccess: successShops * 10,
            docwarning: warningShops * 10,
            docerror: errorShops * 10,
            success_rate: totalShops > 0
                ? ((successShops / totalShops) * 100).round()
                : 0,
            warning_rate: totalShops > 0
                ? ((warningShops / totalShops) * 100).round()
                : 0,
            error_rate: totalShops > 0
                ? ((errorShops / totalShops) * 100).round()
                : 0,
            totalshop: totalShops,
            shops: shops,
            filteredShops: shops,
            searchQuery: '',
            selectedFilter: 'all',
            selectedDate: DateTime.now(),
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
          currentState.selectedDate,
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
          currentState.selectedDate,
        );
        emit(
          currentState.copyWith(
            selectedFilter: event.filter,
            filteredShops: filteredShops,
          ),
        );
      }
    });

    on<UpdateSelectedDate>((event, emit) {
      final currentState = state;
      if (currentState is DashboardLoaded) {
        final filteredShops = _filterShops(
          currentState.shops,
          currentState.searchQuery,
          currentState.selectedFilter,
          event.date,
        );
        emit(
          currentState.copyWith(
            selectedDate: event.date,
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
    DateTime? selectedDate,
  ) {
    return shops.where((shop) {
      final income = _getIncomeForPeriod(shop, selectedDate);
      final matchesSearch =
          searchQuery.isEmpty ||
          (shop.shopname?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

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
  }

  double _getIncomeForPeriod(DocDetails shop, DateTime? selectedDate) {
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
