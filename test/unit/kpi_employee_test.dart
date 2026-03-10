import 'package:flutter_test/flutter_test.dart';
import 'package:moniter/models/kpi_employee.dart';

// Helper to build a minimal KpiEmployee
KpiEmployee makeEmployee({
  int totalDocuments = 10,
  int completedDocuments = 0,
  String status = 'assigned',
  List<KpiCompanyDetail> companyDetails = const [],
}) {
  final now = DateTime(2025, 3, 1);
  return KpiEmployee(
    id: 'emp001',
    name: 'สมชาย ใจดี',
    branch: 'สาขาหลัก',
    documentStartDate: now,
    documentEndDate: now.add(const Duration(days: 30)),
    dueDate: now.add(const Duration(days: 30)),
    totalDocuments: totalDocuments,
    assignedDocuments: totalDocuments,
    pendingDocuments: 0,
    completedDocuments: completedDocuments,
    status: status,
    companyDetails: companyDetails,
  );
}

// Helper to build a minimal KpiCompanyDetail
KpiCompanyDetail makeDetail({
  int totalBillCount = 10,
  int referenceCount = 5,
  String status = '0',
}) {
  return KpiCompanyDetail(
    company: 'บริษัท ทดสอบ จำกัด',
    employee: 'emp001',
    recordingDate: DateTime(2025, 3, 1),
    totalBillCount: totalBillCount,
    assigned: totalBillCount,
    pending: 0,
    waitingKey: 0,
    waitingVerify: 0,
    waitingFix: 0,
    completed: 0,
    cancelled: 0,
    referenceCount: referenceCount,
    status: status,
  );
}

void main() {
  group('KpiEmployee.completionRate', () {
    test('returns 0.0 when companyDetails is empty', () {
      final emp = makeEmployee(companyDetails: []);
      expect(emp.completionRate, equals(0.0));
    });

    test('averages progress across companyDetails', () {
      // detail1: referenceCount=5, totalBillCount=10 → 50%
      // detail2: status='4' → 100%
      // average = 75%
      final emp = makeEmployee(
        companyDetails: [
          makeDetail(totalBillCount: 10, referenceCount: 5, status: '0'),
          makeDetail(totalBillCount: 10, referenceCount: 10, status: '4'),
        ],
      );
      expect(emp.completionRate, closeTo(75.0, 0.01));
    });
  });

  group('KpiEmployee date formatting', () {
    test('documentStartDateFormatted uses Thai year (BE)', () {
      final emp = makeEmployee();
      // documentStartDate = 2025, Thai year = 2568
      expect(emp.documentStartDateFormatted, contains('2568'));
    });

    test('submittedDateFormatted returns ทำงาน when null', () {
      final emp = makeEmployee();
      expect(emp.submittedDateFormatted, equals('ทำงาน'));
    });
  });

  group('KpiCompanyDetail.progress', () {
    test('returns 100.0 when status is 4 (Completed)', () {
      final detail = makeDetail(
        totalBillCount: 5,
        referenceCount: 1,
        status: '4',
      );
      expect(detail.progress, equals(100.0));
    });

    test('returns 0.0 when totalBillCount is 0', () {
      final detail = makeDetail(
        totalBillCount: 0,
        referenceCount: 0,
        status: '0',
      );
      expect(detail.progress, equals(0.0));
    });

    test('returns correct percentage', () {
      final detail = makeDetail(
        totalBillCount: 8,
        referenceCount: 2,
        status: '0',
      );
      expect(detail.progress, closeTo(25.0, 0.01));
    });

    test('returns 100.0 when all bills done', () {
      final detail = makeDetail(
        totalBillCount: 5,
        referenceCount: 5,
        status: '0',
      );
      expect(detail.progress, closeTo(100.0, 0.01));
    });
  });

  group('KpiEmployee.lastActiveFormatted', () {
    test('returns - when lastActive is null', () {
      final emp = makeEmployee();
      expect(emp.lastActiveFormatted, equals('-'));
    });

    test('returns เมื่อสักครู่ when less than 1 minute ago', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      final emp = KpiEmployee(
        id: 'e1',
        name: 'test',
        branch: 'b',
        documentStartDate: now,
        documentEndDate: now,
        dueDate: now,
        totalDocuments: 1,
        assignedDocuments: 1,
        pendingDocuments: 0,
        completedDocuments: 0,
        status: 'assigned',
        lastActive: now,
      );
      expect(emp.lastActiveFormatted, contains('เมื่อสักครู่'));
    });
  });
}
