import 'package:moniter/services/journal_service.dart';
import 'package:moniter/models/journal.dart';

void main() async {
  print('📊 Journal Usage Examples\n');

  try {
    // Example 1: Get all journals
    await example1GetAllJournals();

    // Example 2: Filter by account type
    await example2FilterByAccountType();

    // Example 3: Calculate totals
    await example3CalculateTotals();

    // Example 4: Display formatted data
    await example4DisplayFormatted();

    // Example 5: Group by branch
    await example5GroupByBranch();

    // Example 6: Fetch GL Journals with Filter Task => GL Journal
    await example6FetchGLJournals();

    print('\n✅ All examples completed!');
  } catch (e) {
    print('❌ Error: $e');
  }
}

// Example 1: Get all journals
Future<void> example1GetAllJournals() async {
  print('📋 Example 1: Get All Journals');
  print('─' * 50);

  final response = await JournalService.getAllJournals(limit: 5);
  final journals = response.journals ?? [];

  print('Found ${journals.length} journals\n');

  for (final journal in journals) {
    print('Journal #${journal.id}');
    print('  Branch: ${journal.branchSync} - ${journal.branchName}');
    print('  Doc: ${journal.docNo} (${journal.displayDate})');
    print('  Account: ${journal.accountCode} - ${journal.accountName}');
    print('  Type: ${journal.accountTypeDisplay}');
    print('  Amount: ${journal.displayAmount}');
    print('  Transaction: ${journal.transactionTypeDisplay}');
    print('');
  }
}

// Example 2: Filter by account type
Future<void> example2FilterByAccountType() async {
  print('\n🔍 Example 2: Filter by Account Type');
  print('─' * 50);

  final response = await JournalService.getAllJournals(limit: 100);
  final journals = response.journals ?? [];

  // Group by account type
  final income = journals.where((j) => j.accountType == 'INCOME').toList();
  final expenses = journals.where((j) => j.accountType == 'EXPENSES').toList();
  final assets = journals.where((j) => j.accountType == 'ASSETS').toList();
  final liabilities = journals
      .where((j) => j.accountType == 'LIABILITIES')
      .toList();

  print('Account Type Summary:');
  print('  รายได้ (INCOME): ${income.length} entries');
  print('  ค่าใช้จ่าย (EXPENSES): ${expenses.length} entries');
  print('  สินทรัพย์ (ASSETS): ${assets.length} entries');
  print('  หนี้สิน (LIABILITIES): ${liabilities.length} entries');
  print('');

  // Show income details
  if (income.isNotEmpty) {
    print('รายได้ (INCOME) Details:');
    for (final j in income.take(3)) {
      print('  - ${j.accountName}: ${j.displayAmount}');
    }
  }
}

// Example 3: Calculate totals
Future<void> example3CalculateTotals() async {
  print('\n💰 Example 3: Calculate Totals');
  print('─' * 50);

  final response = await JournalService.getAllJournals(limit: 100);
  final journals = response.journals ?? [];

  // Calculate totals
  final totalDebit = journals.fold(0.0, (sum, j) => sum + (j.debit ?? 0));
  final totalCredit = journals.fold(0.0, (sum, j) => sum + (j.credit ?? 0));
  final netAmount = totalDebit - totalCredit;

  print('Financial Summary:');
  print('  Total Debit: ${_formatCurrency(totalDebit)}');
  print('  Total Credit: ${_formatCurrency(totalCredit)}');
  print('  Net Amount: ${_formatCurrency(netAmount)}');
  print('');

  // Calculate by account type
  final incomeTotal = journals
      .where((j) => j.accountType == 'INCOME')
      .fold(0.0, (sum, j) => sum + (j.credit ?? 0));

  final expensesTotal = journals
      .where((j) => j.accountType == 'EXPENSES')
      .fold(0.0, (sum, j) => sum + (j.debit ?? 0));

  print('By Account Type:');
  print('  รายได้: ${_formatCurrency(incomeTotal)}');
  print('  ค่าใช้จ่าย: ${_formatCurrency(expensesTotal)}');
  print('  กำไร/ขาดทุน: ${_formatCurrency(incomeTotal - expensesTotal)}');
}

// Example 4: Display formatted data
Future<void> example4DisplayFormatted() async {
  print('\n📊 Example 4: Display Formatted Data');
  print('─' * 50);

  final response = await JournalService.getAllJournals(limit: 3);
  final journals = response.journals ?? [];

  for (final journal in journals) {
    print('╔═══════════════════════════════════════════════╗');
    print('║ Journal Entry #${(journal.id?.toString() ?? '-').padRight(33)}║');
    print('╠═══════════════════════════════════════════════╣');
    print('║ Document Information                          ║');
    print('║   Branch: ${(journal.branchSync ?? '-').padRight(36)}║');
    print('║   Doc No: ${(journal.docNo ?? '-').padRight(36)}║');
    print('║   Date: ${journal.displayDate.padRight(38)}║');
    print(
      '║   Period: ${(journal.periodNumber?.toString() ?? '-').padRight(36)}║',
    );
    print(
      '║   Year: ${(journal.accountYear?.toString() ?? '-').padRight(38)}║',
    );
    print('╠═══════════════════════════════════════════════╣');
    print('║ Account Information                           ║');
    print('║   Code: ${(journal.accountCode ?? '-').padRight(38)}║');
    print('║   Name: ${(journal.accountName ?? '-').padRight(38)}║');
    print('║   Type: ${journal.accountTypeDisplay.padRight(38)}║');
    print('╠═══════════════════════════════════════════════╣');
    print('║ Transaction                                   ║');
    print('║   Debit: ${_formatCurrency(journal.debit ?? 0).padRight(37)}║');
    print('║   Credit: ${_formatCurrency(journal.credit ?? 0).padRight(36)}║');
    print('║   Type: ${journal.transactionTypeDisplay.padRight(38)}║');
    print('╚═══════════════════════════════════════════════╝');
    print('');
  }
}

// Example 5: Group by branch
Future<void> example5GroupByBranch() async {
  print('\n🏢 Example 5: Group by Branch');
  print('─' * 50);

  final response = await JournalService.getAllJournals(limit: 100);
  final journals = response.journals ?? [];

  // Group by branch
  final branchGroups = <String, List<Journal>>{};

  for (final journal in journals) {
    final branchKey = journal.branchSync ?? 'unknown';
    if (!branchGroups.containsKey(branchKey)) {
      branchGroups[branchKey] = [];
    }
    branchGroups[branchKey]!.add(journal);
  }

  print('Branch Summary:');
  branchGroups.forEach((branchSync, journals) {
    final branchName = journals.first.branchName ?? 'Unknown';
    final totalDebit = journals.fold(0.0, (sum, j) => sum + (j.debit ?? 0));
    final totalCredit = journals.fold(0.0, (sum, j) => sum + (j.credit ?? 0));

    print('');
    print('Branch: $branchSync - $branchName');
    print('  Entries: ${journals.length}');
    print('  Total Debit: ${_formatCurrency(totalDebit)}');
    print('  Total Credit: ${_formatCurrency(totalCredit)}');
    print('  Net: ${_formatCurrency(totalDebit - totalCredit)}');
  });
}

// Helper function to format currency
String _formatCurrency(double amount) {
  if (amount >= 1000000) {
    return '฿${(amount / 1000000).toStringAsFixed(2)}M';
  } else if (amount >= 1000) {
    return '฿${(amount / 1000).toStringAsFixed(2)}K';
  }
  return '฿${amount.toStringAsFixed(2)}';
}

// Example 6: Fetch GL Journals (Filter Task => GL Journal)
Future<void> example6FetchGLJournals() async {
  print('\n📝 Example 6: Fetch GL Journals (Filter Task => GL Journal)');
  print('─' * 50);

  try {
    // Fetch GL Journals from API with the task query filter
    final response = await JournalService.getAllGLJournals(
      limit: 5,
      task: 'GL Journal',
    );

    final journals = response.journals ?? [];
    print('Found ${journals.length} GL Journals with Task=GL Journal\n');

    for (final journal in journals) {
      print('GL Journal #${journal.id ?? '-'}');
      print('  Doc No: ${journal.docNo} (${journal.displayDate})');
      print('  Shop ID: ${journal.branchSync}');
      print('  Account: ${journal.accountCode} - ${journal.accountName}');
      print('  Amount: ${journal.displayAmount}');
      print('');
    }
  } catch (e) {
    print('Error fetching GL Journals: $e');
  }
}
