import 'package:flutter/material.dart';

class DogSkinService {
  static final Map<String, String> _currentMapping = {};
  
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    for (String key in requiredKeys) {
      int imageIndex = _getIndexFromKey(key);
      String numberStr = imageIndex.toString().padLeft(2, '0');
      _currentMapping[key] = 'assets/games/number link/images/animals/dog_image_$numberStr.png';
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

  static String getDogAssetPath(String cellValue) {
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
    return 'assets/games/number link/images/animals/dog_image_$numberStr.png';
  }

  static Color getDogColor(String cellValue) {
    int index = _getImageIndex(cellValue);
    return _dogColors[index] ?? Colors.brown.shade100;
  }

  static int _getImageIndex(String cellValue) {
    String assetPath = getDogAssetPath(cellValue);
    try {
      final filename = assetPath.split('/').last;
      final numPart = filename.split('_').last.split('.').first;
      return int.parse(numPart);
    } catch (_) {
      return 1;
    }
  }

  static const Map<int, Color> _dogColors = {
    1: Color(0xFFD7CCC8), 2: Color(0xFFFFCCBC), 3: Color(0xFFBCAAA4),
    4: Color(0xFFFFE0B2), 5: Color(0xFFEFEBE9), 6: Color(0xFFFFE4C4),
    7: Color(0xFFF5F5DC), 8: Color(0xFFDEB887), 9: Color(0xFFD2B48C),
    10: Color(0xFFFFF8DC), 11: Color(0xFFFFEBCD), 12: Color(0xFFE8D5B7),
    13: Color(0xFFFFDAB9), 14: Color(0xFFCD853F), 15: Color(0xFFDAA520),
    16: Color(0xFFEEE8AA), 17: Color(0xFFFAF0E6), 18: Color(0xFFFDF5E6),
    19: Color(0xFFFFE4B5), 20: Color(0xFFFFDEAD),
  };

  static Color getDarkDogColor(String cellValue) {
    Color base = getDogColor(cellValue);
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.5).clamp(0.0, 1.0)).toColor();
  }
}
