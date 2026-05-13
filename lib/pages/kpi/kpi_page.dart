import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/kpi/kpi_bloc.dart';
import '../../blocs/kpi/kpi_event.dart';
import '../../blocs/kpi/kpi_state.dart';
import '../../components/dashboard_loading_widgets.dart';
import '../../services/employee_mapping_service.dart';
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
  String _selectedBranch = 'ทุกร้าน';
  DateTime? _documentReceiveStartDate;
  DateTime? _documentReceiveEndDate;

  // Shop selection state
  List<String> _selectedShopIds = [];
  List<String> _selectedShopNames = [];

  // Selected Employee Tags
  final List<String> _selectedEmployeeIds = [];

  // Pagination state
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // State for expanded rows
  final Set<String> _expandedEmployeeIds = {};

  // Font size scale (1.0 = normal, 1.2 = large, 1.4 = extra large)
  double _fontScale = 1.0;

  Map<String, String> _nameMappings = {};

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    final mappings = await EmployeeMappingService.getAllMappings();
    if (mounted) {
      setState(() {
        _nameMappings = mappings;
      });
    }
  }

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
                        setState(() {
                          _selectedShopIds = [];
                          _selectedShopNames = [];
                        });
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
                            KpiFilterSection(
                              searchController: _searchController,
                              selectedBranch: _selectedBranch,
                              documentReceiveStartDate: _documentReceiveStartDate,
                              documentReceiveEndDate: _documentReceiveEndDate,
                              employees: state.employees,
                              shops: state.shops,
                              selectedShopIds: _selectedShopIds,
                              selectedShopNames: _selectedShopNames,
                              isSearching: state.isSearching,
                              selectedEmployeeIds: _selectedEmployeeIds,
                              nameMappings: _nameMappings,
                              onBranchChanged: (val) {
                                setState(() => _selectedBranch = val);
                              },
                              onShopSelected: (shopIds, shopNames) {
                                setState(() {
                                  _selectedShopIds = shopIds;
                                  _selectedShopNames = shopNames;
                                });
                              },
                              onEmployeeSelected: (employee) {
                                setState(() {
                                  if (!_selectedEmployeeIds.contains(employee.id)) {
                                    _selectedEmployeeIds.add(employee.id);
                                  }
                                });
                              },
                              onEmployeeRemoved: (employee) {
                                setState(() {
                                  _selectedEmployeeIds.remove(employee.id);
                                });
                              },
                              onStartDateChanged: (date) {
                                setState(() => _documentReceiveStartDate = date);
                              },
                              onEndDateChanged: (date) {
                                setState(() => _documentReceiveEndDate = date);
                              },
                              onSearch: () {
                                context.read<KpiBloc>().add(
                                  SelectShopAndSearch(
                                    shopIds: _selectedShopIds,
                                    shopNames: _selectedShopNames,
                                    startDate: _documentReceiveStartDate,
                                    endDate: _documentReceiveEndDate,
                                    query: _searchController.text,
                                    selectedEmployeeIds: _selectedEmployeeIds,
                                  ),
                                );
                              },
                              onClearSearch: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedEmployeeIds.clear();
                                  _documentReceiveStartDate = null;
                                  _documentReceiveEndDate = null;
                                });
                                context.read<KpiBloc>().add(
                                  SelectShopAndSearch(
                                    shopIds: _selectedShopIds,
                                    shopNames: _selectedShopNames,
                                  ),
                                );
                              },
                              onRefresh: () {
                                setState(() {
                                  _selectedShopIds = [];
                                  _selectedShopNames = [];
                                });
                                context.read<KpiBloc>().add(LoadKpiData());
                              },
                            ),
                            const SizedBox(height: 15),
                            KpiEmployeeTable(
                              employees: state.filteredEmployees,
                              expandedEmployeeIds: _expandedEmployeeIds,
                              currentPage: _currentPage,
                              rowsPerPage: _rowsPerPage,
                              fontScale: _fontScale,
                              totalEmployees: state.filteredEmployees.length,
                              nameMappings: _nameMappings,
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
      title: const Row(
        children: [
          Icon(Icons.analytics_rounded, color: Color(0xFF3B82F6), size: 22),
          SizedBox(width: 8),
          Text(
            'KPI Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
