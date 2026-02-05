class SudokuPuzzle {
  final String puzzle;
  final String solution;
  final int difficulty;
  final String difficultyLevel;

  SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.difficultyLevel,
  });

  factory SudokuPuzzle.fromCsvRow(List<dynamic> row) {
    return SudokuPuzzle(
      puzzle: row[0].toString().trim(),
      solution: row[1].toString().trim(),
      difficulty: int.parse(row[2].toString().trim()),
      difficultyLevel: row[3].toString().trim(),
    );
  }

  List<List<int>> getPuzzleGrid() {
    return _stringToGrid(puzzle);
  }

  List<List<int>> getSolutionGrid() {
    return _stringToGrid(solution);
  }

  List<List<int>> _stringToGrid(String str) {
    if (str.length != 81) {
      throw FormatException('Invalid puzzle string length: ${str.length}, expected 81');
    }
    
    final grid = <List<int>>[];
    for (int i = 0; i < 9; i++) {
      final row = <int>[];
      for (int j = 0; j < 9; j++) {
        final char = str[i * 9 + j];
        final value = int.tryParse(char);
        if (value == null) {
          throw FormatException('Invalid character "$char" at position ${i * 9 + j}');
        }
        row.add(value);
      }
      grid.add(row);
    }
    return grid;
  }

}

class DifficultyLevel {
  static const String veryEasy = 'Very Easy';
  static const String easy = 'Easy';
  static const String medium = 'Medium';
  static const String hard = 'Hard';
  static const String expert = 'Expert';

  static List<String> get all => [veryEasy, easy, medium, hard, expert];
}
