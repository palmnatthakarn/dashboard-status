import 'package:flutter/material.dart' hide Chip;
import 'package:intl/intl.dart';
import 'common/chip.dart';
import 'common/status_chip.dart';
import 'common/stat_card.dart';
import 'common/section_card.dart';
import 'common/empty_hint.dart';
import 'common/monthly_line_chart.dart';

enum ChartView { monthly, daily, average, yearly }

class ShopDetailPopup extends StatefulWidget {
  final dynamic shop;
  final NumberFormat moneyFormat;
  final DateTime? selectedDate;

  const ShopDetailPopup({
    super.key,
    required this.shop,
    required this.moneyFormat,
    this.selectedDate,
  });

  @override
  State<ShopDetailPopup> createState() => _ShopDetailPopupState();
}

class _ShopDetailPopupState extends State<ShopDetailPopup> {
  ChartView selectedChartView = ChartView.monthly;
  bool showThisWeek = true;
  bool showLastWeek = false;

  Widget _buildChartSection(
    List<Map<String, dynamic>> monthlySummary,
    List<Map<String, dynamic>> daily5,
  ) {
    String title;
    IconData icon;
    Widget content;

    switch (selectedChartView) {
      case ChartView.daily:
        title = 'ข้อมูลรายวัน';
        icon = Icons.today;
        content = Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: showThisWeek,
                  onChanged: (v) => setState(() => showThisWeek = v ?? true),
                ),
                const Text('สัปดาห์นี้'),
                const SizedBox(width: 16),
                Checkbox(
                  value: showLastWeek,
                  onChanged: (v) => setState(() => showLastWeek = v ?? false),
                ),
                const Text('สัปดาห์ก่อนหน้า'),
              ],
            ),
            const SizedBox(height: 10),
            daily5.isNotEmpty
                ? MonthlyLineChart(
                    rows: daily5,
                    money: widget.moneyFormat,
                    chartType: 'daily',
                  )
                : const EmptyHint(text: 'ยังไม่มีข้อมูลรายวัน'),
          ],
        );
        break;
      case ChartView.average:
        title = 'เฉลี่ยรายเดือน';
        icon = Icons.calendar_month;
        content = monthlySummary.isNotEmpty
            ? MonthlyLineChart(
                rows: monthlySummary,
                money: widget.moneyFormat,
                chartType: 'average',
              )
            : const EmptyHint(text: 'ยังไม่มีข้อมูลเฉลี่ยรายเดือน');
        break;
      case ChartView.yearly:
        title = 'ข้อมูลรวมทั้งปี';
        icon = Icons.ssid_chart;
        content = monthlySummary.isNotEmpty
            ? MonthlyLineChart(
                rows: monthlySummary,
                money: widget.moneyFormat,
                chartType: 'yearly',
              )
            : const EmptyHint(text: 'ยังไม่มีข้อมูลรวมทั้งปี');
        break;
      case ChartView.monthly:
        return monthlySummary.isNotEmpty
            ? _MonthlySummarySection(
                rows: monthlySummary,
                money: widget.moneyFormat,
              )
            : SectionCard(
                title: 'สรุปรายเดือน',
                icon: Icons.bar_chart,
                child: const EmptyHint(
                  text: 'ยังไม่มีข้อมูลสรุปรายเดือนสำหรับร้านนี้',
                ),
              );
    }

    return SectionCard(
      title: title,
      icon: icon,
      child: Column(children: [const SizedBox(height: 10), content]),
    );
  }

  // ---------- Safe helpers ----------
  T? _try<T>(T Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is num && !v.isNaN && !v.isInfinite) return v.toDouble();
    return 0.0;
  }

  String _money(dynamic v) {
    final n = _num(v);
    return n == 0 ? '-' : widget.moneyFormat.format(n);
  }

  String _text(dynamic v, {String placeholder = '-'}) {
    if (v == null) return placeholder;
    final s = v.toString().trim();
    return s.isEmpty ? placeholder : s;
  }

  // ---------- Derived ----------
  String get _shopName =>
      _text(_try(() => widget.shop.shopname) ?? _try(() => widget.shop.name));
  String get _shopId => _text(
    _try(() => widget.shop.shopid) ??
        _try(() => widget.shop.code) ??
        _try(() => widget.shop.id),
  );
  double get _totalYear =>
      _num(_try(() => widget.shop.totalDeposit) ?? _sumMonthly('deposit'));
  double get _daily => _num(_try(() => widget.shop.dailyTotal));
  double get _monthlyAvg {
    final msum = _asMonthlySummary();
    if (msum.isNotEmpty) {
      final total = msum.fold<double>(0, (s, e) => s + _num(e['deposit']));
      return total / msum.length;
    }
    return _totalYear / 12.0;
  }

  // คำนวณยอดรายวันตามวันที่เลือก
  double get _dailyForSelectedDate {
    if (widget.selectedDate == null) return 0.0;

    final dailyTransactions = _try(() => widget.shop.dailyTransactions);
    if (dailyTransactions == null) return 0.0;

    // แปลงวันที่เลือกเป็น string format (YYYY-MM-DD)
    final targetDateStr =
        '${widget.selectedDate!.year.toString().padLeft(4, '0')}-${widget.selectedDate!.month.toString().padLeft(2, '0')}-${widget.selectedDate!.day.toString().padLeft(2, '0')}';

    double dailySum = 0.0;

    for (final transaction in dailyTransactions) {
      final timestamp =
          _try(() => transaction.timestamp) ??
          _try(() => transaction['timestamp']);
      if (timestamp != null && timestamp.toString().startsWith(targetDateStr)) {
        final deposit = _num(
          _try(() => transaction.deposit) ?? _try(() => transaction['deposit']),
        );
        final withdraw = _num(
          _try(() => transaction.withdraw) ??
              _try(() => transaction['withdraw']),
        );
        dailySum += deposit - withdraw;
      }
    }

    return dailySum;
  }

  List<Map<String, dynamic>> _asMonthlySummary() {
    final ms = _try(() => widget.shop.monthlySummary);
    if (ms == null) return [];
    if (ms is Map) {
      final entries =
          ms.entries.map<Map<String, dynamic>>((e) {
            final val = e.value;
            return {
              'month': e.key,
              'deposit': val is Map
                  ? _num(val['deposit'])
                  : _num(_try(() => val.deposit)),
              'withdraw': val is Map
                  ? _num(val['withdraw'])
                  : _num(_try(() => val.withdraw)),
            };
          }).toList()..sort(
            (a, b) => a['month'].toString().compareTo(b['month'].toString()),
          );
      return entries;
    } else if (ms is List) {
      return ms
          .map<Map<String, dynamic>>(
            (e) => {
              'month': _text(_try(() => e['month']) ?? _try(() => e.month)),
              'deposit': _num(
                _try(() => e['deposit']) ?? _try(() => e.deposit),
              ),
              'withdraw': _num(
                _try(() => e['withdraw']) ?? _try(() => e.withdraw),
              ),
            },
          )
          .toList();
    }
    return [];
  }

  double _sumMonthly(String field) {
    final m = _asMonthlySummary();
    return m.fold<double>(0, (s, e) => s + _num(e[field]));
  }

  List<Map<String, dynamic>> _asDailyLatest5() {
    final daily = _try(() => widget.shop.daily);
    if (daily == null || (daily is Iterable && daily.isEmpty)) return [];
    final list = (daily as Iterable).toList();
    final mapped =
        list
            .map<Map<String, dynamic>>(
              (d) => {
                'date': _text(
                  _try(() => d['timestamp']) ?? _try(() => d.timestamp),
                ),
                'deposit': _num(
                  _try(() => d['deposit']) ?? _try(() => d.deposit),
                ),
                'withdraw': _num(
                  _try(() => d['withdraw']) ?? _try(() => d.withdraw),
                ),
                'note': _text(_try(() => d['note']) ?? _try(() => d.note)),
              },
            )
            .toList()
          ..sort(
            (a, b) => b['date'].toString().compareTo(a['date'].toString()),
          );
    return mapped.take(5).toList();
  }

  // ดึงข้อมูล daily transactions 3 วันล่าสุดจาก dailyTransactions
  List<Map<String, dynamic>> _getDailyTransactionsLatest3Days() {
    final dailyTransactions = _try(() => widget.shop.dailyTransactions);
    if (dailyTransactions == null ||
        (dailyTransactions is Iterable && dailyTransactions.isEmpty))
      return [];

    final list = (dailyTransactions as Iterable).toList();
    final mapped = list
        .map<Map<String, dynamic>>(
          (transaction) => {
            'date': _text(
              _try(() => transaction.timestamp) ??
                  _try(() => transaction['timestamp']),
            ),
            'deposit': _num(
              _try(() => transaction.deposit) ??
                  _try(() => transaction['deposit']),
            ),
            'withdraw': _num(
              _try(() => transaction.withdraw) ??
                  _try(() => transaction['withdraw']),
            ),
            'note': _text(
              _try(() => transaction.note) ?? _try(() => transaction['note']),
            ),
            'ref': _text(
              _try(() => transaction.ref) ?? _try(() => transaction['ref']),
            ),
            'recorded_by': _text(
              _try(() => transaction.recordedBy?.name) ??
                  _try(() => transaction['recorded_by']?.name) ??
                  _try(() => transaction['recorded_by']?['name']),
            ),
          },
        )
        .where(
          (item) => item['date'] != '-',
        ) // กรองเอาข้อมูลที่มี timestamp เท่านั้น
        .toList();

    // เรียงตาม timestamp จากล่าสุดไปเก่าสุด
    mapped.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    // กรุ๊ปตามวันที่และเอา 3 วันล่าสุด
    final Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    for (final item in mapped) {
      final dateTime = DateTime.tryParse(item['date']?.toString() ?? '');
      if (dateTime != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
        groupedByDate.putIfAbsent(dateKey, () => []);
        groupedByDate[dateKey]!.add(item);
      }
    }

    // เอา 3 วันล่าสุด
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final latest3Days = sortedDates.take(3).toList();

    // รวมข้อมูลจาก 3 วันล่าสุด
    final result = <Map<String, dynamic>>[];
    for (final date in latest3Days) {
      result.addAll(groupedByDate[date]!);
    }

    return result;
  }

  Map<String, dynamic> get _status {
    final y = _totalYear;
    if (y > 1800000) {
      return {
        'label': 'Exceeded',
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFEF2F2),
        'icon': Icons.error,
      };
    } else if (y >= 1000000 && y <= 1800000) {
      return {
        'label': 'Warning',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'icon': Icons.warning_amber,
      };
    } else {
      return {
        'label': 'Safe',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFF0FDF4),
        'icon': Icons.check_circle,
      };
    }
  }

  Widget _buildCompactDailyRow(Map<String, dynamic> transaction) {
    final dateTime = DateTime.tryParse(transaction['date']?.toString() ?? '');
    final dateStr = dateTime != null
        ? DateFormat('dd/MM/yyyy').format(dateTime)
        : transaction['date']?.toString() ?? '-';
    final timeStr = dateTime != null
        ? DateFormat('HH:mm:ss').format(dateTime)
        : '';

    final deposit = _num(transaction['deposit']);
    final withdraw = _num(transaction['withdraw']);
    final note = _text(transaction['note']);
    final ref = _text(transaction['ref']);
    final recordedBy = _text(transaction['recorded_by']);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Date and Time Section
          SizedBox(
            width: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(width: 10),
                if (timeStr.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '|',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info section (Note, Ref, Recorded By)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note != '-') ...[
                  Text(
                    'หมายเหตุ: $note',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    if (ref != '-') ...[
                      Text(
                        'อ้างอิง: $ref',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      if (recordedBy != '-') const SizedBox(width: 8),
                    ],
                    if (recordedBy != '-')
                      Text(
                        'โดย: $recordedBy',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount Section - Compact horizontal layout
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Deposit
              if (deposit > 0) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'ฝาก',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatCompactNumber(deposit)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              // Withdraw
              if (withdraw > 0) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '|',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ถอน',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 8),

                    Text(
                      '${_formatCompactNumber(withdraw)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              // Net Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '|',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'สุทธิ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),

                  Text(
                    '${_formatCompactNumber(deposit - withdraw)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: (deposit - withdraw) >= 0
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompactNumber(double amount) {
    if (amount == 0) return '0';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return widget.moneyFormat.format(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlySummary = _asMonthlySummary();
    final daily5 = _asDailyLatest5();
    final dailyTransactions3Days = _getDailyTransactionsLatest3Days();

    final respName = _text(_try(() => widget.shop.responsible?.name));
    final respEmail = _text(_try(() => widget.shop.responsible?.email));
    final respPhone = _text(_try(() => widget.shop.responsible?.phone));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 860,
          minWidth: 360,
          maxHeight: 820,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _shopName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    height: 1.1,
                                  ),
                                ),
                                Chip(
                                  icon: Icons.qr_code_2,
                                  label: _shopId,
                                  bg: const Color(0xFFDBEAFE),
                                  fg: const Color(0xFF1D4ED8),
                                ),
                                StatusChip(
                                  icon: _status['icon'],
                                  label: _status['label'],
                                  fg: _status['color'],
                                  bg: _status['bg'],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      Icons.person_outlined,
                                      size: 14,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const TextSpan(text: ' ผู้รับผิดชอบ: '),

                                  TextSpan(
                                    text: respName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  if (respEmail != '-') ...[
                                    const TextSpan(text: '  |  '),
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    TextSpan(text: ' $respEmail'),
                                  ],

                                  if (respPhone != '-') ...[
                                    const TextSpan(text: '  |  '),
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    TextSpan(text: ' $respPhone'),
                                  ],
                                ],
                              ),
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 22),
                        tooltip: 'ปิด',
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        // Overview
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: widget.selectedDate != null
                                    ? 'วันที่ ${DateFormat('dd/MM/yyyy').format(widget.selectedDate!)}'
                                    : 'รายวัน/บาท',
                                value: _money(
                                  widget.selectedDate != null
                                      ? _dailyForSelectedDate
                                      : _daily,
                                ),
                                icon: Icons.today,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEFF6FF),
                                    Color(0xFFDBEAFE),
                                  ],
                                ),
                                onTap: () => setState(
                                  () => selectedChartView = ChartView.daily,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'เฉลี่ยรายเดือน/บาท',
                                value: _money(_monthlyAvg),
                                icon: Icons.calendar_month,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF0FDF4),
                                    Color(0xFFD1FAE5),
                                  ],
                                ),
                                onTap: () => setState(
                                  () => selectedChartView = ChartView.average,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'รวมทั้งปี/บาท',
                                value: _money(_totalYear),
                                icon: Icons.ssid_chart,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFF7ED),
                                    Color(0xFFFFEDD5),
                                  ],
                                ),
                                onTap: () => setState(
                                  () => selectedChartView = ChartView.yearly,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Recent Activity
                        SectionCard(
                          title: 'ข้อมูลรายวัน',
                          icon: Icons.view_day_outlined,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '3 วันล่าสุด',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          child: Builder(
                            builder: (_) {
                              if (dailyTransactions3Days.isEmpty)
                                return const EmptyHint(
                                  text: 'ยังไม่มีข้อมูล daily transactions',
                                );
                              return Column(
                                children: dailyTransactions3Days
                                    .map((d) => _buildCompactDailyRow(d))
                                    .toList(),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Dynamic Chart View based on selected StatCard
                        _buildChartSection(monthlySummary, daily5),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'เกณฑ์สถานะ: Safe < 1,000,000 • Warning 1,000,000–1,800,000 • Exceeded > 1,800,000',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      /* SizedBox(height: 40, child: FilledButton.icon(onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check), label: const Text('ปิด'))),*/
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= UI components =================

class _MonthlyTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final NumberFormat money;
  const _MonthlyTable({required this.rows, required this.money});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black.withOpacity(0.06)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _th(['เดือน', 'ยอดเงินฝาก', 'ยอดเงินถอน']),
        ...rows.map(
          (e) => _tr([
            e['month']?.toString() ?? '-',
            money.format(_safe(e['deposit'])),
            money.format(_safe(e['withdraw'])),
          ]),
        ),
      ],
    ),
  );

  double _safe(dynamic v) => (v ?? 0) * 1.0;

  TableRow _th(List<String> cells) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
    children: cells
        .map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Text(
              c,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        )
        .toList(),
  );

  TableRow _tr(List<String> cells) => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: cells
        .map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Text(c, style: const TextStyle(color: Color(0xFF0F172A))),
          ),
        )
        .toList(),
  );
}

// ================= Monthly Summary switcher (Table <-> Chart) ================

enum _MSView { table, chart }

class _MonthlySummarySection extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final NumberFormat money;
  const _MonthlySummarySection({required this.rows, required this.money});

  @override
  State<_MonthlySummarySection> createState() => _MonthlySummarySectionState();
}

class _MonthlySummarySectionState extends State<_MonthlySummarySection> {
  _MSView mode = _MSView.chart;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'สรุปรายเดือน',
      icon: Icons.bar_chart,
      trailing: SegmentedButton<_MSView>(
        segments: const [
          ButtonSegment(value: _MSView.table, icon: Icon(Icons.table_chart)),
          ButtonSegment(value: _MSView.chart, icon: Icon(Icons.bar_chart)),
        ],
        showSelectedIcon: false,
        selected: {mode},
        onSelectionChanged: (s) => setState(() => mode = s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF3B82F6);
            }
            return const Color(0xFFF1F5F9);
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF475569);
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (mode == _MSView.table)
            _MonthlyTable(rows: widget.rows, money: widget.money)
          else
            MonthlyLineChart(
              rows: widget.rows,
              money: widget.money,
              chartType: 'monthly',
            ),
        ],
      ),
    );
  }
}
