import 'package:flutter/material.dart';

class GlowCellRenderer {
  static const String _basePath = 'assets/games/number link/images/glow skin';
  static Widget buildTerminalCell(
    double cellSize,
    Color primaryColor,
    Color secondaryColor, {
    bool hasLeft = false,
    bool hasRight = false,
    bool hasTop = false,
    bool hasBottom = false,
  }) {
    final squareSize = cellSize * 0.75;
    final cornerRadius = squareSize * 0.2;
    final neighborCount = (hasLeft ? 1 : 0) + (hasRight ? 1 : 0) + (hasTop ? 1 : 0) + (hasBottom ? 1 : 0);
    
    if (neighborCount == 0) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: Center(
          child: Container(
            width: squareSize,
            height: squareSize,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    String imageFile;
    double rotation;
    
    if (neighborCount == 1) {
      imageFile = 'L5a.png';
      rotation = _getTerminalRotation(hasLeft, hasRight, hasTop, hasBottom);
    } else {
      imageFile = _getLImageFile(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
      rotation = _getLImageRotation(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    }
    
    final imageFileB = imageFile.replaceAll('a.png', 'b.png');
    
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: [
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFileB',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading $imageFileB for terminal: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Transform.rotate(
            angle: rotation * 3.14159265359 / 180,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/$imageFile',
                width: cellSize,
                height: cellSize,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading $imageFile for terminal: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Center(
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(cornerRadius),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
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
    
    final imageFile = _getLImageFile(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    final imageFileB = imageFile.replaceAll('a.png', 'b.png');
    final rotation = _getLImageRotation(neighborCount, hasLeft, hasRight, hasTop, hasBottom);
    
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: [
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
                  print('ERROR loading $imageFileB for path cell: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
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
                  print('ERROR loading $imageFile for path cell: $error');
                  return Container(
                    color: const Color(0xFFFF00FF), // Magenta
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ErrorXPainter(),
                          ),
                        ),
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
  
  static double _getTerminalRotation(bool hasLeft, bool hasRight, bool hasTop, bool hasBottom) {
    if (hasLeft) return 0.0;
    if (hasRight) return 180.0;
    if (hasTop) return 90.0;
    if (hasBottom) return 270.0;
    return 0.0;
  }
  
  static Widget buildBridge(
    double bridgeWidth,
    double bridgeHeight,
    Color primaryColor,
    Color secondaryColor,
    bool isHorizontal,
  ) {
    if (isHorizontal) {
      return SizedBox(
        width: bridgeWidth,
        height: bridgeHeight,
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1b.png',
                width: bridgeWidth,
                height: bridgeHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading L1b.png for horizontal bridge: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
            ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1a.png',
                width: bridgeWidth,
                height: bridgeHeight,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading L1a.png for horizontal bridge: $error');
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
    
    return SizedBox(
      width: bridgeWidth,
      height: bridgeHeight,
      child: RotatedBox(
        quarterTurns: 1,
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1b.png',
                width: bridgeHeight,
                height: bridgeWidth,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading L1b.png for vertical bridge: $error');
                  return const SizedBox.shrink();
                },
              ),
            ),
            ColorFiltered(
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              child: Image.asset(
                '$_basePath/L1a.png',
                width: bridgeHeight,
                height: bridgeWidth,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading L1a.png for vertical bridge: $error');
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

class _ErrorXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
