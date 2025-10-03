import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final NumberFormat money;
  final String? chartType;

  /// ปรับเวลา/รูปแบบอนิเมชันได้ตามต้องการ
  final Duration appearDuration;
  final Curve appearCurve;
  final Duration updateDuration;
  final Curve updateCurve;

  const MonthlyLineChart({
    super.key,
    required this.rows,
    required this.money,
    this.chartType,
    this.appearDuration = const Duration(milliseconds: 900),
    this.appearCurve = Curves.easeOutCubic,
    this.updateDuration = const Duration(milliseconds: 500),
    this.updateCurve = Curves.easeInOutCubic,
  });

  String _formatLabel(String value) {
    if (chartType == 'daily') {
      // สำหรับรายวัน: แสดงวันจันทร์-อาทิตย์
      try {
        final datePart = value.contains(' ') ? value.split(' ')[0] : value;
        final date = DateTime.parse(datePart);
        const weekdays = ['วันจันทร์', 'วันอังคาร', 'วันพุธ', 'วันพฤหัสบดี', 'วันศุกร์', 'วันเสาร์', 'วันอาทิตย์'];
        final weekdayIndex = date.weekday - 1;
        if (weekdayIndex >= 0 && weekdayIndex < weekdays.length) {
          return weekdays[weekdayIndex];
        }
        return value.length > 3 ? value.substring(0, 3) : value;
      } catch (_) {
        return value.length > 3 ? value.substring(0, 3) : value;
      }
    } else if (chartType == 'average') {
      // สำหรับเฉลี่ยรายเดือน: แสดงเดือนแต่ละเดือน
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) {
        final parts = value.split('-');
        if (parts.length >= 2) {
          final mm = int.tryParse(parts[1]) ?? 0;
          const months = [
            'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
            'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
          ];
          if (mm >= 1 && mm <= 12) {
            return months[mm - 1];
          }
        }
      }
      return value;
    } else {
      // สำหรับรายเดือน: แสดงเดือนแบบเดิม
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) {
        final parts = value.split('-');
        if (parts.length >= 2) {
          final year = parts[0];
          final yy = year.length >= 2 ? year.substring(2) : year;
          final mm = int.tryParse(parts[1]) ?? 0;
          const th = [
            'มค ', 'กพ', 'มีค', 'เมย', 'พค', 'มิย', 'กค', 'สค', 'กย', 'ตค', 'พย', 'ธค',
          ];
          if (mm >= 1 && mm <= 12) {
            return '${th[mm - 1]} $yy';
          }
        }
      }
      return value;
    }
  }

  /// scale ค่าจุดตาม progress (0..1) เพื่อทำเอฟเฟกต์วาดขึ้น
  List<FlSpot> _animatedSpots(List<FlSpot> src, double p) {
    // ใช้ easing เพิ่มเติมให้ดูนุ่มขึ้น
    final eased = Curves.easeOutCubic.transform(p.clamp(0, 1));
    return src
        .map((s) => FlSpot(s.x, s.y * eased))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final labels = <int, String>{};
    final deposits = <FlSpot>[];
    final withdraws = <FlSpot>[];
    double maxVal = 0;

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final d = (r['deposit'] ?? 0) * 1.0;
      final w = (r['withdraw'] ?? 0) * 1.0;
      maxVal = [maxVal, d, w].reduce((a, b) => a > b ? a : b);

      final key = chartType == 'daily' ? (r['date'] ?? '-') : (r['month'] ?? '-');
      labels[i] = _formatLabel(key);
      deposits.add(FlSpot(i.toDouble(), d));
      withdraws.add(FlSpot(i.toDouble(), w));
    }

    final maxY = _niceMaxY(maxVal);

    // ใช้ TweenAnimationBuilder เพื่อให้กราฟค่อยๆ วาดขึ้น (appear)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: appearDuration,
      curve: appearCurve,
      builder: (context, progress, _) {
        final depAni = _animatedSpots(deposits, progress);
        final wtdAni = _animatedSpots(withdraws, progress);

        return SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
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
                    interval: rows.length > 7 ? (rows.length / 12).ceilToDouble() : 1,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[idx] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: depAni,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 2.5,
                  dotData: FlDotData(show: progress > 0.85), // ให้จุดโผล่ช่วงท้ายๆ
                ),
                LineChartBarData(
                  spots: wtdAni,
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 2.5,
                  dotData: FlDotData(show: progress > 0.85),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((t) {
                      final label = t.barIndex == 0 ? 'ฝาก' : 'ถอน';
                      return LineTooltipItem(
                        '${labels[t.spotIndex]}\n$label: ${money.format(t.y)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              borderData: FlBorderData(show: false),
            ),

            // อนิเมชันตอน "อัปเดตข้อมูล" (implicit animation ของ fl_chart)
            duration: updateDuration,
            curve: updateCurve,
          ),
        );
      },
    );
  }

  double _niceMaxY(double maxVal) {
    if (maxVal <= 0) return 1000;
    final mag = pow(10, maxVal.floor().toString().length - 1).toDouble();
    final step = mag / 2;
    return ((maxVal / step).ceil()) * step;
  }
}
