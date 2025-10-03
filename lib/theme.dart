import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color white = Color.fromRGBO(253, 253, 254, 1);
  static const Color skyBlue = Color.fromRGBO(73, 149, 199, 1);
  static const Color grayishBlue = Color.fromRGBO(182, 192, 213, 1);
  static const Color navyBlue = Color.fromRGBO(58, 64, 144, 1);
  static const Color green = Color.fromRGBO(134, 194, 107, 1);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: ColorScheme.light(
      background: AppColors.white,
      surface: AppColors.white,
      primary: AppColors.skyBlue,
      secondary: AppColors.navyBlue,
      tertiary: AppColors.green,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.skyBlue,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
