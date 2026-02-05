import 'dart:math';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/level.dart';

class LevelService {
  final Map<String, List<Level>> _levels = {};
  bool _initialized = false;
  
  /// Get a difficulty based on the current level number.
  /// 
  /// Level progression:
  /// - Level 1-5: very_easy
  /// - Level 6-25: easy
  /// - Level 26-45: normal
  /// - Level 46-65: hard
  /// - Level 66+: very_hard
  String getDifficultyForLevel(int levelNumber) {
    if (levelNumber <= 5) {
      return 'very_easy';
    } else if (levelNumber <= 25) {
      return 'easy';
    } else if (levelNumber <= 45) {
      return 'normal';
    } else if (levelNumber <= 65) {
      return 'hard';
    } else {
      return 'very_hard';
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final difficulties = ['very_easy', 'easy', 'normal', 'hard', 'very_hard'];

    print('🎮 Initializing Level Service...');
    
    for (final difficulty in difficulties) {
      try {
        print('📂 Loading levels for difficulty: $difficulty');
        final csvString = await rootBundle.loadString('assets/games/number link/data/levels/$difficulty.csv');
        print('✅ CSV loaded for $difficulty: ${csvString.length} characters');
        
        final rows = const CsvToListConverter(
          fieldDelimiter: ',',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(csvString);

        // Skip header row
        final levels = <Level>[];
        for (int i = 1; i < rows.length; i++) {
          try {
            final row = rows[i];
            if (row.length >= 5) {
              levels.add(Level.fromCsvRow([
                row[0].toString(),
                row[1].toString(),
                row[2].toString(),
                row[3].toString(),
                row[4].toString(),
              ], filename: '$difficulty.csv', rowIndex: i + 1));
            }
          } catch (e) {
            // Skip invalid rows
            print('⚠️ Error parsing row $i in $difficulty.csv: $e');
            continue;
          }
        }
        _levels[difficulty] = levels;
        print('✅ Loaded ${levels.length} levels for $difficulty');
      } catch (e) {
        // If file doesn't exist or error loading, create empty list
        print('❌ Error loading $difficulty.csv: $e');
        _levels[difficulty] = [];
      }
    }

    _initialized = true;
    print('🎮 Level Service initialized with ${_levels.keys.length} difficulty levels');
  }

  Level? getRandomLevel(String difficulty) {
    final levels = _levels[difficulty];
    if (levels == null || levels.isEmpty) return null;

    final random = Random();
    return levels[random.nextInt(levels.length)];
  }

  Level? getLevel(String difficulty, int index) {
    final levels = _levels[difficulty];
    if (levels == null || index < 0 || index >= levels.length) return null;
    return levels[index];
  }

  int getLevelCount(String difficulty) {
    return _levels[difficulty]?.length ?? 0;
  }

  List<String> getDifficulties() {
    return ['very_easy', 'easy', 'normal', 'hard', 'very_hard'];
  }

  String getDifficultyDisplayName(String difficulty) {
    switch (difficulty) {
      case 'very_easy':
        return 'Very Easy';
      case 'easy':
        return 'Easy';
      case 'normal':
        return 'Normal';
      case 'hard':
        return 'Hard';
      case 'very_hard':
        return 'Very Hard';
      default:
        return difficulty;
    }
  }
}
