import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated left panel shown on the Login page for screens >= 800 px wide.
///
/// Extracted from [LoginPage] to keep that file focused on form logic only.
class LoginLeftPanel extends StatefulWidget {
  const LoginLeftPanel({super.key});

  @override
  State<LoginLeftPanel> createState() => _LoginLeftPanelState();
}

class _LoginLeftPanelState extends State<LoginLeftPanel>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _orbitAnimation;

  static const _blue = Color(0xFF55A7FF);
  static const _violet = Color(0xFF9F7AEA);
  static const _cyan = Color(0xFF78F5FF);

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat(reverse: true);
    _orbitAnimation = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _orbitController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF), Color(0xFFEEF2FF)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              ..._buildAmbientGlows(constraints),
              ..._buildStarDust(constraints),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Center(child: _buildCenterIllustration(constraints)),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildAmbientGlows(BoxConstraints constraints) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    return [
      Positioned(
        top: -h * 0.12,
        left: -w * 0.12,
        child: _orb(w * 0.72, _blue, 0.34),
      ),
      Positioned(
        bottom: -h * 0.18,
        right: -w * 0.16,
        child: _orb(w * 0.82, _violet, 0.28),
      ),
      Positioned(
        top: h * 0.30,
        right: w * 0.05,
        child: _orb(w * 0.30, _cyan, 0.14),
      ),
    ];
  }

  List<Widget> _buildStarDust(BoxConstraints constraints) {
    final points = <({double x, double y, double size, Color color})>[
      (x: 0.14, y: 0.16, size: 3.0, color: _cyan),
      (x: 0.78, y: 0.12, size: 2.0, color: Colors.white),
      (x: 0.88, y: 0.34, size: 3.5, color: _violet),
      (x: 0.10, y: 0.52, size: 2.5, color: Colors.white),
      (x: 0.26, y: 0.82, size: 3.0, color: _blue),
      (x: 0.82, y: 0.78, size: 2.0, color: _cyan),
    ];

    return points.map((point) {
      return Positioned(
        left: constraints.maxWidth * point.x,
        top: constraints.maxHeight * point.y,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: point.size > 2.5 ? _pulseAnimation.value : 1,
            child: child,
          ),
          child: Container(
            width: point.size,
            height: point.size,
            decoration: BoxDecoration(
              color: point.color.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: point.color.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _orb(double size, Color color, double alpha) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnimation.value, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.24),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIllustration(BoxConstraints constraints) {
    final size = (constraints.maxWidth * 0.72).clamp(330.0, 520.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _orbitAnimation]),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: Transform.rotate(angle: _orbitAnimation.value, child: child),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _halo(size * 0.92),
            Transform.rotate(angle: -math.pi / 16, child: _buildMetricPanel()),
            Positioned(
              right: size * 0.02,
              bottom: size * 0.12,
              child: Transform.rotate(
                angle: math.pi / 24,
                child: _buildSignalCard(),
              ),
            ),
            Positioned(
              left: size * 0.02,
              top: size * 0.12,
              child: _buildStatusPill(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _halo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _blue.withValues(alpha: 0.08)),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.48),
            _blue.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPanel() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(8),
      decoration: _outerGlassDecoration(36),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _innerGlassDecoration(29),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _logoMark(),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAT Monitor',
                        style: TextStyle(
                          color: Color(0xFF071129),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Realtime approvals',
                        style: TextStyle(
                          color: Color(0xFF52627A),
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(52, _cyan),
                _bar(92, _blue),
                _bar(66, _violet),
                _bar(118, _cyan),
                _bar(78, _blue),
                _bar(104, _violet),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('Revenue', '฿2.5M', _cyan),
                _stat('Files', '1,240', _blue),
                _stat('Growth', '+12%', _violet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalCard() {
    return Container(
      width: 174,
      padding: const EdgeInsets.all(6),
      decoration: _outerGlassDecoration(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _innerGlassDecoration(22),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live signal',
              style: TextStyle(
                color: Color(0xFF52627A),
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '99.8%',
              style: TextStyle(
                color: Color(0xFF071129),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _blue.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _cyan,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _cyan.withValues(alpha: 0.7), blurRadius: 14),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'SECURE ACCESS',
            style: TextStyle(
              color: Color(0xFF071129),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _outerGlassDecoration(double radius) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.70),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _blue.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: _blue.withValues(alpha: 0.18),
          blurRadius: 54,
          offset: const Offset(0, 26),
        ),
        BoxShadow(
          color: const Color(0xFF375D9B).withValues(alpha: 0.10),
          blurRadius: 70,
          offset: const Offset(0, 36),
        ),
      ],
    );
  }

  BoxDecoration _innerGlassDecoration(double radius) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.96),
          const Color(0xFFF8FBFF).withValues(alpha: 0.86),
          const Color(0xFFEFF4FF).withValues(alpha: 0.78),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _blue.withValues(alpha: 0.12)),
    );
  }

  Widget _logoMark() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cyan, _blue, _violet],
        ),
        boxShadow: [
          BoxShadow(color: _blue.withValues(alpha: 0.45), blurRadius: 28),
        ],
      ),
      child: CustomPaint(painter: _SignalPainter()),
    );
  }

  Widget _bar(double height, Color color) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: height),
          duration: const Duration(milliseconds: 980),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Container(
            width: 22,
            height: value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.24)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFF52627A).withValues(alpha: 0.72),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.62)
      ..lineTo(size.width * 0.40, size.height * 0.48)
      ..lineTo(size.width * 0.54, size.height * 0.58)
      ..lineTo(size.width * 0.76, size.height * 0.34);

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.34),
      2.8,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
