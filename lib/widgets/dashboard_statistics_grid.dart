import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard_bloc_exports.dart';

class DashboardStatisticsGrid extends StatelessWidget {
  final List shops;
  final String selectedFilter;
  final DateTime? selectedDate;
  final Function(String) onFilterTap;
  final Function(List, String) getShopCountByStatus;
  final Function(List) getDocumentCounts;
  final NumberFormat numFmt;

  const DashboardStatisticsGrid({
    Key? key,
    required this.shops,
    required this.selectedFilter,
    required this.selectedDate,
    required this.onFilterTap,
    required this.getShopCountByStatus,
    required this.getDocumentCounts,
    required this.numFmt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final gridCols = isWide ? 4 : (isMedium ? 2 : 1);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: gridCols,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            StaggeredCard(
              delay: 0,
              child: ModernStatCard(
                title: 'ต่ำกว่า 1 ล้านบาท',
                value: numFmt.format(getShopCountByStatus(shops, 'safe')),
                subtitle: 'ร้านค้า',
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
                title: '1-1.8 ล้านบาท',
                value: numFmt.format(getShopCountByStatus(shops, 'warning')),
                subtitle: 'ร้านค้า',
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
                title: 'เกิน 1.8 ล้านบาท',
                value: numFmt.format(getShopCountByStatus(shops, 'exceeded')),
                subtitle: 'ร้านค้า',
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
          ],
        );
      },
    );
  }
}

class ModernStatCard extends StatefulWidget {
  const ModernStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

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
                ? Border.all(color: Colors.white.withOpacity(0.8), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(
                  (_isHovered || widget.isSelected) ? 0.5 : 0.3,
                ),
                blurRadius: (_isHovered || widget.isSelected) ? 20 : 12,
                offset: Offset(0, (_isHovered || widget.isSelected) ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ฝั่งข้อความ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isHovered ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      tween: Tween(
                        begin: 0,
                        end:
                            double.tryParse(widget.value.replaceAll(',', '')) ??
                            0,
                      ),
                      builder: (context, value, child) {
                        final formatter = NumberFormat.decimalPattern('th_TH');
                        return AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isHovered ? 30 : 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          child: Text(formatter.format(value)),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Colors.white.withOpacity(_isHovered ? 1.0 : 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      child: Text(widget.subtitle),
                    ),
                  ],
                ),
              ),

              // ฝั่งไอคอน
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(_isHovered ? 12 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isHovered ? 0.25 : 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isHovered ? 0.05 : 0,
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: _isHovered ? 52 : 50,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedDocumentCard extends StatefulWidget {
  const EnhancedDocumentCard({
    Key? key,
    required this.documentCounts,
    required this.numFmt,
    required this.shops,
  }) : super(key: key);

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3B82F6,
              ).withOpacity(_isHovered ? 0.4 : 0.3),
              blurRadius: _isHovered ? 16 : 12,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เอกสารทั้งหมด',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fontSize = constraints.maxWidth < 120
                              ? 22.0
                              : 28.0;
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            tween: Tween(begin: 0, end: totalDocs.toDouble()),
                            builder: (context, value, child) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.numFmt.format(value.toInt()),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Text(
                        'ฉบับ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(_isHovered ? 10 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isHovered ? 0.25 : 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isHovered ? 0.05 : 0,
                    child: Icon(
                      Icons.folder_rounded,
                      color: Colors.white,
                      size: _isHovered ? 52 : 50,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Details - Improved layout
            Row(
              children: [
                // รายรับ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 211, 245, 18),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'รายรับ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.numFmt.format(depositDocs),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // เส้นคั่นตรงกลาง
                Container(width: 1, height: 40, color: Colors.white24),
                // รายจ่าย
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'รายจ่าย',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.numFmt.format(withdrawDocs),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: BlocBuilder<ImageApprovalBloc, ImageApprovalState>(
                    builder: (context, approvalState) {
                      // คำนวณจำนวนไฟล์ที่อนุมัติแล้วทั้งหมด
                      int approvedFilesCount = 0;
                      for (final shop in widget.shops) {
                        final shopId = shop.shopid ?? '';
                        approvedFilesCount += approvalState.getApprovedCount(
                          shopId,
                        );
                      }

                      // คำนวณจำนวนไฟล์ทั้งหมด
                      int totalFilesCount = 0;
                      for (final shop in widget.shops) {
                        final count = shop.imageCount;
                        if (count is int) {
                          totalFilesCount += count;
                        } else if (count is num) {
                          totalFilesCount += count.toInt();
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'จัดการแล้ว',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          TweenAnimationBuilder<int>(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            tween: IntTween(begin: 0, end: approvedFilesCount),
                            builder: (context, value, child) {
                              return Column(
                                children: [
                                  Text(
                                    '${widget.numFmt.format(value)}/${widget.numFmt.format(totalFilesCount)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                 /* const Text(
                                    'ไฟล์',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),*/
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class StaggeredCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const StaggeredCard({Key? key, required this.child, required this.delay})
    : super(key: key);

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
