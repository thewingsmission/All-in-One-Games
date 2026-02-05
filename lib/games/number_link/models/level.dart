class Level {
  final String flattenedSolution;
  final int lineQuantity;
  final int width;
  final int height;
  final int score;
  final String sourceFile;
  final int sourceRowIndex;

  Level({
    required this.flattenedSolution,
    required this.lineQuantity,
    required this.width,
    required this.height,
    required this.score,
    this.sourceFile = 'unknown',
    this.sourceRowIndex = -1,
  });

  factory Level.fromCsvRow(List<String> row, {String filename = 'unknown', int rowIndex = -1}) {
    return Level(
      flattenedSolution: row[0],
      lineQuantity: int.parse(row[1]),
      width: int.parse(row[3]),  // Data is still in position 3 (4th column)
      height: int.parse(row[2]), // Data is still in position 2 (3rd column)
      score: int.parse(row[4]),
      sourceFile: filename,
      sourceRowIndex: rowIndex,
    );
  }

  List<List<String>> get solutionGrid {
    final grid = List.generate(
      height,
      (row) => List.generate(width, (col) => ''),
    );

    for (int i = 0; i < flattenedSolution.length; i++) {
      final row = i ~/ width;
      final col = i % width;
      grid[row][col] = flattenedSolution[i];
    }

    return grid;
  }

  List<List<String>> get questionGrid {
    final solution = solutionGrid;
    final question = List.generate(
      height,
      (row) => List.generate(width, (col) => '-'),
    );

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final char = solution[row][col];
        int neighbors = 0;

        // Check all four directions
        if (row > 0 && solution[row - 1][col] == char) neighbors++;
        if (row < height - 1 && solution[row + 1][col] == char) neighbors++;
        if (col > 0 && solution[row][col - 1] == char) neighbors++;
        if (col < width - 1 && solution[row][col + 1] == char) neighbors++;

        // Nodes have only 1 neighbor (endpoints)
        if (neighbors == 1) {
          question[row][col] = char;
        }
      }
    }

    return question;
  }

  Map<String, List<Position>> get solutionPaths {
    final paths = <String, List<Position>>{};
    final solution = solutionGrid;

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final char = solution[row][col];
        paths.putIfAbsent(char, () => []);
        paths[char]!.add(Position(col, row));
      }
    }

    return paths;
  }
}

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
