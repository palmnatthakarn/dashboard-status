abstract class ImageApprovalEvent {}

class ApproveImage extends ImageApprovalEvent {
  final String shopId;
  final String imageId;

  ApproveImage({required this.shopId, required this.imageId});
}

class ApproveAllImages extends ImageApprovalEvent {
  final String shopId;

  ApproveAllImages({required this.shopId});
}

class ResetApprovalStatus extends ImageApprovalEvent {
  final String shopId;

  ResetApprovalStatus({required this.shopId});
}

class UpdateTotalImageCount extends ImageApprovalEvent {
  final String shopId;
  final int count;

  UpdateTotalImageCount({required this.shopId, required this.count});
}
