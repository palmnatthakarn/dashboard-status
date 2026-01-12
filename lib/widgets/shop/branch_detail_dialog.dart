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

class _BranchDetailDialogState extends State<BranchDetailDialog> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        // Draggable dialog
        Positioned(
          left: (screenSize.width - 800) / 2 + _offset.dx,
          top: (screenSize.height - 600) / 2 + _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
              });
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 800,
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    Flexible(child: _buildContent()),
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'อัปเดต: ${_getLatestDate()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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
              icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Calculate financial data
    double dailyTotal = 0.0;
    double monthlyTotal = 0.0;
    double yearlyTotal = 0.0;

    if (widget.shops.isNotEmpty && widget.shops.first.dailyAverage != null) {
      dailyTotal = widget.shops.first.dailyAverage ?? 0.0;
      monthlyTotal = widget.shops.first.monthlyAverage ?? 0.0;
      yearlyTotal = widget.shops.first.yearlyAverage ?? 0.0;
    } else {
      // Fallback calculation
      if (widget.shops.isNotEmpty && widget.selectedDate != null) {
        final targetDate = DateFormat(
          'yyyy-MM-dd',
        ).format(widget.selectedDate!);
        for (final shop in widget.shops) {
          if (shop.daily != null) {
            for (final tx in shop.daily!) {
              if (tx.timestamp != null &&
                  tx.timestamp!.startsWith(targetDate)) {
                dailyTotal += tx.deposit ?? 0;
              }
            }
          }
        }
      }

      if (widget.selectedDate != null) {
        final monthStr =
            '${widget.selectedDate!.year}-${widget.selectedDate!.month.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'รายวัน',
                  dailyTotal,
                  Icons.today_rounded,
                  const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'รายเดือน',
                  monthlyTotal,
                  Icons.calendar_month_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'รายปี',
                  yearlyTotal,
                  Icons.trending_up_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Section
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'กราฟเปรียบเทียบรายได้',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildChart(dailyTotal, monthlyTotal, yearlyTotal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatAmount(value),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(double daily, double monthly, double yearly) {
    final calculatedMax = [
      daily,
      monthly,
      yearly,
    ].reduce((a, b) => a > b ? a : b);
    final maxValue = calculatedMax > 0 ? calculatedMax : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: maxValue * 1.15,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1F2937),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              switch (group.x.toInt()) {
                case 0:
                  label = 'รายวัน';
                  break;
                case 1:
                  label = 'รายเดือน';
                  break;
                case 2:
                  label = 'รายปี';
                  break;
                default:
                  label = '';
              }
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: _formatAmount(rod.toY),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'รายวัน';
                    break;
                  case 1:
                    text = 'รายเดือน';
                    break;
                  case 2:
                    text = 'รายปี';
                    break;
                  default:
                    text = '';
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(text, style: style),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAmount(value),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 25.0,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xFFE5E7EB),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, daily, const Color(0xFF06B6D4)),
          _buildBarGroup(1, monthly, const Color(0xFF8B5CF6)),
          _buildBarGroup(2, yearly, const Color(0xFF10B981)),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value > 0 ? value : 0.5,
          width: 48,
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
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
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        return latestDate;
      }
    }
    return 'N/A';
  }
}
