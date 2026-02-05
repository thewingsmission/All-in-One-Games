import 'package:flutter/material.dart';

class AppTheme {
  // Number Link inspired color palette
  static const Color backgroundColor = Color(0xFF000000); // Pure black
  static const Color primaryCyan = Color(0xFF00D9FF); // Dialogs, highlights
  static const Color primaryOrange = Color(0xFFFF6600); // Buttons, accents
  static const Color primaryMagenta = Color(0xFFFF00FF); // Completions
  static const Color neonGreen = Color(0xFF00FF41); // Leaderboard, success
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFFB0B0B0);

  // Number Link theme
  static ThemeData numberLinkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryCyan,
      secondary: primaryOrange,
      surface: backgroundColor,
      background: backgroundColor,
      error: Color(0xFFFF0000),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Arial',
        fontWeight: FontWeight.w900,
        fontSize: 28,
        letterSpacing: 1.5,
        color: textWhite,
      ),
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
        color: textWhite,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: textWhite,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: textWhite,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textWhite,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        letterSpacing: 0.5,
        color: textWhite,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        letterSpacing: 0.3,
        color: textGrey,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: primaryCyan, width: 2),
      ),
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: primaryCyan, width: 2),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: primaryCyan,
      ),
    ),
  );
  
  // Keep old theme for backward compatibility during transition
  static ThemeData lightTheme = numberLinkTheme;
}

/// Color constants for various games
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF00D9FF); // Neon cyan
  static const Color accent = Color(0xFFFF00FF); // Neon magenta
  static const Color background = Color(0xFF000000); // Pure black
  static const Color lightBlueBackground = Color(0xFF1C3A52); // For headers
  
  // Wordle-specific colors
  static const Color correctGreen = Color(0xFF6AAA64); // Correct position
  static const Color presentYellow = Color(0xFFC9B458); // Wrong position
  static const Color absentGray = Color(0xFF787C7E); // Not in word
}
