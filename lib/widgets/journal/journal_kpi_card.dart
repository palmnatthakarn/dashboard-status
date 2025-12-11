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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            Text(
              compactFmt.format(value),
              style: TextStyle(
                fontSize: 16,
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
