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
  String _selectedBranch = 'ทุกสาขา';
  DateTime? _documentReceiveStartDate;
  DateTime? _documentReceiveEndDate;
  DateTimeRange? _previousDateRange;
  DateTimeRange? _statusCheckDateRange;

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

  void _applyManualSearch() {
    context.read<KpiBloc>().add(
      ApplyAllFilters(
        query: _searchController.text,
        branch: _selectedBranch,
        startDate: _documentReceiveStartDate,
        endDate: _documentReceiveEndDate,
        taxId: _taxIdController.text,
        previousDateStart: _previousDateRange?.start,
        previousDateEnd: _previousDateRange?.end,
        statusCheckDateStart: _statusCheckDateRange?.start,
        statusCheckDateEnd: _statusCheckDateRange?.end,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: BlocBuilder<KpiBloc, KpiState>(
        builder: (context, state) {
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
                        documentReceiveStartDate: _documentReceiveStartDate,
                        documentReceiveEndDate: _documentReceiveEndDate,
                        previousDateRange: _previousDateRange,
                        statusCheckDateRange: _statusCheckDateRange,
                        isAdvancedFilterExpanded: _isAdvancedFilterExpanded,
                        employees: state.employees,
                        onToggleAdvancedFilter: () {
                          setState(() {
                            _isAdvancedFilterExpanded =
                                !_isAdvancedFilterExpanded;
                          });
                        },
                        onBranchChanged: (val) {
                          setState(() => _selectedBranch = val);
                        },
                        onStartDateChanged: (date) {
                          setState(() => _documentReceiveStartDate = date);
                        },
                        onEndDateChanged: (date) {
                          setState(() => _documentReceiveEndDate = date);
                        },
                        onPreviousDateRangeChanged: (range) {
                          setState(() => _previousDateRange = range);
                        },
                        onStatusCheckDateRangeChanged: (range) {
                          setState(() => _statusCheckDateRange = range);
                        },
                        onSearch: _applyManualSearch,
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
