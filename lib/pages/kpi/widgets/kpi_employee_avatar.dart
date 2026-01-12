import 'package:flutter/material.dart';
import '../kpi_constants.dart';

/// Employee avatar widget with initial
class KpiEmployeeAvatar extends StatelessWidget {
  final String name;
  final double fontScale;

  const KpiEmployeeAvatar({
    super.key,
    required this.name,
    required this.fontScale,
  });

  Color _getAvatarColor(String name) {
    return KpiColors.avatarColors[name.hashCode %
        KpiColors.avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAvatarColor(name);

    return CircleAvatar(
      radius: KpiDimensions.avatarRadius * fontScale,
      backgroundColor: color.withValues(alpha: 0.1),
      child: Text(
        name.substring(0, 1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14 * fontScale,
        ),
      ),
    );
  }
}
