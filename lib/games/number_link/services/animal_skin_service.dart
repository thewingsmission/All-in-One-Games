import 'package:flutter/material.dart';

class AnimalSkinService {
  // Store the mapping for the current session/level
  static final Map<String, String> _currentMapping = {};
  
  // Resets the mapping and generates a new random sampling.
  // Should be called when a new level is loaded or skin is switched.
  static void randomizeMapping(List<String> requiredKeys) {
    _currentMapping.clear();
    
    // Deterministic mapping: 'a'->1, 'b'->2, 'c'->3, etc.
    for (String key in requiredKeys) {
      int imageIndex = _getIndexFromKey(key);
      String numberStr = imageIndex.toString().padLeft(2, '0');
      _currentMapping[key] = 'assets/games/number link/images/animals/animal_image_$numberStr.png';
    }
  }
  
  static int _getIndexFromKey(String key) {
    if (key.length == 1) {
      int code = key.toLowerCase().codeUnitAt(0);
      if (code >= 97 && code <= 122) { // a-z
        int index = code - 96; // 'a'=1, 'b'=2, etc.
        if (index > 20) index = ((index - 1) % 20) + 1;
        return index;
      }
    }
    return 1; // fallback
  }

  // Mapping of terminal value (a, b, c...) to image asset path
  static String getAnimalAssetPath(String cellValue) {
    // If not in mapping (e.g. initial load or error), fallback to deterministic map
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
    if (index > 20) index = ((index - 1) % 20) + 1;
    String numberStr = index.toString().padLeft(2, '0');
    return 'assets/games/number link/images/animals/animal_image_$numberStr.png';
  }

  // Extracted background colors from the images (pixel 1,1)
  // Maps image filename number (e.g. '01') to Color
  static const Map<String, Color> _animalColors = {
    '01': Color(0xFFCAE9D9),
    '02': Color(0xFFFCD7BC),
    '03': Color(0xFFF7ECDA),
    '04': Color(0xFFFFDEBF),
    '05': Color(0xFFFADFD6),
    '06': Color(0xFFFEC6C5),
    '07': Color(0xFFCFD9C0),
    '08': Color(0xFFCCF9DA),
    '09': Color(0xFFDACAE4),
    '10': Color(0xFFBBDAEC),
    '11': Color(0xFFEEC0C0),
    '12': Color(0xFFE8CEFD),
    '13': Color(0xFFFDB1A3),
    '14': Color(0xFFC5E8E1),
    '15': Color(0xFFE1FAC3),
    '16': Color(0xFFF9ECB5),
    '17': Color(0xFFD4D5D7),
    '18': Color(0xFFFECB96),
    '19': Color(0xFFA5D4CE),
    '20': Color(0xFFFFC5C7),
  };

  static Color getAnimalColor(String cellValue) {
    String assetPath = getAnimalAssetPath(cellValue);
    // Path format: assets/games/number link/images/animals/animal_image_XX.png
    // Extract 'XX'
    try {
      final filename = assetPath.split('/').last; // animal_image_XX.png
      final numPart = filename.split('_').last.split('.').first; // XX
      return _animalColors[numPart] ?? Colors.grey; 
    } catch (_) {
      return Colors.grey;
    }
  }

  static Color getDarkAnimalColor(String cellValue) {
    Color base = getAnimalColor(cellValue);
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.5).clamp(0.0, 1.0)).toColor();
  }
}
