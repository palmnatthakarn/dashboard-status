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
  final _compactFmt = NumberFormat.compactCurrency(symbol: '', decimalDigits: 2);
  
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
      'TODAY' => DateTimeRange(start: today, end: today.add(const Duration(days: 1))),
      '7DAYS' => DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today.add(const Duration(days: 1))),
      'MONTH' => DateTimeRange(start: DateTime(now.year, now.month, 1), end: today.add(const Duration(days: 1))),
      'QUARTER' => () {
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(start: DateTime(now.year, quarterMonth, 1), end: today.add(const Duration(days: 1)));
      }(),
      '3QUARTERS' => () {
        final currentQuarter = (now.month - 1) ~/ 3;
        final startQuarter = (currentQuarter - 2).clamp(0, 3);
        final startMonth = startQuarter * 3 + 1;
        final startYear = currentQuarter < 2 ? now.year - 1 : now.year;
        return DateTimeRange(start: DateTime(startYear, startMonth, 1), end: today.add(const Duration(days: 1)));
      }(),
      'YEAR' => DateTimeRange(start: DateTime(now.year, 1, 1), end: today.add(const Duration(days: 1))),
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
      if (accountClass == AccountClass.expenses || accountClass == AccountClass.liabilities) {
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
    final cacheKey = '$_search|$_typeFilter|$_dateFilter|$_sortColumnIndex|$_sortAscending';
    if (_cachedFiltered != null && _lastCacheKey == cacheKey) {
      return _cachedFiltered!;
    }

    // Filter by date
    final dateRange = _getDateRange(_dateFilter);
    Iterable<Journal> res = widget.journals.where((j) {
      if (dateRange == null) return true;
      final date = j.dateTime;
      if (date == null) return false;
      return date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) && 
             date.isBefore(dateRange.end);
    });

    // Filter by type
    res = res.where((j) {
      if (_typeFilter == 'ALL') return true;
      final accountClass = _getAccountClass(j.accountType);
      return switch (_typeFilter) {
        'INCOME' => accountClass == AccountClass.income,
        'EXPENSES' => accountClass == AccountClass.expenses,
        'ASSETS' => accountClass == AccountClass.assets,
        'LIABILITIES' => accountClass == AccountClass.liabilities,
        _ => true,
      };
    });

    // Filter by search
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((j) =>
          (j.docNo ?? '').toLowerCase().contains(q) ||
          (j.accountName ?? '').toLowerCase().contains(q));
    }

    final list = res.toList();

    // Sort
    if (_sortColumnIndex != null) {
      _sortList(list);
      if (!_sortAscending) {
        final reversed = list.reversed.toList();
        list..clear()..addAll(reversed);
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
        list.sort((a, b) => (a.dateTime ?? DateTime(1900)).compareTo(b.dateTime ?? DateTime(1900)));
      case 1:
        list.sort((a, b) => compare(a.docNo ?? '', b.docNo ?? ''));
      case 2:
        list.sort((a, b) => compare(a.accountName ?? '', b.accountName ?? ''));
      case 3:
        list.sort((a, b) => compare(_typeDisplay(a.accountType), _typeDisplay(b.accountType)));
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
    return FloatingActionButton.extended(
      onPressed: _handleReset,
      backgroundColor: const Color(0xFF3B82F6),
      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
      label: const Text('รีเซ็ต', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSimpleToolbar(bool isWideScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 12),
          // Type Filter Chips + Date Dropdown
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('ALL', 'ทั้งหมด', Icons.apps_rounded),
                      _buildFilterChip('INCOME', 'รายได้', Icons.trending_up_rounded),
                      _buildFilterChip('EXPENSES', 'รายจ่าย', Icons.trending_down_rounded),
                      _buildFilterChip('ASSETS', 'สินทรัพย์', Icons.account_balance_rounded),
                      _buildFilterChip('LIABILITIES', 'หนี้สิน', Icons.credit_card_rounded),
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() { _search = v; _clearCache(); }),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _search = ''; _clearCache(); });
                  },
                )
              : null,
          hintText: 'ค้นหาเลขที่เอกสาร, รายการ...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
      child: Row(
        children: [
          _buildToggleButton(Icons.table_chart_rounded, !_isChartView, () => setState(() => _isChartView = false)),
          _buildToggleButton(Icons.bar_chart_rounded, _isChartView, () => setState(() => _isChartView = true)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isActive ? Colors.white : const Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => setState(() { _typeFilter = value; _clearCache(); }),
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF6B7280)),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF374151),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF3B82F6),
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _dateFilter,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6B7280)),
          style: const TextStyle(color: Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w500),
          items: _dateFilters.map((e) => DropdownMenuItem(
            value: e[0],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF818CF8)),
                const SizedBox(width: 8),
                Text(e[1]),
              ],
            ),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() { _dateFilter = v; _clearCache(); });
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'กลับ',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Journal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  'สาขา: ${widget.branchSync} • $itemCount รายการ',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Quick export button
        IconButton(
          icon: const Icon(Icons.file_download_outlined, color: Color(0xFF6B7280)),
          onPressed: () => _showExportOptions(),
          tooltip: 'ส่งออกข้อมูล',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ส่งออกข้อมูล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF10B981)),
              title: const Text('Excel (.xlsx)'),
              subtitle: const Text('ส่งออกเป็นไฟล์ Excel'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
              title: const Text('PDF'),
              subtitle: const Text('ส่งออกเป็นไฟล์ PDF'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Color(0xFF3B82F6)),
              title: const Text('CSV'),
              subtitle: const Text('ส่งออกเป็นไฟล์ CSV'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSection(double income, double expenses, double profit, bool isWideScreen) {
    final cards = [
      _buildKpiCard('รายได้', income, Icons.trending_up_rounded, const Color(0xFF10B981)),
      _buildKpiCard('รายจ่าย', expenses, Icons.trending_down_rounded, const Color(0xFFEF4444)),
      _buildKpiCard('กำไรสุทธิ', profit, profit >= 0 ? Icons.emoji_events_rounded : Icons.warning_rounded, 
          profit >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B), isPrimary: true),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: isWideScreen
          ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList())
          : Column(children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
              const SizedBox(height: 12),
              cards[2],
            ]),
    );
  }

  Widget _buildKpiCard(String label, double value, IconData icon, Color color, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [color, color.withOpacity(0.8)])
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: isPrimary ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: isPrimary ? Colors.white : color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPrimary ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _compactFmt.format(value),
                  style: TextStyle(
                    fontSize: isPrimary ? 22 : 18,
                    fontWeight: FontWeight.w800,
                    color: isPrimary ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<Journal> filtered) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                  borderRadius: BorderRadius.circular(16),
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
