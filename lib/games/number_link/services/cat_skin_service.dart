import 'package:flutter/material.dart';

class CatSkinService {
  static final Map<String, String> _currentMapping = {};
  
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    
    for (String key in requiredKeys) {
      int imageIndex = _getIndexFromKey(key);
      String numberStr = imageIndex.toString().padLeft(2, '0');
      _currentMapping[key] = 'assets/games/number link/images/animals/cat_image_$numberStr.png';
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

  static String getCatAssetPath(String cellValue) {
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
    return 'assets/games/number link/images/animals/cat_image_$numberStr.png';
  }

  static Color getCatColor(String cellValue) {
    int index = _getImageIndex(cellValue);
    return _catColors[index] ?? Colors.pink.shade100;
  }

  static int _getImageIndex(String cellValue) {
    String assetPath = getCatAssetPath(cellValue);
    try {
      final filename = assetPath.split('/').last;
      final numPart = filename.split('_').last.split('.').first;
      return int.parse(numPart);
    } catch (_) {
      return 1;
    }
  }

  static const Map<int, Color> _catColors = {
    1: Color(0xFFFFE4E1), 2: Color(0xFFFFDAB9), 3: Color(0xFFFFF0F5),
    4: Color(0xFFE6E6FA), 5: Color(0xFFFFE4C4), 6: Color(0xFFFFF5EE),
    7: Color(0xFFF0FFF0), 8: Color(0xFFFFFACD), 9: Color(0xFFFFEFD5),
    10: Color(0xFFFFE4E1), 11: Color(0xFFF0F8FF), 12: Color(0xFFFDF5E6),
    13: Color(0xFFFFDAC1), 14: Color(0xFFE1F5FE), 15: Color(0xFFFCE4EC),
    16: Color(0xFFFFF9C4), 17: Color(0xFFE0F2F1), 18: Color(0xFFFCE4EC),
    19: Color(0xFFE8EAF6), 20: Color(0xFFFFF3E0),
  };

  static Color getDarkCatColor(String cellValue) {
    Color base = getCatColor(cellValue);
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.5).clamp(0.0, 1.0)).toColor();
  }
}
