import 'package:flutter/material.dart';

class GhostSkinService {
  static final Map<String, String> _currentMapping = {};
  
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    for (String key in requiredKeys) {
      int imageIndex = _getIndexFromKey(key);
      String numberStr = imageIndex.toString().padLeft(2, '0');
      _currentMapping[key] = 'assets/games/number link/images/animals/ghost_image_$numberStr.png';
    }
  }
  
  static int _getIndexFromKey(String key) {
    if (key.length == 1) {
      int code = key.toLowerCase().codeUnitAt(0);
      if (code >= 97 && code <= 122) {
        int index = code - 96;
        if (index > 20) index = ((index - 1) % 20) + 1;
        return index;
      }
    }
    return 1;
  }

  static String getGhostAssetPath(String cellValue) {
    if (_currentMapping.containsKey(cellValue)) {
      return _currentMapping[cellValue]!;
    }
    int index = 0;
    if (cellValue.length == 1) {
      int code = cellValue.toLowerCase().codeUnitAt(0);
      if (code >= 97 && code <= 122) {
        index = code - 96;
      }
    }
    if (index < 1) index = 1;
    if (index > 20) index = ((index - 1) % 20) + 1;
    String numberStr = index.toString().padLeft(2, '0');
    return 'assets/games/number link/images/animals/ghost_image_$numberStr.png';
  }

  static Color getGhostColor(String cellValue) {
    int index = _getImageIndex(cellValue);
    return _ghostColors[index] ?? Colors.grey.shade200;
  }

  static int _getImageIndex(String cellValue) {
    String assetPath = getGhostAssetPath(cellValue);
    try {
      final filename = assetPath.split('/').last;
      final numPart = filename.split('_').last.split('.').first;
      return int.parse(numPart);
    } catch (_) {
      return 1;
    }
  }

  static const Map<int, Color> _ghostColors = {
    1: Color(0xFFF5F5F5), 2: Color(0xFFE0E0E0), 3: Color(0xFFECEFF1),
    4: Color(0xFFCFD8DC), 5: Color(0xFFE8EAF6), 6: Color(0xFFC5CAE9),
    7: Color(0xFFB0BEC5), 8: Color(0xFF90A4AE), 9: Color(0xFFEFEBE9),
    10: Color(0xFFE0F2F1), 11: Color(0xFFB2DFDB), 12: Color(0xFFE1F5FE),
    13: Color(0xFFB3E5FC), 14: Color(0xFFF3E5F5), 15: Color(0xFFE1BEE7),
    16: Color(0xFFEDE7F6), 17: Color(0xFFD1C4E9), 18: Color(0xFFE8F5E9),
    19: Color(0xFFC8E6C9), 20: Color(0xFFFFFDE7),
  };

  static Color getDarkGhostColor(String cellValue) {
    Color base = getGhostColor(cellValue);
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.5).clamp(0.0, 1.0)).toColor();
  }
}
