import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal.dart';
import '../models/account_class.dart';
import '../widgets/journal/journal_table.dart';
import '../widgets/journal/journal_chart.dart';
import '../widgets/journal/journal_empty_state.dart';
import '../widgets/journal/journal_summary_bar.dart';

class JournalPage extends StatefulWidget {
  final String branchSync;
  final List<Journal> journals;

  const JournalPage({
    super.key,
    required this.branchSync,
    required this.journals,
  });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  // Formatters
  final _numFmt = NumberFormat('#,##0.00');
  final _compactFmt = NumberFormat.compactCurrency(
    symbol: '',
    decimalDigits: 2,
  );

  // Controllers
  final _searchController = TextEditingController();

  // State
  String _search = '';
  String _typeFilter = 'ALL';
  String _dateFilter = 'ALL';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _isChartView = false;

  // Cache
  List<Journal>? _cachedFiltered;
  String _lastCacheKey = '';

  // Date filter options
  static const _dateFilters = [
    ['ALL', 'ทั้งหมด'],
    ['TODAY', 'วันนี้'],
    ['7DAYS', '7 วันล่าสุด'],
    ['MONTH', 'เดือนนี้'],
    ['QUARTER', 'ไตรมาสนี้'],
    ['3QUARTERS', '3 ไตรมาส'],
    ['YEAR', 'ปีนี้'],
  ];

  DateTimeRange? _getDateRange(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (filter) {
      'TODAY' => DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 1)),
      ),
      '7DAYS' => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today.add(const Duration(days: 1)),
      ),
      'MONTH' => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: today.add(const Duration(days: 1)),
      ),
      'QUARTER' => () {
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, quarterMonth, 1),
          end: today.add(const Duration(days: 1)),
        );
      }(),
      '3QUARTERS' => () {
        final currentQuarter = (now.month - 1) ~/ 3;
        final startQuarter = (currentQuarter - 2).clamp(0, 3);
        final startMonth = startQuarter * 3 + 1;
        final startYear = currentQuarter < 2 ? now.year - 1 : now.year;
        return DateTimeRange(
          start: DateTime(startYear, startMonth, 1),
          end: today.add(const Duration(days: 1)),
        );
      }(),
      'YEAR' => DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: today.add(const Duration(days: 1)),
      ),
      _ => null,
    };
  }

  // Helper methods
  AccountClass _getAccountClass(String? t) => AccountClass.fromString(t);
  String _typeDisplay(String? t) => _getAccountClass(t).displayName;
  Color _typeColor(String? t) => _getAccountClass(t).color;

  // Calculations
  double _calcIncome(Iterable<Journal> list) {
    double total = 0.0;
    for (final j in list) {
      if (_getAccountClass(j.accountType) == AccountClass.income) {
        total += (j.credit ?? 0) - (j.debit ?? 0);
      }
    }
    return total;
  }

  double _calcExpenses(Iterable<Journal> list) {
    double total = 0.0;
    for (final j in list) {
      final accountClass = _getAccountClass(j.accountType);
      if (accountClass == AccountClass.expenses ||
          accountClass == AccountClass.liabilities) {
        total += (j.debit ?? 0) - (j.credit ?? 0);
      }
    }
    return total;
  }

  double _calcTotalDebit(Iterable<Journal> list) =>
      list.fold(0.0, (p, e) => p + (e.debit ?? 0));

  double _calcTotalCredit(Iterable<Journal> list) =>
      list.fold(0.0, (p, e) => p + (e.credit ?? 0));

  // Filtered & sorted data
  List<Journal> get _filtered {
    final cacheKey =
        '$_search|$_typeFilter|$_dateFilter|$_sortColumnIndex|$_sortAscending';
    if (_cachedFiltered != null && _lastCacheKey == cacheKey) {
      return _cachedFiltered!;
    }

    // Filter by date
    final dateRange = _getDateRange(_dateFilter);
    Iterable<Journal> res = widget.journals.where((j) {
      if (dateRange == null) return true;
      final date = j.dateTime;
      if (date == null) return false;
      return date.isAfter(
            dateRange.start.subtract(const Duration(seconds: 1)),
          ) &&
          date.isBefore(dateRange.end);
    });

    // Filter by type
    res = res.where((j) {
      if (_typeFilter == 'ALL') return true;
      final accountClass = _getAccountClass(j.accountType);
      return switch (_typeFilter) {
        'ASSETS' => accountClass == AccountClass.assets,
        'LIABILITIES' => accountClass == AccountClass.liabilities,
        'EQUITY' => accountClass == AccountClass.equity,
        'INCOME' => accountClass == AccountClass.income,
        'EXPENSES' => accountClass == AccountClass.expenses,
        _ => true,
      };
    });

    // Filter by search
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where(
        (j) =>
            (j.docNo ?? '').toLowerCase().contains(q) ||
            (j.accountName ?? '').toLowerCase().contains(q),
      );
    }

    final list = res.toList();

    // Sort
    if (_sortColumnIndex != null) {
      _sortList(list);
      if (!_sortAscending) {
        final reversed = list.reversed.toList();
        list
          ..clear()
          ..addAll(reversed);
      }
    }

    _cachedFiltered = list;
    _lastCacheKey = cacheKey;
    return list;
  }

  void _sortList(List<Journal> list) {
    int compare<T extends Comparable>(T a, T b) => a.compareTo(b);
    switch (_sortColumnIndex) {
      case 0:
        list.sort(
          (a, b) => (a.dateTime ?? DateTime(1900)).compareTo(
            b.dateTime ?? DateTime(1900),
          ),
        );
      case 1:
        list.sort((a, b) => compare(a.docNo ?? '', b.docNo ?? ''));
      case 2:
        list.sort((a, b) => compare(a.accountName ?? '', b.accountName ?? ''));
      case 3:
        list.sort(
          (a, b) =>
              compare(_typeDisplay(a.accountType), _typeDisplay(b.accountType)),
        );
      case 4:
        list.sort((a, b) => compare(a.debit ?? 0.0, b.debit ?? 0.0));
      case 5:
        list.sort((a, b) => compare(a.credit ?? 0.0, b.credit ?? 0.0));
    }
  }

  void _clearCache() {
    _cachedFiltered = null;
    _lastCacheKey = '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final income = _calcIncome(filtered);
    final expenses = _calcExpenses(filtered);
    final profit = income - expenses;
    final totalDebit = _calcTotalDebit(filtered);
    final totalCredit = _calcTotalCredit(filtered);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(filtered.length),
      body: Column(
        children: [
          // KPI Section - Responsive
          _buildKpiSection(income, expenses, profit, isWideScreen),

          // Toolbar - Simplified
          _buildSimpleToolbar(isWideScreen),

          const SizedBox(height: 12),

          // Main Content
          Expanded(child: _buildMainContent(filtered)),

          // Summary Bar
          JournalSummaryBar(
            totalDebit: _numFmt.format(totalDebit),
            totalCredit: _numFmt.format(totalCredit),
          ),
        ],
      ),
      // FAB for quick actions
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _handleReset,
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text(
          'รีเซ็ต',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSimpleToolbar(bool isWideScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Search Row
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              _buildViewToggle(),
            ],
          ),
          const SizedBox(height: 16),
          // Type Filter Chips + Date Dropdown
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('ALL', 'ทั้งหมด', Icons.apps_rounded),
                      _buildFilterChip(
                        'ASSETS',
                        '1 สินทรัพย์',
                        Icons.account_balance_rounded,
                      ),
                      _buildFilterChip(
                        'LIABILITIES',
                        '2 หนี้สิน',
                        Icons.credit_card_rounded,
                      ),
                      _buildFilterChip(
                        'EQUITY',
                        '3 ทุน',
                        Icons.pie_chart_rounded,
                      ),
                      _buildFilterChip(
                        'INCOME',
                        '4 รายได้',
                        Icons.trending_up_rounded,
                      ),
                      _buildFilterChip(
                        'EXPENSES',
                        '5 ค่าใช้จ่าย',
                        Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildDateFilterDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() {
          _search = v;
          _clearCache();
        }),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _search = '';
                      _clearCache();
                    });
                  },
                )
              : null,
          hintText: 'ค้นหาเลขที่เอกสาร, รายการ...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleButton(
            Icons.table_chart_rounded,
            !_isChartView,
            () => setState(() => _isChartView = false),
          ),
          _buildToggleButton(
            Icons.bar_chart_rounded,
            _isChartView,
            () => setState(() => _isChartView = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _typeFilter == value;
    final color = switch (value) {
      'INCOME' => const Color(0xFF10B981),
      'EXPENSES' => const Color(0xFFEF4444),
      'ASSETS' => const Color(0xFF3B82F6),
      'LIABILITIES' => const Color(0xFFF59E0B),
      'EQUITY' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF6B7280),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() {
          _typeFilter = value;
          _clearCache();
        }),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _dateFilter,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          items: _dateFilters.map((e) {
            return DropdownMenuItem(
              value: e[0],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _dateFilter == e[0]
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Text(e[1]),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _dateFilter = v;
                _clearCache();
              });
            }
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(int itemCount) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFF6B7280),
            ),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            tooltip: 'กลับ',
          ),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'สาขา: ${widget.branchSync} • $itemCount รายการ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFF374151),
                    size: 22,
                  ),
                  onPressed: () {
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final RenderBox overlay =
                        Navigator.of(
                              context,
                            ).overlay!.context.findRenderObject()
                            as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                          button.size.bottomRight(Offset.zero),
                          ancestor: overlay,
                        ),
                      ),
                      Offset.zero & overlay.size,
                    );
                    _showExportOptions(position);
                  },
                  tooltip: 'ส่งออกข้อมูล',
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showExportOptions(RelativeRect position) {
    showMenu(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.file_download_rounded,
                    color: Color(0xFF374151),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ส่งออกข้อมูล',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            // Excel Export Action
          },
          child: _buildExportMenuItem(
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF10B981),
            title: 'Excel (.xlsx)',
            subtitle: 'เหมาะสำหรับนำไปคำนวณต่อ',
          ),
        ),
        PopupMenuItem(
          onTap: () {
            // PDF Export Action
          },
          child: _buildExportMenuItem(
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFEF4444),
            title: 'PDF Document',
            subtitle: 'เอกสารสำหรับการพิมพ์',
          ),
        ),
        PopupMenuItem(
          onTap: () {
            // CSV Export Action
          },
          child: _buildExportMenuItem(
            icon: Icons.code_rounded,
            color: const Color(0xFF3B82F6),
            title: 'CSV File',
            subtitle: 'ไฟล์ข้อมูลดิบ',
          ),
        ),
      ],
    );
  }

  Widget _buildExportMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiSection(
    double income,
    double expenses,
    double profit,
    bool isWideScreen,
  ) {
    final cards = [
      _buildKpiCard(
        'รายได้',
        income,
        Icons.trending_up_rounded,
        const Color(0xFF10B981),
      ),
      _buildKpiCard(
        'รายจ่าย',
        expenses,
        Icons.trending_down_rounded,
        const Color(0xFFEF4444),
      ),
      _buildKpiCard(
        'กำไรสุทธิ',
        profit,
        profit >= 0 ? Icons.emoji_events_rounded : Icons.warning_rounded,
        profit >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
        isPrimary: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: isWideScreen
          ? Row(
              children: cards
                  .map(
                    (c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: c,
                      ),
                    ),
                  )
                  .toList(),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 12),
                cards[2],
              ],
            ),
    );
  }

  Widget _buildKpiCard(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? null
            : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? color.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _compactFmt.format(value),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isPrimary ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isPrimary)
            Tooltip(
              message: 'กำไร = รายได้ - รายจ่าย',
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<Journal> filtered) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: filtered.isEmpty
          ? const JournalEmptyState(
              title: 'ไม่พบรายการ',
              subtitle: 'ลองเปลี่ยนตัวกรองหรือเคลียร์คำค้นหา',
            )
          : _isChartView
          ? JournalChart(
              rows: filtered,
              typeColor: _typeColor,
              typeDisplay: _typeDisplay,
              numFmt: _numFmt,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: JournalTable(
                rows: filtered,
                typeColor: _typeColor,
                typeDisplay: _typeDisplay,
                numFmt: _numFmt,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                onSort: (i, asc) => setState(() {
                  _sortColumnIndex = i;
                  _sortAscending = asc;
                  _clearCache();
                }),
              ),
            ),
    );
  }

  void _handleReset() {
    setState(() {
      _search = '';
      _searchController.clear();
      _typeFilter = 'ALL';
      _dateFilter = 'ALL';
      _sortColumnIndex = null;
      _sortAscending = true;
      _clearCache();
    });
  }
}
