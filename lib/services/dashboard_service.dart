import 'dart:developer';
import 'package:intl/intl.dart';
import '../models/doc_details.dart';
import '../models/journal.dart';
import 'journal_service.dart';

class DashboardService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// ดึงข้อมูล Dashboard จาก API/journal โดยใช้ branch_sync และ doc_datetime
  static Future<List<DocDetails>> fetchDashboardData() async {
    log('🚀 Fetching dashboard data from API/journal...');

    try {
      // ดึงข้อมูล journal ทั้งหมด
      final journalResponse = await JournalService.getAllJournals(
        limit: 1000, // เพิ่ม limit เพื่อดึงข้อมูลให้ครบ
      );

      final journals = journalResponse.journals ?? [];
      log('✅ Got ${journals.length} journal records');

      // จัดกลุ่มข้อมูลตาม branch_sync
      final Map<String, List<Journal>> branchGroups = {};

      for (final journal in journals) {
        final branchSync = journal.branchSync ?? '';
        if (branchSync.isNotEmpty) {
          if (!branchGroups.containsKey(branchSync)) {
            branchGroups[branchSync] = [];
          }
          branchGroups[branchSync]!.add(journal);
        }
      }

      log('📊 Grouped data into ${branchGroups.length} branches');

      // แปลงเป็น DocDetails format
      final List<DocDetails> docDetailsList = [];

      for (final entry in branchGroups.entries) {
        final branchSync = entry.key;
        final journals = entry.value;

        if (journals.isEmpty) continue;

        // ใช้ branch name จาก journal แรก
        final branchName = journals.first.branchName ?? 'สาขา $branchSync';

        // คำนวณข้อมูลสถิติ
        final dailyTransactions = _buildDailyTransactions(journals);
        final monthlySummary = _buildMonthlySummary(journals);

        final docDetails = DocDetails(
          shopid: branchSync,
          shopname: branchName,
          daily: dailyTransactions,
          monthlySummary: monthlySummary,
          responsible: ResponsiblePerson(name: 'ระบบอัตโนมัติ', role: 'system'),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          timezone: 'Asia/Bangkok',
          dailyImages: [],
          dailyTransactions: journals
              .map(
                (j) => {
                  'doc_datetime': j.docDatetime,
                  'doc_no': j.docNo,
                  'account_type': j.accountType,
                  'credit': j.credit,
                  'debit': j.debit,
                  'account_name': j.accountName,
                  'description': '${j.accountName} - ${j.bookName}',
                },
              )
              .toList(),
        );

        docDetailsList.add(docDetails);
      }

      log('🎉 Successfully processed ${docDetailsList.length} branches');
      return docDetailsList;
    } catch (e) {
      log('💥 Error fetching dashboard data: $e');
      rethrow;
    }
  }

  /// สร้างข้อมูล daily transactions จาก journals
  static List<DailyTransaction> _buildDailyTransactions(
    List<Journal> journals,
  ) {
    final Map<String, double> dailyTotals = {};

    for (final journal in journals) {
      final docDate = journal.docDatetime;
      if (docDate == null || docDate.isEmpty) continue;

      // แปลงเป็น format yyyy-MM-dd
      final date = _formatDateString(docDate);
      if (date.isEmpty) continue;

      // คำนวณยอดรายได้สุทธิ (credit - debit สำหรับ INCOME, debit - credit สำหรับ EXPENSES)
      double amount = 0.0;
      final accountType = journal.accountType?.toUpperCase();

      if (accountType == 'INCOME') {
        amount = (journal.credit ?? 0) - (journal.debit ?? 0);
      } else if (accountType == 'EXPENSES' || accountType == 'LIABILITIES') {
        amount = (journal.debit ?? 0) - (journal.credit ?? 0);
      }

      dailyTotals[date] = (dailyTotals[date] ?? 0.0) + amount;
    }

    return dailyTotals.entries
        .map(
          (entry) => DailyTransaction(
            timestamp: entry.key,
            deposit: entry.value > 0 ? entry.value : 0.0,
            withdraw: entry.value < 0 ? -entry.value : 0.0,
          ),
        )
        .toList();
  }

  /// สร้างข้อมูล monthly summary จาก journals
  static Map<String, MonthlyData> _buildMonthlySummary(List<Journal> journals) {
    final Map<String, MonthlyData> monthlySummary = {};

    for (final journal in journals) {
      final docDate = journal.docDatetime;
      if (docDate == null || docDate.isEmpty) continue;

      // แปลงเป็น format yyyy-MM
      final monthKey = _formatMonthKey(docDate);
      if (monthKey.isEmpty) continue;

      // คำนวณยอดรายได้และรายจ่าย
      double income = 0.0;
      double expense = 0.0;

      final accountType = journal.accountType?.toUpperCase();

      if (accountType == 'INCOME') {
        income = (journal.credit ?? 0) - (journal.debit ?? 0);
      } else if (accountType == 'EXPENSES' || accountType == 'LIABILITIES') {
        expense = (journal.debit ?? 0) - (journal.credit ?? 0);
      }

      if (!monthlySummary.containsKey(monthKey)) {
        monthlySummary[monthKey] = MonthlyData(deposit: 0.0, withdraw: 0.0);
      }

      monthlySummary[monthKey] = MonthlyData(
        deposit: (monthlySummary[monthKey]!.deposit ?? 0.0) + income,
        withdraw: (monthlySummary[monthKey]!.withdraw ?? 0.0) + expense,
      );
    }

    return monthlySummary;
  }

  /// แปลง date string เป็น yyyy-MM-dd format
  static String _formatDateString(String dateStr) {
    try {
      // ลองแปลงหลายรูปแบบ
      DateTime? date;

      // รูปแบบ ISO 8601
      if (dateStr.contains('T')) {
        date = DateTime.tryParse(dateStr);
      } else if (dateStr.contains('-')) {
        // รูปแบบ yyyy-MM-dd หรือ yyyy-MM-dd HH:mm:ss
        final parts = dateStr.split(' ');
        date = DateTime.tryParse(parts[0]);
      } else if (dateStr.length == 8) {
        // รูปแบบ yyyyMMdd
        date = DateTime.tryParse(
          '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}',
        );
      }

      if (date != null) {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      log('⚠️ Error parsing date: $dateStr - $e');
    }

    return '';
  }

  /// แปลง date string เป็น yyyy-MM format สำหรับ monthly key
  static String _formatMonthKey(String dateStr) {
    try {
      final dateFormatted = _formatDateString(dateStr);
      if (dateFormatted.isNotEmpty) {
        return dateFormatted.substring(0, 7); // yyyy-MM
      }
    } catch (e) {
      log('⚠️ Error parsing month key: $dateStr - $e');
    }

    return '';
  }
}
