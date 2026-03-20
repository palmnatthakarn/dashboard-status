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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
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
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
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

// ---------------------------------------------------------------------------

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

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
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
      color: const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          _buildBgOrbs(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 24 : 60),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                      parent: _enterCtrl, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.06), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: _enterCtrl, curve: Curves.easeOutCubic)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(
                                  0,
                                  Tween(begin: -4.0, end: 4.0)
                                      .animate(CurvedAnimation(
                                          parent: _floatCtrl,
                                          curve: Curves.easeInOut))
                                      .value),
                              child: child,
                            ),
                            child: _buildAppIcon(),
                          ),
                          const SizedBox(height: 32),
                          _buildCard(context),
                          const SizedBox(height: 24),
                          const Text(
                            'Monitor � Business Intelligence Platform',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFCBD5E1),
                                letterSpacing: 0.3),
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
    return Stack(children: [
      Positioned(
        top: -100, right: -100,
        child: Container(
          width: 300, height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF4A6CF7).withValues(alpha: 0.09),
              const Color(0xFF4A6CF7).withValues(alpha: 0.0),
            ]),
          ),
        ),
      ),
      Positioned(
        bottom: -100, left: -100,
        child: Container(
          width: 340, height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF6BCB77).withValues(alpha: 0.07),
              const Color(0xFF6BCB77).withValues(alpha: 0.0),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildAppIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF4A6CF7).withValues(alpha: 0.15),
              const Color(0xFF4A6CF7).withValues(alpha: 0.0),
            ]),
          ),
        ),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A6CF7), Color(0xFF5B7EF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A6CF7).withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.bar_chart_rounded,
              color: Colors.white, size: 36),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final isLoading = widget.state is AuthLoading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      /*decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6CF7).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),*/
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         /* Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF4A6CF7),
              size: 28,
            ),
          ),
          const SizedBox(height: 28),*/
          Center(
            child: const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: const Text(
              'Sign in to access your business intelligence \n       dashboard and continue your work.',
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _GoogleSignInButton(
            isLoading: isLoading,
            onPressed: () =>
                context.read<AuthBloc>().add(LoginWithGoogleRequested()),
          ),
          const SizedBox(height: 32),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 16, color: const Color(0xFF4A6CF7).withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                const Text(
                  'Secure authentication via Google',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _GoogleSignInButton(
      {required this.isLoading, required this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : LinearGradient(
                    colors: _hovered
                        ? [const Color(0xFF5B7EF9), const Color(0xFF4A6CF7)]
                        : [const Color(0xFF4A6CF7), const Color(0xFF5B7EF9)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading ? const Color(0xFFF1F5F9) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7)
                          .withValues(alpha: _hovered ? 0.35 : 0.20),
                      blurRadius: _hovered ? 20 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation(Color(0xFF4A6CF7)),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32, height: 32,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 22,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
