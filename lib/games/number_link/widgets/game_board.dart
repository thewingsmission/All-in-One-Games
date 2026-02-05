import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:all_in_one_games/games/number_link/models/game_state.dart';

class GameBoard extends StatefulWidget {
  final VoidCallback onCellChanged;

  const GameBoard({super.key, required this.onCellChanged});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  String? _currentDrawingColor;
  int? _lastDragRow;
  int? _lastDragCol;

  void _handleCellTap(int row, int col) {
    final gameState = context.read<GameState>();
    final cell = gameState.playerGrid[row][col];

    // Allow starting drawing from:
    // 1. A node (terminal point)
    // 2. Any colored cell (not empty)
    // BUT not if the color has been solved via hint
    if (cell != '-' && !gameState.solvedColors.contains(cell)) {
      setState(() {
        _currentDrawingColor = cell;
        _lastDragRow = row;
        _lastDragCol = col;
      });
      gameState.startDrawing(cell);
    }
  }

  void _handleCellDragUpdate(int row, int col) {
    if (_currentDrawingColor == null) return;

    final gameState = context.read<GameState>();

    // Set cell to current drawing color
    final changed = gameState.setCell(row, col, _currentDrawingColor!);
    
    if (changed) {
      setState(() {
        _lastDragRow = row;
        _lastDragCol = col;
      });
      widget.onCellChanged();
    }
  }

  void _handleDragEnd() {
    setState(() {
      _currentDrawingColor = null;
      _lastDragRow = null;
      _lastDragCol = null;
    });
    context.read<GameState>().stopDrawing();
  }

  bool _isNode(int row, int col) {
    final gameState = context.read<GameState>();
    final level = gameState.currentLevel;
    if (level == null) return false;

    final questionGrid = level.questionGrid;
    return questionGrid[row][col] != '-';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final level = gameState.currentLevel;
        if (level == null) return const SizedBox();

        final cellSize = _calculateCellSize(level.width, level.height);

        return GestureDetector(
          onPanStart: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);

            final boardPadding = 20.0;
            final x = (localPosition.dx - boardPadding) ~/ cellSize;
            final y = (localPosition.dy - boardPadding) ~/ cellSize;

            if (x >= 0 && x < level.width && y >= 0 && y < level.height) {
              _handleCellTap(y, x);
            }
          },
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);

            final boardPadding = 20.0;
            final x = (localPosition.dx - boardPadding) ~/ cellSize;
            final y = (localPosition.dy - boardPadding) ~/ cellSize;

            if (x >= 0 && x < level.width && y >= 0 && y < level.height) {
              _handleCellDragUpdate(y, x);
            }
          },
          onPanEnd: (details) => _handleDragEnd(),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(level.height, (row) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(level.width, (col) {
                    final cell = gameState.playerGrid[row][col];
                    final isNode = _isNode(row, col);
                    final color = gameState.colorMapping[cell] ?? Colors.grey.shade100;

                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isNode
                          ? Center(
                              child: Container(
                                width: cellSize * 0.5,
                                height: cellSize * 0.5,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  double _calculateCellSize(int width, int height) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reserve space for padding and UI elements
    final availableWidth = screenWidth - 60;
    final availableHeight = screenHeight - 400;

    final cellWidth = availableWidth / width;
    final cellHeight = availableHeight / height;

    final size = cellWidth < cellHeight ? cellWidth : cellHeight;

    // Ensure minimum and maximum size
    return size.clamp(30.0, 80.0);
  }
}

