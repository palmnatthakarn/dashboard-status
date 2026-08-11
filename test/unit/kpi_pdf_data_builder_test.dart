import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/models/kpi_combined_employee.dart';
import 'package:moniter/pages/kpi/kpi_pdf_data_builder.dart';

void main() {
  test('PDF groups always contain the complete shop summary snapshot', () {
    final employees = [
      KpiCombinedEmployee(
        name: 'employee@example.com',
        totalDocuments: 3,
        totalJournals: 2,
        totalUploaded: 7,
        shopStats: [
          KpiCombinedShopStat(
            shopName: 'Business A',
            totalDocuments: 3,
            journalCount: 2,
            tasks: [
              KpiCombinedTaskItem(
                taskName: 'August close',
                taskCode: 'AUG',
                status: 1,
                totalDocument: 3,
                ownerAt: DateTime(2026, 8, 1),
                ownerBy: 'employee@example.com',
                isOwner: true,
                journalEntries: [
                  KpiCombinedJournalItem(
                    docNo: 'JV-001',
                    accountName: 'Cash',
                    debit: 100,
                    credit: 0,
                    docDate: DateTime(2026, 8, 1),
                    createdBy: 'employee@example.com',
                    checkedBy: '',
                    updatedBy: '',
                  ),
                  KpiCombinedJournalItem(
                    docNo: 'JV-001',
                    accountName: 'Revenue',
                    debit: 0,
                    credit: 100,
                    docDate: DateTime(2026, 8, 1),
                    createdBy: 'employee@example.com',
                    checkedBy: '',
                    updatedBy: '',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];

    final groups = KpiPdfDataBuilder.buildGroups(
      employees: employees,
      summaryReady: true,
      nameMappings: const {'employee@example.com': 'Employee One'},
    );

    expect(groups, hasLength(1));
    expect(groups.single.name, 'Employee One (employee@example.com)');
    expect(groups.single.rows, hasLength(4));
    expect(groups.single.rows.first.first, 'Business A');
    expect(groups.single.rows[1].first, contains('August close'));
    expect(groups.single.rows[1][12], '1');
    expect(groups.single.rows[1][14], '1');
    expect(groups.single.totalRows, hasLength(1));
    expect(groups.single.summary, contains('อัปโหลดโดยคนนี้ 7'));
  });
}
