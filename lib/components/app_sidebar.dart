import 'package:flutter/material.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onSignOut;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onSignOut,
  });

  static const List<SidebarMenuItem> menuItems = [
    SidebarMenuItem(
      title: 'Overview',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    SidebarMenuItem(
      title: 'KPI',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    SidebarMenuItem(
      title: 'Documents',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
    ),
    SidebarMenuItem(
      title: 'Reports',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article_rounded,
    ),
    SidebarMenuItem(
      title: 'งบการเงิน',
      icon: Icons.monetization_on_outlined,
      selectedIcon: Icons.monetization_on_rounded,
      isSubItem: true,
    ),
    SidebarMenuItem(
      title: 'ภาษี',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      isSubItem: true,
    ),

    SidebarMenuItem(
      title: 'สมุดรายวัน',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      isSubItem: true,
    ),
    SidebarMenuItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int? _hoveredIndex;
  bool _isReportsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: widget.isCollapsed ? 80 : 260,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 12 : 16,
                  vertical: 8,
                ),
                itemCount: AppSidebar.menuItems.length,
                itemBuilder: (context, index) {
                  final item = AppSidebar.menuItems[index];

                  // Hide sub-items if Reports is collapsed
                  if (item.isSubItem && !_isReportsExpanded) {
                    return const SizedBox.shrink();
                  }

                  return _buildMenuItem(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    label: item.title,
                    index: index,
                    badge: item.badge,
                    isSubItem: item.isSubItem,
                    isReportsItem: item.title == 'Reports',
                  );
                },
              ),
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 12 : 20,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: widget.isCollapsed
          ? _buildCollapsedHeader()
          : _buildExpandedHeader(),
    );
  }

  Widget _buildCollapsedHeader() {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 86, 94, 247),
                    Color.fromARGB(255, 50, 53, 245),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 86, 94, 247),
                Color.fromARGB(255, 50, 53, 245),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 65, 74, 242).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 65, 74, 242),
                    Color.fromARGB(255, 50, 53, 245),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Account SAH',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                'NameUser@gmail.com',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (widget.onToggleCollapse != null) _buildToggleButton(),
      ],
    );
  }

  Widget _buildToggleButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggleCollapse,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 280),
            turns: widget.isCollapsed ? 0.5 : 0,
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    String? badge,
    bool isSubItem = false,
    bool isReportsItem = false,
  }) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isSubItem && !widget.isCollapsed ? 12 : 0,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (isReportsItem) {
              setState(() => _isReportsExpanded = !_isReportsExpanded);
              return;
            }
            widget.onItemSelected(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 10,
              vertical: widget.isCollapsed ? 10 : 10,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color.fromARGB(255, 65, 74, 242),
                        Color.fromARGB(255, 104, 107, 248),
                      ],
                    )
                  : isHovered
                  ? LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade50],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: widget.isCollapsed
                ? _buildCollapsedMenuItem(
                    icon,
                    selectedIcon,
                    label,
                    isSelected,
                    isHovered,
                  )
                : _buildExpandedMenuItem(
                    icon,
                    selectedIcon,
                    label,
                    isSelected,
                    isHovered,
                    badge,
                    isSubItem,
                    isReportsItem,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedMenuItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    bool isSelected,
    bool isHovered,
  ) {
    return Column(
      children: [
        Container(
          width: 25,
          height: 25,
          child: Tooltip(
            message: label,
            preferBelow: false,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 202, 203, 245),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              color: Color.fromARGB(255, 92, 91, 91),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            child: Center(
              child: AnimatedScale(
                scale: isHovered && !isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? Colors.white
                      : isHovered
                      ? const Color(0xFF6366F1)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedMenuItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    bool isSelected,
    bool isHovered,
    String? badge,
    bool isSubItem,
    bool isReportsItem,
  ) {
    return Row(
      children: [
        if (isSubItem)
          const SizedBox(
            width: 8,
          ), // Additional spacing/visual cue for sub-items
        Container(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : isHovered
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Colors.white
                  : isHovered
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade600,
              size: isSubItem ? 18 : 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSubItem ? 13 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isHovered
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (badge != null) _buildBadge(badge),
        if (isReportsItem) ...[
          const SizedBox(width: 8),
          Icon(
            _isReportsExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey.shade500,
          ),
        ],
        /* if (isSelected)
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),*/
      ],
    );
  }

  Widget _buildBadge(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        badge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(children: [_buildSignOutButton(context)]),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showSignOutDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 0 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withOpacity(0.1),
                const Color(0xFF8B5CF6).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 10),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sign Out Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to sign out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSignOut?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Confirm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class SidebarMenuItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;
  final bool isSubItem;

  const SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.badge,
    this.isSubItem = false,
  });
}
