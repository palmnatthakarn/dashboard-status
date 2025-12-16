import 'package:flutter/material.dart';
import 'package:moniter/pages/report_page.dart';
import '../components/app_sidebar.dart';
import '../dashboard_screen.dart';
import '../pages/kpi/kpi_page.dart';
import '../pages/documents_page.dart';
import '../pages/settings_page.dart';

/// Breakpoints สำหรับ responsive design
class ScreenBreakpoints {
  static const double mobile = 600;
  static const double tablet = 800;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// ประเภทของหน้าจอ
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Helper class สำหรับ responsive design
class ResponsiveHelper {
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ScreenBreakpoints.mobile) {
      return ScreenType.mobile;
    } else if (width < ScreenBreakpoints.tablet) {
      return ScreenType.tablet;
    } else if (width < ScreenBreakpoints.desktop) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      getScreenType(context) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getScreenType(context) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) {
    final type = getScreenType(context);
    return type == ScreenType.desktop || type == ScreenType.largeDesktop;
  }

  static bool isLargeDesktop(BuildContext context) =>
      getScreenType(context) == ScreenType.largeDesktop;

  static double getSidebarWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 280;
      case ScreenType.tablet:
        return 72; // Collapsed sidebar
      case ScreenType.desktop:
        return 280;
      case ScreenType.largeDesktop:
        return 300;
    }
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(12);
      case ScreenType.tablet:
        return const EdgeInsets.all(16);
      case ScreenType.desktop:
        return const EdgeInsets.all(20);
      case ScreenType.largeDesktop:
        return const EdgeInsets.all(24);
    }
  }
}

/// MainLayout - จัดการ layout หลักของแอป
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Widget> _pages = [
    DashboardScreen(),
    const KpiPage(),
    const DocumentsPage(),
    const ReportPage(title: 'รายงานภาพรวม'),
    const ReportPage(title: 'รายงานการเงิน'),
    const ReportPage(title: 'รายงานภาษี'),
    const ReportPage(title: 'รายงานรายวัน'),
    const SettingsPage(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveHelper.getScreenType(context);

    return Scaffold(
      body: _buildBody(screenType),
      drawer: _buildDrawer(screenType),
    );
  }

  Widget _buildBody(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return _pages[_selectedIndex];
      case ScreenType.tablet:
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return Row(
          children: [
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _isSidebarExpanded ? 280 : 85,
                  minWidth: _isSidebarExpanded ? 280 : 85,
                ),
                child: AppSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemSelected,
                  isCollapsed: !_isSidebarExpanded,
                  onToggleCollapse: _toggleSidebar,
                ),
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        );
    }
  }

  Widget? _buildDrawer(ScreenType screenType) {
    if (screenType == ScreenType.mobile) {
      return AppSidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          _onItemSelected(index);
          Navigator.pop(context);
        },
      );
    }
    return null;
  }
}

/// Responsive widget ที่แสดงผลต่างกันตามขนาดหน้าจอ
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveHelper.getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }
}

/// Responsive value ที่เปลี่ยนค่าตามขนาดหน้าจอ
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T desktop;
  final T? largeDesktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  T getValue(BuildContext context) {
    final screenType = ResponsiveHelper.getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }
}
