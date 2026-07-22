import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../components/common/login_left_panel.dart';
import '../dashboard_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.error)),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.all(18),
              ),
            );
          }
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthSuccess) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF78F5FF)),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 800) {
                return Row(
                  children: [
                    const Expanded(flex: 5, child: LoginLeftPanel()),
                    Expanded(flex: 5, child: _LoginRightPanel(state: state)),
                  ],
                );
              }
              return _LoginRightPanel(state: state, isMobile: true);
            },
          );
        },
      ),
    );
  }
}

class _LoginRightPanel extends StatefulWidget {
  final AuthState state;
  final bool isMobile;

  const _LoginRightPanel({required this.state, this.isMobile = false});

  @override
  State<_LoginRightPanel> createState() => _LoginRightPanelState();
}

class _LoginRightPanelState extends State<_LoginRightPanel>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _floatCtrl;

  static const _blue = Color(0xFF55A7FF);
  static const _violet = Color(0xFF9F7AEA);
  static const _cyan = Color(0xFF78F5FF);

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _floatCtrl.dispose();
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
      child: Stack(
        children: [
          _buildBgOrbs(),
          _buildNoiseVeil(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 22 : 60,
                  vertical: widget.isMobile ? 34 : 48,
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _enterCtrl,
                    curve: Curves.easeOutCubic,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.10),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _enterCtrl,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(
                                0,
                                Tween(begin: -5.0, end: 5.0)
                                    .animate(
                                      CurvedAnimation(
                                        parent: _floatCtrl,
                                        curve: Curves.easeInOutCubic,
                                      ),
                                    )
                                    .value,
                              ),
                              child: child,
                            ),
                            child: _buildAppIcon(),
                          ),
                          const SizedBox(height: 28),
                          _buildCard(context),
                          const SizedBox(height: 24),
                          Text(
                            'Monitor  Business Intelligence Platform',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF52627A).withValues(alpha: 0.58),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgOrbs() {
    return Stack(
      children: [
        Positioned(top: -180, right: -150, child: _orb(430, _blue, 0.25)),
        Positioned(bottom: -190, left: -160, child: _orb(470, _violet, 0.24)),
        Positioned(top: 210, left: 48, child: _orb(210, _cyan, 0.12)),
      ],
    );
  }

  Widget _orb(double size, Color color, double alpha) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) => Transform.scale(
        scale: Tween(begin: 0.96, end: 1.04)
            .animate(
              CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutCubic),
            )
            .value,
        child: child,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.26),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoiseVeil() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.035,
          child: CustomPaint(painter: _NoisePainter()),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _blue.withValues(alpha: 0.25),
                _blue.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: _blue.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.28),
                blurRadius: 44,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_cyan, _blue, _violet],
              ),
            ),
            child: CustomPaint(painter: _MonitorMarkPainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final isLoading = widget.state is AuthLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: _blue.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.16),
            blurRadius: 58,
            offset: const Offset(0, 28),
          ),
          BoxShadow(
            color: const Color(0xFF375D9B).withValues(alpha: 0.10),
            blurRadius: 72,
            offset: const Offset(0, 36),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 26 : 38,
              vertical: widget.isMobile ? 34 : 42,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.94),
                  const Color(0xFFF8FBFF).withValues(alpha: 0.84),
                  const Color(0xFFEFF4FF).withValues(alpha: 0.76),
                ],
              ),
              border: Border.all(color: _blue.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _eyebrow(),
                const SizedBox(height: 18),
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF071129),
                    letterSpacing: -1.3,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to enter your VAT intelligence workspace with secure Google authentication.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF52627A),
                    height: 1.65,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 38),
                _GoogleSignInButton(
                  isLoading: isLoading,
                  onPressed: () =>
                      context.read<AuthBloc>().add(LoginWithGoogleRequested()),
                ),
                const SizedBox(height: 28),
                _secureNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eyebrow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _blue.withValues(alpha: 0.14)),
      ),
      child: Text(
        'PRIVATE DASHBOARD',
        style: TextStyle(
          color: _cyan.withValues(alpha: 0.94),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _secureNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(
          painter: _LockLinePainter(color: _cyan.withValues(alpha: 0.72)),
          size: const Size(16, 16),
        ),
        const SizedBox(width: 9),
        Text(
          'Encrypted access via Google',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF52627A).withValues(alpha: 0.78),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;
  bool _pressed = false;

  static const _blue = Color(0xFF55A7FF);
  static const _violet = Color(0xFF9F7AEA);
  static const _cyan = Color(0xFF78F5FF);

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : (_hovered ? 1.012 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.isLoading
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.isLoading
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.isLoading
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 11, 12, 11),
            decoration: BoxDecoration(
              gradient: widget.isLoading
                  ? null
                  : LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _hovered
                          ? const [_cyan, _blue, _violet]
                          : const [_blue, _violet],
                    ),
              color: widget.isLoading
                  ? Colors.white.withValues(alpha: 0.10)
                  : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: widget.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: _blue.withValues(alpha: _hovered ? 0.36 : 0.22),
                        blurRadius: _hovered ? 34 : 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
            ),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_cyan),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            'G',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        width: 38,
                        height: 38,
                        transform: Matrix4.translationValues(
                          _hovered ? 3 : 0,
                          _hovered ? -1 : 0,
                          0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: _hovered ? 0.22 : 0.14,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: CustomPaint(painter: _ArrowNorthEastPainter()),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MonitorMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.62)
      ..lineTo(size.width * 0.40, size.height * 0.48)
      ..lineTo(size.width * 0.54, size.height * 0.58)
      ..lineTo(size.width * 0.76, size.height * 0.34);
    canvas.drawPath(path, paint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.1;
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.74),
      Offset(size.width * 0.78, size.height * 0.74),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockLinePainter extends CustomPainter {
  final Color color;

  const _LockLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.20,
        size.height * 0.44,
        size.width * 0.60,
        size.height * 0.42,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.30,
        size.height * 0.14,
        size.width * 0.40,
        size.height * 0.48,
      ),
      3.14,
      3.14,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LockLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ArrowNorthEastPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.36, size.height * 0.64)
      ..lineTo(size.width * 0.64, size.height * 0.36)
      ..moveTo(size.width * 0.46, size.height * 0.34)
      ..lineTo(size.width * 0.66, size.height * 0.34)
      ..lineTo(size.width * 0.66, size.height * 0.54);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 260; i++) {
      final x = ((i * 37) % size.width.toInt()).toDouble();
      final y = ((i * 71) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.45 : 0.25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
