import 'package:shared_preferences/shared_preferences.dart';

/// Service for local storage operations
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  
  static const String tokenKey = 'game_tokens';
  static int get tokenCountSync => _prefs?.getInt(tokenKey) ?? 0;
  
  StorageService._();
  
  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }
  
  // Save string
  Future<bool> saveString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }
  
  // Get string
  String? getString(String key) {
    return _prefs!.getString(key);
  }
  
  // Save int
  Future<bool> saveInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }
  
  // Get int
  int? getInt(String key) {
    return _prefs!.getInt(key);
  }
  
  // Save bool
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }
  
  // Get bool
  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }
  
  // Save list of strings
  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }
  
  // Get list of strings
  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }
  
  // Remove key
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }
  
  // Clear all
  Future<bool> clear() async {
    return await _prefs!.clear();
  }
  
  // Check if key exists
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }
}
