import 'package:flutter/material.dart';

/// Text style classes for KPI dashboard
class KpiTextStyles {
  /// Employee name in main row
  static TextStyle employeeName(double fontScale) => TextStyle(
    fontSize: 13 * fontScale,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1E293B),
  );

  /// Branch label badge
  static TextStyle branchLabel(double fontScale) =>
      TextStyle(fontSize: 10 * fontScale, color: Colors.grey[600]);

  /// Job/company name in expanded details
  static TextStyle jobName(double fontScale) => TextStyle(
    fontSize: 12 * fontScale,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF374151),
  );

  /// Employee name in expanded details
  static TextStyle detailEmployee(double fontScale) => TextStyle(
    fontSize: 12 * fontScale,
    color: Colors.grey[500],
    fontWeight: FontWeight.w500,
  );

  /// Date in expanded details
  static TextStyle detailDate(double fontScale) =>
      TextStyle(fontSize: 11 * fontScale, color: Colors.grey[400]);

  /// Data cell in main table
  static TextStyle dataCell(
    double fontScale, {
    required Color color,
    required bool hasValue,
  }) => TextStyle(
    fontSize: 13 * fontScale,
    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
    color: hasValue ? color : const Color(0xFF94A3B8),
  );

  /// Simple count in expanded details
  static TextStyle simpleCount(
    double fontScale, {
    required Color color,
    required bool hasValue,
  }) => TextStyle(
    fontSize: 12 * fontScale,
    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
    color: hasValue ? color : Colors.grey[400],
  );

  /// Header cell
  static TextStyle headerCell() => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.grey[600],
  );
}
