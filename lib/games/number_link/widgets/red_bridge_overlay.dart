import 'package:flutter/material.dart';

/// A simple overlay that draws all solution bridges in red for visual testing
class RedBridgeOverlay extends StatelessWidget {
  final List<List<String>> solutionGrid;
  final double cellSize;
  final double gap;
  final double padding;

  const RedBridgeOverlay({
    super.key,
    required this.solutionGrid,
    required this.cellSize,
    required this.gap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BridgePainter(
        solutionGrid: solutionGrid,
        cellSize: cellSize,
        gap: gap,
        padding: padding,
      ),
      child: Container(), // Transparent container
    );
  }
}

class BridgePainter extends CustomPainter {
  final List<List<String>> solutionGrid;
  final double cellSize;
  final double gap;
  final double padding;

  BridgePainter({
    required this.solutionGrid,
    required this.cellSize,
    required this.gap,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final height = solutionGrid.length;
    final width = solutionGrid[0].length;
    final cellPlusGap = cellSize + gap;

    // Draw all bridges
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final cell = solutionGrid[row][col];
        if (cell == '-') continue;

        final x = padding + (col * cellPlusGap);
        final y = padding + (row * cellPlusGap);

        // Right bridge
        if (col < width - 1 && solutionGrid[row][col + 1] == cell) {
          final rect = Rect.fromLTWH(
            x + cellSize,  // Start at right edge
            y,             // Same Y as cell
            gap,           // Width = gap
            cellSize,      // Height = cellSize
          );
          canvas.drawRect(rect, paint);
        }

        // Bottom bridge
        if (row < height - 1 && solutionGrid[row + 1][col] == cell) {
          final rect = Rect.fromLTWH(
            x,             // Same X as cell
            y + cellSize,  // Start at bottom edge
            cellSize,      // Width = cellSize
            gap,           // Height = gap
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
