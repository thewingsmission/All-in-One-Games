import 'package:flutter/material.dart';

/// Each skin defines 3 major colors: correct (green), present (yellow), absent (gray).
class WordleSkin {
  final String name;
  final Color correct;
  final Color present;
  final Color absent;

  const WordleSkin({
    required this.name,
    required this.correct,
    required this.present,
    required this.absent,
  });
}

/// Built-in Wordle skins (each with 3 major colors).
final List<WordleSkin> wordleSkins = [
  const WordleSkin(
    name: 'Classic',
    correct: Color(0xFF6AAA64),
    present: Color(0xFFC9B458),
    absent: Color(0xFF787C7E),
  ),
  const WordleSkin(
    name: 'Ocean',
    correct: Color(0xFF1E88E5),
    present: Color(0xFF26C6DA),
    absent: Color(0xFF546E7A),
  ),
  const WordleSkin(
    name: 'Sunset',
    correct: Color(0xFFE53935),
    present: Color(0xFFFFB74D),
    absent: Color(0xFF8D6E63),
  ),
  const WordleSkin(
    name: 'Forest',
    correct: Color(0xFF43A047),
    present: Color(0xFF7CB342),
    absent: Color(0xFF5D4037),
  ),
  const WordleSkin(
    name: 'Berry',
    correct: Color(0xFF8E24AA),
    present: Color(0xFFAB47BC),
    absent: Color(0xFF5C6BC0),
  ),
];
