import 'dart:math';
import 'package:flutter/services.dart';

class EquationService {
  final Map<int, List<String>> _equations = {};
  bool _initialized = false;
  
  /// Initialize equation lists for given lengths
  Future<void> initialize({List<int> equationLengths = const [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]}) async {
    if (_initialized) return;
    
    for (final length in equationLengths) {
      try {
        final csvString = await rootBundle.loadString(
          'assets/games/nerdle/data/$length-formula-sample.csv'
        );
        
        // Parse CSV - each line is an equation
        final equations = csvString
            .split('\n')
            .map((line) => line.trim())
            .where((eq) => eq.length == length && eq.contains('='))
            .toList();
        
        _equations[length] = equations;
        print('✅ Loaded ${equations.length} equations of length $length');
      } catch (e) {
        print('❌ Error loading $length-length equations: $e');
        _equations[length] = [];
      }
    }
    
    _initialized = true;
    print('✅ EquationService initialized with ${_equations.keys.length} equation lengths');
  }
  
  /// Get a random equation of specified length
  String? getRandomEquation(int length) {
    final equations = _equations[length];
    if (equations == null || equations.isEmpty) {
      print('⚠️ No equations found for length $length');
      return null;
    }
    return equations[Random().nextInt(equations.length)];
  }
  
  /// Check if an equation exists in the list
  bool isValidEquation(String equation, int length) {
    final equations = _equations[length];
    if (equations == null) return false;
    return equations.contains(equation);
  }
  
  /// Get equation count for a specific length
  int getEquationCount(int length) {
    return _equations[length]?.length ?? 0;
  }
  
  /// Get all available equation lengths
  List<int> getAvailableLengths() {
    return _equations.keys.where((length) => _equations[length]!.isNotEmpty).toList()..sort();
  }
}
