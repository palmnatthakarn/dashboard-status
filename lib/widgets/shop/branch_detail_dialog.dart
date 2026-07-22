import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/doc_details.dart';

class BranchDetailDialog extends StatefulWidget {
  final String shopId;
  final List<DocDetails> shops;
  final DateTime? selectedDate;

  const BranchDetailDialog({
    super.key,
    required this.shopId,
    required this.shops,
    this.selectedDate,
  });

  @override
  State<BranchDetailDialog> createState() => _BranchDetailDialogState();
}

enum ChartMode { daily, monthly }

class _BranchDetailDialogState extends State<BranchDetailDialog> {
  Offset _offset = Offset.zero;
  ChartMode _chartMode = ChartMode.daily;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        // Draggable dialog
        Positioned(
          left: (screenSize.width - 850) / 2 + _offset.dx,
          top: (screenSize.height - 650) / 2 + _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
              });
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 850,
                height: 650, // Fixed height for a robust layout
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Slight pleasant off-white
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Extract shop name
    String shopName = widget.shopId;
    if (widget.shops.isNotEmpty) {
      final shop = widget.shops.first;
      try {
        if (shop.names != null && shop.names!.isNotEmpty) {
          final thaiName = shop.names!.firstWhere(
            (name) => name.code == 'th',
            orElse: () => shop.names!.first,
          );
          if (thaiName.name != null && thaiName.name!.isNotEmpty) {
            shopName = thaiName.name!;
          }
        }
        if (shopName == widget.shopId &&
            shop.shopname != null &&
            shop.shopname!.isNotEmpty) {
          shopName = shop.shopname!;
        }
      } catch (e) {
        if (shop.shopname != null && shop.shopname!.isNotEmpty) {
          shopName = shop.shopname!;
        }
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${widget.shopId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.update_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'อัปเดตล่าสุด: ${_getLatestDate()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Calculate static financial totals for the top cards
    double dailyTotal = 0.0;
    double monthlyTotal = 0.0;
    double yearlyTotal = 0.0;

    if (widget.shops.isNotEmpty && widget.shops.first.dailyAverage != null) {
      dailyTotal = widget.shops.first.dailyAverage ?? 0.0;
      monthlyTotal = widget.shops.first.monthlyAverage ?? 0.0;
      yearlyTotal = widget.shops.first.yearlyAverage ?? 0.0;
    } else {
      if (widget.shops.isNotEmpty && widget.selectedDate != null) {
        final targetDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate!);
        for (final shop in widget.shops) {
          if (shop.daily != null) {
            for (final tx in shop.daily!) {
              if (tx.timestamp != null && tx.timestamp!.startsWith(targetDate)) {
                dailyTotal += tx.deposit ?? 0;
              }
            }
          }
        }
      }

      if (widget.selectedDate != null) {
        final monthStr = '${widget.selectedDate!.year}-${widget.selectedDate!.month.toString().padLeft(2, '0')}';
        for (final shop in widget.shops) {
          if (shop.monthlySummary != null) {
            for (final entry in shop.monthlySummary!.entries) {
              if (entry.key.startsWith(monthStr)) {
                monthlyTotal += entry.value.deposit ?? 0;
              }
            }
          }
        }
      }

      yearlyTotal = widget.shops.fold(0.0, (sum, s) => sum + s.totalDeposit);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'ยอดขายรายวัน',
                  dailyTotal,
                  Icons.today_rounded,
                  const Color(0xFF0EA5E9), // Light Blue
                  const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'ยอดขายเดือนนี้',
                  monthlyTotal,
                  Icons.calendar_month_rounded,
                  const Color(0xFF8B5CF6), // Purple
                  const Color(0xFFEDE9FE),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  'ยอดขายทั้งปี',
                  yearlyTotal,
                  Icons.auto_graph_rounded,
                  const Color(0xFF10B981), // Emerald Green
                  const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Interactive Chart Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            size: 20,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'แนวโน้มยอดขาย',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    // Toggle Switch Daily/Monthly
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton(
                            title: 'รายวัน',
                            mode: ChartMode.daily,
                            icon: Icons.calendar_view_day_rounded,
                          ),
                          _buildToggleButton(
                            title: 'รายเดือน',
                            mode: ChartMode.monthly,
                            icon: Icons.calendar_view_month_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: _buildTrendChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String title, required ChartMode mode, required IconData icon}) {
    final isSelected = _chartMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chartMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    double value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatAmountFull(value),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 28,
              fontFamily: 'Roboto', // Ensures nice number rendering
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  // --- CHART DATA EXTRACTION ---

  Widget _buildTrendChart() {
    if (_chartMode == ChartMode.daily) {
      return _buildLineChartDaily();
    } else {
      return _buildBarChartMonthly();
    }
  }

  // Parses last 7 days from `widget.shops[].daily`
  List<FlSpot> _getDailySpots(outDateLabels) {
    if (widget.shops.isEmpty) return [];
    
    // Attempt to aggregate by date
    Map<String, double> aggregatedDaily = {};
    for (final shop in widget.shops) {
      if (shop.daily != null) {
        for (final tx in shop.daily!) {
          if (tx.timestamp != null) {
            try {
              final DateTime dt = DateTime.parse(tx.timestamp!);
              final dateStr = DateFormat('yyyy-MM-dd').format(dt);
              aggregatedDaily[dateStr] = (aggregatedDaily[dateStr] ?? 0) + (tx.deposit ?? 0);
            } catch (e) {
              // Ignore invalid dates
            }
          }
        }
      }
    }

    // Sort by date descending
    final sortedKeys = aggregatedDaily.keys.toList()..sort((a, b) => b.compareTo(a));
    // Take last 7 days max
    final last7 = sortedKeys.take(7).toList()..sort(); // ascending order for chart
    
    List<FlSpot> spots = [];
    outDateLabels.clear();

    for (int i = 0; i < last7.length; i++) {
      final dateValue = last7[i];
      final dt = DateTime.parse(dateValue);
      outDateLabels.add(DateFormat('dd MMM').format(dt));
      spots.add(FlSpot(i.toDouble(), aggregatedDaily[dateValue]!));
    }

    return spots;
  }

  // Parses last 6 months from `widget.shops[].monthlySummary`
  List<BarChartGroupData> _getMonthlyBars(outMonthLabels, double width, Color color) {
    if (widget.shops.isEmpty) return [];

    Map<String, double> aggregatedMonthly = {};
    for (final shop in widget.shops) {
      if (shop.monthlySummary != null) {
        shop.monthlySummary!.forEach((monthKey, data) {
           aggregatedMonthly[monthKey] = (aggregatedMonthly[monthKey] ?? 0) + (data.deposit ?? 0);
        });
      }
    }

    final sortedKeys = aggregatedMonthly.keys.toList()..sort((a, b) => b.compareTo(a));
    final last6 = sortedKeys.take(6).toList()..sort();

    List<BarChartGroupData> bars = [];
    outMonthLabels.clear();

    for (int i = 0; i < last6.length; i++) {
        final mKey = last6[i]; // e.g., "2026-03"
        try {
            final parts = mKey.split('-');
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final dt = DateTime(year, month);
            outMonthLabels.add(DateFormat('MMM yy').format(dt));
        } catch(e) {
            outMonthLabels.add(mKey);
        }
        bars.add(
            BarChartGroupData(
                x: i,
                barRods: [
                    BarChartRodData(
                      toY: aggregatedMonthly[mKey] ?? 0,
                      color: color,
                      width: width,
                      borderRadius: BorderRadius.circular(4),
                    )
                ]
            )
        );
    }
    return bars;
  }

  Widget _buildLineChartDaily() {
    List<String> dateLabels = [];
    final spots = _getDailySpots(dateLabels);

    if (spots.isEmpty) {
        return const Center(
          child: Text('ไม่มีข้อมูลย้อนหลัง 7 วัน', style: TextStyle(color: Colors.grey)),
        );
    }

    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY * 1.2) / 4 > 0 ? (maxY * 1.2) / 4 : 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.5,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dateLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    dateLabels[idx],
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                 if (value == 0 || value == maxY * 1.2) return const SizedBox.shrink(); 
                 return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatAmountK(value),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                 );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (spot) => const Color(0xFF1E293B),
             tooltipRoundedRadius: 8,
             getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${_formatAmountFull(spot.y)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    children: [
                       TextSpan(
                         text: dateLabels[spot.x.toInt()],
                         style: const TextStyle(
                           color: Color(0xFF94A3B8),
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         )
                       )
                    ]
                  );
                }).toList();
             }
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF0EA5E9),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: const Color(0xFF0EA5E9),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartMonthly() {
    List<String> monthLabels = [];
    final bars = _getMonthlyBars(monthLabels, 32, const Color(0xFF8B5CF6));

     if (bars.isEmpty) {
        return const Center(
          child: Text('ไม่มีข้อมูลย้อนหลังรายเดือน', style: TextStyle(color: Colors.grey)),
        );
    }

    double maxY = 0;
    for(var b in bars) {
        if(b.barRods.isNotEmpty && b.barRods[0].toY > maxY) {
            maxY = b.barRods[0].toY;
        }
    }
    if (maxY == 0) maxY = 100;

     return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY * 1.2) / 4 > 0 ? (maxY * 1.2) / 4 : 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.5,
            dashArray: [5, 5],
          ),
        ),
         titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= monthLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    monthLabels[idx],
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                 if (value == 0 || value == maxY * 1.2) return const SizedBox.shrink(); 
                 return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatAmountK(value),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                 );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
             touchTooltipData: BarTouchTooltipData(
             getTooltipColor: (spot) => const Color(0xFF1E293B),
             tooltipRoundedRadius: 8,
             getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${_formatAmountFull(rod.toY)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    children: [
                       TextSpan(
                         text: monthLabels[group.x.toInt()],
                         style: const TextStyle(
                           color: Color(0xFF94A3B8),
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         )
                       )
                    ]
                  );
             }
          ),
        ),
        barGroups: bars,
      )
     );
  }

  // --- FORMATTERS ---

  String _formatAmountFull(double amount) {
    if (amount == 0) return '฿0';
    final formatter = NumberFormat('#,##0.00');
    return '฿${formatter.format(amount)}';
  }

  String _formatAmountK(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getLatestDate() {
    if (widget.shops.isEmpty) return 'N/A';
    String? latestDate;
    for (final shop in widget.shops) {
      if (shop.updatedAt != null) {
        if (latestDate == null || shop.updatedAt!.compareTo(latestDate) > 0) {
          latestDate = shop.updatedAt;
        }
      }
    }
    if (latestDate != null) {
      try {
        final date = DateTime.parse(latestDate);
        return DateFormat('dd MMM yyyy HH:mm').format(date);
      } catch (e) {
        return latestDate;
      }
    }
    return 'N/A';
  }
}

