import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF0B4D8A);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF17A2B8);
  static const Color successColor = Color(0xFF28A745);
  static const Color dangerColor = Color(0xFFDC3545);
  static const Color secondaryColor = Color(0xFF6C757D);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
  );
}