import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalKpiCard extends StatelessWidget {
  const JournalKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.compactFmt,
    this.bold = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final NumberFormat compactFmt;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            Text(
              compactFmt.format(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
