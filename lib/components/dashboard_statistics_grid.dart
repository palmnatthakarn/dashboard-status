import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/bloc_exports.dart';

class DashboardStatisticsGrid extends StatelessWidget {
  final List shops;
  final String selectedFilter;
  final DateTime? selectedDate;
  final Function(String) onFilterTap;
  final Function(List, String) getShopCountByStatus;
  final Function(List) getDocumentCounts;
  final NumberFormat numFmt;

  const DashboardStatisticsGrid({
    super.key,
    required this.shops,
    required this.selectedFilter,
    required this.selectedDate,
    required this.onFilterTap,
    required this.getShopCountByStatus,
    required this.getDocumentCounts,
    required this.numFmt,
  });

  @override
  Widget build(BuildContext context) {
    // เพิ่ม error handling
    if (shops.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
          child: Text(
            'ไม่มีข้อมูลสาขา',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // ปรับการคำนวณจำนวนคอลัมน์ให้รองรับหน้าจอขนาดเล็กมากขึ้น
        int gridCols;
        double aspectRatio;
        double spacing;

        if (constraints.maxWidth >= 1200) {
          gridCols = 4;
          aspectRatio = 2.2;
          spacing = 16;
        } else if (constraints.maxWidth >= 900) {
          gridCols = 4;
          aspectRatio = 2.0;
          spacing = 12;
        } else if (constraints.maxWidth >= 600) {
          gridCols = 2;
          aspectRatio = 1.8;
          spacing = 12;
        } else if (constraints.maxWidth >= 400) {
          gridCols = 2;
          aspectRatio = 1.6;
          spacing = 8;
        } else {
          gridCols = 1;
          aspectRatio = 1.4;
          spacing = 8;
        }

        // Widget สำหรับสร้าง grid items
        List<Widget> gridItems = [
          StaggeredCard(
            delay: 0,
            child: ModernStatCard(
              title: 'กำไรต่ำกว่า 1 ล้านบาท',
              value: numFmt.format(getShopCountByStatus(shops, 'safe')),
              subtitle: 'สาขา',
              icon: Icons.check_circle_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isSelected: selectedFilter == 'safe',
              onTap: () => onFilterTap('safe'),
            ),
          ),
          StaggeredCard(
            delay: 150,
            child: ModernStatCard(
              title: 'กำไร 1-1.8 ล้านบาท',
              value: numFmt.format(getShopCountByStatus(shops, 'warning')),
              subtitle: 'สาขา',
              icon: Icons.warning_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isSelected: selectedFilter == 'warning',
              onTap: () => onFilterTap('warning'),
            ),
          ),
          StaggeredCard(
            delay: 300,
            child: ModernStatCard(
              title: 'กำไรเกิน 1.8 ล้านบาท',
              value: numFmt.format(getShopCountByStatus(shops, 'exceeded')),
              subtitle: 'สาขา',
              icon: Icons.error_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isSelected: selectedFilter == 'exceeded',
              onTap: () => onFilterTap('exceeded'),
            ),
          ),
          StaggeredCard(
            delay: 450,
            child: EnhancedDocumentCard(
              documentCounts: getDocumentCounts(shops) as Map<String, int>,
              numFmt: numFmt,
              shops: shops,
            ),
          ),
        ];

        // สำหรับหน้าจอเล็ก ใช้ SingleChildScrollView
        if (constraints.maxWidth < 600) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: gridItems
                    .map(
                      (item) => Container(
                        width: constraints.maxWidth * 0.85,
                        margin: EdgeInsets.only(right: spacing),
                        child: item,
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        }

        // สำหรับหน้าจอใหญ่ ใช้ GridView
        return Padding(
          padding: EdgeInsets.all(spacing),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: gridCols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
            children: gridItems,
          ),
        );
      },
    );
  }
}

class ModernStatCard extends StatefulWidget {
  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.isSelected = false,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<ModernStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale((_isHovered || widget.isSelected) ? 1.02 : 1.0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            border: widget.isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(
                  alpha: (_isHovered || widget.isSelected) ? 0.5 : 0.3,
                ),
                blurRadius: (_isHovered || widget.isSelected) ? 20 : 12,
                offset: Offset(0, (_isHovered || widget.isSelected) ? 8 : 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // คำนวณขนาดฟอนต์ตามขนาด container
              final isCompact = constraints.maxWidth < 200;
              final titleFontSize = isCompact
                  ? (_isHovered ? 12.0 : 11.0)
                  : (_isHovered ? 14.0 : 13.0);
              final valueFontSize = isCompact
                  ? (_isHovered ? 24.0 : 22.0)
                  : (_isHovered ? 30.0 : 28.0);
              final iconSize = isCompact ? 40.0 : (_isHovered ? 52.0 : 50.0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ฝั่งข้อความ
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 12),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          tween: Tween(
                            begin: 0,
                            end:
                                double.tryParse(
                                  widget.value.replaceAll(',', ''),
                                ) ??
                                0,
                          ),
                          builder: (context, value, child) {
                            final formatter = NumberFormat.decimalPattern(
                              'th_TH',
                            );
                            return Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: valueFontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  child: Text(formatter.format(value)),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: isCompact ? 2 : 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: _isHovered ? 1.0 : 0.9,
                            ),
                            fontSize: isCompact ? 10.0 : 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                          child: Text(widget.subtitle),
                        ),
                      ],
                    ),
                  ),

                  // ฝั่งไอคอน
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.all(
                              isCompact ? 6 : (_isHovered ? 12 : 10),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: _isHovered ? 0.25 : 0.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                isCompact ? 8 : 12,
                              ),
                            ),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: _isHovered ? 0.05 : 0,
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class EnhancedDocumentCard extends StatefulWidget {
  const EnhancedDocumentCard({
    super.key,
    required this.documentCounts,
    required this.numFmt,
    required this.shops,
  });

  final Map<String, int> documentCounts;
  final NumberFormat numFmt;
  final List shops;

  @override
  State<EnhancedDocumentCard> createState() => _EnhancedDocumentCardState();
}

class _EnhancedDocumentCardState extends State<EnhancedDocumentCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final totalDocs = widget.documentCounts['total'] ?? 0;
    final depositDocs = widget.documentCounts['deposit'] ?? 0;
    final withdrawDocs = widget.documentCounts['withdraw'] ?? 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3B82F6,
              ).withValues(alpha: _isHovered ? 0.4 : 0.3),
              blurRadius: _isHovered ? 16 : 12,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 250;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact
                                  ? (_isHovered ? 13.0 : 12.0)
                                  : (_isHovered ? 15.0 : 14.0),
                              fontWeight: FontWeight.w500,
                            ),
                            child: Text(
                              'เอกสารทั้งหมด',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0, end: totalDocs.toDouble()),
                              builder: (context, value, child) {
                                return AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact
                                        ? (_isHovered ? 22.0 : 20.0)
                                        : (_isHovered ? 28.0 : 24.0),
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  child: Text(
                                    widget.numFmt.format(value.toInt()),
                                  ),
                                );
                              },
                            ),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: _isHovered ? 1.0 : 0.9,
                              ),
                              fontSize: isCompact ? 10.0 : 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                            child: Text('ฉบับ'),
                          ),
                        ],
                      ),
                    ),
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.all(
                        isCompact ? 6 : (_isHovered ? 12 : 8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: _isHovered ? 0.25 : 0.2,
                        ),
                        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isHovered ? 0.05 : 0,
                        child: Icon(
                          Icons.folder_rounded,
                          color: Colors.white,
                          size: isCompact ? 36.0 : (_isHovered ? 52.0 : 48.0),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Details
                if (!isCompact) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // รายรับ
                      Expanded(
                        child: _buildDetailItem(
                          'รายรับ',
                          widget.numFmt.format(depositDocs),
                          const Color.fromARGB(255, 211, 245, 18),
                          isCompact,
                          _isHovered,
                        ),
                      ),
                      // เส้นคั่น
                      Container(width: 1, height: 30, color: Colors.white24),
                      // รายจ่าย
                      Expanded(
                        child: _buildDetailItem(
                          'รายจ่าย',
                          widget.numFmt.format(withdrawDocs),
                          const Color(0xFFEF4444),
                          isCompact,
                          _isHovered,
                        ),
                      ),
                      // เส้นคั่น
                      Container(width: 1, height: 30, color: Colors.white24),
                      // จัดการแล้ว
                      Expanded(
                        child:
                            BlocBuilder<ImageApprovalBloc, ImageApprovalState>(
                              builder: (context, approvalState) {
                                int approvedFilesCount = 0;
                                int totalFilesCount = 0;

                                for (final shop in widget.shops) {
                                  final shopId = shop.shopid ?? '';
                                  approvedFilesCount += approvalState
                                      .getApprovedCount(shopId);

                                  final count = shop.imageCount;
                                  if (count is int) {
                                    totalFilesCount += count;
                                  } else if (count is num) {
                                    totalFilesCount += count.toInt();
                                  }
                                }

                                return _buildFileProgressItem(
                                  approvedFilesCount,
                                  totalFilesCount,
                                  isCompact,
                                  _isHovered,
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    Color color,
    bool isCompact,
    bool isHovered,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 6 : 8,
              height: isCompact ? 6 : 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: isCompact ? 4 : 6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isCompact
                      ? (isHovered ? 11.0 : 10.0)
                      : (isHovered ? 13.0 : 12.0),
                  fontWeight: FontWeight.w400,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 2 : 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact
                  ? (isHovered ? 14.0 : 12.0)
                  : (isHovered ? 18.0 : 16.0),
              fontWeight: FontWeight.w600,
            ),
            child: Text(value),
          ),
        ),
      ],
    );
  }

  Widget _buildFileProgressItem(
    int approved,
    int total,
    bool isCompact,
    bool isHovered,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 6 : 8,
              height: isCompact ? 6 : 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isCompact ? 4 : 6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isCompact
                      ? (isHovered ? 9.0 : 8.0)
                      : (isHovered ? 11.0 : 10.0),
                  fontWeight: FontWeight.w400,
                ),
                child: Text(
                  'จัดการแล้ว',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 1 : 2),
        TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween: IntTween(begin: 0, end: approved),
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact
                          ? (isHovered ? 12.0 : 10.0)
                          : (isHovered ? 16.0 : 14.0),
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(
                      '${widget.numFmt.format(value)}/${widget.numFmt.format(total)}',
                    ),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isCompact
                        ? (isHovered ? 7.0 : 6.0)
                        : (isHovered ? 9.0 : 8.0),
                    fontWeight: FontWeight.w400,
                  ),
                  child: Text('ไฟล์'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class StaggeredCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const StaggeredCard({super.key, required this.child, required this.delay});

  @override
  State<StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: widget.child),
        );
      },
    );
  }
}
