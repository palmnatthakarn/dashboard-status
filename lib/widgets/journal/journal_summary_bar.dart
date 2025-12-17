import 'package:flutter/material.dart';

class JournalSummaryBar extends StatelessWidget {
  const JournalSummaryBar({
    super.key,
    required this.totalDebit,
    required this.totalCredit,
  });

  final String totalDebit;
  final String totalCredit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'เดบิต',
            value: totalDebit,
            color: const Color(0xFF3B82F6),
            icon: Icons.arrow_circle_up,
          ),
          const SizedBox(width: 12),
          _SummaryItem(
            label: 'เครดิต',
            value: totalCredit,
            color: const Color(0xFF8B5CF6),
            icon: Icons.arrow_circle_down,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: color)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
