import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/models/doc_details.dart';
import 'package:moniter/utils/dashboard_helper.dart';

void main() {
  group('DashboardHelper shop status counts', () {
    test('uses yearlyAverage before monthlySummary so cards match table status', () {
      final shops = [
        DocDetails(
          shopid: 'red-shop',
          yearlyAverage: 12610000,
          monthlySummary: {'total': MonthlyData(deposit: 0)},
        ),
        DocDetails(
          shopid: 'safe-shop',
          yearlyAverage: 25000,
          monthlySummary: {'total': MonthlyData(deposit: 2500000)},
        ),
      ];

      expect(
        DashboardHelper.getShopCountByStatus(shops, 'exceeded', null),
        equals(1),
      );
      expect(
        DashboardHelper.getShopCountByStatus(shops, 'safe', null),
        equals(1),
      );
      expect(
        DashboardHelper.getShopCountByStatus(shops, 'warning', null),
        equals(0),
      );
    });

    test('falls back to monthlySummary for legacy dashboard data', () {
      final shops = [
        DocDetails(
          shopid: 'legacy-warning-shop',
          monthlySummary: {'2026-05': MonthlyData(deposit: 1500000)},
        ),
      ];

      expect(
        DashboardHelper.getShopCountByStatus(shops, 'warning', null),
        equals(1),
      );
    });
  });
}
