import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'app_logger.dart';

class DashboardHelper {
  static double getIncomeForPeriod(
    dynamic shop,
    DateTimeRange? selectedDateRange,
  ) {
    final yearlyAverage = _readYearlyAverage(shop);
    if (yearlyAverage != null) return yearlyAverage;

    // คำนวณยอดรายปีจาก monthly_summary
    if (shop.monthlySummary == null) return 0.0;

    double sum = 0.0;
    shop.monthlySummary.forEach((String month, dynamic monthData) {
      if (monthData.deposit != null) {
        sum += monthData.deposit!;
      }
    });
    return sum;
  }

  static int getShopCountByStatus(
    List shops,
    String status,
    DateTimeRange? selectedDateRange,
  ) {
    try {
      if (shops.isEmpty) return 0;

      return shops.where((shop) {
        try {
          final profitLoss = calculateProfitLoss(shop, selectedDateRange);
          switch (status) {
            case 'safe':
              return profitLoss < AppConstants.safeIncomeMax;
            case 'warning':
              return profitLoss >= AppConstants.warningIncomeMin &&
                  profitLoss <= AppConstants.warningIncomeMax;
            case 'exceeded':
              return profitLoss > AppConstants.exceededIncomeMin;
            case 'all':
              return true;
            default:
              return false;
          }
        } catch (e) {
          dLog('Error calculating profit/loss for shop: $e');
          return false;
        }
      }).length;
    } catch (e) {
      dLog('Error in getShopCountByStatus: $e');
      return 0;
    }
  }

  // คำนวณกำไร/ขาดทุนจากข้อมูล journal
  static double calculateProfitLoss(
    dynamic shop,
    DateTimeRange? selectedDateRange,
  ) {
    try {
      final yearlyAverage = _readYearlyAverage(shop);
      if (yearlyAverage != null) return yearlyAverage;

      if (shop.dailyTransactions == null || shop.dailyTransactions.isEmpty) {
        // ใช้ข้อมูลจาก monthlySummary แทนถ้าไม่มี dailyTransactions
        return getIncomeForPeriod(shop, selectedDateRange);
      }

      double totalIncome = 0.0; // รายรับ (credit - debit)
      double totalExpenses = 0.0; // รายจ่าย (credit - debit)

      for (final transaction in shop.dailyTransactions) {
        if (transaction is Map<String, dynamic>) {
          final accountType = transaction['account_type']?.toString() ?? '';
          final credit =
              double.tryParse(transaction['credit']?.toString() ?? '0') ?? 0.0;
          final debit =
              double.tryParse(transaction['debit']?.toString() ?? '0') ?? 0.0;

          if (accountType.toUpperCase() == 'INCOME') {
            totalIncome += (credit - debit);
          } else if (accountType.toUpperCase() == 'EXPENSES') {
            totalExpenses += (credit - debit);
          }
        }
      }

      return totalIncome - totalExpenses; // กำไร/ขาดทุน
    } catch (e) {
      // หากมีข้อผิดพลาด ให้ใช้ข้อมูลจาก monthlySummary
      return getIncomeForPeriod(shop, selectedDateRange);
    }
  }

  static Map<String, int> getDocumentCounts(List shops) {
    try {
      if (shops.isEmpty) {
        return {
          'deposit': 0,
          'withdraw': 0,
          'total': 0,
          'approved': 0,
          'pending': 0,
          'rejected': 0,
        };
      }

      int totalDeposit = 0;
      int totalWithdraw = 0;
      int totalDocs = 0;
      int approved = 0;
      int pending = 0;

      for (final shop in shops) {
        try {
          // นับจาก localImageCount (imagecount จาก API)
          if (shop.localImageCount != null) {
            final imageCount = shop.localImageCount as int;
            totalDocs += imageCount;
          }

          // คำนวณจาก dailyTransactions สำหรับ deposit/withdraw
          if (shop.dailyTransactions != null) {
            for (final transaction in shop.dailyTransactions) {
              if (transaction is Map<String, dynamic>) {
                final accountType =
                    transaction['account_type']?.toString() ?? '';
                if (accountType.toUpperCase() == 'INCOME') {
                  totalDeposit++;
                  approved++;
                } else if (accountType.toUpperCase() == 'EXPENSES') {
                  totalWithdraw++;
                  approved++;
                }
              }
            }
          }
        } catch (e) {
          dLog('Error processing shop documents: $e');
        }
      }

      return {
        'deposit': totalDeposit,
        'withdraw': totalWithdraw,
        'total': totalDocs, // ใช้ค่าจาก imagecount
        'approved': approved > 0 ? approved : 0,
        'pending': pending > 0 ? pending : 0,
        'rejected': 0,
      };
    } catch (e) {
      dLog('Error in getDocumentCounts: $e');
      return {
        'deposit': 0,
        'withdraw': 0,
        'total': 0,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
      };
    }
  }

  static double? _readYearlyAverage(dynamic shop) {
    try {
      final value = shop.yearlyAverage;
      if (value is num) return value.toDouble();
    } catch (_) {
      return null;
    }
    return null;
  }
}
