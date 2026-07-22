import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/blocs/kpi_combined/kpi_combined_state.dart';
import 'package:moniter/models/kpi_combined_employee.dart';

void main() {
  group('KpiCombined totals', () {
    test('shop GL totals keep no-photo keying separate from remaining', () {
      const shop = KpiCombinedShopStat(
        shopName: 'ร้านทดสอบ',
        journalRequiredDocs: 10,
        journalCount: 6,
        journalCountNoPhoto: 3,
      );

      expect(shop.journalCountTotal, 9);
      expect(shop.journalRemaining, 4);
    });

    test('employee GL totals sum normal and no-photo keying', () {
      const employee = KpiCombinedEmployee(
        name: 'employee@example.com',
        journalRequiredDocs: 12,
        totalJournals: 7,
        totalJournalsNoPhoto: 2,
      );

      expect(employee.totalJournalsCombined, 9);
      expect(employee.journalRemaining, 5);
    });

    test('loaded state aggregates document totals across all employees', () {
      const employees = [
        KpiCombinedEmployee(
          name: 'a@example.com',
          totalDocuments: 10,
          requiredToRecordDocuments: 4,
          recordedDocuments: 3,
          remainingDocuments: 1,
        ),
        KpiCombinedEmployee(
          name: 'b@example.com',
          totalDocuments: 7,
          requiredToRecordDocuments: 6,
          recordedDocuments: 2,
          remainingDocuments: 5,
        ),
      ];
      final state = KpiCombinedLoaded(
        employees: employees,
        filteredEmployees: employees,
        shops: const [],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      expect(state.totalDocuments, 17);
      expect(state.requiredToRecordDocuments, 10);
      expect(state.recordedDocuments, 5);
      expect(state.filteredRemainingDocuments, 6);
    });
  });
}
