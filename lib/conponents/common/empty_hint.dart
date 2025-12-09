import 'package:flutter/material.dart';

class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        const Icon(Icons.inbox_outlined, color: Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF475569))),
        ),
      ],
    ),
  );
}