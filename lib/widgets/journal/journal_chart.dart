import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/journal.dart';

class JournalChart extends StatefulWidget {
  const JournalChart({
    super.key,
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
  State<JournalChart> createState() => _JournalChartState();
}

class _JournalChartState extends State<JournalChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Set<String> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, double>> dailyData = {};
    final Set<String> types = {};
    double totalAmount = 0;

    for (final j in widget.rows) {
      final date = j.displayDate;
      final type = widget.typeDisplay(j.accountType);
      types.add(type);
      
      dailyData[date] ??= {};
      final amount = (j.debit ?? 0) + (j.credit ?? 0);
      dailyData[date]![type] = (dailyData[date]![type] ?? 0) + amount;
      totalAmount += amount;
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final typeList = types.toList();

    if (_selectedTypes.isEmpty) {
      _selectedTypes = types;
    }

    if (sortedDates.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFEEF2FF).withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeaderWithSummary(totalAmount, sortedDates.length, dailyData, typeList),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return _buildChart(dailyData, sortedDates, typeList);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart_rounded, size: 48, color: Color(0xFF818CF8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่มีข้อมูลสำหรับแสดงกราฟ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithSummary(double total, int days, Map<String, Map<String, double>> dailyData, List<String> typeList) {
    final Map<String, double> totals = {};
    for (final dayData in dailyData.values) {
      for (final entry in dayData.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'กราฟแนวโน้มรายวัน',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ยอดรวม ${widget.numFmt.format(total)} บาท • $days วัน',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        const Spacer(),
        // Right: Summary cards
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: typeList.map((type) {
            final color = widget.typeColor(type);
            final typeTotal = totals[type] ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    type,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.numFmt.format(typeTotal),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChart(Map<String, Map<String, double>> dailyData, List<String> sortedDates, List<String> typeList) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(dailyData),
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFF3F4F6),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatAxisValue(value),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (sortedDates.length / 6).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _formatDate(sortedDates[index]),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: typeList.where((t) => _selectedTypes.contains(t)).map((type) {
            final color = widget.typeColor(type);
            
            return LineChartBarData(
              spots: sortedDates.asMap().entries.map((dateEntry) {
                final x = dateEntry.key.toDouble();
                final y = (dailyData[dateEntry.value]?[type] ?? 0) * _animation.value;
                return FlSpot(x, y);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              shadow: Shadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              getTooltipColor: (touchedSpot) => Colors.white.withValues(alpha: 0.90),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final activeTypes = typeList.where((t) => _selectedTypes.contains(t)).toList();
                  final type = activeTypes[spot.barIndex];
                  final color = widget.typeColor(type);
                  return LineTooltipItem(
                    '$type\n',
                    TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                    children: [
                      TextSpan(
                        text: widget.numFmt.format(spot.y),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1, dashArray: [5, 5]),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, idx) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: bar.color ?? Colors.blue,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  String _formatDate(String date) {
    final parts = date.split('/');
    if (parts.length >= 2) {
      return '${parts[0]}/${parts[1]}';
    }
    return date.length > 5 ? date.substring(0, 5) : date;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  double _calculateInterval(Map<String, Map<String, double>> data) {
    double maxValue = 0;
    for (final dayData in data.values) {
      for (final value in dayData.values) {
        if (value > maxValue) maxValue = value;
      }
    }
    if (maxValue <= 0) return 1000;
    return (maxValue / 5).ceilToDouble();
  }
}
