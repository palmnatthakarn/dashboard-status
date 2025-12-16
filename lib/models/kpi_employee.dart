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
  final int cancelledDocuments; // เอกสารที่ยกเลิก

  // Detailed status breakdown
  final int waitingKey; // เอกสารที่รอคีย์ข้อมูล
  final int waitingVerify; // เอกสารที่คีย์เสร็จแล้ว แต่รอการตรวจสอบ
  final int waitingFix; // เอกสารที่ถูกส่งกลับมาให้แก้ไข

  final String status; // 'assigned', 'pending', 'completed'

  // New Filter Fields
  final String? taxId;
  final DateTime? previousDate;
  final DateTime? statusCheckDate;

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
    this.cancelledDocuments = 0,
    this.waitingKey = 0,
    this.waitingVerify = 0,
    this.waitingFix = 0,
    required this.status,
    this.taxId,
    this.previousDate,
    this.statusCheckDate,
    this.companyDetails = const [],
  });

  double get completionRate =>
      totalDocuments > 0 ? (completedDocuments / totalDocuments) * 100 : 0;

  String get documentStartDateFormatted => _formatDate(documentStartDate);
  String get documentEndDateFormatted => _formatDate(documentEndDate);
  String get dueDateFormatted => _formatDate(dueDate);
  String get submittedDateFormatted =>
      submittedDate != null ? _formatDate(submittedDate!) : 'ทำงาน';

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
  final int assigned;
  final int pending;
  final int waitingKey;
  final int waitingVerify;
  final int waitingFix; // Added
  final int completed;
  final int cancelled;
  final String status;

  KpiCompanyDetail({
    required this.company,
    required this.employee,
    required this.recordingDate,
    required this.assigned,
    required this.pending,
    required this.waitingKey,
    required this.waitingVerify,
    required this.waitingFix,
    required this.completed,
    required this.cancelled,
    required this.status,
  });
}
