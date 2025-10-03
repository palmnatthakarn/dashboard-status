import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  const Tag({
    super.key,
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}