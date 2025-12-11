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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'เดบิต',
            value: totalDebit,
            color: const Color(0xFF3B82F6),
            icon: Icons.arrow_circle_up,
          ),
          const SizedBox(width: 16),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
