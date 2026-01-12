import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'blocs/bloc_exports.dart';
import 'components/shop_data_table.dart';
import 'components/dashboard_filter_section.dart';
import 'components/dashboard_statistics_grid.dart';
import 'components/dashboard_loading_widgets.dart';
import 'utils/dashboard_helper.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final _moneyTh = NumberFormat.currency(
    locale: 'th_TH',
    symbol: '฿',
    decimalDigits: 2,
  );
  final _numFmt = NumberFormat.decimalPattern('th_TH');

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardBloc()..add(FetchDashboardData()),
        ),
        BlocProvider(create: (context) => ImageApprovalBloc()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            '',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              // Debug: แสดง state ปัจจุบัน
              print('📊 Current Dashboard State: ${state.runtimeType}');

              if (state is DashboardInitial) {
                // แสดง loading เมื่ออยู่ใน initial state
                return const DashboardLoadingWidget();
              }

              if (state is DashboardLoading) {
                return const DashboardLoadingWidget();
              }

              if (state is DashboardLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<DashboardBloc>().add(FetchDashboardData());
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Statistics Cards
                              DashboardStatisticsGrid(
                                shops: state.shops,
                                selectedFilter: state.selectedFilter,
                                selectedDateRange: state.selectedDateRange,
                                onFilterTap: (filter) {
                                  context.read<DashboardBloc>().add(
                                    UpdateFilter(
                                      state.selectedFilter == filter
                                          ? 'all'
                                          : filter,
                                    ),
                                  );
                                },
                                getShopCountByStatus: (shops, status) =>
                                    DashboardHelper.getShopCountByStatus(
                                      shops,
                                      status,
                                      state.selectedDateRange,
                                    ),
                                getDocumentCounts: (shops) =>
                                    DashboardHelper.getDocumentCounts(shops),
                                numFmt: _numFmt,
                              ),

                              const SizedBox(height: 24),

                              // Filters Section
                              DashboardFilterSection(
                                searchQuery: state.searchQuery,
                                selectedFilter: state.selectedFilter,
                                shops: state.shops,
                                onSearchChanged: (query) {
                                  context.read<DashboardBloc>().add(
                                    UpdateSearchQuery(query),
                                  );
                                },
                                onFilterChanged: (filter) {
                                  context.read<DashboardBloc>().add(
                                    UpdateFilter(filter),
                                  );
                                },
                                getShopCountByStatus: (status) =>
                                    DashboardHelper.getShopCountByStatus(
                                      state.shops,
                                      status,
                                      state.selectedDateRange,
                                    ),
                              ),

                              const SizedBox(height: 16),

                              // Data Table
                              ShopDataTable(
                                shops: state.filteredShops,
                                selectedDateRange: state.selectedDateRange,
                                getIncomeForPeriod:
                                    DashboardHelper.getIncomeForPeriod,
                                moneyFormat: _moneyTh,
                                onDateRangeChanged: (DateTimeRange? dateRange) {
                                  context.read<DashboardBloc>().add(
                                    UpdateSelectedDate(dateRange),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is DashboardError) {
                return DashboardErrorWidget(
                  message: state.message,
                  onRetry: () =>
                      context.read<DashboardBloc>().add(FetchDashboardData()),
                );
              }

              return const Center(child: Text('ไม่พบข้อมูล'));
            },
          ),
        ),
      ),
    );
  }
}
