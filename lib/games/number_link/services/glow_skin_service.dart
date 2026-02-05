import 'package:flutter/material.dart';

enum NeighborConfig {
  terminal,      // Terminal cell (endpoint)
  horizontal,    // 2 neighbors: left-right (L1)
  vertical,      // 2 neighbors: top-bottom (L1 rotated 90°)
  cornerTL,      // 2 neighbors: top-left (L2)
  cornerTR,      // 2 neighbors: top-right (L2 rotated 90°)
  cornerBR,      // 2 neighbors: bottom-right (L2 rotated 180°)
  cornerBL,      // 2 neighbors: bottom-left (L2 rotated 270°)
  tShapeUp,      // 3 neighbors: left-top-right (L3)
  tShapeRight,   // 3 neighbors: top-right-bottom (L3 rotated 90°)
  tShapeDown,    // 3 neighbors: right-bottom-left (L3 rotated 180°)
  tShapeLeft,    // 3 neighbors: bottom-left-top (L3 rotated 270°)
  cross,         // 4 neighbors: all sides (L4)
}

class GlowSkinService {
  // Store the mapping for the current session/level
  // Maps cell value (a, b, c...) to color index (1-10)
  static final Map<String, int> _currentMapping = {};
  
  // Resets the mapping and generates assignments
  // For now, we have 10 colors, so we cycle through them
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    
    // We have 10 glow colors available (B1 through B10)
    const int totalColors = 10;
    
    for (int i = 0; i < requiredKeys.length; i++) {
      String key = requiredKeys[i];
      // Cycle through colors 1-10
      // Special case: 'k' uses same color as 'a' for demonstration
      if (key == 'k' && _currentMapping.containsKey('a')) {
        _currentMapping[key] = _currentMapping['a']!;
      } else {
        _currentMapping[key] = (i % totalColors) + 1;
      }
    }
  }
  
  // Get color index for a cell value
  static int getColorIndex(String cellValue) {
    if (_currentMapping.containsKey(cellValue)) {
      return _currentMapping[cellValue]!;
    }
    
    // Fallback logic
    int index = 0;
    if (cellValue.length == 1) {
      int code = cellValue.toLowerCase().codeUnitAt(0);
      if (code >= 97 && code <= 122) {
        index = code - 96; // a=1
      }
    }
    if (index < 1) index = 1;
    return ((index - 1) % 10) + 1; // Cycle through 1-10
  }
  
  // Get the appropriate image asset path based on cell value and neighbor configuration
  static String getGlowAssetPath(String cellValue, NeighborConfig config) {
    final colorIndex = getColorIndex(cellValue);
    
    switch (config) {
      case NeighborConfig.terminal:
        return 'assets/games/number link/images/ui/glow/B$colorIndex.png';
      
      case NeighborConfig.horizontal:
      case NeighborConfig.vertical:
        return 'assets/games/number link/images/ui/glow/B${colorIndex}_L1.png';
      
      case NeighborConfig.cornerTL:
      case NeighborConfig.cornerTR:
      case NeighborConfig.cornerBR:
      case NeighborConfig.cornerBL:
        return 'assets/games/number link/images/ui/glow/B${colorIndex}_L2.png';
      
      case NeighborConfig.tShapeUp:
      case NeighborConfig.tShapeRight:
      case NeighborConfig.tShapeDown:
      case NeighborConfig.tShapeLeft:
        return 'assets/games/number link/images/ui/glow/B${colorIndex}_L3.png';
      
      case NeighborConfig.cross:
        return 'assets/games/number link/images/ui/glow/B${colorIndex}_L4.png';
    }
  }
  
  // Get rotation angle in degrees based on neighbor configuration
  static double getRotationAngle(NeighborConfig config) {
    switch (config) {
      case NeighborConfig.terminal:
      case NeighborConfig.horizontal:
      case NeighborConfig.cornerTL:
      case NeighborConfig.tShapeUp:
      case NeighborConfig.cross:
        return 0.0;
      
      case NeighborConfig.vertical:
      case NeighborConfig.cornerTR:
      case NeighborConfig.tShapeRight:
        return 90.0;
      
      case NeighborConfig.cornerBR:
      case NeighborConfig.tShapeDown:
        return 180.0;
      
      case NeighborConfig.cornerBL:
      case NeighborConfig.tShapeLeft:
        return 270.0;
    }
  }
  
  // Determine neighbor configuration based on neighbors
  // neighbors: [top, right, bottom, left] - true if neighbor of same color exists
  // NOTE: This is for REGULAR cells only, not terminal cells
  // Terminal cells are handled separately in the renderer
  static NeighborConfig determineNeighborConfig(List<bool> neighbors) {
    final top = neighbors[0];
    final right = neighbors[1];
    final bottom = neighbors[2];
    final left = neighbors[3];
    
    final count = neighbors.where((n) => n).length;
    
    if (count == 0) {
      // No neighbors - shouldn't happen in valid gameplay, use horizontal as default
      return NeighborConfig.horizontal;
    } else if (count == 1) {
      // One neighbor - end of a line being drawn
      // Use L1 (2-neighbor) image oriented toward the neighbor
      if (top || bottom) return NeighborConfig.vertical;
      if (left || right) return NeighborConfig.horizontal;
    } else if (count == 2) {
      // Two neighbors
      if (left && right) return NeighborConfig.horizontal;
      if (top && bottom) return NeighborConfig.vertical;
      if (top && left) return NeighborConfig.cornerTL;
      if (top && right) return NeighborConfig.cornerTR;
      if (bottom && right) return NeighborConfig.cornerBR;
      if (bottom && left) return NeighborConfig.cornerBL;
    } else if (count == 3) {
      // Three neighbors (T-shape)
      if (!bottom) return NeighborConfig.tShapeUp;     // left-top-right
      if (!left) return NeighborConfig.tShapeRight;    // top-right-bottom
      if (!top) return NeighborConfig.tShapeDown;      // right-bottom-left
      if (!right) return NeighborConfig.tShapeLeft;    // bottom-left-top
    } else if (count == 4) {
      return NeighborConfig.cross;
    }
    
    return NeighborConfig.horizontal; // Fallback
  }
}
