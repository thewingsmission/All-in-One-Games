import 'package:flutter/material.dart';

/// Gameplay palette: 20 colors (10 main + 10 pale), same order as design guide.
/// Order: Red, Cyan, Green, Blue, Orange, Pink, Magenta, Yellow, Turquoise, Purple,
/// then Pale Red … Pale Purple.
class GameplayPalette {
  GameplayPalette._();

  /// 10 main colors (design order 1,3,9,8,5,2,6,4,10,7)
  static const List<Color> mainColors = [
    Color(0xFFFF0040), // Red
    Color(0xFF00D9FF), // Cyan
    Color(0xFF00FF41), // Green
    Color(0xFF0080FF), // Blue
    Color(0xFFFF6600), // Orange
    Color(0xFFFF3399), // Pink
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FFAA), // Turquoise
    Color(0xFF9900FF), // Purple
  ];

  /// 10 pale colors (same order as main)
  static const List<Color> paleColors = [
    Color(0xFFFF99AA), // Pale Red
    Color(0xFF99EEFF), // Pale Cyan
    Color(0xFF99FFAA), // Pale Green
    Color(0xFF99CCFF), // Pale Blue
    Color(0xFFFFBB88), // Pale Orange
    Color(0xFFFF99DD), // Pale Pink
    Color(0xFFFF99FF), // Pale Magenta
    Color(0xFFFFFF99), // Pale Yellow
    Color(0xFF99FFDD), // Pale Turquoise
    Color(0xFFDD99FF), // Pale Purple
  ];

  /// 20 colors for game mapping: main 0–9 then pale 10–19 (same order as design guide).
  static List<Color> get colors => [...mainColors, ...paleColors];

  /// Names for the 20 colors (design order): Red, Cyan, Green, Blue, Orange, Pink, Magenta, Yellow, Turquoise, Purple, then Pale *.
  static const List<String> colorNames = [
    'Red', 'Cyan', 'Green', 'Blue', 'Orange', 'Pink', 'Magenta', 'Yellow', 'Turquoise', 'Purple',
    'Pale Red', 'Pale Cyan', 'Pale Green', 'Pale Blue', 'Pale Orange', 'Pale Pink', 'Pale Magenta', 'Pale Yellow', 'Pale Turquoise', 'Pale Purple',
  ];

  /// 20 pale colors for glow skin: pale for each of the 20 (pale of pale = same pale)
  static List<Color> get paleForGlow => [...paleColors, ...paleColors];

  /// Returns hex string #RRGGBB for logging (e.g. #00FFAA for Turquoise).
  static String toHex(Color c) => '#${(c.value & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
}
