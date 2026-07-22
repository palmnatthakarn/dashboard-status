import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/kpi/kpi_bloc.dart';
import '../../blocs/kpi/kpi_event.dart';
import '../../blocs/kpi/kpi_state.dart';
import '../../components/dashboard_loading_widgets.dart';
import '../../services/auth_repository.dart';
import '../../services/employee_mapping_service.dart';
import '../../services/pdf_export_service.dart';
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

  // Default to the current month, matching KpiBloc's default fetch window
  // (see KpiBloc._onLoadKpiData). Without this, these stayed null, so the
  // date picker showed blank and pressing "search" sent null dates, which
  // makes KpiBloc fetch ALL-time GL journal data instead of just this
  // month — silently undoing the date-scoping optimization.
  DateTime? _documentReceiveStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _documentReceiveEndDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );

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

  int _remainingToRecord(int requiredToRecord, int recorded) {
    final value = requiredToRecord - recorded;
    return value > 0 ? value : 0;
  }

  Future<void> _exportPdf(KpiLoaded state) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('กำลังสร้างไฟล์ PDF...'),
          ],
        ),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 2),
      ),
    );

    // Each employee gets its own bold name banner (with a quick summary),
    // followed by a small table listing exactly which shop(s) they worked
    // on — so it's unambiguous who did what, where, instead of one long
    // flat table where employee/shop rows look almost identical.
    const subHeaders = [
      'ร้าน',
      'จำนวน',
      'รอตรวจสอบ',
      'ผ่าน',
      'ไม่ผ่าน',
      'ไม่บันทึก',
      'ไม่ต้องอนุมัติ',
      'ต้องบันทึก',
      'บันทึก',
      'คงเหลือ',
      'เสร็จ',
    ];

    final groups = <KpiPdfGroup>[];
    for (final emp in state.filteredEmployees) {
      final displayName = _nameMappings[emp.name] ?? emp.name;
      final remaining = _remainingToRecord(
        emp.requiredToRecordDocuments,
        emp.referenceCount,
      );

      final shopRows = <List<String>>[
        for (final detail in emp.companyDetails)
          [
            detail.shopName ?? detail.company,
            '${detail.totalBillCount}',
            '${detail.waitingVerify}',
            '${detail.passed}',
            '${detail.cancelled}',
            '${detail.notRecorded}',
            '${detail.notRequiredApproval}',
            '${detail.requiredToRecord}',
            '${detail.referenceCount}',
            '${_remainingToRecord(detail.requiredToRecord, detail.referenceCount)}',
            '${detail.completed}',
          ],
      ];
      // No per-shop breakdown available — still show the employee's own
      // totals as a single row so the shop count isn't just silently
      // dropped.
      if (shopRows.isEmpty) {
        shopRows.add([
          emp.branch,
          '${emp.totalDocuments}',
          '${emp.waitingVerify}',
          '${emp.passedDocuments}',
          '${emp.cancelledDocuments}',
          '${emp.notRecordedDocuments}',
          '${emp.notRequiredApprovalDocuments}',
          '${emp.requiredToRecordDocuments}',
          '${emp.referenceCount}',
          '$remaining',
          '${emp.completedDocuments}',
        ]);
      }

      groups.add(
        KpiPdfGroup(
          name: displayName,
          summary:
              'รวม ${emp.totalDocuments} รายการ · เสร็จ ${emp.completedDocuments} · คงเหลือ $remaining',
          rows: shopRows,
        ),
      );
    }

    await PdfExportService.exportGroupedTableToPdf(
      title: 'รายงาน KPI',
      subHeaders: subHeaders,
      groups: groups,
      startDate: _documentReceiveStartDate,
      endDate: _documentReceiveEndDate,
      userName: AuthRepository.username ?? 'ผู้ใช้งาน',
    );
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
    return BlocConsumer<KpiBloc, KpiState>(
      listener: (context, state) {
        // Same unrecoverable-session handling as the Overview page: don't
        // leave the user on a retry button that will fail forever.
        if (state is KpiError &&
            AuthRepository.isSessionExpiredError(state.message)) {
          context.read<AuthBloc>().add(LogoutRequested());
        }
      },
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
                          final now = DateTime.now();
                          _documentReceiveStartDate =
                              DateTime(now.year, now.month, 1);
                          _documentReceiveEndDate =
                              DateTime(now.year, now.month + 1, 0);
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
                                  // Keep the date picker in sync with
                                  // LoadKpiData()'s own current-month
                                  // default below.
                                  final now = DateTime.now();
                                  _documentReceiveStartDate =
                                      DateTime(now.year, now.month, 1);
                                  _documentReceiveEndDate =
                                      DateTime(now.year, now.month + 1, 0);
                                });
                                context.read<KpiBloc>().add(LoadKpiData());
                              },
                              onExportPdf: () => _exportPdf(state),
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
