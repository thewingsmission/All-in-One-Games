import 'package:flutter/material.dart';

/// App-wide color palette (inspired by Number Link web game)
class AppColors {
  // Primary colors - Blue theme from Number Link
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Accent colors - Vibrant gradient colors
  static const Color accent = Color(0xFF4CAF50);
  static const Color accentDark = Color(0xFF388E3C);
  
  // Background colors - Clean white/light
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF424242);
  static const Color lightBlueBackground = Color(0xFFE3F2FD);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Game card colors (for menu)
  static const Color cardBackground = Colors.white;
  static const Color cardShadow = Color(0x1F000000);
  
  // Leaderboard colors
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  
  // Difficulty colors (from Number Link)
  static const Color veryEasy = Color(0xFF81C784);
  static const Color easy = Color(0xFF8BC34A);
  static const Color normal = Color(0xFF2196F3);
  static const Color intermediate = Color(0xFFFFB74D);
  static const Color hard = Color(0xFFFF9800);
  static const Color veryHard = Color(0xFFE53935);
}
