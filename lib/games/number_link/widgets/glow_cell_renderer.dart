import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowCellRenderer {
  /// Helper to get color index from character (a=1, b=2, etc.)
  static int getColorIndex(String cellValue) {
    if (cellValue.isEmpty || cellValue == '-') return 0;
    return cellValue.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
  }

  /// Helper to apply color tint to white images
  static Widget coloredImage(String assetPath, Color color, double width, double height, {BoxFit fit = BoxFit.contain}) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Container(
          color: Colors.grey,
          child: Icon(Icons.error, color: Colors.white, size: width * 0.3),
        ),
      ),
    );
  }

  /// Helper to determine L image name and rotation based on neighbors
  static Map<String, dynamic> _getLImageConfig(bool hasTop, bool hasRight, bool hasBottom, bool hasLeft) {
    final neighborCount = [hasTop, hasRight, hasBottom, hasLeft].where((x) => x).length;
    String imageName;
    double rotation = 0;

    if (neighborCount == 1) {
      // 1 neighbor - use L1 straight line
      imageName = 'L1';
      if (hasTop || hasBottom) {
        rotation = 90; // Vertical
      } else {
        rotation = 0; // Horizontal
      }
    } else if (neighborCount == 2) {
      // 2 neighbors
      if (hasTop && hasBottom) {
        imageName = 'L1';
        rotation = 90;
      } else if (hasLeft && hasRight) {
        imageName = 'L1';
        rotation = 0;
      } else if (hasTop && hasRight) {
        imageName = 'L2';
        rotation = 90;
      } else if (hasRight && hasBottom) {
        imageName = 'L2';
        rotation = 180;
      } else if (hasBottom && hasLeft) {
        imageName = 'L2';
        rotation = 270;
      } else {
        imageName = 'L2';
        rotation = 0;
      }
    } else if (neighborCount == 3) {
      // 3 neighbors (T-junction)
      imageName = 'L3';
      if (!hasTop) {
        rotation = 180;
      } else if (!hasRight) {
        rotation = 270;
      } else if (!hasBottom) {
        rotation = 0;
      } else {
        rotation = 90;
      }
    } else {
      // 4 neighbors (cross) or 0 neighbors
      imageName = 'L4';
      rotation = 0;
    }

    return {'imageName': imageName, 'rotation': rotation};
  }

  /// Renders a glow skin terminal cell (endpoint)
  /// Terminal cell: color_block + index on top, optionally L5a+L5b underneath if one neighbor
  static Widget buildTerminalCell(
    double cellSize,
    String cellValue,
    Color primaryColor,
    Color paleColor, {
    required bool hasTop,
    required bool hasRight,
    required bool hasBottom,
    required bool hasLeft,
  }) {
    final colorIndex = getColorIndex(cellValue);
    if (colorIndex == 0) {
      return Container(
        width: cellSize,
        height: cellSize,
        color: Colors.white,
      );
    }

    final colorBlockPath = 'assets/games/number link/images/glow skin/color_block${colorIndex.toString().padLeft(2, '0')}.png';
    final indexPath = 'assets/games/number link/images/glow skin/index${colorIndex.toString().padLeft(2, '0')}.png';

    // Count neighbors
    final neighborCount = [hasTop, hasRight, hasBottom, hasLeft].where((x) => x).length;

    // Build layers from bottom to top
    final layers = <Widget>[];

    // Determine which L image to use based on neighbor count
    if (neighborCount == 1) {
      // 1 neighbor: Use L5 only
      double rotation = 0;
      if (hasLeft) rotation = 0;
      if (hasRight) rotation = 180;
      if (hasTop) rotation = 90;
      if (hasBottom) rotation = 270;

      layers.add(
        Transform.rotate(
          angle: rotation * math.pi / 180,
          child: Stack(
            children: [
              coloredImage('assets/games/number link/images/glow skin/L5b.png', primaryColor, cellSize, cellSize),
              coloredImage('assets/games/number link/images/glow skin/L5a.png', paleColor, cellSize, cellSize),
            ],
          ),
        ),
      );
    } else if (neighborCount == 2) {
      // 2 neighbors: Use L1 for straight lines, L2 for corners
      String imageName;
      double rotation = 0;
      
      if (hasLeft && hasRight) {
        // Horizontal line
        imageName = 'L1';
        rotation = 0;
      } else if (hasTop && hasBottom) {
        // Vertical line
        imageName = 'L1';
        rotation = 90;
      } else if (hasLeft && hasTop) {
        // Left-top corner
        imageName = 'L2';
        rotation = 0;
      } else if (hasTop && hasRight) {
        // Top-right corner
        imageName = 'L2';
        rotation = 90;
      } else if (hasRight && hasBottom) {
        // Right-bottom corner
        imageName = 'L2';
        rotation = 180;
      } else {
        // hasBottom && hasLeft - Bottom-left corner
        imageName = 'L2';
        rotation = 270;
      }

      layers.add(
        Transform.rotate(
          angle: rotation * math.pi / 180,
          child: Stack(
            children: [
              coloredImage('assets/games/number link/images/glow skin/${imageName}b.png', primaryColor, cellSize, cellSize),
              coloredImage('assets/games/number link/images/glow skin/${imageName}a.png', paleColor, cellSize, cellSize),
            ],
          ),
        ),
    );
    } else if (neighborCount == 3) {
      // 3 neighbors: Use L3
      double rotation = 0;
      if (hasLeft && hasTop && hasRight) rotation = 0;
      if (hasTop && hasRight && hasBottom) rotation = 90;
      if (hasRight && hasBottom && hasLeft) rotation = 180;
      if (hasBottom && hasLeft && hasTop) rotation = 270;

      layers.add(
        Transform.rotate(
          angle: rotation * math.pi / 180,
          child: Stack(
            children: [
              coloredImage('assets/games/number link/images/glow skin/L3b.png', primaryColor, cellSize, cellSize),
              coloredImage('assets/games/number link/images/glow skin/L3a.png', paleColor, cellSize, cellSize),
            ],
          ),
        ),
      );
    }
    // 0 neighbors: No L image layer

    // Add color_block
    layers.add(
      Image.asset(
        colorBlockPath,
        width: cellSize,
        height: cellSize,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Container(color: Colors.grey),
      ),
    );

    // Add index on top
    layers.add(
      Image.asset(
        indexPath,
      width: cellSize,
      height: cellSize,
      fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Container(),
      ),
    );

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(children: layers),
    );
  }
  
  /// Renders a glow skin regular cell based on neighbors
  /// Uses L1a+L1b, L2a+L2b, L3a+L3b, or L4a+L4b based on neighbor configuration
  static Widget buildRegularCell(
    double cellSize,
    String cellValue,
    Color primaryColor,
    Color paleColor, {
    required bool hasTop,
    required bool hasRight,
    required bool hasBottom,
    required bool hasLeft,
  }) {
    if (cellValue.isEmpty || cellValue == '-') {
      return Container(
        width: cellSize,
        height: cellSize,
        color: Colors.white,
      );
    }
    
    // Get L1/L2/L3/L4 configuration based on neighbors
    final config = _getLImageConfig(hasTop, hasRight, hasBottom, hasLeft);
    final imageName = config['imageName'] as String;
    final rotation = config['rotation'] as double;
    
    return SizedBox(
        width: cellSize,
        height: cellSize,
      child: Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Stack(
          children: [
            // Layer b (primary color) at bottom
            coloredImage('assets/games/number link/images/glow skin/${imageName}b.png', primaryColor, cellSize, cellSize),
            // Layer a (pale color) on top
            coloredImage('assets/games/number link/images/glow skin/${imageName}a.png', paleColor, cellSize, cellSize),
          ],
        ),
      ),
    );
  }
  
  /// Renders a glow skin bridge connector (in the gap between cells)
  /// Bridge uses L1a + L1b with color tinting
  /// For vertical bridges, L1 images are rotated 90° but container stays in place
  static Widget buildBridge(
    double bridgeWidth,
    double bridgeHeight,
    String cellValue,
    Color primaryColor,
    Color paleColor,
    bool isHorizontal,
  ) {
    if (cellValue.isEmpty || cellValue == '-') {
      return Container(
        width: bridgeWidth,
        height: bridgeHeight,
        color: Colors.white,
      );
    }
    
    if (isHorizontal) {
      // Horizontal bridge: L1 images without rotation
      return SizedBox(
        width: bridgeWidth,
        height: bridgeHeight,
        child: Stack(
          children: [
            coloredImage('assets/games/number link/images/glow skin/L1b.png', primaryColor, bridgeWidth, bridgeHeight, fit: BoxFit.fill),
            coloredImage('assets/games/number link/images/glow skin/L1a.png', paleColor, bridgeWidth, bridgeHeight, fit: BoxFit.fill),
          ],
        ),
      );
    } else {
      // Vertical bridge: Use RotatedBox to pre-rotate L1 images by 90°
      return SizedBox(
        width: bridgeWidth,
        height: bridgeHeight,
        child: Stack(
          children: [
            RotatedBox(
              quarterTurns: 1, // 90° clockwise
              child: coloredImage('assets/games/number link/images/glow skin/L1b.png', primaryColor, bridgeHeight, bridgeWidth, fit: BoxFit.fill),
            ),
            RotatedBox(
              quarterTurns: 1, // 90° clockwise
              child: coloredImage('assets/games/number link/images/glow skin/L1a.png', paleColor, bridgeHeight, bridgeWidth, fit: BoxFit.fill),
            ),
          ],
        ),
      );
    }
  }
}
