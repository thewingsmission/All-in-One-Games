import 'dart:math';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/sudoku_puzzle.dart';

class PuzzleService {
  static List<SudokuPuzzle>? _allPuzzles;
  static bool _isLoading = false;

  static Future<void> loadPuzzles() async {
    if (_allPuzzles != null || _isLoading) return;
    
    _isLoading = true;
    try {
      print('Starting to load CSV...');
      final csvString = await rootBundle.loadString('assets/games/sudoku/sudoku_5000.csv');
      print('CSV loaded, length: ${csvString.length}');
      
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,  // Prevent converting large numbers to scientific notation
      ).convert(csvString);
      print('CSV parsed, rows: ${csvData.length}');
      
      // Skip header row
      _allPuzzles = csvData.skip(1).map((row) {
        try {
          return SudokuPuzzle.fromCsvRow(row);
        } catch (e) {
          print('Error parsing row: $e');
          return null;
        }
      }).where((puzzle) => puzzle != null).cast<SudokuPuzzle>().toList();
      
      print('Loaded ${_allPuzzles!.length} puzzles');
    } catch (e, stackTrace) {
      print('Error loading puzzles: $e');
      print('Stack trace: $stackTrace');
      _allPuzzles = [];
    } finally {
      _isLoading = false;
    }
  }

  static Future<SudokuPuzzle> getRandomPuzzle({String? difficultyLevel}) async {
    await loadPuzzles();
    
    if (_allPuzzles == null || _allPuzzles!.isEmpty) {
      throw Exception('No puzzles loaded');
    }

    List<SudokuPuzzle> filteredPuzzles;
    
    if (difficultyLevel != null) {
      filteredPuzzles = _allPuzzles!.where((puzzle) {
        return puzzle.difficultyLevel == difficultyLevel;
      }).toList();
    } else {
      filteredPuzzles = _allPuzzles!;
    }

    if (filteredPuzzles.isEmpty) {
      throw Exception('No puzzles found for difficulty: $difficultyLevel');
    }

    final random = Random();
    return filteredPuzzles[random.nextInt(filteredPuzzles.length)];
  }

  static int getPuzzleCount({String? difficultyLevel}) {
    if (_allPuzzles == null) return 0;

    if (difficultyLevel != null) {
      return _allPuzzles!.where((puzzle) {
        return puzzle.difficultyLevel == difficultyLevel;
      }).length;
    }

    return _allPuzzles!.length;
  }
}
