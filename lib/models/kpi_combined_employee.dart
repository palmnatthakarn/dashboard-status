/// One actual GL journal row linked to a [KpiCombinedTaskItem] — the
/// drill-down level below task, so a viewer can see the real journal
/// entries (not just a count) behind a task's "คีย์แล้ว" figures.
class KpiCombinedJournalItem {
  final String docNo;
  final String accountName;
  final double debit;
  final double credit;
  final DateTime? docDate;

  // When this entry was actually keyed (createdat), as opposed to [docDate]
  // (the document's own dated period, e.g. an invoice's printed date). The
  // date-range filter includes/excludes an entry based on THIS timestamp
  // (see KpiCombinedBloc._isWithinRange / journalInRange), so it's what
  // must be shown on screen next to the entry — showing docDate instead
  // was confusing users into thinking the date filter was broken, since an
  // entry keyed inside the selected range can have a docDate from a
  // completely different month.
  final DateTime? keyedAt;
  final String createdBy;
  final String checkedBy;
  final String updatedBy;

  // Raw jobguidfixed from the GL journal row, kept around purely so an
  // orphan entry (see KpiCombinedShopStat.orphanJournalEntries) can show
  // the actual value on screen — comparing it against a task's own
  // guidfixed used to require digging through DevTools/terminal logs,
  // which turned out to be unreliable to reach depending on how the app
  // was launched (`-d web-server` needs the Dart Debug Chrome extension;
  // `-d chrome` can fail to attach with a stale/locked debug profile).
  // Surfacing it directly in the UI sidesteps all of that.
  final String? jobGuidfixed;

  // documentRef (raw `documentref`) — a SEPARATE reference field from
  // jobguidfixed, not a task link. KpiJournalBloc (the original, pre-merge
  // page) already treats these as distinct: jobguidfixed non-empty →
  // linked to a real task; jobguidfixed empty but documentRef non-empty →
  // labelled "(Manual)", explicitly NOT a task name lookup. Shown here
  // alongside jobGuidfixed for the same on-screen debugging reason.
  final String? documentRef;

  // Diagnostic-only, populated exclusively for entries added to
  // KpiCombinedShopStat.orphanJournalEntries. resolvedTaskGuid is whatever
  // KpiCombinedBloc's resolveTaskGuid() came up with (jobguidfixed, or the
  // docNo→taskGuid photo-link fallback) — null if NEITHER path produced
  // anything. resolvedTaskGuidFound is whether that guid actually matched
  // a task in the /task data that was fetched. Together they tell the
  // difference between "no link exists at all" and "a link was found but
  // the task it points to isn't in what /task returned" — the UI couldn't
  // otherwise distinguish those two very different situations.
  final String? resolvedTaskGuid;
  final bool resolvedTaskGuidFound;

  // How many entries were in the docNo->taskGuid map (built from
  // /documentimagegroup) at the time this journal was resolved — the
  // single most useful number for telling apart "the whole fetch failed /
  // came back empty" (0) from "the fetch worked but doesn't contain THIS
  // docNo" (some positive number, but resolvedTaskGuid is still null).
  final int docNoMapSize;

  // How many raw /documentimagegroup items the pagination loop actually
  // paged through, vs. what the API's own pagination metadata (`total`)
  // says exists. If these two numbers are far apart, the map is genuinely
  // incomplete — the docNo we're looking for may simply not have been
  // reached yet — as opposed to "we fetched everything and this docNo
  // truly has no group behind it". Surfaced on-screen because
  // console/DevTools access has proven unreliable to reach in this
  // environment throughout this investigation.
  final int docNoMapTotalItemsSeen;
  final int? docNoMapApiReportedTotal;

  const KpiCombinedJournalItem({
    required this.docNo,
    required this.accountName,
    required this.debit,
    required this.credit,
    required this.docDate,
    this.keyedAt,
    required this.createdBy,
    required this.checkedBy,
    required this.updatedBy,
    this.jobGuidfixed,
    this.documentRef,
    this.resolvedTaskGuid,
    this.resolvedTaskGuidFound = false,
    this.docNoMapSize = 0,
    this.docNoMapTotalItemsSeen = 0,
    this.docNoMapApiReportedTotal,
  });
}

/// One underlying task attributed to an employee within a specific shop —
/// the drill-down level below [KpiCombinedShopStat]. Lets a viewer answer
/// "which actual documents make up this number" instead of trusting an
/// aggregate. An employee can appear on a task either as the owner (the
/// person the task/document group was assigned to) or as a contributor
/// (someone else keyed part of the owner's documents into the journal) —
/// [isOwner] / [keyedByThisEmployee] distinguish the two.
///
/// [journalEntries] is the actual GL journal rows tied to this task (via
/// jobguidfixed) — for the owner row this is every entry linked to the
/// task; for a contributor row it's scoped down to just the entries THAT
/// employee created, since contributor rows represent "keyed part of
/// someone else's task".
class KpiCombinedTaskItem {
  final String taskName;
  final String taskCode;
  final int status;
  final int totalDocument;
  final DateTime ownerAt;
  final String ownerBy;
  final bool isOwner;
  final int keyedByThisEmployee; // only meaningful when isOwner == false
  final List<KpiCombinedJournalItem> journalEntries;

  // ── สถานะการตรวจสอบ / สถานะการบันทึกบัญชี (task workflow breakdown) ──
  // Same figures KpiCombinedBloc already computes per task to roll up into
  // the shop/employee totals — kept here too so the task drill-down row can
  // show its own status columns instead of leaving them blank. Every field
  // except [recorded] describes the task itself, so it's identical whether
  // this is the owner row or a contributor row for the same task (the same
  // way [totalDocument] already is). [recorded] is the one figure that
  // legitimately differs per row — it's "how much THIS row's person
  // recorded", not the task's total.
  final int waitingVerify;
  final int passed;
  final int cancelled;
  final int notRecorded;
  final int notRequiredApproval;
  final int requiredToRecord;
  final int recorded;
  final int remaining;
  final int completed;

  const KpiCombinedTaskItem({
    required this.taskName,
    required this.taskCode,
    required this.status,
    required this.totalDocument,
    required this.ownerAt,
    required this.ownerBy,
    required this.isOwner,
    this.keyedByThisEmployee = 0,
    this.journalEntries = const [],
    this.waitingVerify = 0,
    this.passed = 0,
    this.cancelled = 0,
    this.notRecorded = 0,
    this.notRequiredApproval = 0,
    this.requiredToRecord = 0,
    this.recorded = 0,
    this.remaining = 0,
    this.completed = 0,
  });
}

/// Per-shop breakdown for a [KpiCombinedEmployee] — unlike KpiEmployee's
/// `companyDetails` (which is one row per TASK, with shop name attached),
/// these numbers are genuinely SUMMED per shop, matching how KPI Journal's
/// `shopStats` already works. Built by aggregating the underlying
/// task/journal rows in KpiCombinedBloc.
class KpiCombinedShopStat {
  final String shopName;

  // ── เอกสาร (task workflow status) ──
  final int totalDocuments;
  final int waitingVerify;
  final int passed;
  final int cancelled;
  final int notRecorded;
  final int notRequiredApproval;
  final int requiredToRecord; // ต้องบันทึก (คำนวณจากสถานะ task)
  final int recorded; // บันทึกแล้ว (จาก GL journal, cross-referenced)
  final int remaining;
  final int completed;

  // ── บันทึกบัญชี (actual GL journal entries keyed) ──
  final int
  journalRequiredDocs; // ต้องบันทึก (จากจำนวนกลุ่มรูปภาพ — คนละที่มากับด้านบน)
  final int journalCount; // คีย์
  // "คีย์" entries keyed with NO evidence behind them at all — no
  // jobguidfixed AND no documentimagegroup photo reference for the docNo.
  // Split out of [journalCount] (2026-07) so a fully untraceable manual
  // entry doesn't get counted the same as one that at least has a photo
  // backing it (just an unresolved task) — those stay in [journalCount].
  final int journalCountNoPhoto; // คีย์ (ไม่มีรูป)
  final int journalChecked; // ตรวจสอบ
  final int journalUpdated; // แก้ไข

  // คีย์รวม — journalCount + journalCountNoPhoto combined, so a viewer
  // doesn't have to add the two "คีย์" columns themselves to see total
  // keying activity regardless of photo backing. Pure derivation, not
  // stored/accumulated separately (2026-07).
  int get journalCountTotal => journalCount + journalCountNoPhoto;

  // คงเหลือ (บันทึกบัญชี) — journalRequiredDocs minus journalCount
  // (deliberately NOT journalCountTotal: a no-photo entry has no photo
  // document behind it, so it doesn't fulfill any of the
  // journalRequiredDocs photo-document requirement — only entries with
  // real evidence, i.e. [journalCount], count against it). Clamped at 0,
  // matching [remaining]'s (task-side) same clamp-at-0 convention right
  // above.
  int get journalRemaining => (journalRequiredDocs - journalCount) > 0
      ? journalRequiredDocs - journalCount
      : 0;

  // The actual tasks behind the numbers above, for drill-down display.
  final List<KpiCombinedTaskItem> tasks;

  // GL journal rows that count toward journalCount/journalChecked/
  // journalUpdated above but whose jobguidfixed doesn't resolve to any task
  // in [tasks] (task deleted, mismatched guid, or the shop simply has no
  // task workflow at all) — the "คีย์ที่ไม่มีงานให้ดูรายละเอียด" case. Kept
  // separate from [tasks] so the UI can still offer a drill-down for a shop
  // whose only GL activity is these, instead of showing a non-zero count
  // with no way to see what's behind it.
  final List<KpiCombinedJournalItem> orphanJournalEntries;

  const KpiCombinedShopStat({
    required this.shopName,
    this.totalDocuments = 0,
    this.waitingVerify = 0,
    this.passed = 0,
    this.cancelled = 0,
    this.notRecorded = 0,
    this.notRequiredApproval = 0,
    this.requiredToRecord = 0,
    this.recorded = 0,
    this.remaining = 0,
    this.completed = 0,
    this.journalRequiredDocs = 0,
    this.journalCount = 0,
    this.journalCountNoPhoto = 0,
    this.journalChecked = 0,
    this.journalUpdated = 0,
    this.tasks = const [],
    this.orphanJournalEntries = const [],
  });

  KpiCombinedShopStat copyWith({
    String? shopName,
    int? totalDocuments,
    int? waitingVerify,
    int? passed,
    int? cancelled,
    int? notRecorded,
    int? notRequiredApproval,
    int? requiredToRecord,
    int? recorded,
    int? remaining,
    int? completed,
    int? journalRequiredDocs,
    int? journalCount,
    int? journalCountNoPhoto,
    int? journalChecked,
    int? journalUpdated,
    List<KpiCombinedTaskItem>? tasks,
    List<KpiCombinedJournalItem>? orphanJournalEntries,
  }) {
    return KpiCombinedShopStat(
      shopName: shopName ?? this.shopName,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      waitingVerify: waitingVerify ?? this.waitingVerify,
      passed: passed ?? this.passed,
      cancelled: cancelled ?? this.cancelled,
      notRecorded: notRecorded ?? this.notRecorded,
      notRequiredApproval: notRequiredApproval ?? this.notRequiredApproval,
      requiredToRecord: requiredToRecord ?? this.requiredToRecord,
      recorded: recorded ?? this.recorded,
      remaining: remaining ?? this.remaining,
      completed: completed ?? this.completed,
      journalRequiredDocs: journalRequiredDocs ?? this.journalRequiredDocs,
      journalCount: journalCount ?? this.journalCount,
      journalCountNoPhoto: journalCountNoPhoto ?? this.journalCountNoPhoto,
      journalChecked: journalChecked ?? this.journalChecked,
      journalUpdated: journalUpdated ?? this.journalUpdated,
      tasks: tasks ?? this.tasks,
      orphanJournalEntries: orphanJournalEntries ?? this.orphanJournalEntries,
    );
  }
}

/// One employee row in the merged KPI page — combines KpiEmployee's
/// document-workflow stats (from /task, via KpiBloc's logic) with
/// KpiJournalEmployee's journal-keying stats (from /gl/journal, via
/// KpiJournalBloc's logic). An employee can appear here even if they only
/// have data on one side (e.g. assigned documents but hasn't keyed any
/// journal entries yet, or vice versa) — the other side's numbers are 0.
///
/// NOTE: `requiredToRecordDocuments` (เอกสาร) and `journalRequiredDocs`
/// (บันทึกบัญชี) are BOTH labelled "ต้องบันทึก" in the UI but come from two
/// different sources (task status vs. document-image-group count) and are
/// not guaranteed to match — kept as separate fields/columns deliberately,
/// never summed together.
class KpiCombinedEmployee {
  final String name;
  final DateTime? lastActive;

  // ── เอกสาร (task workflow) totals ──
  final int totalDocuments;
  final int waitingVerify;
  final int passedDocuments;
  final int cancelledDocuments;
  final int notRecordedDocuments;
  final int notRequiredApprovalDocuments;
  final int requiredToRecordDocuments;
  final int recordedDocuments;
  final int remainingDocuments;
  final int completedDocuments;

  // ── บันทึกบัญชี (GL journal keying) totals ──
  final int journalRequiredDocs;
  final int totalJournals;
  final int
  totalJournalsNoPhoto; // คีย์ (ไม่มีรูป) — see KpiCombinedShopStat.journalCountNoPhoto
  final int totalChecked;
  final int totalUpdated;

  // Same pure derivations as KpiCombinedShopStat's journalCountTotal /
  // journalRemaining, just at the already-summed employee level.
  int get totalJournalsCombined => totalJournals + totalJournalsNoPhoto;
  int get journalRemaining => (journalRequiredDocs - totalJournals) > 0
      ? journalRequiredDocs - totalJournals
      : 0;

  final List<KpiCombinedShopStat> shopStats;

  const KpiCombinedEmployee({
    required this.name,
    this.lastActive,
    this.totalDocuments = 0,
    this.waitingVerify = 0,
    this.passedDocuments = 0,
    this.cancelledDocuments = 0,
    this.notRecordedDocuments = 0,
    this.notRequiredApprovalDocuments = 0,
    this.requiredToRecordDocuments = 0,
    this.recordedDocuments = 0,
    this.remainingDocuments = 0,
    this.completedDocuments = 0,
    this.journalRequiredDocs = 0,
    this.totalJournals = 0,
    this.totalJournalsNoPhoto = 0,
    this.totalChecked = 0,
    this.totalUpdated = 0,
    this.shopStats = const [],
  });

  KpiCombinedEmployee copyWith({
    String? name,
    DateTime? lastActive,
    int? totalDocuments,
    int? waitingVerify,
    int? passedDocuments,
    int? cancelledDocuments,
    int? notRecordedDocuments,
    int? notRequiredApprovalDocuments,
    int? requiredToRecordDocuments,
    int? recordedDocuments,
    int? remainingDocuments,
    int? completedDocuments,
    int? journalRequiredDocs,
    int? totalJournals,
    int? totalJournalsNoPhoto,
    int? totalChecked,
    int? totalUpdated,
    List<KpiCombinedShopStat>? shopStats,
  }) {
    return KpiCombinedEmployee(
      name: name ?? this.name,
      lastActive: lastActive ?? this.lastActive,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      waitingVerify: waitingVerify ?? this.waitingVerify,
      passedDocuments: passedDocuments ?? this.passedDocuments,
      cancelledDocuments: cancelledDocuments ?? this.cancelledDocuments,
      notRecordedDocuments: notRecordedDocuments ?? this.notRecordedDocuments,
      notRequiredApprovalDocuments:
          notRequiredApprovalDocuments ?? this.notRequiredApprovalDocuments,
      requiredToRecordDocuments:
          requiredToRecordDocuments ?? this.requiredToRecordDocuments,
      recordedDocuments: recordedDocuments ?? this.recordedDocuments,
      remainingDocuments: remainingDocuments ?? this.remainingDocuments,
      completedDocuments: completedDocuments ?? this.completedDocuments,
      journalRequiredDocs: journalRequiredDocs ?? this.journalRequiredDocs,
      totalJournals: totalJournals ?? this.totalJournals,
      totalJournalsNoPhoto: totalJournalsNoPhoto ?? this.totalJournalsNoPhoto,
      totalChecked: totalChecked ?? this.totalChecked,
      totalUpdated: totalUpdated ?? this.totalUpdated,
      shopStats: shopStats ?? this.shopStats,
    );
  }
}

/// Shop dropdown item shared by the merged page's filter bar.
class KpiCombinedShopItem {
  final String shopId;
  final String shopName;

  const KpiCombinedShopItem({required this.shopId, required this.shopName});
}
