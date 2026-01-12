import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../components/common/app_logo.dart';
import '../dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Form animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Left panel animations
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Form animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    // Floating animation (up and down)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _onGoogleLoginPressed() {
    context.read<AuthBloc>().add(LoginWithGoogleRequested());
  }

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          if (state is AuthSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthSuccess) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6CF7)),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Use split layout for wider screens (e.g., tablets and desktops)
              if (constraints.maxWidth >= 800) {
                return Row(
                  children: [
                    // Left Side - Blue Panel with Decorations
                    Expanded(flex: 5, child: _buildLeftPanel()),
                    // Right Side - Login Form
                    Expanded(flex: 5, child: _buildRightPanel(state)),
                  ],
                );
              } else {
                // Mobile layout - just the form
                return _buildMobileLayout(state);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
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
              // Decorative shapes - distributed better
              ..._buildDecorativeShapes(constraints),
              // Main content - centered illustration
              Center(child: _buildCenterIllustration(constraints)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildDecorativeShapes(BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final width = constraints.maxWidth;

    return [
      // Top left - orange dot
      Positioned(
        top: height * 0.05,
        left: width * 0.1,
        child: _buildAnimatedShape(const Color(0xFFFF9F43), 16, 0),
      ),
      // Top center-right - coral/salmon dot
      Positioned(
        top: height * 0.08,
        right: width * 0.15,
        child: _buildAnimatedShape(const Color(0xFFFF6B6B), 14, 1),
      ),
      // Top right corner - yellow
      Positioned(
        top: height * 0.12,
        right: width * 0.05,
        child: _buildAnimatedShape(const Color(0xFFFFD93D), 12, 2),
      ),
      // Left side - cyan teardrop
      Positioned(
        top: height * 0.25,
        left: width * 0.08,
        child: _buildTeardrop(const Color(0xFF4ECDC4), 24, -0.5),
      ),
      // Left mid - green dot
      Positioned(
        top: height * 0.45,
        left: width * 0.03,
        child: _buildAnimatedShape(const Color(0xFF6BCB77), 18, 3),
      ),
      // Right side - purple teardrop
      Positioned(
        top: height * 0.35,
        right: width * 0.05,
        child: _buildTeardrop(const Color(0xFFA66CFF), 20, 0.5),
      ),
      // Right mid - orange dot
      Positioned(
        top: height * 0.55,
        right: width * 0.1,
        child: _buildAnimatedShape(const Color(0xFFFFB347), 15, 4),
      ),
      // Bottom left - pink bar
      Positioned(
        bottom: height * 0.15,
        left: width * 0.1,
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
      // Bottom center-left - cyan bar
      Positioned(
        bottom: height * 0.08,
        left: width * 0.3,
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
      // Bottom right - yellow dot
      Positioned(
        bottom: height * 0.1,
        right: width * 0.12,
        child: _buildAnimatedShape(const Color(0xFFFFE066), 20, 5),
      ),
      // Bottom right corner - coral
      Positioned(
        bottom: height * 0.2,
        right: width * 0.05,
        child: _buildAnimatedShape(const Color(0xFFFF7675), 12, 6),
      ),
    ];
  }

  Widget _buildAnimatedShape(Color color, double size, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            // Alternate pulse direction based on index
            final pulseValue = index.isEven
                ? _pulseAnimation.value
                : 2 - _pulseAnimation.value;
            return Transform.scale(scale: value * pulseValue, child: child);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.35),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeardrop(Color color, double size, double baseAngle) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        // Slow subtle rotation
        final rotationAngle = baseAngle + (_rotateAnimation.value * 0.3);
        return Transform.rotate(angle: rotationAngle, child: child);
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
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterIllustration(BoxConstraints constraints) {
    final size = constraints.maxWidth * 0.7;
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Container(
        width: size.clamp(280.0, 450.0),
        height: size.clamp(280.0, 450.0),
        padding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated background glow with pulse
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
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
                );
              },
            ),
            // Main dashboard illustration
            _buildDashboardIllustration(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardIllustration() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main card with chart
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
              // Header row
              Row(
                children: [
                  const AppLogo.small(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Monitor your KPI',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chart bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildChartBar(45, const Color(0xFF4A6CF7)),
                  _buildChartBar(70, const Color(0xFF6BCB77)),
                  _buildChartBar(55, const Color(0xFFFFB347)),
                  _buildChartBar(85, const Color(0xFF4A6CF7)),
                  _buildChartBar(40, const Color(0xFFA66CFF)),
                  _buildChartBar(65, const Color(0xFF6BCB77)),
                ],
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Revenue', '฿2.5M', const Color(0xFF6BCB77)),
                  _buildStatItem('Orders', '1,240', const Color(0xFF4A6CF7)),
                  _buildStatItem('Growth', '+12%', const Color(0xFFFFB347)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Floating badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFloatingBadge(
              Icons.trending_up,
              'Analytics',
              const Color(0xFF6BCB77),
            ),
            const SizedBox(width: 12),
            _buildFloatingBadge(Icons.people, 'Teams', const Color(0xFFA66CFF)),
            const SizedBox(width: 12),
            _buildFloatingBadge(
              Icons.assessment,
              'Reports',
              const Color(0xFFFF9F43),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartBar(double height, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: height),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          width: 24,
          height: value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildFloatingBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCard(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _buildProfileBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4A6CF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'Shooting calories correctly',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(AuthState state) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildLoginForm(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthState state) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildLoginForm(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthState state) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            const Center(child: AppLogo.medium()),
            const SizedBox(height: 32),
            // Hello Again Title
            const Text(
              'Hello Again!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),
            // Email/Username Field
            _buildSimpleTextField(
              controller: _usernameController,
              hint: 'Email',
              suffixIcon: Icon(
                Icons.alternate_email,
                color: Colors.grey.shade400,
                size: 20,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อผู้ใช้';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Password Field
            _buildSimpleTextField(
              controller: _passwordController,
              hint: 'Password',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสผ่าน';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Remember Me & Recovery Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                        activeColor: const Color(0xFF4A6CF7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember Me',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Recovery Password',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A6CF7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Login Button
            _buildLoginButton(state),
            const SizedBox(height: 24),
            // Sign in with Google
            _buildGoogleLoginButton(state),
            const SizedBox(height: 40),
            // Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account yet?",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 4),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A6CF7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthState state) {
    final isLoading = state is AuthLoading;

    return ElevatedButton(
      onPressed: isLoading ? null : _onLoginPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A6CF7),
        disabledBackgroundColor: Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildGoogleLoginButton(AuthState state) {
    bool isLoading = state is AuthLoading;
    return OutlinedButton(
      onPressed: isLoading ? null : _onGoogleLoginPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                image: NetworkImage(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png",
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Sign in with Google',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
