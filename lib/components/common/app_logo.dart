import 'package:flutter/material.dart';

/// A customizable logo widget with stacked horizontal bars
/// that creates a modern, minimal brand identity.
class AppLogo extends StatelessWidget {
  /// Size of the logo container (width and height)
  final double size;

  /// Whether to show the logo on a gradient background
  final bool showBackground;

  /// Background color (used when showBackground is true and useGradient is false)
  final Color? backgroundColor;

  /// Whether to use gradient background
  final bool useGradient;

  /// Color of the bars (default: primary blue)
  final Color barColor;

  /// Border radius of the container
  final double borderRadius;

  /// Whether to show shadow
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 60,
    this.showBackground = true,
    this.backgroundColor,
    this.useGradient = false,
    this.barColor = const Color(0xFF4A6CF7),
    this.borderRadius = 12,
    this.showShadow = true,
  });

  /// Creates a small logo suitable for headers and icons
  const AppLogo.small({
    super.key,
    this.showBackground = true,
    this.useGradient = true,
    this.backgroundColor,
    this.showShadow = false,
  }) : size = 40,
       barColor = Colors.white,
       borderRadius = 10;

  /// Creates a medium logo for general use
  const AppLogo.medium({
    super.key,
    this.showBackground = true,
    this.useGradient = false,
    this.backgroundColor,
    this.showShadow = true,
  }) : size = 60,
       barColor = const Color(0xFF4A6CF7),
       borderRadius = 12;

  /// Creates a large logo for splash screens and prominent displays
  const AppLogo.large({
    super.key,
    this.showBackground = true,
    this.useGradient = false,
    this.backgroundColor,
    this.showShadow = true,
  }) : size = 80,
       barColor = const Color(0xFF4A6CF7),
       borderRadius = 16;

  @override
  Widget build(BuildContext context) {
    final barWidth1 = size * 0.5;
    final barWidth2 = size * 0.4;
    final barWidth3 = size * 0.3;
    final barHeight = size * 0.1;
    final barSpacing = size * 0.067;

    Widget bars = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: barWidth1,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        ),
        SizedBox(height: barSpacing),
        Container(
          width: barWidth2,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: useGradient ? 0.8 : 0.7),
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        ),
        SizedBox(height: barSpacing),
        Container(
          width: barWidth3,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: useGradient ? 0.6 : 0.4),
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        ),
      ],
    );

    if (!showBackground) {
      return SizedBox(width: size, height: size, child: bars);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: useGradient ? null : (backgroundColor ?? Colors.white),
        gradient: useGradient
            ? const LinearGradient(
                colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
              )
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: bars,
    );
  }
}
