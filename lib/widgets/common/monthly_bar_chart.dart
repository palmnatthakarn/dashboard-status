import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final NumberFormat money;
  const MonthlyBarChart({super.key, required this.rows, required this.money});

  String _shortMonth(String m) {
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(m)) {
      final year = m.split('-')[0];
      final yy = year.substring(2);
      final mm = int.tryParse(m.split('-')[1]) ?? 0;
      const th = [
        'มค ',
        'กพ',
        'มีค',
        'เมย',
        'พค',
        'มิย',
        'กค',
        'สค',
        'กย',
        'ตค',
        'พย',
        'ธค',
      ];
      if (mm >= 1 && mm <= 12) {
        return '${th[mm - 1]} $yy';
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final labels = <int, String>{};
    final bars = <BarChartGroupData>[];
    double maxVal = 0;

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final month = (r['month'] ?? '-').toString();
      final d = (r['deposit'] ?? 0) * 1.0;
      final w = (r['withdraw'] ?? 0) * 1.0;
      maxVal = max(maxVal, max(d, w));

      labels[i] = _shortMonth(month);
      bars.add(
        BarChartGroupData(
          x: i,
          barsSpace: 6,
          barRods: [
            BarChartRodData(
              toY: d,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: w,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    final maxY = _niceMaxY(maxVal);

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxY / 4,
                getTitlesWidget: (v, _) => Text(
                  money.format(v),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      labels[v.toInt()] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: bars,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) {
                final title = labels[group.x] ?? '';
                final label = ri == 0 ? 'ฝาก' : 'ถอน';
                return BarTooltipItem(
                  '$title\n$label: ${money.format(rod.toY)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  double _niceMaxY(double maxVal) {
    if (maxVal <= 0) return 1000;
    final mag = pow(10, maxVal.floor().toString().length - 1).toDouble();
    final step = mag / 2;
    return ((maxVal / step).ceil()) * step;
  }
}