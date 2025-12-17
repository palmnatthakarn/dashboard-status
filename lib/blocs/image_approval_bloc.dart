import 'package:flutter_bloc/flutter_bloc.dart';
import 'image_approval_event.dart';
import 'image_approval_state.dart';

class ImageApprovalBloc extends Bloc<ImageApprovalEvent, ImageApprovalState> {
  ImageApprovalBloc() : super(const ImageApprovalState()) {
    on<ApproveImage>(_onApproveImage);
    on<ApproveAllImages>(_onApproveAllImages);
    on<ResetApprovalStatus>(_onResetApprovalStatus);
    on<UpdateTotalImageCount>(_onUpdateTotalImageCount);
  }

  void _onApproveImage(ApproveImage event, Emitter<ImageApprovalState> emit) {
    final currentApproved = Map<String, Set<String>>.from(state.approvedImages);
    
    // สร้าง Set ใหม่หากยังไม่มี
    if (!currentApproved.containsKey(event.shopId)) {
      currentApproved[event.shopId] = <String>{};
    }
    
    // เพิ่มรูปที่อนุมัติ
    currentApproved[event.shopId]!.add(event.imageId);
    
    emit(state.copyWith(approvedImages: currentApproved));
  }

  void _onApproveAllImages(ApproveAllImages event, Emitter<ImageApprovalState> emit) {
    final currentApproved = Map<String, Set<String>>.from(state.approvedImages);
    final totalCount = state.getTotalCount(event.shopId);
    
    // สร้าง Set ของรูปทั้งหมด (ใช้ index เป็น imageId)
    final allImageIds = <String>{};
    for (int i = 0; i < totalCount; i++) {
      allImageIds.add(i.toString());
    }
    
    currentApproved[event.shopId] = allImageIds;
    
    emit(state.copyWith(approvedImages: currentApproved));
  }

  void _onResetApprovalStatus(ResetApprovalStatus event, Emitter<ImageApprovalState> emit) {
    final currentApproved = Map<String, Set<String>>.from(state.approvedImages);
    currentApproved.remove(event.shopId);
    
    emit(state.copyWith(approvedImages: currentApproved));
  }

  void _onUpdateTotalImageCount(UpdateTotalImageCount event, Emitter<ImageApprovalState> emit) {
    final currentTotals = Map<String, int>.from(state.totalImageCounts);
    currentTotals[event.shopId] = event.count;
    
    emit(state.copyWith(totalImageCounts: currentTotals));
  }

  // เมธอดสำหรับอัปเดตจำนวนรูปทั้งหมดของร้าน
  void updateTotalImageCount(String shopId, int count) {
    add(UpdateTotalImageCount(shopId: shopId, count: count));
  }
}
