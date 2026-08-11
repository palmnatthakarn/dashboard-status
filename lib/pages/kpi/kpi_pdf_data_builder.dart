import '../../models/kpi_combined_employee.dart';
import '../../services/pdf_export_service.dart';

/// Builds a stable KPI export snapshot independent of page expansion state.
class KpiPdfDataBuilder {
  const KpiPdfDataBuilder._();

  static List<KpiPdfGroup> buildGroups({
    required List<KpiCombinedEmployee> employees,
    required bool summaryReady,
    Map<String, String> nameMappings = const {},
  }) {
    return employees.map((employee) {
      final shopRows = employee.shopStats
          .map((shop) => _shopRow(shop, summaryReady: summaryReady))
          .toList(growable: false);
      final rows = <List<String>>[];
      final contextRowIndexes = <int>{};
      for (var index = 0; index < employee.shopStats.length; index++) {
        final shop = employee.shopStats[index];
        rows.add(shopRows[index]);
        for (final task in shop.tasks) {
          if (!task.isOwner) contextRowIndexes.add(rows.length);
          rows.add(_taskRow(task));
          rows.addAll(task.journalEntries.map(_journalRow));
        }
        rows.addAll(
          shop.orphanJournalEntries.map(
            (journal) => _journalRow(journal, orphan: true),
          ),
        );
      }
      return KpiPdfGroup(
        name: _employeeDisplayName(employee.name, nameMappings),
        summary:
            'บิลที่รับผิดชอบ ${employee.totalDocuments} · อัปโหลดโดยคนนี้ ${employee.totalUploaded} · คีย์บัญชี ${employee.totalJournalsCombined} รายการ',
        rows: rows,
        totalRows: shopRows,
        contextRowIndexes: contextRowIndexes,
        showColumnTotals: true,
      );
    }).toList(growable: false);
  }

  static String _employeeDisplayName(
    String rawName,
    Map<String, String> nameMappings,
  ) {
    final mappedName = nameMappings[rawName]?.trim();
    final trimmedRawName = rawName.trim();
    if (mappedName == null ||
        mappedName.isEmpty ||
        mappedName == trimmedRawName ||
        trimmedRawName.isEmpty) {
      return rawName;
    }
    return '$mappedName ($trimmedRawName)';
  }

  static List<String> _shopRow(
    KpiCombinedShopStat shop, {
    required bool summaryReady,
  }) => [
    shop.shopName,
    '${shop.totalDocuments}',
    '${shop.uploadedCount}',
    '${shop.waitingVerify}',
    '${shop.passed}',
    '${shop.cancelled}',
    '${shop.notRecorded}',
    '${shop.notRequiredApproval}',
    '${shop.requiredToRecord}',
    '${shop.recorded}',
    '${shop.remaining}',
    '${shop.completed}',
    '${shop.journalCount}',
    summaryReady ? '${shop.journalCountNoPhoto}' : '-',
    '${shop.journalCountTotal}',
    '${shop.journalChecked}',
    '${shop.journalUpdated}',
  ];

  static List<String> _taskRow(KpiCombinedTaskItem task) {
    final label = task.taskName.trim().isNotEmpty ? task.taskName : task.taskCode;
    final keyed = _uniqueJournalCount(
      task.journalEntries.where((journal) {
        if (journal.createdBy.isEmpty) return false;
        return !task.isOwner || journal.createdBy.trim() == task.ownerBy.trim();
      }),
    );
    return [
      '  งาน: $label',
      '${task.totalDocument}', '-', '${task.waitingVerify}', '${task.passed}',
      '${task.cancelled}', '${task.notRecorded}',
      '${task.notRequiredApproval}', '${task.requiredToRecord}',
      '${task.recorded}', '${task.remaining}', '${task.completed}', '$keyed',
      '0', '$keyed',
      '${task.journalEntries.where((j) => j.checkedBy.isNotEmpty).length}',
      '${task.journalEntries.where((j) => j.updatedBy.isNotEmpty).length}',
    ];
  }

  static int _uniqueJournalCount(Iterable<KpiCombinedJournalItem> journals) =>
      journals.map(_journalCountKey).toSet().length;

  static String _journalCountKey(KpiCombinedJournalItem journal) {
    final docNo = journal.docNo.trim();
    if (docNo.isNotEmpty) return 'doc:$docNo';
    final keyedAt = journal.keyedAt?.toIso8601String() ?? '';
    return 'row:$keyedAt|${journal.accountName}';
  }

  static List<String> _journalRow(
    KpiCombinedJournalItem journal, {
    bool orphan = false,
  }) {
    final hasDocumentRef = (journal.documentRef ?? '').trim().isNotEmpty;
    final noPhoto =
        (journal.resolvedTaskGuid == null ||
            journal.resolvedTaskGuid!.trim().isEmpty) &&
        !hasDocumentRef;
    final prefix = orphan ? '    รายการไม่ผูกงาน' : '    รายการ';
    return [
      '$prefix: ${journal.docNo} · ${journal.accountName}',
      '1', '-', ...List.generate(9, (_) => '0'),
      journal.createdBy.isNotEmpty && !noPhoto ? '1' : '0',
      journal.createdBy.isNotEmpty && noPhoto ? '1' : '0',
      journal.createdBy.isNotEmpty ? '1' : '0',
      journal.checkedBy.isNotEmpty ? '1' : '0',
      journal.updatedBy.isNotEmpty ? '1' : '0',
    ];
  }
}
