import 'package:flutter/material.dart';
import '../../models/doc_details.dart';
import '../../models/daily_images.dart';

class ImageGalleryDialog extends StatefulWidget {
  final String title;
  final List<DocDetails> shops;

  const ImageGalleryDialog({
    super.key,
    required this.title,
    required this.shops,
  });

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  // Map category -> List of images
  final Map<String, List<DailyImage>> _categorizedImages = {};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _processImages();
  }

  void _processImages() {
    for (final shop in widget.shops) {
      if (shop.dailyImages != null) {
        for (final img in shop.dailyImages!) {
          if (img.imageUrl?.isNotEmpty == true) {
            // Default category if null or empty
            final category = (img.category?.isNotEmpty == true)
                ? img.category!
                : 'อื่นๆ';

            _categorizedImages[category]!.add(img);
          }
        }
      }
    }

    // [MOCK] Generate 50 mock images
    final categories = [
      'บิลค่าใช้จ่าย',
      'สลิปโอนเงิน',
      'บิลค่าน้ำ',
      'บิลค่าไฟ',
      'อื่นๆ',
    ];
    for (int i = 0; i < 50; i++) {
      final category = categories[i % categories.length];
      final mockImg = DailyImage(
        imageid: 'mock_$i',
        category: category,
        subcategory: 'รายละเอียดบิลใบที่ ${i + 1}',
        description: i.toString().padLeft(2, '0'),
        uploadedAt: DateTime.now()
            .subtract(Duration(minutes: i * 10))
            .toIso8601String(),
        imageUrl: 'https://picsum.photos/seed/$i/300/400',
        shopid: 'MOCK001',
      );

      _categorizedImages.putIfAbsent(category, () => []);
      _categorizedImages[category]!.add(mockImg);
    }

    // Sort categories (optional, you might want specific order)
    if (_categorizedImages.isNotEmpty) {
      _selectedCategory = _categorizedImages.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categorizedImages.isEmpty) {
      return _buildEmptyState(context);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  // Left Sidebar: Categories
                  Container(
                    width: 250,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                    child: _buildCategoryList(),
                  ),
                  const VerticalDivider(width: 1),
                  // Right Content: Image Grid
                  Expanded(child: _buildImageGrid()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_rounded,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบบิล',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ไม่มีบิลที่อัปโหลดในรายการนี้',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getTotalImageCount()} บิลทั้งหมด',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  int _getTotalImageCount() {
    int total = 0;
    _categorizedImages.forEach((_, list) => total += list.length);
    return total;
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _categorizedImages.keys.length,
      itemBuilder: (context, index) {
        final category = _categorizedImages.keys.elementAt(index);
        final count = _categorizedImages[category]!.length;
        final isSelected = category == _selectedCategory;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedCategory = category),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: const Color(0xFFE5E7EB))
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGrid() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    final images = _categorizedImages[_selectedCategory]!;

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        return _buildImageCard(img);
      },
    );
  }

  Widget _buildImageCard(DailyImage img) {
    // Generate a unique tag based on ID or URL, combined with object hash to ensure uniqueness
    // handling potential duplicates in data or same URLs
    final String heroTag = '${img.imageid ?? img.imageUrl}_${img.hashCode}';

    return InkWell(
      onTap: () => _showImageDetail(context, img, heroTag),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    img.imageUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    img.subcategory ?? 'ไม่มีรายละเอียด',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (img.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      img.description!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(img.uploadedAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(BuildContext context, DailyImage img, String heroTag) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          img.imageUrl ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          img.subcategory ?? 'ไม่มีรายละเอียด',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (img.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            img.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'อัปโหลดเมื่อ: ${_formatDate(img.uploadedAt)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      // Assuming ISO format or similar
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (_) {
      return dateStr;
    }
  }
}
