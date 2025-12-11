import 'package:flutter/material.dart';

/// Account classification enum for categorizing journal entries
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
