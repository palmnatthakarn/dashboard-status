import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/doc_details.dart';
import '../services/api_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<FetchDashboardData>((event, emit) async {
      log('🚀 Starting dashboard data fetch...');
      emit(DashboardLoading());

      try {
        log('📊 Fetching summary data...');
        final summary = await ApiService.fetchSummary();
        log(
          '✅ Summary data received: ${summary.completedCount} completed, ${summary.pendingCount} pending, ${summary.failedCount} failed',
        );

        log('🏪 Fetching shops data...');
        final shopsResponse = await ApiService.fetchShops();
        log('✅ Shops data received: ${shopsResponse.docdetails.length} shops');

        // ตรวจสอบว่ามีข้อมูลร้านค้าหรือไม่
        if (shopsResponse.docdetails.isEmpty) {
          log('⚠️ No shops found in response');
          emit(
            DashboardLoaded(
              doctotal: summary.doctotal,
              docsuccess: summary.docsuccess,
              docwarning: summary.docwarning,
              docerror: summary.docerror,
              success_rate: summary.success_rate,
              warning_rate: summary.warning_rate,
              error_rate: summary.error_rate,
              totalshop: summary.totalshop,
              shops: [],
              filteredShops: [],
              searchQuery: '',
              selectedFilter: 'all',
              selectedDate: null,
            ),
          );
          return;
        }

        log('🖼️ Fetching daily images data...');

        // ดึงข้อมูลจาก /daily-images API
        final dailyImages = await ApiService.fetchDailyImages();
        log('📸 Fetched ${dailyImages.length} daily images');

        // ผสานข้อมูล dailyImages และ daily transactions เข้ากับ shops
        final updatedShops = <DocDetails>[];
        for (final shop in shopsResponse.docdetails) {
          // หา dailyImages ที่ตรงกับ shopId
          final shopImages = dailyImages
              .where((image) => image.shopid == shop.shopid)
              .toList();

          // ดึงข้อมูล daily transactions สำหรับร้านนี้
          List<dynamic>? dailyTransactions;
          try {
            final dailyResponse = await ApiService.fetchShopDailyTransactions(
              shop.shopid ?? '',
            );
            dailyTransactions = dailyResponse?.daily.cast<dynamic>();
            log(
              '💰 Shop ${shop.shopname}: ${dailyTransactions?.length ?? 0} daily transactions',
            );
          } catch (e) {
            log(
              '⚠️ Failed to fetch daily transactions for ${shop.shopname}: $e',
            );
            dailyTransactions = null;
          }

          // สร้าง DocDetails ใหม่พร้อมข้อมูล dailyImages และ dailyTransactions
          final updatedShop = DocDetails(
            shopid: shop.shopid,
            shopname: shop.shopname,
            monthlySummary: shop.monthlySummary,
            daily: shop.daily,
            responsible: shop.responsible,
            backupResponsible: shop.backupResponsible,
            createdAt: shop.createdAt,
            updatedAt: shop.updatedAt,
            timezone: shop.timezone,
            dailyImages: shopImages, // เพิ่มข้อมูลรูปภาพ
            dailyTransactions: dailyTransactions, // เพิ่มข้อมูล transactions
          );

          updatedShops.add(updatedShop);
          log(
            '🏪 Shop ${shop.shopname}: ${shopImages.length} images, ${dailyTransactions?.length ?? 0} transactions',
          );
        }

        emit(
          DashboardLoaded(
            doctotal: summary.doctotal,
            docsuccess: summary.docsuccess,
            docwarning: summary.docwarning,
            docerror: summary.docerror,
            success_rate: summary.success_rate,
            warning_rate: summary.warning_rate,
            error_rate: summary.error_rate,
            totalshop: summary.totalshop,
            shops: updatedShops, // ใช้ shops ที่อัปเดตแล้ว
            filteredShops: updatedShops,
            searchQuery: '',
            selectedFilter: 'all',
            selectedDate: null,
          ),
        );

        log('🎉 Dashboard data loaded successfully!');
      } catch (e) {
        log('💥 Error loading dashboard data: $e');
        log('🔄 Using fallback data...');

        emit(
          DashboardLoaded(
            doctotal: 0,
            docsuccess: 0,
            docwarning: 0,
            docerror: 0,
            success_rate: 0,
            warning_rate: 0,
            error_rate: 0,
            totalshop: 0,
            shops: [],
            filteredShops: [],
            searchQuery: '',
            selectedFilter: 'all',
            selectedDate: null,
          ),
        );
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
