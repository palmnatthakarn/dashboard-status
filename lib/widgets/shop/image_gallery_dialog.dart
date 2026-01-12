import 'package:flutter/material.dart';
import '../../services/document_image_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ImageGalleryDialog extends StatefulWidget {
  final String title;
  final String shopId;

  const ImageGalleryDialog({
    super.key,
    required this.title,
    required this.shopId,
  });

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  // Map category -> List of images
  final Map<String, List<DocumentImage>> _categorizedImages = {};
  String? _selectedCategory;
  Offset _offset = Offset.zero; // Track drag offset
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    print('🔄 Starting _fetchImages for shopId: ${widget.shopId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _categorizedImages.clear(); // Clear previous shop's images
      _selectedCategory = null; // Reset selected category
    });

    try {
      print('📞 Calling DocumentImageService.fetchShopImages...');
      final images = await DocumentImageService.fetchShopImages(
        shopId: widget.shopId,
      );

      print('📥 Received ${images.length} images from service');

      if (!mounted) {
        print('⚠️ Widget not mounted, returning');
        return;
      }

      if (images.isEmpty) {
        print('❌ No images received, showing error');
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่พบรูปภาพ';
        });
        return;
      }

      print('✅ Processing ${images.length} images...');

      // Categorize images by file type
      for (final img in images) {
        print(
          '🖼️ Image: id=${img.imageId}, url=${img.imageUrl}, category=${img.category}',
        );

        if (img.imageUrl?.isNotEmpty == true) {
          // Determine category based on file extension
          final isPdf = img.imageUrl!.toLowerCase().endsWith('.pdf');
          final category = isPdf ? 'ไฟล์ PDF' : 'รูปภาพ (JPG/PNG)';

          _categorizedImages.putIfAbsent(category, () => []);
          _categorizedImages[category]!.add(img);
          print('  ✓ Added to category: $category');
        } else {
          print('  ✗ Skipped (no imageUrl)');
        }
      }

      print('📊 Categories: ${_categorizedImages.keys.toList()}');
      print(
        '📊 Total categorized images: ${_categorizedImages.values.fold(0, (sum, list) => sum + list.length)}',
      );

      // Set first category as selected (prefer Images over PDF)
      if (_categorizedImages.isNotEmpty) {
        // Prefer showing images first
        _selectedCategory = _categorizedImages.containsKey('รูปภาพ (JPG/PNG)')
            ? 'รูปภาพ (JPG/PNG)'
            : _categorizedImages.keys.first;
        print('✅ Selected category: $_selectedCategory');
      } else {
        print('⚠️ No categories after processing!');
      }

      setState(() {
        _isLoading = false;
      });

      print('✅ _fetchImages completed successfully');
    } catch (e, stackTrace) {
      print('💥 Error in _fetchImages: $e');
      print('📍 Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    // Show empty state
    if (_categorizedImages.isEmpty) {
      return _buildEmptyState(context);
    }

    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Draggable dialog
        Positioned(
          left: (screenSize.width - 900) / 2 + _offset.dx,
          top: (screenSize.height - 700) / 2 + _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
              });
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 900,
                height: 700,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'กำลังโหลดรูปภาพ...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
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
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'เกิดข้อผิดพลาด',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ปิด'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchImages,
                  child: const Text('ลองใหม่'),
                ),
              ],
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
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: Padding(
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
        final isPdfCategory = category == 'ไฟล์ PDF';

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
                    isPdfCategory
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    size: 20,
                    color: isSelected
                        ? (isPdfCategory
                              ? Colors.red[400]
                              : const Color(0xFF3B82F6))
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
                          ? (isPdfCategory
                                ? Colors.red.withValues(alpha: 0.1)
                                : const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.1))
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isPdfCategory
                                  ? Colors.red[400]
                                  : const Color(0xFF3B82F6))
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

  Widget _buildImageCard(DocumentImage img) {
    // Generate a unique tag based on ID or URL, combined with object hash to ensure uniqueness
    final String heroTag = '${img.imageId ?? img.imageUrl}_${img.hashCode}';
    final bool isPdf = img.imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

    return InkWell(
      onTap: () {
        if (isPdf) {
          // Open PDF in new tab
          _openPdfInNewTab(img.imageUrl!);
        } else {
          _showImageDetail(context, img, heroTag);
        }
      },
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
                child: isPdf
                    ? Container(
                        color: const Color(0xFFF3F4F6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'PDF Document',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Hero(
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
                  Row(
                    children: [
                      if (isPdf)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 14,
                            color: Colors.red[400],
                          ),
                        ),
                      Expanded(
                        child: Text(
                          img.subcategory ??
                              img.description ??
                              'ไม่มีรายละเอียด',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Uploaded by
                  if (img.uploadedBy?.isNotEmpty == true)
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            img.uploadedBy!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  void _openPdfInNewTab(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Could not launch URL: $url');
      }
    } catch (e) {
      print('❌ Error opening PDF: $e');
    }
  }

  void _showImageDetail(
    BuildContext context,
    DocumentImage img,
    String heroTag,
  ) {
    final bool isPdf = img.imageUrl?.toLowerCase().endsWith('.pdf') ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isPdf)
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.red[400],
                            size: 24,
                          )
                        else
                          const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                img.subcategory ??
                                    img.description ??
                                    'ไม่มีรายละเอียด',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              if (img.description?.isNotEmpty == true &&
                                  img.description != img.subcategory) ...[
                                const SizedBox(height: 4),
                                Text(
                                  img.description!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: isPdf
                        ? _buildPdfViewer(img.imageUrl!)
                        : ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Hero(
                                tag: heroTag,
                                child: Image.network(
                                  img.imageUrl ?? '',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Footer with date
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
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
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SfPdfViewer.network(
        url,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
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
