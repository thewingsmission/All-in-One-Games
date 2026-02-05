import 'dart:math';
import 'package:flutter/services.dart';

class WordListService {
  final Map<int, List<String>> _wordLists = {};
  bool _initialized = false;
  
  /// Initialize word lists for given word lengths
  Future<void> initialize({List<int> wordLengths = const [3, 4, 5, 6, 7, 8, 9, 10]}) async {
    if (_initialized) return;
    
    for (final length in wordLengths) {
      try {
        final csvString = await rootBundle.loadString(
          'assets/games/wordle/data/word_tables/$length-word-Table.csv'
        );
        
        // Parse CSV - each line is a word followed by comma
        final words = csvString
            .split('\n')
            .map((line) => line.trim().replaceAll(',', ''))
            .where((word) => word.length == length)
            .map((word) => word.toUpperCase())
            .toList();
        
        _wordLists[length] = words;
        print('✅ Loaded ${words.length} words of length $length');
      } catch (e) {
        print('❌ Error loading $length-letter words: $e');
        _wordLists[length] = [];
      }
    }
    
    _initialized = true;
    print('✅ WordListService initialized with ${_wordLists.keys.length} word lengths');
  }
  
  /// Get a random word of specified length
  String? getRandomWord(int length) {
    final words = _wordLists[length];
    if (words == null || words.isEmpty) {
      print('⚠️ No words found for length $length');
      return null;
    }
    return words[Random().nextInt(words.length)];
  }
  
  /// Check if a word exists in the list
  bool isValidWord(String word, int length) {
    final words = _wordLists[length];
    if (words == null) return false;
    return words.contains(word.toUpperCase());
  }
  
  /// Get word count for a specific length
  int getWordCount(int length) {
    return _wordLists[length]?.length ?? 0;
  }
  
  /// Get all available word lengths
  List<int> getAvailableLengths() {
    return _wordLists.keys.where((length) => _wordLists[length]!.isNotEmpty).toList()..sort();
  }
}
