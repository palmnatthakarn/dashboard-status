import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'blocs/dashboard_bloc_exports.dart';
import 'conponents/shop_data_table.dart';
import 'conponents/dashboard_filter_section.dart';
import 'conponents/dashboard_statistics_grid.dart';
import 'conponents/dashboard_loading_widgets.dart';
import 'utils/dashboard_helper.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          leading: MediaQuery.of(context).size.width < 800
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              : null,
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
                                selectedDate: state.selectedDate,
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
                                      state.selectedDate,
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
                                      state.selectedDate,
                                    ),
                              ),

                              const SizedBox(height: 16),

                              // Data Table
                              ShopDataTable(
                                shops: state.filteredShops,
                                selectedDate: state.selectedDate,
                                getIncomeForPeriod:
                                    DashboardHelper.getIncomeForPeriod,
                                moneyFormat: _moneyTh,
                                onDateChanged: (DateTime? date) {
                                  context.read<DashboardBloc>().add(
                                    UpdateSelectedDate(date),
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
