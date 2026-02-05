import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _scoreKey = 'number_link_cumulative_score';
  static const String _levelKey = 'number_link_current_level';
  static const String _unlockedSkinsKey = 'number_link_unlocked_skins';
  static const String _currentSkinKey = 'number_link_current_skin';

  // Score methods
  Future<int> getCumulativeScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_scoreKey) ?? 0;
  }

  Future<void> saveCumulativeScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }

  Future<void> addScore(int points) async {
    final currentScore = await getCumulativeScore();
    await saveCumulativeScore(currentScore + points);
  }

  // Level progress methods
  Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 1; // Default to level 1
  }

  Future<void> saveCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, level);
  }

  // Unlocked skins methods (saved as comma-separated string)
  Future<List<String>> getUnlockedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    final skinsString = prefs.getString(_unlockedSkinsKey);
    if (skinsString == null || skinsString.isEmpty) {
      return ['numbered', 'square']; // Default unlocked skins
    }
    return skinsString.split(',');
  }

  Future<void> saveUnlockedSkins(List<String> skins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unlockedSkinsKey, skins.join(','));
  }

  // Current skin selection
  Future<String> getCurrentSkin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSkinKey) ?? 'numbered'; // Default to numbered
  }

  Future<void> saveCurrentSkin(String skin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSkinKey, skin);
  }

  // Clear all progress (for reset)
  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_levelKey);
    await prefs.remove(_unlockedSkinsKey);
    await prefs.remove(_currentSkinKey);
    await prefs.remove(_scoreKey);
  }
}
