import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/models/dashboard_summary.dart';

void main() {
  group('DashboardSummary.fromJson()', () {
    final validJson = {
      'totalshop': 5,
      'doctotal': 100,
      'docsuccess': 70,
      'docwarning': 20,
      'docerror': 10,
      'timestamp': '2025-03-01T08:00:00Z',
      'success_rate': 70,
      'warning_rate': 20,
      'error_rate': 10,
    };

    test('parses all fields correctly', () {
      final summary = DashboardSummary.fromJson(validJson);
      expect(summary.totalshop, equals(5));
      expect(summary.doctotal, equals(100));
      expect(summary.docsuccess, equals(70));
      expect(summary.docwarning, equals(20));
      expect(summary.docerror, equals(10));
      expect(summary.successRate, equals(70));
      expect(summary.warningRate, equals(20));
      expect(summary.errorRate, equals(10));
    });

    test('computed getters match raw fields', () {
      final summary = DashboardSummary.fromJson(validJson);
      expect(summary.completedCount, equals(summary.docsuccess));
      expect(summary.pendingCount, equals(summary.docwarning));
      expect(summary.failedCount, equals(summary.docerror));
    });

    test('rates sum to 100', () {
      final summary = DashboardSummary.fromJson(validJson);
      expect(
        summary.successRate + summary.warningRate + summary.errorRate,
        equals(100),
      );
    });

    test('toJson() round-trips correctly', () {
      final summary = DashboardSummary.fromJson(validJson);
      final json = summary.toJson();
      final summary2 = DashboardSummary.fromJson(json);
      expect(summary2.totalshop, equals(summary.totalshop));
      expect(summary2.doctotal, equals(summary.doctotal));
      expect(summary2.successRate, equals(summary.successRate));
    });
  });
}
