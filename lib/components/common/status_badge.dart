import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontScale;
  final Color? colorOverride;
  final Color? bgOverride;
  final String? labelOverride;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontScale = 1.0,
    this.colorOverride,
    this.bgOverride,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    Color bg;

    // Use overrides if provided, otherwise derive from status
    if (colorOverride != null && bgOverride != null) {
      color = colorOverride!;
      bg = bgOverride!;
      text = labelOverride ?? status;
    } else {
      switch (status.toLowerCase()) {
        case 'active':
        case 'normal':
          color = const Color(0xFF166534);
          bg = const Color(0xFFDCFCE7);
          text = 'ปกติ';
          break;
        case 'warning':
          color = const Color(0xFF854D0E);
          bg = const Color(0xFFFEF9C3);
          text = 'เฝ้าระวัง';
          break;
        case 'critical':
          color = const Color(0xFF991B1B);
          bg = const Color(0xFFFEE2E2);
          text = 'วิกฤต';
          break;
        case 'completed':
        case 'success':
          color = const Color(0xFF166534);
          bg = const Color(0xFFDCFCE7);
          text = 'เสร็จสิ้น';
          break;
        case 'pending':
        case 'waiting':
          color = const Color(0xFFB45309);
          bg = const Color(0xFFFEF3C7);
          text = 'รอดำเนินการ';
          break;
        case 'cancelled':
        case 'cancel':
          color = const Color(0xFF475569);
          bg = const Color(0xFFF1F5F9);
          text = 'ยกเลิก';
          break;
        case 'inactive':
          color = const Color(0xFF64748B);
          bg = const Color(0xFFF8FAFC);
          text = 'ไม่เคลื่อนไหว';
          break;
        default:
          color = const Color(0xFF475569);
          bg = const Color(0xFFF1F5F9);
          text = status;
      }
    }

    if (labelOverride != null) {
      text = labelOverride!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11 * fontScale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
