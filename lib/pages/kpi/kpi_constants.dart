import 'package:flutter/material.dart';

/// Color constants for KPI dashboard
class KpiColors {
  // Status colors matching the current implementation
  static const Color totalDocuments = Color(0xFF6366F1); // จำนวน - Indigo
  static const Color waitingKey = Color(0xFF64748B); // รอบันทึกบัญชี - Gray
  static const Color waitingFix = Color(0xFF3B82F6); // รอแก้ไข - Blue
  static const Color assigned = Color(0xFF86595E); // อัปโหลด - Grayish
  static const Color waitingVerify = Color(0xFFF59E0B); // รอตรวจสอบ - Orange
  static const Color completed = Color(0xFF10B981); // สมบูรณ์ - Green
  static const Color cancelled = Color(0xFFEF4444); // ยกเลิก - Red

  // UI colors
  static const Color cardBackground = Colors.white;
  static const Color alternateRow = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFF1F5F9);
  static const Color headerBackground = Color(0xFFF8FAFC);

  // Text colors
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF374151);
  static const Color mutedText = Color(0xFF94A3B8);

  // Avatar colors
  static const List<Color> avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
  ];

  // Delay step colors
  static const Color delayUpload = Color(
    0xFFEF4444,
  ); // 🔴 อัปโหลด - Red (worst)
  static const Color delayVerify = Color(0xFFF59E0B); // 🟡 ตรวจสอบ - Yellow
  static const Color delayRecord = Color(0xFFF97316); // 🟠 บันทึก - Orange

  // Incentive colors
  static const Color incentivePass = Color(0xFF10B981); // ✅ ผ่าน - Green
  static const Color incentiveFail = Color(0xFFEF4444); // ❌ ไม่ผ่าน - Red
}

/// Dimension constants for KPI dashboard
class KpiDimensions {
  static const double avatarRadius = 16.0;
  static const double avatarSpacing = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double rowPadding = 16.0;
  static const double rowVerticalPadding = 16.0;
  static const double headerPadding = 12.0;
  static const double expandIconWidth = 40.0;

  // Calculated values
  static const double avatarTotalWidth =
      (avatarRadius * 2) + avatarSpacing; // 44.0
}
