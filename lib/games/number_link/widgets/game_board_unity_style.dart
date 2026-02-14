import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:all_in_one_games/games/number_link/models/game_state.dart';
import 'package:all_in_one_games/games/number_link/models/cell_style.dart';
import 'package:all_in_one_games/games/number_link/widgets/red_bridge_overlay.dart';
import 'package:all_in_one_games/games/number_link/widgets/glow_cell_renderer.dart';

class GameBoardUnityStyle extends StatefulWidget {
  final VoidCallback onCellChanged;
  final bool isHintMode;
  final Function(String)? onHintSelected;
  final VoidCallback? onHintCancelled;

  const GameBoardUnityStyle({
    super.key, 
    required this.onCellChanged,
    this.isHintMode = false,
    this.onHintSelected,
    this.onHintCancelled,
  });

  @override
  State<GameBoardUnityStyle> createState() => _GameBoardUnityStyleState();
}

class _GameBoardUnityStyleState extends State<GameBoardUnityStyle> {
  String? _currentDrawingColor;
  int? _lastDragRow;
  int? _lastDragCol;
  bool _hasDebugPrintedSolutionBridges = false;
  bool _showSolutionBridgesTest = false; // Test mode DISABLED
  DateTime? _testModeStartTime;

  void _handleCellTap(int row, int col) {
    final gameState = context.read<GameState>();
    
    // Don't allow interaction if puzzle is frozen
    if (gameState.isPuzzleFrozen) {
      return;
    }
    
    if (widget.isHintMode) {
      if (_isNode(row, col)) {
        final cell = gameState.playerGrid[row][col];
        if (!gameState.solvedColors.contains(cell)) {
          widget.onHintSelected?.call(cell);
        }
      } else {
        widget.onHintCancelled?.call();
      }
      return;
    }

    final cell = gameState.playerGrid[row][col];

    // Prevent starting drawing with colors that have been solved via hints
    if (gameState.solvedColors.contains(cell)) {
      return;
    }

    // Allow starting from any cell (colored or empty)
    // If empty, use '-' as the "eraser" color
    setState(() {
      _currentDrawingColor = cell;
      _lastDragRow = row;
      _lastDragCol = col;
    });
    gameState.startDrawing(cell);
  }

  void _handleCellDragUpdate(int row, int col) {
    final gameState = context.read<GameState>();
    
    // Don't allow interaction if puzzle is frozen
    if (gameState.isPuzzleFrozen) {
      return;
    }
    
    if (widget.isHintMode) return;

    if (_currentDrawingColor == null) {
      return;
    }

    // Prevent redundant updates if we're still on the same cell
    if (row == _lastDragRow && col == _lastDragCol) {
      return;
    }
    
    if (gameState.setCell(row, col, _currentDrawingColor!)) {
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

  Widget _buildNodeIndicator(
    CellStyle style, 
    double cellSize,
    double gap,
    Color cellColor,
    String cellValue,
    GameState gameState,
    int row,
    int col, {
    bool hasLeft = false,
    bool hasRight = false,
    bool hasTop = false,
    bool hasBottom = false,
  }) {
    switch (style) {
      case CellStyle.numbered:
        // Convert cell value to number (a=1, b=2, etc.) — black font with white outer glow
        String text = cellValue;
        if (cellValue.length == 1) {
          final int code = cellValue.toLowerCase().codeUnitAt(0);
          if (code >= 97 && code <= 122) {
            text = (code - 96).toString();
          }
        }
        return Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontSize: cellSize * 0.6,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 6, offset: Offset.zero),
                Shadow(color: Colors.white.withOpacity(0.7), blurRadius: 10, offset: Offset.zero),
                Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 14, offset: Offset.zero),
              ],
            ),
          ),
        );
      case CellStyle.square:
        // White tiny square at cell center
        return Center(
          child: Container(
            width: cellSize * 0.3,
            height: cellSize * 0.3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case CellStyle.strip:
        // 7x7 grid system (scale = 1.0)
        final unit = cellSize / 7.0;
        
        return SizedBox(
          width: cellSize,
          height: cellSize,
          child: Stack(
            children: [
              // Fill entire area with cell color as background
              Container(
                width: cellSize,
                height: cellSize,
                color: cellColor,
              ),
              // White border area - use continuous rectangles
              // Horizontal white strip (top and bottom together, covering rows 2 and 6)
              Positioned(
                left: unit * 1,
                top: unit * 1,
                child: Container(
                  width: unit * 5,
                  height: unit * 5,
                  color: Colors.white,
                ),
              ),
              // Inner colored area (3x3 center)
              Positioned(
                left: unit * 2,
                top: unit * 2,
                child: Container(
                  width: unit * 3,
                  height: unit * 3,
                  color: cellColor,
                ),
              ),
              // Now overlay directional strips
              // Left strip
              if (hasLeft) ...[ // Column 2 rows 3-5 colored
                Positioned(
                  left: unit * 1,
                  top: unit * 2,
                  child: Container(
                    width: unit,
                    height: unit * 3,
                    color: cellColor,
                  ),
                ),
                // White at (1,2)
                Positioned(
                  left: 0,
                  top: unit * 1,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
                // White at (1,6)
                Positioned(
                  left: 0,
                  top: unit * 5,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              ],
              // Right strip
              if (hasRight) ...[
                // Column 6 rows 3-5 colored
                Positioned(
                  left: unit * 5,
                  top: unit * 2,
                  child: Container(
                    width: unit,
                    height: unit * 3,
                    color: cellColor,
                  ),
                ),
                // White at (7,2)
                Positioned(
                  left: unit * 6,
                  top: unit * 1,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
                // White at (7,6)
                Positioned(
                  left: unit * 6,
                  top: unit * 5,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              ],
              // Top strip
              if (hasTop) ...[
                // Row 2 columns 3-5 colored
                Positioned(
                  left: unit * 2,
                  top: unit * 1,
                  child: Container(
                    width: unit * 3,
                    height: unit,
                    color: cellColor,
                  ),
                ),
                // White at (2,1)
                Positioned(
                  left: unit * 1,
                  top: 0,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
                // White at (6,1)
                Positioned(
                  left: unit * 5,
                  top: 0,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              ],
              // Bottom strip
              if (hasBottom) ...[
                // Row 6 columns 3-5 colored
                Positioned(
                  left: unit * 2,
                  top: unit * 5,
                  child: Container(
                    width: unit * 3,
                    height: unit,
                    color: cellColor,
                  ),
                ),
                // White at (2,7)
                Positioned(
                  left: unit * 1,
                  top: unit * 6,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
                // White at (6,7)
                Positioned(
                  left: unit * 5,
                  top: unit * 6,
                  child: Container(
                    width: unit,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              ],
              // Center cell (4,4) must always be white - overlay last
              Positioned(
                left: unit * 3,
                top: unit * 3,
                child: Container(
                  width: unit,
                  height: unit,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case CellStyle.glow:
        final primaryColor = gameState.colorMapping[cellValue] ?? Colors.grey;
        final secondaryColor = gameState.secondaryColorMapping[cellValue] ?? Colors.grey;
        return GlowCellRenderer.buildTerminalCell(
          cellSize,
          primaryColor,
          secondaryColor,
          cellValue,
          hasLeft: hasLeft,
          hasRight: hasRight,
          hasTop: hasTop,
          hasBottom: hasBottom,
        );
    }
  }

  Widget _buildCellContent(
    CellStyle style,
    double cellSize,
    Color cellColor,
    GameState gameState, {
    String cellValue = '', // Added
    bool hasLeft = false,
    bool hasRight = false,
    bool hasTop = false,
    bool hasBottom = false,
    bool isTerminal = false,
  }) {
    switch (style) {
      case CellStyle.numbered:
        // Simple colored square (scale = 1.0) - same as square style
        return Container(
          width: cellSize,
          height: cellSize,
          color: cellColor,
        );
      case CellStyle.square:
        // Simple colored square (scale = 1.0)
        return Container(
          width: cellSize,
          height: cellSize,
          color: cellColor,
        );
      case CellStyle.strip:
        // 7x7 grid system for all cells (scale = 1.0)
        // White strips show where there are NO neighbors
        final unit = cellSize / 7.0;
        
        return SizedBox(
          width: cellSize,
          height: cellSize,
          child: Stack(
            children: [
              // Fill entire area with cell color
              Container(
                width: cellSize,
                height: cellSize,
                color: cellColor,
              ),
              // Column 2 (vertical white strip when NO left neighbor)
              if (!hasLeft)
                Positioned(
                  left: unit * 1,
                  top: unit * 1,
                  child: Container(
                    width: unit,
                    height: unit * 5,
                    color: Colors.white,
                  ),
                ),
              // Column 6 (vertical white strip when NO right neighbor)
              if (!hasRight)
                Positioned(
                  left: unit * 5,
                  top: unit * 1,
                  child: Container(
                    width: unit,
                    height: unit * 5,
                    color: Colors.white,
                  ),
                ),
              // Row 2 (horizontal white strip when NO top neighbor)
              if (!hasTop)
                Positioned(
                  left: unit * 1,
                  top: unit * 1,
                  child: Container(
                    width: unit * 5,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              // Row 6 (horizontal white strip when NO bottom neighbor)
              if (!hasBottom)
                Positioned(
                  left: unit * 1,
                  top: unit * 5,
                  child: Container(
                    width: unit * 5,
                    height: unit,
                    color: Colors.white,
                  ),
                ),
              // Four corner whites - ALWAYS present at (2,2), (2,6), (6,2), (6,6)
              Positioned(
                left: unit * 1,
                top: unit * 1,
                child: Container(width: unit, height: unit, color: Colors.white),
              ),
              Positioned(
                left: unit * 5,
                top: unit * 1,
                child: Container(width: unit, height: unit, color: Colors.white),
              ),
              Positioned(
                left: unit * 1,
                top: unit * 5,
                child: Container(width: unit, height: unit, color: Colors.white),
              ),
              Positioned(
                left: unit * 5,
                top: unit * 5,
                child: Container(width: unit, height: unit, color: Colors.white),
              ),
              // White cells at edges when there ARE neighbors
              // Top edge: (1,2) and (1,6) when has top neighbor
              if (hasTop) ...[
                Positioned(
                  left: unit * 1,
                  top: 0,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
                Positioned(
                  left: unit * 5,
                  top: 0,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
              ],
              // Bottom edge: (7,2) and (7,6) when has bottom neighbor
              if (hasBottom) ...[
                Positioned(
                  left: unit * 1,
                  top: unit * 6,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
                Positioned(
                  left: unit * 5,
                  top: unit * 6,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
              ],
              // Left edge: (2,1) and (6,1) when has left neighbor
              if (hasLeft) ...[
                Positioned(
                  left: 0,
                  top: unit * 1,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
                Positioned(
                  left: 0,
                  top: unit * 5,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
              ],
              // Right edge: (2,7) and (6,7) when has right neighbor
              if (hasRight) ...[
                Positioned(
                  left: unit * 6,
                  top: unit * 1,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
                Positioned(
                  left: unit * 6,
                  top: unit * 5,
                  child: Container(width: unit, height: unit, color: Colors.white),
                ),
              ],
            ],
          ),
        );
      case CellStyle.glow:
        if (isTerminal) {
          return Container(
            width: cellSize,
            height: cellSize,
            color: Colors.transparent,
          );
        }
        if (cellValue.isEmpty || cellValue == '-') {
          return Container(
            width: cellSize,
            height: cellSize,
            color: Colors.white,
          );
        }
        final primaryColor = gameState.colorMapping[cellValue] ?? Colors.grey;
        final secondaryColor = gameState.secondaryColorMapping[cellValue] ?? Colors.grey;
        return GlowCellRenderer.buildRegularCell(
          cellSize,
          primaryColor,
          secondaryColor,
          hasLeft: hasLeft,
          hasRight: hasRight,
          hasTop: hasTop,
          hasBottom: hasBottom,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final level = gameState.currentLevel;
        if (level == null) return const SizedBox();

        final sizes = _calculateSizes(level.width, level.height);
        final cellSize = sizes['cellSize']!;
        final gap = sizes['gap']!;
        final borderRadius = cellSize * 0.15; // Unity-style rounded corners

        // One-time debug: Print solution grid bridges
        if (!_hasDebugPrintedSolutionBridges) {
          _hasDebugPrintedSolutionBridges = true;
          final solutionGrid = level.solutionGrid;
          final boardPadding = 20.0;
          final cellPlusGap = cellSize + gap;
          
          for (int row = 0; row < level.height; row++) {
            for (int col = 0; col < level.width; col++) {
              final cell = solutionGrid[row][col];
              final positionX = boardPadding + (col * cellPlusGap);
              final positionY = boardPadding + (row * cellPlusGap);
              
              // Check right neighbor
              if (col < level.width - 1 && solutionGrid[row][col + 1] == cell && cell != '-') {
                final bridgeX = positionX + cellSize;
                final bridgeY = positionY;
              }
              
              // Check bottom neighbor
              if (row < level.height - 1 && solutionGrid[row + 1][col] == cell && cell != '-') {
                final bridgeX = positionX;
                final bridgeY = positionY + cellSize;
              }
            }
          }
        }

        return GestureDetector(
          onPanStart: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            
            final boardPadding = 20.0;
            final cellPlusGap = cellSize + gap;
            
            // Convert position to grid coordinates accounting for gaps
            final x = ((localPosition.dx - boardPadding) / cellPlusGap).floor();
            final y = ((localPosition.dy - boardPadding) / cellPlusGap).floor();

            if (x >= 0 && x < level.width && y >= 0 && y < level.height) {
              _handleCellTap(y, x);
            }
          },
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);

            final boardPadding = 20.0;
            final cellPlusGap = cellSize + gap;
            
            // Convert position to grid coordinates accounting for gaps
            final x = ((localPosition.dx - boardPadding) / cellPlusGap).floor();
            final y = ((localPosition.dy - boardPadding) / cellPlusGap).floor();

            if (x >= 0 && x < level.width && y >= 0 && y < level.height) {
              _handleCellDragUpdate(y, x);
            }
          },
          onPanEnd: (details) => _handleDragEnd(),
          child: Stack(
            children: [
              // Actual game grid (rendered first, below red bridges)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(level.height, (row) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                  children: List.generate(level.width, (col) {
                    final cell = gameState.playerGrid[row][col];
                    final isNode = _isNode(row, col);
                    final color = gameState.colorMapping[cell] ?? Colors.white;

                    // Check neighbors for connectors
                    final hasRightNeighbor = col < level.width - 1 && 
                        gameState.playerGrid[row][col + 1] == cell && cell != '-';
                    final hasBottomNeighbor = row < level.height - 1 && 
                        gameState.playerGrid[row + 1][col] == cell && cell != '-';
                    final hasLeftNeighbor = col > 0 && 
                        gameState.playerGrid[row][col - 1] == cell && cell != '-';
                    final hasTopNeighbor = row > 0 && 
                        gameState.playerGrid[row - 1][col] == cell && cell != '-';

                    // Calculate position (accounting for board padding and gaps)
                    final boardPadding = 20.0;
                    final cellPlusGap = cellSize + gap;
                    final positionX = boardPadding + (col * cellPlusGap);
                    final positionY = boardPadding + (row * cellPlusGap);
                    
                    // Debug print cell information

                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(
                        right: col < level.width - 1 ? gap : 0,
                        bottom: row < level.height - 1 ? gap : 0,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Cell content (scale = 1.0)
                          _buildCellContent(
                            gameState.cellStyle,
                            cellSize,
                            color,
                            gameState,
                            cellValue: cell,
                            hasLeft: hasLeftNeighbor,
                            hasRight: hasRightNeighbor,
                            hasTop: hasTopNeighbor,
                            hasBottom: hasBottomNeighbor,
                            isTerminal: isNode,
                          ),
                          // Bridges for Numbered style (scale = 1.0, fills gap)
                          if (gameState.cellStyle == CellStyle.numbered && hasRightNeighbor) ...[
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX + cellSize;
                                final bridgeY = positionY;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              left: cellSize,
                              top: 0,
                              child: Container(
                                width: gap,
                                height: cellSize,
                                color: color,
                              ),
                            ),
                          ],
                          if (gameState.cellStyle == CellStyle.numbered && hasBottomNeighbor) ...[
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX;
                                final bridgeY = positionY + cellSize;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              top: cellSize,
                              left: 0,
                              child: Container(
                                width: cellSize,
                                height: gap,
                                color: color,
                              ),
                            ),
                          ],
                          // Bridges for Square style (scale = 1.0, fills gap)
                          if (gameState.cellStyle == CellStyle.square && hasRightNeighbor) ...[
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX + cellSize;
                                final bridgeY = positionY;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              left: cellSize,
                              top: 0,
                              child: Container(
                                width: gap,
                                height: cellSize,
                                color: color,
                              ),
                            ),
                          ],
                          if (gameState.cellStyle == CellStyle.square && hasBottomNeighbor) ...[
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX;
                                final bridgeY = positionY + cellSize;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              top: cellSize,
                              left: 0,
                              child: Container(
                                width: cellSize,
                                height: gap,
                                color: color,
                              ),
                            ),
                          ],
                          // Bridges for Strip style (scale = 1.0, fills gap with white strips)
                          if (gameState.cellStyle == CellStyle.strip && hasRightNeighbor) ...[
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX + cellSize;
                                final bridgeY = positionY;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              left: cellSize,
                              top: 0,
                              child: SizedBox(
                                width: gap,
                                height: cellSize,
                                child: Stack(
                                  children: [
                                    // Fill with color
                                    Container(
                                      width: gap,
                                      height: cellSize,
                                      color: color,
                                    ),
                                    // Two white cells - ALWAYS present
                                    // Top white cell at row 2
                                    Positioned(
                                      top: cellSize / 7.0,
                                      child: Container(
                                        width: gap,
                                        height: cellSize / 7.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Bottom white cell at row 6
                                    Positioned(
                                      top: cellSize * 5 / 7.0,
                                      child: Container(
                                        width: gap,
                                        height: cellSize / 7.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (gameState.cellStyle == CellStyle.strip && hasBottomNeighbor) ...[ 
                            Builder(
                              builder: (context) {
                                final bridgeX = positionX;
                                final bridgeY = positionY + cellSize;
                                return const SizedBox.shrink();
                              },
                            ),
                            Positioned(
                              top: cellSize,
                              left: 0,
                              child: SizedBox(
                                width: cellSize,
                                height: gap,
                                child: Stack(
                                  children: [
                                    // Fill with color
                                    Container(
                                      width: cellSize,
                                      height: gap,
                                      color: color,
                                    ),
                                    // Two white cells - ALWAYS present
                                    // Left white cell at column 2
                                    Positioned(
                                      left: cellSize / 7.0,
                                      child: Container(
                                        width: cellSize / 7.0,
                                        height: gap,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Right white cell at column 6
                                    Positioned(
                                      left: cellSize * 5 / 7.0,
                                      child: Container(
                                        width: cellSize / 7.0,
                                        height: gap,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (gameState.cellStyle == CellStyle.glow && hasRightNeighbor) ...[
                             Positioned(
                               left: cellSize,
                               top: 0,
                               child: GlowCellRenderer.buildBridge(
                                 gap,
                                 cellSize,
                                 gameState.colorMapping[cell] ?? Colors.grey,
                                 gameState.secondaryColorMapping[cell] ?? Colors.grey,
                                 true, // isHorizontal
                               ),
                            ),
                          ],
                          if (gameState.cellStyle == CellStyle.glow && hasBottomNeighbor) ...[
                             Positioned(
                               top: cellSize,
                               left: 0,
                               child: GlowCellRenderer.buildBridge(
                                 cellSize,
                                 gap,
                                 gameState.colorMapping[cell] ?? Colors.grey,
                                 gameState.secondaryColorMapping[cell] ?? Colors.grey,
                                 false, // isHorizontal (vertical)
                               ),
                            ),
                          ],
                          // Node indicator based on style
                          if (isNode)
                            Center(
                              child: _buildNodeIndicator(
                                gameState.cellStyle, 
                                cellSize,
                                gap,
                                color,
                                cell,
                                gameState,
                                row,
                                col,
                                hasLeft: hasLeftNeighbor,
                                hasRight: hasRightNeighbor,
                                hasTop: hasTopNeighbor,
                                hasBottom: hasBottomNeighbor,
                              ),
                            ),
                          // Overlay for Hint Mode
                          if (widget.isHintMode)
                              Positioned.fill(
                                child: _buildHintOverlay(
                                  row, 
                                  col, 
                                  cell, 
                                  isNode,
                                  gameState.cellStyle,
                                  cellSize,
                                  gap,
                                  hasLeftNeighbor,
                                  hasRightNeighbor,
                                  hasTopNeighbor,
                                  hasBottomNeighbor,
                                ),
                              ),
                        ],
                      ),
                    );
                  }),
                );
              }),
            ),
              ),
              // Visual test: Simple red bridge overlay using CustomPaint
              if (_showSolutionBridgesTest) ...[
                Builder(
                  builder: (context) {
                    if (_testModeStartTime == null) {
                      _testModeStartTime = DateTime.now();
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Positioned.fill(
                  child: RedBridgeOverlay(
                    solutionGrid: level.solutionGrid,
                    cellSize: cellSize,
                    gap: gap,
                    padding: 20.0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintOverlay(
    int row, 
    int col, 
    String cellValue, 
    bool isNode, 
    CellStyle style,
    double cellSize,
    double gap,
    bool hasLeft,
    bool hasRight,
    bool hasTop,
    bool hasBottom,
  ) {
      final gameState = context.read<GameState>();
      
      // Determine if we should cover this cell
      // Cover UNLESS it's an unhinted node (selectable target)
      bool coverCell = true;
      if (isNode && !gameState.solvedColors.contains(cellValue)) {
          coverCell = false;
      }

      final overlayColor = Colors.black.withOpacity(0.7);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Cell overlay - exact match with cell (scale=1.0)
          if (coverCell)
            Container(
              width: cellSize,
              height: cellSize,
              color: overlayColor,
            ),
          
          // 2. Bridge overlays - exact match with bridges (scale=1.0)
          // Right bridge (in gap to the right)
          if (hasRight)
            Positioned(
              left: cellSize,
              top: 0,
              child: Container(
                width: gap,
                height: cellSize,
                color: overlayColor,
              ),
            ),
          
          // Bottom bridge (in gap below)
          if (hasBottom)
            Positioned(
              top: cellSize,
              left: 0,
              child: Container(
                width: cellSize,
                height: gap,
                color: overlayColor,
              ),
            ),
        ],
      );
  }

  // New algorithm: Calculate actual cell size and gap size separately
  // Both cells and bridges use scale = 1.0
  Map<String, double> _calculateSizes(int width, int height) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final availableWidth = screenWidth - 60;
    final availableHeight = screenHeight - 400;

    // Gap ratio: gap = 0.25 * cellSize (to maintain same visual spacing as 0.8 scale)
    const gapRatio = 0.25;
    
    // For n cells with gaps between them:
    // total = cellSize * n + gap * (n - 1)
    // total = cellSize * n + (gapRatio * cellSize) * (n - 1)
    // total = cellSize * (n + gapRatio * (n - 1))
    // cellSize = total / (n + gapRatio * (n - 1))
    
    final cellWidth = availableWidth / (width + gapRatio * (width - 1));
    final cellHeight = availableHeight / (height + gapRatio * (height - 1));

    final cellSize = (cellWidth < cellHeight ? cellWidth : cellHeight).clamp(30.0, 90.0);
    final gap = cellSize * gapRatio;

    return {
      'cellSize': cellSize,  // Actual cell size (scale 1.0)
      'gap': gap,            // Gap between cells
    };
  }

  double _calculateCellSize(int width, int height) {
    return _calculateSizes(width, height)['cellSize']!;
  }
}


class CornerTrianglesPainter extends CustomPainter {
  final Color color;
  final double triangleSize;

  CornerTrianglesPainter({
    required this.color,
    required this.triangleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final s = triangleSize;

    // Top Left
    final pathTL = Path()
      ..moveTo(0, 0)
      ..lineTo(s, 0)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(pathTL, paint);

    // Top Right
    final pathTR = Path()
      ..moveTo(w, 0)
      ..lineTo(w - s, 0)
      ..lineTo(w, s)
      ..close();
    canvas.drawPath(pathTR, paint);

    // Bottom Left
    final pathBL = Path()
      ..moveTo(0, h)
      ..lineTo(s, h)
      ..lineTo(0, h - s)
      ..close();
    canvas.drawPath(pathBL, paint);

    // Bottom Right
    final pathBR = Path()
      ..moveTo(w, h)
      ..lineTo(w - s, h)
      ..lineTo(w, h - s)
      ..close();
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CornerTrianglesPainter oldDelegate) {
    return color != oldDelegate.color || triangleSize != oldDelegate.triangleSize;
  }
}
