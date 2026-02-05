import 'package:flutter/material.dart';

/// Game model representing each mini-game
class GameInfo {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final Color themeColor;
  final bool hasDifficulty;
  final List<String> difficulties;
  final String rules;

  const GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.themeColor,
    required this.hasDifficulty,
    this.difficulties = const [],
    required this.rules,
  });
}
