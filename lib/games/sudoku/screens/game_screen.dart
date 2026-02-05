import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sudoku_puzzle.dart';
import '../services/puzzle_service.dart';

class GameScreen extends StatefulWidget {
  final SudokuPuzzle puzzle;

  const GameScreen({super.key, required this.puzzle});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> _currentGrid;
  late List<List<bool>> _isFixed;
  late List<List<bool>> _isHint; // Track which cells were filled by hints
  int? _selectedRow;
  int? _selectedCol;
  int _hintsUsed = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isComplete = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
    // Request focus when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _currentGrid = widget.puzzle.getPuzzleGrid().map((row) => List<int>.from(row)).toList();
    _isFixed = List.generate(
      9,
      (i) => List.generate(9, (j) => _currentGrid[i][j] != 0),
    );
    _isHint = List.generate(
      9,
      (i) => List.generate(9, (j) => false),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isComplete) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectCell(int row, int col) {
    if (!_isFixed[row][col] && !_isComplete) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _enterNumber(int number) {
    if (_selectedRow != null && _selectedCol != null && !_isComplete) {
      final row = _selectedRow!;
      final col = _selectedCol!;

      if (!_isFixed[row][col]) {
        setState(() {
          _currentGrid[row][col] = number;
          
          // Check if puzzle is complete
          _checkCompletion();
        });
      }
    }
  }

  void _clearCell() {
    if (_selectedRow != null && _selectedCol != null && !_isComplete) {
      final row = _selectedRow!;
      final col = _selectedCol!;

      if (!_isFixed[row][col]) {
        setState(() {
          _currentGrid[row][col] = 0;
        });
      }
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_isComplete) return;

    final key = event.logicalKey;
    
    // Handle space bar for hint
    if (key == LogicalKeyboardKey.space) {
      _useHint();
      return;
    }
    
    if (_selectedRow == null || _selectedCol == null) return;
    
    // Handle number keys (1-9)
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _enterNumber(1);
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _enterNumber(2);
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _enterNumber(3);
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _enterNumber(4);
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _enterNumber(5);
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _enterNumber(6);
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _enterNumber(7);
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _enterNumber(8);
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _enterNumber(9);
    } 
    // Handle backspace/delete to clear cell
    else if (key == LogicalKeyboardKey.backspace || 
             key == LogicalKeyboardKey.delete ||
             key == LogicalKeyboardKey.digit0 || 
             key == LogicalKeyboardKey.numpad0) {
      _clearCell();
    }
    // Handle arrow keys for navigation
    else if (key == LogicalKeyboardKey.arrowUp && _selectedRow! > 0) {
      setState(() {
        _selectedRow = _selectedRow! - 1;
      });
    } else if (key == LogicalKeyboardKey.arrowDown && _selectedRow! < 8) {
      setState(() {
        _selectedRow = _selectedRow! + 1;
      });
    } else if (key == LogicalKeyboardKey.arrowLeft && _selectedCol! > 0) {
      setState(() {
        _selectedCol = _selectedCol! - 1;
      });
    } else if (key == LogicalKeyboardKey.arrowRight && _selectedCol! < 8) {
      setState(() {
        _selectedCol = _selectedCol! + 1;
      });
    }
  }

  void _useHint() {
    if (_selectedRow != null && _selectedCol != null && !_isComplete) {
      final solution = widget.puzzle.getSolutionGrid();
      final row = _selectedRow!;
      final col = _selectedCol!;

      if (!_isFixed[row][col]) {
        setState(() {
          _currentGrid[row][col] = solution[row][col];
          _isFixed[row][col] = true;
          _isHint[row][col] = true; // Mark as hint cell
          _hintsUsed++;
          _checkCompletion();
        });
      }
    }
  }

  void _checkCompletion() {
    final solution = widget.puzzle.getSolutionGrid();
    bool isComplete = true;

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_currentGrid[i][j] != solution[i][j]) {
          isComplete = false;
          break;
        }
      }
      if (!isComplete) break;
    }

    if (isComplete) {
      setState(() {
        _isComplete = true;
      });
      _timer?.cancel();
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00FF41), width: 2), // Green border
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF00FF41), size: 32),
            SizedBox(width: 12),
            Text(
              'PUZZLE SOLVED!',
              style: TextStyle(
                color: Color(0xFF00FF41),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'TIME',
              value: _formatTime(_secondsElapsed),
              color: const Color(0xFF00D9FF),
            ),
            _StatRow(
              label: 'HINTS USED',
              value: _hintsUsed.toString(),
              color: const Color(0xFF00FF41),
            ),
            _StatRow(
              label: 'DIFFICULTY',
              value: widget.puzzle.difficultyLevel.toUpperCase(),
              color: const Color(0xFFFF00FF),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text(
              'BACK TO MENU',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00FF41),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                // Load new puzzle of same difficulty
                await _loadNewPuzzleSameDifficulty();
              },
              child: const Text(
                'NEW GAME',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNewPuzzleSameDifficulty() async {
    try {
      final newPuzzle = await PuzzleService.getRandomPuzzle(
        difficultyLevel: widget.puzzle.difficultyLevel,
      );
      
      if (!mounted) return;
      
      // Replace current screen with new game screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(puzzle: newPuzzle),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading puzzle: $e'),
          backgroundColor: const Color(0xFFFF325C),
        ),
      );
    }
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFF325C), width: 2), // Red border
        ),
        title: const Text(
          'RESET GAME',
          style: TextStyle(
            color: Color(0xFFFF325C),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          'Are you sure you want to reset the puzzle?',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF325C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _initializeGame();
                  _selectedRow = null;
                  _selectedCol = null;
                  _hintsUsed = 0;
                  _secondsElapsed = 0;
                  _isComplete = false;
                });
                _timer?.cancel();
                _startTimer();
                _focusNode.requestFocus(); // Request focus again after reset
              },
              child: const Text(
                'RESET',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pure black
        appBar: AppBar(
          backgroundColor: const Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'LEVEL ${widget.puzzle.difficultyLevel.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'Arial',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
              color: Color(0xFF00D9FF), // Cyan
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFFF00FF)),
              onPressed: _resetGame,
              tooltip: 'Reset',
            ),
          ],
        ),
      body: Container(
        color: const Color(0xFF000000), // Pure black
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes to fit everything on screen
              final availableHeight = constraints.maxHeight;
              final availableWidth = constraints.maxWidth;
              
              // Reserve space for stats and controls
              final statsHeight = 60.0;
              final controlsHeight = 160.0;
              final spacing = 12.0;
              
              // Calculate grid size
              final maxGridSize = availableHeight - statsHeight - controlsHeight - (spacing * 4);
              final gridSize = maxGridSize < availableWidth ? maxGridSize : availableWidth - 32;
              
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stats row - cyberpunk style
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CyberpunkStatCard(
                            icon: Icons.timer_outlined,
                            label: 'TIME',
                            value: _formatTime(_secondsElapsed),
                            color: const Color(0xFF00D9FF), // Cyan
                          ),
                          _CyberpunkStatCard(
                            icon: Icons.lightbulb_outline,
                            label: 'HINTS',
                            value: _hintsUsed.toString(),
                            color: const Color(0xFF00FF41), // Green
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),

                      // Sudoku grid - neon style
                      SizedBox(
                        width: gridSize,
                        height: gridSize,
                        child: _SudokuGrid(
                          grid: _currentGrid,
                          isFixed: _isFixed,
                          isHint: _isHint,
                          selectedRow: _selectedRow,
                          selectedCol: _selectedCol,
                          onCellTap: _selectCell,
                        ),
                      ),
                      SizedBox(height: spacing),

                      // Number input buttons - cyberpunk style
                      SizedBox(
                        width: gridSize,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (index) {
                                final number = index + 1;
                                return _CyberpunkNumberButton(
                                  number: number,
                                  onPressed: () => _enterNumber(number),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ...List.generate(4, (index) {
                                  final number = index + 6;
                                  return _CyberpunkNumberButton(
                                    number: number,
                                    onPressed: () => _enterNumber(number),
                                  );
                                }),
                                _CyberpunkActionButton(
                                  icon: Icons.backspace_outlined,
                                  onPressed: _clearCell,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF000000),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF00FF41), // Green
                                    width: 2,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _selectedRow != null && _selectedCol != null
                                        ? _useHint
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Center(
                                      child: Text(
                                        'USE HINT',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF00FF41),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      ), // Close KeyboardListener
    );
  }
}

class _SudokuGrid extends StatelessWidget {
  final List<List<int>> grid;
  final List<List<bool>> isFixed;
  final List<List<bool>> isHint;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;

  const _SudokuGrid({
    required this.grid,
    required this.isFixed,
    required this.isHint,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Pure black
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00D9FF), // Cyan neon border
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          final row = index ~/ 9;
          final col = index % 9;
          final value = grid[row][col];
          final fixed = isFixed[row][col];
          final hint = isHint[row][col];
          final selected = row == selectedRow && col == selectedCol;
          final highlighted = row == selectedRow || col == selectedCol;

          return GestureDetector(
            onTap: () => onCellTap(row, col),
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00D9FF).withOpacity(0.3)
                    : highlighted
                        ? const Color(0xFF00D9FF).withOpacity(0.1)
                        : const Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(
                    color: row % 3 == 0
                        ? const Color(0xFF00D9FF)
                        : const Color(0xFF00D9FF).withOpacity(0.2),
                    width: row % 3 == 0 ? 2 : 1,
                  ),
                  left: BorderSide(
                    color: col % 3 == 0
                        ? const Color(0xFF00D9FF)
                        : const Color(0xFF00D9FF).withOpacity(0.2),
                    width: col % 3 == 0 ? 2 : 1,
                  ),
                  right: col == 8
                      ? const BorderSide(color: Color(0xFF00D9FF), width: 2)
                      : BorderSide.none,
                  bottom: row == 8
                      ? const BorderSide(color: Color(0xFF00D9FF), width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Center(
                child: value == 0
                    ? null
                    : Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: hint
                              ? const Color(0xFFFFF632) // Yellow for hints
                              : fixed
                                  ? Colors.white // White for original numbers
                                  : const Color(0xFF00FF41), // Green for user input
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CyberpunkNumberButton extends StatelessWidget {
  final int number;
  final VoidCallback onPressed;

  const _CyberpunkNumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00D9FF),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00D9FF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberpunkActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CyberpunkActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF325C), // Red
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFFFF325C),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberpunkStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CyberpunkStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.7),
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
