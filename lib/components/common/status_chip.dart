import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: fg.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}