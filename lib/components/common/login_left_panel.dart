import 'package:flutter/material.dart';
import 'app_logo.dart';

/// Animated left panel shown on the Login page for screens ≥ 800 px wide.
///
/// Extracted from [LoginPage] to keep that file focused on form logic only.
class LoginLeftPanel extends StatefulWidget {
  const LoginLeftPanel({super.key});

  @override
  State<LoginLeftPanel> createState() => _LoginLeftPanelState();
}

class _LoginLeftPanelState extends State<LoginLeftPanel>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A6CF7), Color(0xFF5B7EF9), Color(0xFF4A6CF7)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              ..._buildDecorativeShapes(constraints),
              Center(child: _buildCenterIllustration(constraints)),
            ],
          );
        },
      ),
    );
  }

  // ─── Decorative shapes ────────────────────────────────────────────────────

  List<Widget> _buildDecorativeShapes(BoxConstraints constraints) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;
    return [
      Positioned(top: h * 0.05, left: w * 0.10, child: _dot(const Color(0xFFFF9F43), 16, 0)),
      Positioned(top: h * 0.08, right: w * 0.15, child: _dot(const Color(0xFFFF6B6B), 14, 1)),
      Positioned(top: h * 0.12, right: w * 0.05, child: _dot(const Color(0xFFFFD93D), 12, 2)),
      Positioned(top: h * 0.25, left: w * 0.08, child: _teardrop(const Color(0xFF4ECDC4), 24, -0.5)),
      Positioned(top: h * 0.45, left: w * 0.03, child: _dot(const Color(0xFF6BCB77), 18, 3)),
      Positioned(top: h * 0.35, right: w * 0.05, child: _teardrop(const Color(0xFFA66CFF), 20, 0.5)),
      Positioned(top: h * 0.55, right: w * 0.10, child: _dot(const Color(0xFFFFB347), 15, 4)),
      Positioned(
        bottom: h * 0.15,
        left: w * 0.10,
        child: Transform.rotate(
          angle: 0.4,
          child: Container(
            width: 50,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFFF69B4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: h * 0.08,
        left: w * 0.30,
        child: Transform.rotate(
          angle: -0.3,
          child: Container(
            width: 35,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      Positioned(bottom: h * 0.10, right: w * 0.12, child: _dot(const Color(0xFFFFE066), 20, 5)),
      Positioned(bottom: h * 0.20, right: w * 0.05, child: _dot(const Color(0xFFFF7675), 12, 6)),
    ];
  }

  Widget _dot(Color color, double size, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final pulse = index.isEven ? _pulseAnimation.value : 2 - _pulseAnimation.value;
            return Transform.scale(scale: value * pulse, child: child);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.35),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _teardrop(Color color, double size, double baseAngle) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: baseAngle + (_rotateAnimation.value * 0.3),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size * 1.4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size),
            topRight: Radius.circular(size),
            bottomLeft: Radius.circular(size * 0.3),
            bottomRight: Radius.circular(size * 0.3),
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
      ),
    );
  }

  // ─── Centre illustration ──────────────────────────────────────────────────

  Widget _buildCenterIllustration(BoxConstraints constraints) {
    final size = constraints.maxWidth * 0.7;
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _floatAnimation.value), child: child),
      child: SizedBox(
        width: size.clamp(280.0, 450.0),
        height: size.clamp(280.0, 450.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildDashboardCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const AppLogo.small(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748))),
                        Text('Monitor your KPI',
                            style: TextStyle(fontSize: 11, color: Color(0xFF718096))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _bar(45, const Color(0xFF4A6CF7)),
                  _bar(70, const Color(0xFF6BCB77)),
                  _bar(55, const Color(0xFFFFB347)),
                  _bar(85, const Color(0xFF4A6CF7)),
                  _bar(40, const Color(0xFFA66CFF)),
                  _bar(65, const Color(0xFF6BCB77)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat('Revenue', '฿2.5M', const Color(0xFF6BCB77)),
                  _stat('Orders', '1,240', const Color(0xFF4A6CF7)),
                  _stat('Growth', '+12%', const Color(0xFFFFB347)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badge(Icons.trending_up, 'Analytics', const Color(0xFF6BCB77)),
            const SizedBox(width: 12),
            _badge(Icons.people, 'Teams', const Color(0xFFA66CFF)),
            const SizedBox(width: 12),
            _badge(Icons.assessment, 'Reports', const Color(0xFFFF9F43)),
          ],
        ),
      ],
    );
  }

  Widget _bar(double height, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        width: 24,
        height: value,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
        ],
      ),
    );
  }
}
