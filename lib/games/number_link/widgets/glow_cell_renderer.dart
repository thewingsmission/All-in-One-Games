import 'package:flutter/material.dart';

/// Glow skin renderer using L1a-L5a images (512×512) based on neighbor configuration.
/// - Terminal: transparent background + primary-colored circle + L5a.png (if 1 neighbor)
/// - Path: transparent background + L1a/L2a/L3a/L4a.png tinted primary (based on neighbors)
/// - Bridge: transparent background + L1a.png tinted primary, scaled by dimensions
class GlowCellRenderer {
  static const String _basePath = 'assets/games/number link/images/glow skin';
  
  /// Terminal cell: transparent background + circle of primary color + L image underneath.
  /// Circle diameter = 0.75 × cellSize.
  /// L image selection:
  /// - 0 neighbors: no L image
  /// - 1 neighbor: L5a.png + L5b.png (terminal-specific)
  /// - 2+ neighbors: L1a/L2a/L3a/L4a.png + Lxb.png (same as path cells)
  static Widget buildTerminalCell(
    double cellSize,
    Color primaryColor,
    Color secondaryColor, {
    bool hasLeft = false,
    bool hasRight = false,
    bool hasTop = false,
    bool hasBottom = false,
  }) {
    final circleSize = cellSize * 0.75;
    final neighborCount = (hasLeft ? 1 : 0) + (hasRight ? 1 : 0) + (hasTop ? 1 : 0) + (hasBottom ? 1 : 0);
    
    // Terminal with 0 neighbors: just circle (no L image)
    if (neighborCount == 0) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: Center(
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    
    // Terminal with 1+ neighbors: add L image layer underneath circle
    String imageFile;
    double rotation;
    
    if (neighborCount == 1) {
      // 1 neighbor: use L5a.png (terminal-specific)
      imageFile = 'L5a.png';
      rotation = _getTerminalRotation(hasLeft, hasRight, hasTop, hasBottom);
    } else {
      // 2+ neighbors: use same logic as path cells (L1a/L2a/L3a/L4a)
      imageFile = _getLImageFile(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
      rotation = _getLImageRotation(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    }
    
    // Get the partner Lxb file name (e.g., L1a.png → L1b.png)
    final imageFileB = imageFile.replaceAll('a.png', 'b.png');
    
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: [
          // Lxb layer (bottom, secondary color)
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180, // Convert degrees to radians
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFileB',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading $imageFileB for terminal: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Lxa layer (middle, primary color)
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180, // Convert degrees to radians
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFile',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading $imageFile for terminal: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Circle on top
          Center(
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Path cell: transparent background + Lxb.png (secondary color) + Lxa.png (primary color).
  /// Image selection and rotation based on neighbor configuration.
  static Widget buildRegularCell(
    double cellSize,
    Color primaryColor,
    Color secondaryColor, {
    bool hasLeft = false,
    bool hasRight = false,
    bool hasTop = false,
    bool hasBottom = false,
  }) {
    final neighborCount = (hasLeft ? 1 : 0) + (hasRight ? 1 : 0) + (hasTop ? 1 : 0) + (hasBottom ? 1 : 0);
    
    // Determine which L image to use and rotation
    final imageFile = _getLImageFile(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    final imageFileB = imageFile.replaceAll('a.png', 'b.png');
    final rotation = _getLImageRotation(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: [
          // Lxb layer (bottom, secondary color)
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180, // Convert degrees to radians
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFileB',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading $imageFileB for path cell: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Lxa layer (top, primary color)
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180, // Convert degrees to radians
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFile',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading $imageFile for path cell: $error');
                  // Very obvious error: magenta background + white X
                  return Container(
                    color: const Color(0xFFFF00FF), // Magenta
                    child: Stack(
                      children: [
                        // Diagonal lines forming X
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ErrorXPainter(),
                          ),
                        ),
                        // Text "ERR"
                        Center(
                          child: Text(
                            'ERR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cellSize * 0.3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Determine which L image file to use based on neighbor count and configuration.
  static String _getLImageFile(int neighborCount, bool hasLeft, bool hasRight, bool hasTop, bool hasBottom) {
    switch (neighborCount) {
      case 1:
        return 'L1a.png'; // Path with 1 neighbor uses L1a
      case 2:
        // Straight line (left-right or top-bottom) → L1a.png
        if ((hasLeft && hasRight) || (hasTop && hasBottom)) {
          return 'L1a.png';
        }
        // Corner → L2a.png
        return 'L2a.png';
      case 3:
        return 'L3a.png'; // T-junction
      case 4:
        return 'L4a.png'; // Cross
      default:
        return 'L1a.png'; // Fallback
    }
  }
  
  /// Determine rotation angle based on neighbor configuration.
  static double _getLImageRotation(int neighborCount, bool hasLeft, bool hasRight, bool hasTop, bool hasBottom) {
    switch (neighborCount) {
      case 1:
        // One neighbor: rotate so stripe points toward neighbor
        if (hasLeft) return 0.0;
        if (hasRight) return 180.0;
        if (hasTop) return 90.0;
        if (hasBottom) return 270.0;
        return 0.0;
      
      case 2:
        // Straight line
        if ((hasLeft && hasRight)) return 0.0; // Horizontal
        if ((hasTop && hasBottom)) return 90.0; // Vertical
        
        // Corner (L2a.png)
        if (hasTop && hasRight) return 90.0;
        if (hasRight && hasBottom) return 180.0;
        if (hasBottom && hasLeft) return 270.0;
        if (hasTop && hasLeft) return 0.0;
        return 0.0;
      
      case 3:
        // T-junction: rotation based on missing side
        if (!hasTop) return 180.0;    // Missing top
        if (!hasRight) return 270.0;  // Missing right
        if (!hasBottom) return 0.0;   // Missing bottom
        if (!hasLeft) return 90.0;    // Missing left
        return 0.0;
      
      case 4:
        return 0.0; // Cross: always 0°
      
      default:
        return 0.0;
    }
  }
  
  /// Get rotation for terminal cell with 1 neighbor (L5a.png).
  static double _getTerminalRotation(bool hasLeft, bool hasRight, bool hasTop, bool hasBottom) {
    if (hasLeft) return 0.0;
    if (hasRight) return 180.0;
    if (hasTop) return 90.0;
    if (hasBottom) return 270.0;
    return 0.0;
  }
  
  /// Bridge: transparent background + L1b.png (secondary) + L1a.png (primary).
  /// Horizontal bridge (e.g. 10×256): scale x by (10/512), y by (256/512) → BoxFit.fill
  /// Vertical bridge: rotate 90° clockwise then scale.
  static Widget buildBridge(
    double bridgeWidth,
    double bridgeHeight,
    Color primaryColor,
    Color secondaryColor,
    bool isHorizontal,
  ) {
    if (isHorizontal) {
      // Horizontal bridge: L1b (secondary) + L1a (primary), no rotation
      return SizedBox(
        width: bridgeWidth,
        height: bridgeHeight,
        child: Stack(
          children: [
            // L1b layer (bottom, secondary color)
            ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1b.png',
                width: bridgeWidth,
                height: bridgeHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading L1b.png for horizontal bridge: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
            // L1a layer (top, primary color)
            ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1a.png',
                width: bridgeWidth,
                height: bridgeHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading L1a.png for horizontal bridge: $error');
                  // Very obvious error: magenta with white text
                  return Container(
                    color: const Color(0xFFFF00FF), // Magenta
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          'ERR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    
    // Vertical bridge: L1b (secondary) + L1a (primary), rotate 90° clockwise
    return SizedBox(
      width: bridgeWidth,
      height: bridgeHeight,
      child: RotatedBox(
        quarterTurns: 1,
        child: Stack(
          children: [
            // L1b layer (bottom, secondary color)
            ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1b.png',
                width: bridgeHeight,
                height: bridgeWidth,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading L1b.png for vertical bridge: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
            // L1a layer (top, primary color)
            ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1a.png',
                width: bridgeHeight,
                height: bridgeWidth,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  // ignore: avoid_print
                  print('ERROR loading L1a.png for vertical bridge: $error');
                  // Very obvious error: magenta with white text
                  return Container(
                    color: const Color(0xFFFF00FF), // Magenta
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          'ERR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw a white X for error indication
class _ErrorXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw X (two diagonal lines)
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
