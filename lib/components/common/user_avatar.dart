import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double fontScale;
  final double radius;
  final List<Color>? colorPalette;

  const UserAvatar({
    super.key,
    required this.name,
    this.fontScale = 1.0,
    this.radius = 18.0, // Default equivalent to KPI Dimensions
    this.colorPalette,
  });

  Color _getAvatarColor(String name) {
    // Default palette if none provided
    final palette =
        colorPalette ??
        [
          const Color(0xFF3B82F6), // Blue
          const Color(0xFFEF4444), // Red
          const Color(0xFF10B981), // Green
          const Color(0xFFF59E0B), // Orange
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEC4899), // Pink
          const Color(0xFF6366F1), // Indigo
          const Color(0xFF14B8A6), // Teal
        ];
    return palette[name.hashCode % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAvatarColor(name);

    return CircleAvatar(
      radius: radius * fontScale,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Text(
        name.isNotEmpty ? name.substring(0, 1) : '?',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: (radius * 0.77) * fontScale, // Approx 14 for radius 18
        ),
      ),
    );
  }
}
