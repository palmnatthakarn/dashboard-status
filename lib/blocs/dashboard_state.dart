import '../models/doc_details.dart';
import '../models/daily_images.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int doctotal;
  final int docsuccess;
  final int docwarning;
  final int docerror;
  final int success_rate;
  final int warning_rate;
  final int error_rate;
  final int totalshop;
  final List<DocDetails> shops;
  final List<DocDetails> filteredShops;
  final String searchQuery;
  final String selectedFilter;
  final DateTime? selectedDate;

  DashboardLoaded({
    required this.doctotal,
    required this.docsuccess,
    required this.docwarning,
    required this.docerror,
    required this.success_rate,
    required this.warning_rate,
    required this.error_rate,
    required this.totalshop,
    required this.shops,
    required this.filteredShops,
    required this.searchQuery,
    required this.selectedFilter,
    required this.selectedDate,
  });

  DashboardLoaded copyWith({
    int? doctotal,
    int? docsuccess,
    int? docwarning,
    int? docerror,
    int? successRate,
    int? warningRate,
    int? errorRate,
    int? totalshop,
    List<DocDetails>? shops,
    List<DocDetails>? filteredShops,
    String? searchQuery,
    String? selectedFilter,
    DateTime? selectedDate,
  }) {
    return DashboardLoaded(
      doctotal: doctotal ?? this.doctotal,
      docsuccess: docsuccess ?? this.docsuccess,
      docwarning: docwarning ?? this.docwarning,
      docerror: docerror ?? this.docerror,
      success_rate: successRate ?? this.success_rate,
      warning_rate: warningRate ?? this.warning_rate,
      error_rate: errorRate ?? this.error_rate,
      totalshop: totalshop ?? this.totalshop,
      shops: shops ?? this.shops,
      filteredShops: filteredShops ?? this.filteredShops,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class ShopDailyLoaded extends DashboardState {
  final String shopId;
  final List<DailyImage> dailyImages;

  ShopDailyLoaded({required this.shopId, required this.dailyImages});
}
