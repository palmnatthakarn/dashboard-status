import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 85 : 280,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with logo
            _buildHeader(),

            const SizedBox(height: 8),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'ภาพรวม',
                    index: 0,
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    label: 'KPI',
                    index: 1,
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    selectedIcon: Icons.description_rounded,
                    label: 'เอกสาร',
                    index: 2,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    label: 'ตั้งค่าบัญชี',
                    index: 10,
                  ),
                ],
              ),
            ),

            // Sign Out Button
            _buildSignOutButton(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
  // จัดเรียงรายการจากซ้ายไปขวา
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // 1. Logo/Icon ตามสถานะ isCollapsed
    if (!isCollapsed) ...[
      // สถานะ Expanded (แสดง Logo ตัวใหญ่)
      Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.only(right: 5), // เพิ่ม margin ด้านขวา
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'Logo',
          style: TextStyle(
            fontSize: 14, // ปรับขนาดตัวอักษรเล็กน้อย
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ] else ...[
      // สถานะ Collapsed (แสดง Icon ตัวเล็ก)
      Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(right: 4), // เพิ่ม margin ด้านขวาเล็กน้อย
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade600,
          size: 24,
        ),
      ),
    ],

    // 2. ใช้ Spacer() เพื่อดันปุ่มไปอยู่ด้านขวาสุดของ Row
    if (onToggleCollapse != null) const Spacer(),

    // 3. ปุ่ม Toggle Collapse
    if (onToggleCollapse != null)
      InkWell(
        onTap: onToggleCollapse,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Icon(
            isCollapsed
                ? Icons.keyboard_double_arrow_right_rounded
                : Icons.keyboard_double_arrow_left_rounded,
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
      ),
  ],
)
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          // Sign out action
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF2563EB),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

  Widget _buildMenuItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    String? badge,
  }) {
    final isSelected = selectedIndex == index;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade600,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade600,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1976D2)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarMenuItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;

  const SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });
}