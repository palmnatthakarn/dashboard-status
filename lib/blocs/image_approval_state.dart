class ImageApprovalState {
  // Map<shopId, Set<imageId>> เก็บรายการรูปที่อนุมัติแล้ว
  final Map<String, Set<String>> approvedImages;

  // Map<shopId, int> เก็บจำนวนรูปทั้งหมดของแต่ละร้าน
  final Map<String, int> totalImageCounts;

  const ImageApprovalState({
    this.approvedImages = const {},
    this.totalImageCounts = const {},
  });

  ImageApprovalState copyWith({
    Map<String, Set<String>>? approvedImages,
    Map<String, int>? totalImageCounts,
  }) {
    return ImageApprovalState(
      approvedImages: approvedImages ?? this.approvedImages,
      totalImageCounts: totalImageCounts ?? this.totalImageCounts,
    );
  }

  // ดึงจำนวนรูปที่อนุมัติแล้วของร้าน
  int getApprovedCount(String shopId) {
    return approvedImages[shopId]?.length ?? 0;
  }

  // ดึงจำนวนรูปทั้งหมดของร้าน
  int getTotalCount(String shopId) {
    return totalImageCounts[shopId] ?? 0;
  }

  // ตรวจสอบว่าอนุมัติหมดแล้วหรือยัง
  bool isAllApproved(String shopId) {
    final total = getTotalCount(shopId);
    final approved = getApprovedCount(shopId);
    return total > 0 && approved >= total;
  }

  // ตรวจสอบว่ารูปนี้อนุมัติแล้วหรือยัง
  bool isImageApproved(String shopId, String imageId) {
    return approvedImages[shopId]?.contains(imageId) ?? false;
  }

  // สร้าง text สำหรับแสดงสถานะ เช่น "2/5 ไฟล์"
  String getApprovalStatusText(String shopId) {
    final approved = getApprovedCount(shopId);
    final total = getTotalCount(shopId);
    return "$approved/$total ไฟล์";
  }
}
