import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard_bloc_exports.dart';

class ShopImageFilesDialog extends StatefulWidget {
  final dynamic shop;

  const ShopImageFilesDialog({super.key, required this.shop});

  @override
  State<ShopImageFilesDialog> createState() => _ShopImageFilesDialogState();
}

class _ShopImageFilesDialogState extends State<ShopImageFilesDialog> {
  // เส้นทางปัจจุบัน (null = หน้า root โฟลเดอร์ category)
  String? currentCategory;
  String? currentSubcategory;

  @override
  void initState() {
    super.initState();
    // อัปเดต total image count เมื่อเปิด dialog
    final shopId = widget.shop?.shopid ?? '';
    final totalImages = _images.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageApprovalBloc>().add(
        UpdateTotalImageCount(shopId: shopId, count: totalImages),
      );
    });
  }

  List<dynamic> get _images {
    final imgs = widget.shop?.dailyImages;
    if (imgs == null) return const [];
    if (imgs is List) return imgs;
    return const [];
  }

  // จัดกลุ่มรูปเป็น Map<category, List<image>>
  Map<String, List<dynamic>> get _byCategory {
    final map = <String, List<dynamic>>{};
    for (final img in _images) {
      final cat = (img.category ?? 'ไม่ระบุหมวดหมู่').toString();
      map.putIfAbsent(cat, () => []);
      map[cat]!.add(img);
    }
    return map;
  }

  // เมื่ออยู่ใน category แล้ว จัดกลุ่มเป็น subcategory
  Map<String, List<dynamic>> get _bySubcategoryInCurrent {
    final map = <String, List<dynamic>>{};
    if (currentCategory == null) return map;
    final imagesInCat = _byCategory[currentCategory] ?? [];
    for (final img in imagesInCat) {
      final sub = (img.subcategory ?? 'ไม่ระบุหมวดหมู่ย่อย').toString();
      map.putIfAbsent(sub, () => []);
      map[sub]!.add(img);
    }
    return map;
  }

  // รูปที่จะแสดงในโฟลเดอร์สุดท้าย (เมื่อเลือกทั้ง category + subcategory)
  List<dynamic> get _imagesInLeafFolder {
    if (currentCategory == null) return const [];
    if (currentSubcategory == null) {
      // ถ้ายังไม่เลือก subcategory ให้ไม่แสดงรูป (รอเลือก subfolder ก่อน)
      return const [];
    }
    return _bySubcategoryInCurrent[currentSubcategory] ?? const [];
  }

  bool get _isRoot => currentCategory == null;
  bool get _isCategoryOnly =>
      currentCategory != null && currentSubcategory == null;
  bool get _isLeaf => currentCategory != null && currentSubcategory != null;

  void _goBack() {
    if (_isLeaf) {
      setState(() => currentSubcategory = null);
    } else if (_isCategoryOnly) {
      setState(() => currentCategory = null);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = widget.shop?.imageCount ?? _images.length;
    final shopName = widget.shop?.shopname ?? '-';
    final titleColor = const Color(0xFF0F172A);
    final badgeColor = const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder_open, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(
                  children: [
                    Text(
                      'ไฟล์ที่อัปโหลด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (currentCategory != null) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'หมวด: ${currentCategory!}',
                        style: TextStyle(fontSize: 14, color: badgeColor),
                      ),
                    ],
                    if (currentSubcategory != null) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ย่อย: ${currentSubcategory!}',
                        style: TextStyle(fontSize: 14, color: badgeColor),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$shopName ($total ไฟล์)',
                  style: TextStyle(fontSize: 13, color: badgeColor),
                ),
              ],
            ),
          ),
          // ปุ่มอนุมัติทั้งหมด
          BlocBuilder<ImageApprovalBloc, ImageApprovalState>(
            builder: (context, approvalState) {
              final shopId = widget.shop?.shopid ?? '';
              final totalImages = _images.length;
              final approvedCount = approvalState.getApprovedCount(shopId);
              final isAllApproved = approvedCount >= totalImages;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: totalImages > 0 && !isAllApproved
                      ? () {
                          context.read<ImageApprovalBloc>().add(
                            ApproveAllImages(shopId: shopId),
                          );
                        }
                      : null,
                  icon: Icon(
                    isAllApproved ? Icons.check_circle : Icons.approval,
                    size: 16,
                  ),
                  label: Text(
                    isAllApproved ? 'ตรวจสอบแล้ว' : 'อนุมัติทั้งหมด',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllApproved
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _goBack,
            tooltip: 'ย้อนกลับ',
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'ปิด',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_images.isEmpty) {
      return const _EmptyState();
    }

    if (_isRoot) {
      // โฟลเดอร์ Category
      final folders = _byCategory.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      return _FolderGrid(
        items: folders
            .map(
              (e) => FolderItem(
                title: e.key,
                count: e.value.length,
                onTap: () => setState(() {
                  currentCategory = e.key;
                  currentSubcategory = null;
                }),
              ),
            )
            .toList(),
        headline: 'หมวดหมู่ทั้งหมด',
      );
    }

    if (_isCategoryOnly) {
      // โฟลเดอร์ย่อย Subcategory
      final subfolders = _bySubcategoryInCurrent.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
      return _FolderGrid(
        items: subfolders
            .map(
              (e) => FolderItem(
                title: e.key,
                count: e.value.length,
                onTap: () => setState(() {
                  currentSubcategory = e.key;
                }),
              ),
            )
            .toList(),
        headline: 'หมวดหมู่ย่อยใน "${currentCategory!}"',
      );
    }

    // Leaf: แสดงรูปในโฟลเดอร์ย่อย
    final images = _imagesInLeafFolder;
    if (images.isEmpty) {
      return const _EmptyState(text: 'โฟลเดอร์นี้ยังไม่มีรูปภาพ');
    }
    return _ImageGrid(
      images: images,
      onTap: (img) => _showImagePreview(context, img),
      shopId: widget.shop?.shopid ?? '',
    );
  }

  void _showImagePreview(BuildContext context, dynamic image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        image?.category?.toString() ?? 'ไม่ระบุหมวดหมู่',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child:
                      (image?.imageUrl != null &&
                          (image.imageUrl as String).isNotEmpty)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              image.imageUrl as String,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _PreviewError(url: image.imageUrl);
                              },
                            ),
                          ),
                        )
                      : const _PreviewError(url: 'ไม่พบ URL รูปภาพ'),
                ),
              ),
              // Footer
              if (image?.subcategory != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    image.subcategory.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- UI helpers ----------------

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({this.text = 'ไม่พบไฟล์ที่อัปโหลด'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderItem {
  final String title;
  final int count;
  final VoidCallback onTap;

  FolderItem({required this.title, required this.count, required this.onTap});
}

class _FolderGrid extends StatelessWidget {
  final List<FolderItem> items;
  final String headline;

  const _FolderGrid({required this.items, required this.headline});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(text: 'ไม่มีโฟลเดอร์');
    }
    final cross = MediaQuery.of(context).size.width > 720 ? 4 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (context, i) {
              final f = items[i];
              return InkWell(
                onTap: f.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 44,
                      child: const Icon(
                        Icons.folder,
                        color: Color(0xFF3B82F6),
                        size: 60,
                      ),
                    ),
                    const SizedBox(width: 0),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              f.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          //const SizedBox(height: 2),
                          //Text('$f.count ไฟล์', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    // const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<dynamic> images;
  final void Function(dynamic img) onTap;
  final String shopId; // เพิ่ม shopId เป็น parameter

  const _ImageGrid({
    required this.images,
    required this.onTap,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    final cross = MediaQuery.of(context).size.width > 720 ? 5 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รูปภาพ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            itemCount: images.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              final img = images[i];
              final url = (img?.imageUrl ?? '').toString();
              final code = (img?.imageid ?? 'ไม่ระบุรหัสรูปภาพ').toString();

              return BlocBuilder<ImageApprovalBloc, ImageApprovalState>(
                builder: (context, approvalState) {
                  final imageId = i.toString(); // ใช้ index เป็น imageId
                  final isApproved = approvalState.isImageApproved(
                    shopId,
                    imageId,
                  );

                  return InkWell(
                    onTap: () => onTap(img),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFFF0FDF4)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isApproved
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                          width: isApproved ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  child: url.isNotEmpty
                                      ? Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Color(0xFF9CA3AF),
                                                  size: 32,
                                                ),
                                              ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: Color(0xFF9CA3AF),
                                            size: 32,
                                          ),
                                        ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        code,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    // ปุ่มอนุมัติแต่ละรูป
                                    InkWell(
                                      onTap: () {
                                        if (!isApproved) {
                                          context.read<ImageApprovalBloc>().add(
                                            ApproveImage(
                                              shopId: shopId,
                                              imageId: imageId,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isApproved
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          isApproved ? Icons.check : Icons.add,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // แสดงเครื่องหมายอนุมัติที่มุมบนขว้า
                          if (isApproved)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PreviewError extends StatelessWidget {
  final String url;
  const _PreviewError({required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 64),
          const SizedBox(height: 12),
          const Text(
            'ไม่สามารถโหลดรูปภาพได้',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'URL: $url',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
