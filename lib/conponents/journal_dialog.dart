import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/journal.dart';

enum AccountClass {
  income,
  expenses,
  assets,
  liabilities,
  unknown;

  static AccountClass fromString(String? type) {
    if (type == null) return AccountClass.unknown;
    final normalized = type.toUpperCase();
    switch (normalized) {
      case 'INCOME':
      case 'รายได้':
        return AccountClass.income;
      case 'EXPENSES':
      case 'รายจ่าย':
        return AccountClass.expenses;
      case 'ASSETS':  
      case 'สินทรัพย์':
        return AccountClass.assets;
      case 'LIABILITIES':
      case 'หนี้สิน':
        return AccountClass.liabilities;
      default:
        return AccountClass.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AccountClass.income:
        return 'รายได้';
      case AccountClass.expenses:
        return 'รายจ่าย';
      case AccountClass.assets:
        return 'สินทรัพย์';
      case AccountClass.liabilities:
        return 'หนี้สิน';
      case AccountClass.unknown:
        return '-';
    }
  }

  Color get color {
    switch (this) {
      case AccountClass.income:
        return const Color(0xFF10B981);
      case AccountClass.expenses:
      case AccountClass.liabilities:
        return const Color(0xFFEF4444);
      case AccountClass.assets:
        return const Color(0xFF3B82F6);
      case AccountClass.unknown:
        return const Color(0xFF64748B);
    }
  }
}

class JournalDialog extends StatefulWidget {
  final String branchSync;
  final List<Journal> journals;

  const JournalDialog({
    super.key,
    required this.branchSync,
    required this.journals,
  });

  @override
  State<JournalDialog> createState() => _JournalDialogState();
}

class _JournalDialogState extends State<JournalDialog> {
  final _numFmt = NumberFormat('#,##0.00');
  final _compactFmt = NumberFormat.compactCurrency(
    symbol: '',
    decimalDigits: 2,
  );
  final _searchController = TextEditingController();

  // --- UI states ---
  String _search = '';
  String _typeFilter = 'ALL'; // ALL, INCOME, EXPENSES, ASSETS, LIABILITIES
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _isChartView = false; // Toggle between table and chart view

  // --- Performance caching ---
  List<Journal>? _cachedFiltered;
  String _lastCacheKey = '';

  // ==== Helpers for business rules ====
  AccountClass _getAccountClass(String? t) => AccountClass.fromString(t);
  
  String _typeDisplay(String? t) => _getAccountClass(t).displayName;
  
  Color _typeColor(String? t) => _getAccountClass(t).color;

  // ==== Totals ====
  double _calcIncome(Iterable<Journal> list) {
    double total = 0.0;
    for (final j in list) {
      final credit = j.credit ?? 0;
      final debit = j.debit ?? 0;
      if (_getAccountClass(j.accountType) == AccountClass.income) {
        total += (credit - debit);
      }
    }
    return total;
  }

  double _calcExpenses(Iterable<Journal> list) {
    double total = 0.0;
    for (final j in list) {
      final credit = j.credit ?? 0;
      final debit = j.debit ?? 0;
      final accountClass = _getAccountClass(j.accountType);
      if (accountClass == AccountClass.expenses || accountClass == AccountClass.liabilities) {
        total += (debit - credit);
      }
    }
    return total;
  }

  double _calcTotalDebit(Iterable<Journal> list) =>
      list.fold(0.0, (p, e) => p + (e.debit ?? 0));
  double _calcTotalCredit(Iterable<Journal> list) =>
      list.fold(0.0, (p, e) => p + (e.credit ?? 0));

  // ==== Filtering + Sorting with Caching ====
  List<Journal> get _filtered {
    final cacheKey = '$_search|$_typeFilter|$_sortColumnIndex|$_sortAscending';
    if (_cachedFiltered != null && _lastCacheKey == cacheKey) {
      return _cachedFiltered!;
    }

    // 1) filter by type
    Iterable<Journal> res = widget.journals.where((j) {
      if (_typeFilter == 'ALL') return true;
      final accountClass = _getAccountClass(j.accountType);
      switch (_typeFilter) {
        case 'INCOME':
          return accountClass == AccountClass.income;
        case 'EXPENSES':
          return accountClass == AccountClass.expenses;
        case 'ASSETS':
          return accountClass == AccountClass.assets;
        case 'LIABILITIES':
          return accountClass == AccountClass.liabilities;
        default:
          return true;
      }
    });

    // 2) search by docNo or accountName
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where(
        (j) =>
            (j.docNo ?? '').toLowerCase().contains(q) ||
            (j.accountName ?? '').toLowerCase().contains(q),
      );
    }

    final list = res.toList();

    // 3) sorting
    if (_sortColumnIndex != null) {
      int compare<T extends Comparable>(T a, T b) => a.compareTo(b);
      switch (_sortColumnIndex) {
        case 0:
          // ใช้ DateTime sorting แทน string
          list.sort((a, b) {
            final dateA = a.dateTime ?? DateTime(1900);
            final dateB = b.dateTime ?? DateTime(1900);
            return dateA.compareTo(dateB);
          });
          break;
        case 1:
          list.sort((a, b) => compare(a.docNo ?? '', b.docNo ?? ''));
          break;
        case 2:
          list.sort(
            (a, b) => compare(a.accountName ?? '', b.accountName ?? ''),
          );
          break;
        case 3:
          list.sort(
            (a, b) => compare(
              _typeDisplay(a.accountType),
              _typeDisplay(b.accountType),
            ),
          );
          break;
        case 4:
          list.sort((a, b) => compare(a.debit ?? 0.0, b.debit ?? 0.0));
          break;
        case 5:
          list.sort((a, b) => compare(a.credit ?? 0.0, b.credit ?? 0.0));
          break;
      }

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

  void _clearCache() {
    _cachedFiltered = null;
    _lastCacheKey = '';
  }

  @override
  void didUpdateWidget(JournalDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // เคลียร์ cache เมื่อ data เปลี่ยน
    if (oldWidget.journals != widget.journals) {
      _cachedFiltered = null;
      _lastCacheKey = '';
    }
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

    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFAFBFC), Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.8, -0.6),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Close button with animation
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ======= Header (gradient card) =======
                    _HeaderCard(
                      title: 'Journal สาขา: ${widget.branchSync}',
                      income: income,
                      expenses: expenses,
                      profit: profit,
                      compactFmt: _compactFmt,
                    ),
                    const SizedBox(height: 14),

                    // ======= Toolbar: Quick filters + search =======
                    _Toolbar(
                      typeFilter: _typeFilter,
                      onTypeChanged: (v) => setState(() {
                        _typeFilter = v;
                        _clearCache();
                      }),
                      onReset: () => setState(() {
                        _search = '';
                        _searchController.clear();
                        _typeFilter = 'ALL';
                        _sortColumnIndex = null;
                        _sortAscending = true;
                        _clearCache();
                      }),
                      searchController: _searchController,
                      onSearchChanged: (v) => setState(() {
                        _search = v;
                        _clearCache();
                      }),
                      isChartView: _isChartView,
                      onViewToggle: () =>
                          setState(() => _isChartView = !_isChartView),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // ======= Table/Chart or Empty state =======
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              title: 'ไม่พบรายการ',
                              subtitle:
                                  'ลองเปลี่ยนตัวกรองหรือเคลียร์คำค้นหา แล้วลองใหม่อีกครั้ง',
                            )
                          : _isChartView
                          ? _ChartView(
                              rows: filtered,
                              typeColor: _typeColor,
                              typeDisplay: _typeDisplay,
                              numFmt: _numFmt,
                            )
                          : _PrettyTable(
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

                    // ======= Summary =======
                    _SummaryBar(
                      totalDebit: totalDebit,
                      totalCredit: totalCredit,
                      income: income,
                      expenses: expenses,
                      profit: profit,
                      numFmt: _numFmt,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Fancy Header Card ----------
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.compactFmt,
  });

  final String title;
  final double income;
  final double expenses;
  final double profit;
  final NumberFormat compactFmt;

  @override
  Widget build(BuildContext context) {
    final ok = profit >= 0;
    final glow = ok ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.88),
            Colors.white.withOpacity(0.92),
          ],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glow.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF3B82F6),
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
          ),
          _KpiChip(
            label: 'รายได้',
            value: income,
            icon: Icons.trending_up,
            color: const Color(0xFF10B981),
            compactFmt: compactFmt,
          ),
          _DividerDot(),
          _KpiChip(
            label: 'รายจ่าย',
            value: expenses,
            icon: Icons.trending_down,
            color: const Color(0xFFEF4444),
            compactFmt: compactFmt,
          ),
          _DividerDot(),
          _KpiChip(
            label: 'กำไร/ขาดทุน',
            value: profit,
            icon: ok ? Icons.arrow_upward : Icons.arrow_downward,
            color: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            compactFmt: compactFmt,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compactFmt,
    this.bold = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final NumberFormat compactFmt;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (animation * 0.2),
          child: Opacity(
            opacity: animation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Could add more interactions here
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.12),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, iconAnimation, child) {
                          return Transform.rotate(
                            angle: iconAnimation * 0.1,
                            child: Icon(icon, size: 16, color: color),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color.withOpacity(0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            compactFmt.format(value),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: bold
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: color,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Toolbar ----------
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.typeFilter,
    required this.onTypeChanged,
    required this.onReset,
    required this.searchController,
    required this.onSearchChanged,
    required this.isChartView,
    required this.onViewToggle,
  });

  final String typeFilter;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onReset;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isChartView;
  final VoidCallback onViewToggle;

  @override
  Widget build(BuildContext context) {
    final chips = const [
      ['ALL', 'ทั้งหมด'],
      ['INCOME', 'รายได้'],
      ['EXPENSES', 'รายจ่าย'],
      ['ASSETS', 'สินทรัพย์'],
      ['LIABILITIES', 'หนี้สิน'],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Choice chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips
              .asMap()
              .entries
              .map(
                (entry) => TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (entry.key * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, animation, child) {
                    final e = entry.value;
                    final isSelected = typeFilter == e[0];
                    return Transform.scale(
                      scale: 0.8 + (animation * 0.2),
                      child: Opacity(
                        opacity: animation,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onTypeChanged(e[0]);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.9),
                                          Colors.white.withOpacity(0.7),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 250),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                    ),
                                    child: Text(e[1]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 12),
        // Search
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            searchController.clear();
                            onSearchChanged('');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                hintText: 'ค้นหาเลขที่เอกสารหรือชื่อบัญชี...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFE2E8F0).withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // View toggle button
        Tooltip(
          message: isChartView ? 'แสดงตาราง' : 'แสดงกราฟ',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.mediumImpact();
                onViewToggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isChartView
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isChartView
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6))
                              .withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isChartView ? Icons.table_chart : Icons.show_chart,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isChartView ? 'ตาราง' : 'กราฟ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'รีเซ็ตตัวกรองทั้งหมด',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.mediumImpact();
                onReset();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, animation, child) {
                        return Transform.rotate(
                          angle: animation * 6.28, // 2π for full rotation
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'รีเซ็ต',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------- Pretty Table ----------
class _PrettyTable extends StatelessWidget {
  const _PrettyTable({
    required this.rows,
    required this.typeColor,
    required this.typeDisplay,
    required this.numFmt,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  final List<Journal> rows;
  final Color Function(String?) typeColor;
  final String Function(String?) typeDisplay;
  final NumberFormat numFmt;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int, bool) onSort;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      radius: const Radius.circular(12),
      thickness: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable2(
          columnSpacing: 18,
          horizontalMargin: 12,
          headingRowHeight: 46,
          dataRowHeight: 54,
          minWidth: 900,
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
          sortColumnIndex: sortColumnIndex,
          sortAscending: sortAscending,
          columns: [
            DataColumn2(
              label: const Text(
                'วันที่',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.M,
              onSort: onSort,
            ),
            DataColumn2(
              label: const Text(
                'เลขที่เอกสาร',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.L,
              onSort: onSort,
            ),
            DataColumn2(
              label: const Text(
                'รายการ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.L,
              onSort: onSort,
            ),
            DataColumn2(
              label: const Text(
                'ประเภท',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              size: ColumnSize.M,
              onSort: onSort,
            ),
            const DataColumn2(
              label: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'เดบิต',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              size: ColumnSize.M,
              numeric: true,
            ),
            const DataColumn2(
              label: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'เครดิต',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              size: ColumnSize.M,
              numeric: true,
            ),
          ],
          rows: List.generate(rows.length, (i) {
            final j = rows[i];
            final debit = j.debit ?? 0;
            final credit = j.credit ?? 0;
            final zebra = i.isEven ? Colors.white : const Color(0xFFFAFAFB);

            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFFEFF6FF); // hover highlight
                }
                return zebra;
              }),
              cells: [
                DataCell(Text(j.displayDate)),
                DataCell(_DocCell(j.docNo)),
                DataCell(Text(j.accountName ?? '-')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor(j.accountType).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: typeColor(j.accountType).withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      typeDisplay(j.accountType),
                      style: TextStyle(
                        color: typeColor(j.accountType),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      debit > 0 ? numFmt.format(debit) : '-',
                      style: TextStyle(
                        fontWeight: debit > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: debit > 0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      credit > 0 ? numFmt.format(credit) : '-',
                      style: TextStyle(
                        fontWeight: credit > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: credit > 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _DocCell extends StatelessWidget {
  const _DocCell(this.docNo);
  final String? docNo;

  @override
  Widget build(BuildContext context) {
    final txt = docNo ?? '-';
    return Row(
      children: [
        const Icon(
          Icons.description_outlined,
          size: 16,
          color: Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Tooltip(
            message: txt,
            child: Text(txt, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ),
        if (docNo != null && docNo!.isNotEmpty) ...[
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: docNo!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('คัดลอกเลขที่เอกสารแล้ว')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ---------- Summary Bar ----------
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.totalDebit,
    required this.totalCredit,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.numFmt,
    required this.theme,
  });

  final double totalDebit;
  final double totalCredit;
  final double income;
  final double expenses;
  final double profit;
  final NumberFormat numFmt;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ok = profit >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _pill('รวมเดบิต', numFmt.format(totalDebit), const Color(0xFFEF4444)),
          _vsep(),
          _pill(
            'รวมเครดิต',
            numFmt.format(totalCredit),
            const Color(0xFF10B981),
          ),
          _vsep(),
          _pill('รายได้', numFmt.format(income), const Color(0xFF3B82F6)),
          _vsep(),
          _pill('รายจ่าย', numFmt.format(expenses), const Color(0xFFEF4444)),
          _vsep(),
          _pill(
            'กำไร/ขาดทุน',
            numFmt.format(profit),
            ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color, {bool bold = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vsep() =>
      Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
}

/// ---------- Chart View ----------
class _ChartView extends StatefulWidget {
  const _ChartView({
    required this.rows,
    required this.typeColor,
    required this.typeDisplay,
    required this.numFmt,
  });

  final List<Journal> rows;
  final Color Function(String?) typeColor;
  final String Function(String?) typeDisplay;
  final NumberFormat numFmt;

  @override
  State<_ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<_ChartView> {
  List<_ChartDataPoint>? _cachedChartData;
  double? _cachedMaxY;

  @override
  Widget build(BuildContext context) {
    final chartData = _prepareChartData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              const Text(
                'กราฟแสดงยอดเงินตามวันที่',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่มีข้อมูลสำหรับแสดงกราฟ',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE2E8F0),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE2E8F0),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < chartData.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    chartData[index].date,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: null,
                            reservedSize: 80,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                NumberFormat.compact().format(value),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      minX: 0,
                      maxX: (chartData.length - 1).toDouble(),
                      minY: 0,
                      maxY: _getMaxY(),
                      lineBarsData: [
                        // Debit line
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(i.toDouble(), chartData[i].debit),
                          ),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: chartData.length <= 20),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFEF4444).withOpacity(0.1),
                                const Color(0xFFEF4444).withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Credit line
                        LineChartBarData(
                          spots: List.generate(
                            chartData.length,
                            (i) => FlSpot(i.toDouble(), chartData[i].credit),
                          ),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: chartData.length <= 20),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.1),
                                const Color(0xFF10B981).withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.white,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final index = barSpot.x.toInt();
                              if (index >= 0 && index < chartData.length) {
                                final data = chartData[index];
                                final isDebit = barSpot.barIndex == 0;
                                return LineTooltipItem(
                                  '${data.date}\n${isDebit ? 'เดบิต' : 'เครดิต'}: ${widget.numFmt.format(barSpot.y)}',
                                  TextStyle(
                                    color: isDebit
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: const Color(0xFFEF4444), label: 'เดบิต'),
              const SizedBox(width: 24),
              _LegendItem(color: const Color(0xFF10B981), label: 'เครดิต'),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartDataPoint> _prepareChartData() {
    if (_cachedChartData != null) return _cachedChartData!;

    final Map<String, _ChartDataPoint> dailyData = {};

    for (final journal in widget.rows) {
      final date = journal.displayDate;
      final existing = dailyData[date];
      if (existing == null) {
        dailyData[date] = _ChartDataPoint(
          date: date,
          debit: journal.debit ?? 0,
          credit: journal.credit ?? 0,
        );
      } else {
        existing.debit += journal.debit ?? 0;
        existing.credit += journal.credit ?? 0;
      }
    }

    _cachedChartData = dailyData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return _cachedChartData!;
  }

  double _getMaxY() {
    if (_cachedMaxY != null) return _cachedMaxY!;

    final chartData = _prepareChartData();
    if (chartData.isEmpty) return _cachedMaxY = 100;

    double maxValue = 0;
    for (final data in chartData) {
      if (data.debit > maxValue) maxValue = data.debit;
      if (data.credit > maxValue) maxValue = data.credit;
    }

    return _cachedMaxY = maxValue * 1.1;
  }
}

class _ChartDataPoint {
  final String date;
  double debit;
  double credit;

  _ChartDataPoint({
    required this.date,
    required this.debit,
    required this.credit,
  });
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

/// ---------- Empty State ----------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
