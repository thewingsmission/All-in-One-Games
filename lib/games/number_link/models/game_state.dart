import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/constants/gameplay_palette.dart';
import 'level.dart';
import 'point.dart';
import 'cell_style.dart';

class GameState extends ChangeNotifier {
  Level? _currentLevel;
  List<List<String>> _playerGrid = [];
  Map<String, Color> _colorMapping = {};
  Map<String, Color> _secondaryColorMapping = {}; // Secondary color for glow skin Lxb layer
  String? _currentDrawingColor;
  int _cumulativeScore = 0;
  String _difficulty = 'very_easy';
  Set<String> _lockedCells = {}; // Track cells that are locked (from hints)
  Set<String> _solvedColors = {}; // Track colors that have been solved via hints
  CellStyle _cellStyle = CellStyle.numbered;
  int _currentLevelNumber = 1; // Track current level in endless mode
  bool _hintUsedThisLevel = false; // Track if hint was used in current level
  // TEMPORARY: for testing - all skins unlocked; revert to { numbered, square } when done
  Set<CellStyle> _unlockedSkins = CellStyle.values.toSet();
  // Set<CellStyle> _unlockedSkins = { CellStyle.numbered, CellStyle.square };
  bool _isPuzzleFrozen = false; // Track if puzzle is solved and frozen

  Level? get currentLevel => _currentLevel;
  List<List<String>> get playerGrid => _playerGrid;
  Map<String, Color> get colorMapping => _colorMapping;
  Map<String, Color> get secondaryColorMapping => _secondaryColorMapping;
  String? get currentDrawingColor => _currentDrawingColor;
  int get cumulativeScore => _cumulativeScore;
  String get difficulty => _difficulty;
  Set<String> get solvedColors => _solvedColors; // Expose solved colors
  CellStyle get cellStyle => _cellStyle;
  int get currentLevelNumber => _currentLevelNumber;
  bool get hintUsedThisLevel => _hintUsedThisLevel;
  Set<CellStyle> get unlockedSkins => _unlockedSkins;
  bool get isPuzzleFrozen => _isPuzzleFrozen;

  void setDifficulty(String diff) {
    _difficulty = diff;
    notifyListeners();
  }

  void setCellStyle(CellStyle style) {
    _cellStyle = style;
    notifyListeners();
  }

  void loadLevel(Level level) {
    _currentLevel = level;
    _playerGrid = List.generate(
      level.height,
      (row) => List.generate(level.width, (col) => '-'),
    );

    // Set nodes from question grid
    final questionGrid = level.questionGrid;
    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        if (questionGrid[row][col] != '-') {
          _playerGrid[row][col] = questionGrid[row][col];
        }
      }
    }

    // Generate random colors for each unique character
    _generateColorMapping(level);
    _currentDrawingColor = null;
    _lockedCells.clear(); // Clear locked cells for new level
    _solvedColors.clear(); // Clear solved colors for new level
    _hintUsedThisLevel = false; // Reset hint usage for new level
    _isPuzzleFrozen = false; // Unfreeze puzzle for new level
    notifyListeners();
  }
  
  void advanceToNextLevel() {
    _currentLevelNumber++;
    notifyListeners();
  }
  
  void resetLevelNumber() {
    _currentLevelNumber = 1;
    notifyListeners();
  }
  
  void setLevelNumber(int level) {
    _currentLevelNumber = level;
    notifyListeners();
  }
  
  void unlockAllSkins() {
    _unlockedSkins = {
      CellStyle.numbered,
      CellStyle.square,
    };
    notifyListeners();
  }
  
  /// Check if there are any newly unlocked skins for the current level.
  /// Returns null if no new skins, otherwise returns the newly unlocked skin.
  /// TEMPORARY: disabled for testing - no level-based unlock.
  CellStyle? checkForNewlyUnlockedSkin() {
    return null; // TEMPORARY: skip level-based skin unlock for tests
    // final level = _currentLevelNumber;
    // if (level == 11 && !_unlockedSkins.contains(CellStyle.strip)) { ... }
    // ... (restore when done testing)
  }
  
  /// Unlock all skins that should be available for the current level
  void unlockSkinsForCurrentLevel() {
    final level = _currentLevelNumber;
    
    // Unlock all skins based on current level
    if (level >= 11) {
      _unlockedSkins.add(CellStyle.strip);
    }
    if (level >= 31) {
      _unlockedSkins.add(CellStyle.glow);
    }
    notifyListeners();
  }
  
  /// Check if a skin is unlocked
  bool isSkinUnlocked(CellStyle style) {
    return _unlockedSkins.contains(style);
  }
  
  /// Freeze the puzzle (prevent further modifications)
  void freezePuzzle() {
    _isPuzzleFrozen = true;
    notifyListeners();
  }

  void _generateColorMapping(Level level) {
    // Gameplay palette: 20 colors (max 20 lines). All skins use primary from these 20.
    final colors = GameplayPalette.colors;
    _colorMapping.clear();
    _secondaryColorMapping.clear();
    _colorMapping['-'] = Colors.white;
    _secondaryColorMapping['-'] = Colors.white;

    final uniqueChars = <String>[];
    int totalTerminalCells = 0;
    final charCounts = <String, int>{};

    for (int row = 0; row < level.height; row++) {
      for (int col = 0; col < level.width; col++) {
        final char = level.questionGrid[row][col];
        if (char != '-') {
          totalTerminalCells++;
          charCounts[char] = (charCounts[char] ?? 0) + 1;
          if (!uniqueChars.contains(char)) {
            uniqueChars.add(char);
          }
        }
      }
    }

    uniqueChars.sort();

    // Randomly assign 20 palette colors to lines (indices 0–19)
    final indices = List.generate(colors.length, (i) => i)..shuffle(Random());

    debugPrint('=== LEVEL DEBUG ===');
    debugPrint('Source: ${level.sourceFile}, Row: ${level.sourceRowIndex}');
    debugPrint('Size: ${level.width}×${level.height}');
    debugPrint('Score: ${level.score}');
    
    debugPrint('--- Puzzle ---');
    for (int row = 0; row < level.height; row++) {
      debugPrint(level.questionGrid[row].toString());
    }
    
    debugPrint('--- Solution ---');
    for (int row = 0; row < level.height; row++) {
      debugPrint(level.solutionGrid[row].toString());
    }
    debugPrint('=== END LEVEL DEBUG ===');

    for (var i = 0; i < uniqueChars.length; i++) {
      final idx = indices[i % indices.length];
      _colorMapping[uniqueChars[i]] = colors[idx];
      
      // Calculate secondary color for glow skin Lxb layer
      // If primary index < 10, secondary = primary + 10
      // If primary index >= 10, secondary = primary - 10
      final secondaryIdx = idx < 10 ? idx + 10 : idx - 10;
      _secondaryColorMapping[uniqueChars[i]] = colors[secondaryIdx];
    }
  }

  void startDrawing(String color) {
    _currentDrawingColor = color;
    notifyListeners();
  }

  void stopDrawing() {
    _currentDrawingColor = null;
    notifyListeners();
  }

  bool setCell(int row, int col, String value) {
    if (row < 0 || row >= _playerGrid.length) return false;
    if (col < 0 || col >= _playerGrid[0].length) return false;

    // Don't override nodes (endpoints)
    if (_isNode(row, col)) return false;

    // Don't override locked cells (from hints)
    final cellKey = '$row,$col';
    if (_lockedCells.contains(cellKey)) return false;

    _playerGrid[row][col] = value;
    notifyListeners();
    return true;
  }

  bool _isNode(int row, int col) {
    if (_currentLevel == null) return false;
    final questionGrid = _currentLevel!.questionGrid;
    return questionGrid[row][col] != '-';
  }

  void reset() {
    if (_currentLevel == null) return;

    final questionGrid = _currentLevel!.questionGrid;
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        final cellKey = '$row,$col';
        // Only clear cells that are NOT nodes and NOT locked (from hints)
        if (!_isNode(row, col) && !_lockedCells.contains(cellKey)) {
          _playerGrid[row][col] = '-';
        }
      }
    }
    // Do NOT clear locked cells - keep hinted lines visible
    // Do NOT clear solved colors - keep track of which colors were hinted
    // Do NOT reset hint usage - hint remains used
    notifyListeners();
  }

  bool checkWin() {
    if (_currentLevel == null) return false;

    // Check if all cells are filled
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        if (_playerGrid[row][col] == '-') return false;
      }
    }

    // Check if no crossing (each cell has max 2 same-color neighbors)
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        final char = _playerGrid[row][col];
        int neighbors = 0;

        if (row > 0 && _playerGrid[row - 1][col] == char) neighbors++;
        if (row < _playerGrid.length - 1 && _playerGrid[row + 1][col] == char) {
          neighbors++;
        }
        if (col > 0 && _playerGrid[row][col - 1] == char) neighbors++;
        if (col < _playerGrid[row].length - 1 && _playerGrid[row][col + 1] == char) {
          neighbors++;
        }

        if (neighbors > 2) return false;
      }
    }

    // Check if nodes have exactly 1 neighbor
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        if (_isNode(row, col)) {
          final char = _playerGrid[row][col];
          int neighbors = 0;

          if (row > 0 && _playerGrid[row - 1][col] == char) neighbors++;
          if (row < _playerGrid.length - 1 && _playerGrid[row + 1][col] == char) {
            neighbors++;
          }
          if (col > 0 && _playerGrid[row][col - 1] == char) neighbors++;
          if (col < _playerGrid[row].length - 1 && _playerGrid[row][col + 1] == char) {
            neighbors++;
          }

          if (neighbors != 1) return false;
        }
      }
    }

    // CRITICAL FIX: Compare player grid with solution grid
    // The above checks only ensure structural validity but don't verify correctness
    final solutionGrid = _currentLevel!.solutionGrid;
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        if (_playerGrid[row][col] != solutionGrid[row][col]) {
          debugPrint('=== SOLUTION MISMATCH ===');
          debugPrint('Position ($row, $col): Player=${_playerGrid[row][col]}, Solution=${solutionGrid[row][col]}');
          debugPrint('Player Grid:');
          for (int r = 0; r < _playerGrid.length; r++) {
            debugPrint(_playerGrid[r].toString());
          }
          debugPrint('Solution Grid:');
          for (int r = 0; r < solutionGrid.length; r++) {
            debugPrint(solutionGrid[r].toString());
          }
          debugPrint('=== END MISMATCH ===');
          return false;
        }
      }
    }

    return true;
  }

  void applyHint(String colorToSolve) {
    if (_currentLevel == null) return;

    final solutionPaths = _currentLevel!.solutionPaths;
    final path = solutionPaths[colorToSolve];
    if (path == null) return;

    // Clear current path for this color (but only unlocked cells)
    for (int row = 0; row < _playerGrid.length; row++) {
      for (int col = 0; col < _playerGrid[row].length; col++) {
        final cellKey = '$row,$col';
        if (!_isNode(row, col) && 
            _playerGrid[row][col] == colorToSolve && 
            !_lockedCells.contains(cellKey)) {
          _playerGrid[row][col] = '-';
        }
      }
    }

    // Apply solution path and lock these cells
    for (final pos in path) {
      if (!_isNode(pos.y, pos.x)) {
        _playerGrid[pos.y][pos.x] = colorToSolve;
        _lockedCells.add('${pos.y},${pos.x}'); // Lock this cell
      }
    }

    // Mark this color as solved
    _solvedColors.add(colorToSolve);
    _hintUsedThisLevel = true; // Mark hint as used

    notifyListeners();
  }

  void addScore(int points) {
    _cumulativeScore += points;
    notifyListeners();
  }

  void setCumulativeScore(int score) {
    _cumulativeScore = score;
    notifyListeners();
  }

  // Progress saving/loading methods
  Future<void> loadProgress(dynamic storageService) async {
    try {
      debugPrint('Loading progress...');
      
      // Load current level
      _currentLevelNumber = await storageService.getCurrentLevel();
      debugPrint('Loaded level: $_currentLevelNumber');
      
      // Load unlocked skins
      final skinStrings = await storageService.getUnlockedSkins();
      _unlockedSkins = skinStrings.map((s) => _stringToSkin(s)).toSet().cast<CellStyle>();
      // TEMPORARY: for testing - force all skins unlocked; remove next line when done
      _unlockedSkins = CellStyle.values.toSet();
      debugPrint('Loaded skins: $skinStrings');
      
      // Load current skin
      final currentSkinString = await storageService.getCurrentSkin();
      _cellStyle = _stringToSkin(currentSkinString);
      debugPrint('Loaded current skin: $currentSkinString');
      
      notifyListeners();
      debugPrint('Progress loaded successfully');
    } catch (e) {
      debugPrint('Error loading progress: $e');
      // Use defaults on error
      _currentLevelNumber = 1;
      _unlockedSkins = {
        CellStyle.numbered, 
        CellStyle.square,
      };
      _cellStyle = CellStyle.numbered;
      notifyListeners();
    }
  }

  Future<void> saveProgress(dynamic storageService) async {
    // Save current level
    await storageService.saveCurrentLevel(_currentLevelNumber);
    
    // Save unlocked skins
    final skinStrings = _unlockedSkins.map((s) => _skinToString(s)).toList();
    await storageService.saveUnlockedSkins(skinStrings);
    
    // Save current skin
    await storageService.saveCurrentSkin(_skinToString(_cellStyle));
  }

  // Helper methods to convert between CellStyle and String
  CellStyle _stringToSkin(String skinString) {
    switch (skinString) {
      case 'numbered':
        return CellStyle.numbered;
      case 'square':
        return CellStyle.square;
      case 'strip':
        return CellStyle.strip;
      case 'glow':
        return CellStyle.glow;
      default:
        return CellStyle.numbered;
    }
  }

  String _skinToString(CellStyle skin) {
    switch (skin) {
      case CellStyle.numbered:
        return 'numbered';
      case CellStyle.square:
        return 'square';
      case CellStyle.strip:
        return 'strip';
      case CellStyle.glow:
        return 'glow';
    }
  }
}
