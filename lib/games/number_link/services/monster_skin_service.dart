import 'package:flutter/material.dart';

class MonsterSkinService {
  static final Map<String, String> _currentMapping = {};
  
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    for (String key in requiredKeys) {
      int imageIndex = _getIndexFromKey(key);
      String numberStr = imageIndex.toString().padLeft(2, '0');
      _currentMapping[key] = 'assets/games/number link/images/animals/monster_image_$numberStr.png';
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

  static String getMonsterAssetPath(String cellValue) {
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
    return 'assets/games/number link/images/animals/monster_image_$numberStr.png';
  }

  static Color getMonsterColor(String cellValue) {
    int index = _getImageIndex(cellValue);
    return _monsterColors[index] ?? Colors.purple.shade100;
  }

  static int _getImageIndex(String cellValue) {
    String assetPath = getMonsterAssetPath(cellValue);
    try {
      final filename = assetPath.split('/').last;
      final numPart = filename.split('_').last.split('.').first;
      return int.parse(numPart);
    } catch (_) {
      return 1;
    }
  }

  static const Map<int, Color> _monsterColors = {
    1: Color(0xFFE1BEE7), 2: Color(0xFFCE93D8), 3: Color(0xFFBA68C8),
    4: Color(0xFFAB47BC), 5: Color(0xFFD1C4E9), 6: Color(0xFFB39DDB),
    7: Color(0xFF9575CD), 8: Color(0xFF7E57C2), 9: Color(0xFFB2DFDB),
    10: Color(0xFF80CBC4), 11: Color(0xFF4DB6AC), 12: Color(0xFF26A69A),
    13: Color(0xFFC5E1A5), 14: Color(0xFFAED581), 15: Color(0xFF9CCC65),
    16: Color(0xFF8BC34A), 17: Color(0xFFFFF9C4), 18: Color(0xFFFFF59D),
    19: Color(0xFFFFEE58), 20: Color(0xFFFFEB3B),
  };

  static Color getDarkMonsterColor(String cellValue) {
    Color base = getMonsterColor(cellValue);
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.5).clamp(0.0, 1.0)).toColor();
  }
}
