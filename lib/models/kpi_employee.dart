class KpiEmployee {
  final String id;
  final String name;
  final String branch;
  final DateTime documentStartDate; // วันที่เริ่มต้นเอกสาร
  final DateTime documentEndDate; // วันที่สิ้นสุดเอกสาร
  final DateTime dueDate; // ถึงวันที่
  final DateTime? submittedDate; // คำเปิดผู้ส่งยกมา
  final int totalDocuments;
  final int assignedDocuments;
  final int pendingDocuments;
  final int completedDocuments;
  final int passedDocuments; // เอกสารที่ผ่านการตรวจสอบ (Status 1)
  final int remainingDocuments; // เอกสารคงเหลือ (Status 0)
  final int cancelledDocuments; // เอกสารที่ยกเลิก

  // Detailed status breakdown
  final int waitingKey; // เอกสารที่รอคีย์ข้อมูล
  final int waitingVerify; // เอกสารที่คีย์เสร็จแล้ว แต่รอการตรวจสอบ
  final int waitingFix; // เอกสารที่ถูกส่งกลับมาให้แก้ไข
  final int referenceBalance; // ยอดอ้างอิง
  final int referenceCount; // ยอดบันทึก

  // Delay tracking
  final String delayStep; // 'อัปโหลด', 'ตรวจสอบ', 'บันทึก', 'none'
  final int delayDays; // จำนวนวันที่ค้าง

  // Incentive status
  final bool incentivePassed; // ผ่านเกณฑ์อินเซ็นทีฟหรือไม่
  final int billsNeeded; // จำนวนบิลที่ยังขาด

  final String status; // 'assigned', 'pending', 'completed'

  // New Filter Fields
  final String? taxId;
  final DateTime? previousDate;
  final DateTime? statusCheckDate;
  final DateTime? lastActive; // Added

  // Detailed Company Data
  final List<KpiCompanyDetail> companyDetails;

  KpiEmployee({
    required this.id,
    required this.name,
    required this.branch,
    required this.documentStartDate,
    required this.documentEndDate,
    required this.dueDate,
    this.submittedDate,
    required this.totalDocuments,
    required this.assignedDocuments,
    required this.pendingDocuments,
    required this.completedDocuments,
    this.passedDocuments = 0,
    this.remainingDocuments = 0,
    this.cancelledDocuments = 0,
    this.waitingKey = 0,
    this.waitingVerify = 0,
    this.waitingFix = 0,
    this.referenceBalance = 0,
    this.referenceCount = 0,
    this.delayStep = 'none',
    this.delayDays = 0,
    this.incentivePassed = false,
    this.billsNeeded = 0,
    required this.status,
    this.taxId,
    this.previousDate,
    this.statusCheckDate,
    this.lastActive,
    this.companyDetails = const [],
  });

  double get completionRate {
    if (companyDetails.isEmpty) return 0.0;
    double totalPercent = 0.0;
    for (var detail in companyDetails) {
      totalPercent += detail.progress;
    }
    return totalPercent / companyDetails.length;
  }

  String get documentStartDateFormatted => _formatDate(documentStartDate);
  String get documentEndDateFormatted => _formatDate(documentEndDate);
  String get dueDateFormatted => _formatDate(dueDate);
  String get submittedDateFormatted =>
      submittedDate != null ? _formatDate(submittedDate!) : 'ทำงาน';

  String get lastActiveFormatted {
    if (lastActive == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(lastActive!);
    final timeStr = _formatTime(lastActive!);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่ ($timeStr)';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว ($timeStr)';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว ($timeStr)';
    return '${_formatDate(lastActive!)} $timeStr';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getThaiMonth(date.month)} ${date.year + 543}';
  }

  String _getThaiMonth(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return months[month - 1];
  }
}

class KpiCompanyDetail {
  final String company;
  final String employee; // Team member / Contact
  final DateTime recordingDate;
  final int totalBillCount; // มอบหมายคีย์อิน - total documents assigned
  final int assigned;
  final int pending;
  final int waitingKey;
  final int waitingVerify;
  final int waitingFix; // Added
  final int completed;
  final int passed; // Status 1
  final int remaining; // Status 0
  final int cancelled;
  final int referenceCount; // Added
  final String status;
  final DateTime? lastActive; // Added
  final String delayStep; // Added
  final int delayDays; // Added
  final String? shopName; // Added for multi-shop view

  KpiCompanyDetail({
    required this.company,
    required this.employee,
    required this.recordingDate,
    this.totalBillCount = 0,
    required this.assigned,
    required this.pending,
    required this.waitingKey,
    required this.waitingVerify,
    required this.waitingFix,
    required this.completed,
    this.passed = 0,
    this.remaining = 0,
    required this.cancelled,
    this.referenceCount = 0,
    required this.status,
    this.lastActive,
    this.delayStep = 'none',
    this.delayDays = 0,
    this.shopName,
  });

  String get lastActiveFormatted {
    if (lastActive == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(lastActive!);
    final timeStr = _formatTime(lastActive!);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่ ($timeStr)';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว ($timeStr)';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว ($timeStr)';
    return '${_formatDate(lastActive!)} $timeStr';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getThaiMonth(date.month)} ${date.year + 543}';
  }

  String _getThaiMonth(int month) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return months[month - 1];
  }

  /// Calculate progress percentage
  /// If status is 4 (Completed), return 100%
  /// Otherwise, return (referenceCount / totalBillCount) * 100
  double get progress {
    if (status == '4') return 100.0;
    if (totalBillCount == 0) return 0.0;
    return (referenceCount / totalBillCount) * 100.0;
  }
}
