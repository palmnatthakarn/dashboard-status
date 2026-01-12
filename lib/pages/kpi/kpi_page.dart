import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/kpi/kpi_bloc.dart';
import '../../blocs/kpi/kpi_event.dart';
import '../../blocs/kpi/kpi_state.dart';
import '../../components/dashboard_loading_widgets.dart';
import 'kpi_bottleneck_section.dart';
import 'kpi_employee_table.dart';
import 'kpi_filter_section.dart';

class KpiPage extends StatelessWidget {
  const KpiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KpiBloc()..add(LoadKpiData()),
      child: const KpiPageContent(),
    );
  }
}

class KpiPageContent extends StatefulWidget {
  const KpiPageContent({super.key});

  @override
  State<KpiPageContent> createState() => _KpiPageContentState();
}

class _KpiPageContentState extends State<KpiPageContent> {
  final _searchController = TextEditingController();
  final _taxIdController = TextEditingController();
  String _selectedBranch = 'ทุกร้าน';
  DateTime? _documentReceiveStartDate;
  DateTime? _documentReceiveEndDate;
  DateTimeRange? _previousDateRange;
  DateTimeRange? _statusCheckDateRange;

  // Shop selection state
  String? _selectedShopId;
  String? _selectedShopName;

  // Pagination state
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // State for expanded rows
  final Set<String> _expandedEmployeeIds = {};

  // Font size scale (1.0 = normal, 1.2 = large, 1.4 = extra large)
  double _fontScale = 1.0;

  // Filter section expansion state
  final bool _isFilterExpanded = true;
  bool _isAdvancedFilterExpanded = false;

  void _toggleExpansion(String id) {
    setState(() {
      if (_expandedEmployeeIds.contains(id)) {
        _expandedEmployeeIds.remove(id);
      } else {
        _expandedEmployeeIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KpiBloc, KpiState>(
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: _buildAppBar(),
              body: Builder(
                builder: (context) {
                  if (state is KpiLoading) {
                    return const DashboardLoadingWidget();
                  }

                  if (state is KpiError) {
                    return DashboardErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<KpiBloc>().add(LoadKpiData()),
                    );
                  }

                  if (state is KpiLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<KpiBloc>().add(LoadKpiData());
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KpiBottleneckSection(
                              state: state,
                              onStatusSelected: (status) {
                                context.read<KpiBloc>().add(
                                  FilterByStatus(status ?? 'all'),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                            if (_isFilterExpanded) ...[
                              KpiFilterSection(
                                searchController: _searchController,
                                taxIdController: _taxIdController,
                                selectedBranch: _selectedBranch,
                                documentReceiveStartDate:
                                    _documentReceiveStartDate,
                                documentReceiveEndDate: _documentReceiveEndDate,
                                previousDateRange: _previousDateRange,
                                statusCheckDateRange: _statusCheckDateRange,
                                isAdvancedFilterExpanded:
                                    _isAdvancedFilterExpanded,
                                employees: state.employees,
                                shops: state.shops,
                                selectedShopId: state.selectedShopId,
                                selectedShopName: state.selectedShopName,
                                isSearching: state.isSearching,
                                onToggleAdvancedFilter: () {
                                  setState(() {
                                    _isAdvancedFilterExpanded =
                                        !_isAdvancedFilterExpanded;
                                  });
                                },
                                onBranchChanged: (val) {
                                  setState(() => _selectedBranch = val);
                                },
                                onShopSelected: (shopId, shopName) {
                                  setState(() {
                                    _selectedShopId = shopId;
                                    _selectedShopName = shopName;
                                  });
                                },
                                onStartDateChanged: (date) {
                                  setState(
                                    () => _documentReceiveStartDate = date,
                                  );
                                },
                                onEndDateChanged: (date) {
                                  setState(
                                    () => _documentReceiveEndDate = date,
                                  );
                                },
                                onPreviousDateRangeChanged: (range) {
                                  setState(() => _previousDateRange = range);
                                },
                                onStatusCheckDateRangeChanged: (range) {
                                  setState(() => _statusCheckDateRange = range);
                                },
                                onSearch: () {
                                  context.read<KpiBloc>().add(
                                    SelectShopAndSearch(
                                      shopId: _selectedShopId,
                                      shopName: _selectedShopName,
                                      startDate: _documentReceiveStartDate,
                                      endDate: _documentReceiveEndDate,
                                      query: _searchController.text,
                                    ),
                                  );
                                },
                                onClearSearch: () {
                                  setState(() => _searchController.clear());
                                },
                                onRefresh: () {
                                  context.read<KpiBloc>().add(LoadKpiData());
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                            KpiEmployeeTable(
                              employees: state.filteredEmployees,
                              expandedEmployeeIds: _expandedEmployeeIds,
                              currentPage: _currentPage,
                              rowsPerPage: _rowsPerPage,
                              fontScale: _fontScale,
                              totalEmployees: state.filteredEmployees.length,
                              onToggleExpand: _toggleExpansion,
                              onPageChanged: (page) {
                                setState(() => _currentPage = page);
                              },
                              onRowsPerPageChanged: (rows) {
                                setState(() {
                                  _rowsPerPage = rows;
                                  _currentPage = 1;
                                });
                              },
                              onFontScaleChanged: (scale) {
                                setState(() => _fontScale = scale);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            if (state is KpiLoaded && state.isSearching)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const DashboardLoadingWidget(),
                ),
              ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Text(
            'KPI Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
