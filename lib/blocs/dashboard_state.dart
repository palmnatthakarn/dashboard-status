import 'package:flutter/material.dart';
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
  final double successRate;
  final double warningRate;
  final double errorRate;
  final int totalshop;
  final List<DocDetails> shops;
  final List<DocDetails> filteredShops;
  final String searchQuery;
  final String selectedFilter;
  final DateTimeRange? selectedDateRange;

  DashboardLoaded({
    required this.doctotal,
    required this.docsuccess,
    required this.docwarning,
    required this.docerror,
    required this.successRate,
    required this.warningRate,
    required this.errorRate,
    required this.totalshop,
    required this.shops,
    required this.filteredShops,
    required this.searchQuery,
    required this.selectedFilter,
    required this.selectedDateRange,
  });

  DashboardLoaded copyWith({
    int? doctotal,
    int? docsuccess,
    int? docwarning,
    int? docerror,
    double? successRate,
    double? warningRate,
    double? errorRate,
    int? totalshop,
    List<DocDetails>? shops,
    List<DocDetails>? filteredShops,
    String? searchQuery,
    String? selectedFilter,
    DateTimeRange? selectedDateRange,
  }) {
    return DashboardLoaded(
      doctotal: doctotal ?? this.doctotal,
      docsuccess: docsuccess ?? this.docsuccess,
      docwarning: docwarning ?? this.docwarning,
      docerror: docerror ?? this.docerror,
      successRate: successRate ?? this.successRate,
      warningRate: warningRate ?? this.warningRate,
      errorRate: errorRate ?? this.errorRate,
      totalshop: totalshop ?? this.totalshop,
      shops: shops ?? this.shops,
      filteredShops: filteredShops ?? this.filteredShops,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
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
