import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../kpi_text_styles.dart';

/// Reusable data cell widget for KPI table
class KpiDataCell extends StatelessWidget {
  final int value;
  final Color color;
  final bool isZeroDim;
  final double fontScale;
  final VoidCallback? onTap; // Added

  const KpiDataCell({
    super.key,
    required this.value,
    required this.color,
    this.isZeroDim = false,
    required this.fontScale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0 && isZeroDim) {
      return const Expanded(
        child: Center(
          child: Text('-', style: TextStyle(color: Color(0xFFE2E8F0))),
        ),
      );
    }

    return Expanded(
      child: Center(
        child: InkWell(
          onTap: value > 0 ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: onTap != null && value > 0
                  ? color.withValues(alpha: 0.1)
                  : null,
            ),
            child: Text(
              NumberFormat('#,###').format(value),
              style:
                  KpiTextStyles.dataCell(
                    fontScale,
                    color: color,
                    hasValue: value > 0,
                  ).copyWith(
                    decoration: onTap != null && value > 0
                        ? TextDecoration.underline
                        : null,
                    decorationColor: color.withValues(alpha: 0.5),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple count widget for expanded details
class KpiSimpleCount extends StatelessWidget {
  final int count;
  final Color color;
  final bool isZeroDim;
  final double fontScale;

  const KpiSimpleCount({
    super.key,
    required this.count,
    required this.color,
    this.isZeroDim = false,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && isZeroDim) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(color: Colors.grey[300], fontSize: 12 * fontScale),
        ),
      );
    }

    return Center(
      child: Text(
        NumberFormat('#,###').format(count),
        style: KpiTextStyles.simpleCount(
          fontScale,
          color: color,
          hasValue: count > 0,
        ),
      ),
    );
  }
}
