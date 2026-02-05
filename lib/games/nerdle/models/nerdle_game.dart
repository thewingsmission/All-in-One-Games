import 'package:flutter/foundation.dart';

enum CharStatus { correct, present, absent, unknown }

class NerdleGame extends ChangeNotifier {
  final int equationLength;

  /// Hard variant: max attempts = equation length
  int get maxAttempts => equationLength;

  /// Extra attempts from shop (Trial)
  int extraAttempts = 0;
  
  String targetEquation = '';
  List<String> attempts = [];
  String currentGuess = '';
  bool isWon = false;
  bool isLost = false;
  
  // Valid characters for Nerdle
  static const List<String> validChars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    '+', '-', 'x', '÷', '='
  ];
  
  NerdleGame({required this.equationLength});
  
  void startNewGame(String equation) {
    targetEquation = equation;
    attempts = [];
    currentGuess = '';
    isWon = false;
    isLost = false;
    extraAttempts = 0;
    notifyListeners();
  }

  /// Call after buying Trial in shop.
  void addExtraAttempt() {
    extraAttempts += 1;
    notifyListeners();
  }
  
  void addCharacter(String char) {
    if (currentGuess.length < equationLength && !isWon && !isLost) {
      if (validChars.contains(char)) {
        currentGuess += char;
        notifyListeners();
      }
    }
  }
  
  void removeCharacter() {
    if (currentGuess.isNotEmpty && !isWon && !isLost) {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      notifyListeners();
    }
  }
  
  bool submitGuess() {
    if (currentGuess.length != equationLength || isWon || isLost) return false;
    
    // Validate equation format
    if (!_isValidEquation(currentGuess)) {
      return false; // Invalid equation
    }
    
    attempts.add(currentGuess);
    
    if (currentGuess == targetEquation) {
      isWon = true;
    } else if (attempts.length >= maxAttempts + extraAttempts) {
      isLost = true;
    }
    
    currentGuess = '';
    notifyListeners();
    return true;
  }
  
  bool _isValidEquation(String equation) {
    // Must contain exactly one equals sign
    if (equation.split('=').length != 2) return false;
    
    final parts = equation.split('=');
    final leftSide = parts[0];
    final rightSide = parts[1];
    
    // Right side must be a number
    if (!_isNumber(rightSide)) return false;
    
    // Try to evaluate left side
    try {
      final leftValue = _evaluateExpression(leftSide);
      final rightValue = int.parse(rightSide);
      
      // Must be a valid equation
      return leftValue == rightValue;
    } catch (e) {
      return false;
    }
  }
  
  bool _isNumber(String str) {
    return int.tryParse(str) != null;
  }
  
  int _evaluateExpression(String expr) {
    // Simple expression evaluator for Nerdle equations
    // Handle order of operations: * and / before + and -
    
    expr = expr.replaceAll('x', '*').replaceAll('÷', '/');
    
    // Split by + and - (keeping operators)
    List<String> terms = [];
    String currentTerm = '';
    
    for (int i = 0; i < expr.length; i++) {
      if ((expr[i] == '+' || expr[i] == '-') && i > 0) {
        terms.add(currentTerm);
        terms.add(expr[i]);
        currentTerm = '';
      } else {
        currentTerm += expr[i];
      }
    }
    if (currentTerm.isNotEmpty) {
      terms.add(currentTerm);
    }
    
    // Evaluate * and / first
    List<dynamic> simplified = [];
    for (int i = 0; i < terms.length; i++) {
      if (terms[i] == '+' || terms[i] == '-') {
        simplified.add(terms[i]);
      } else {
        simplified.add(_evaluateMultDiv(terms[i]));
      }
    }
    
    // Now evaluate + and -
    int result = simplified[0] as int;
    for (int i = 1; i < simplified.length; i += 2) {
      final operator = simplified[i] as String;
      final operand = simplified[i + 1] as int;
      
      if (operator == '+') {
        result += operand;
      } else if (operator == '-') {
        result -= operand;
      }
    }
    
    return result;
  }
  
  int _evaluateMultDiv(String expr) {
    // Evaluate * and / in a term
    List<String> factors = [];
    String currentFactor = '';
    
    for (int i = 0; i < expr.length; i++) {
      if ((expr[i] == '*' || expr[i] == '/') && i > 0) {
        factors.add(currentFactor);
        factors.add(expr[i]);
        currentFactor = '';
      } else {
        currentFactor += expr[i];
      }
    }
    if (currentFactor.isNotEmpty) {
      factors.add(currentFactor);
    }
    
    int result = int.parse(factors[0]);
    for (int i = 1; i < factors.length; i += 2) {
      final operator = factors[i];
      final operand = int.parse(factors[i + 1]);
      
      if (operator == '*') {
        result *= operand;
      } else if (operator == '/') {
        if (operand == 0) throw Exception('Division by zero');
        result ~/= operand; // Integer division
      }
    }
    
    return result;
  }
  
  CharStatus getCharStatus(int attemptIndex, int charIndex) {
    if (attemptIndex >= attempts.length) return CharStatus.unknown;
    
    final attempt = attempts[attemptIndex];
    if (charIndex >= attempt.length) return CharStatus.unknown;
    
    final char = attempt[charIndex];
    final targetChar = targetEquation[charIndex];
    
    if (char == targetChar) {
      return CharStatus.correct;
    } else if (targetEquation.contains(char)) {
      return CharStatus.present;
    } else {
      return CharStatus.absent;
    }
  }
  
  CharStatus getKeyboardCharStatus(String char) {
    CharStatus status = CharStatus.unknown;
    
    for (var attempt in attempts) {
      for (int i = 0; i < attempt.length; i++) {
        if (attempt[i] == char) {
          if (targetEquation[i] == char) {
            return CharStatus.correct; // Best status
          } else if (targetEquation.contains(char)) {
            status = CharStatus.present;
          } else if (status == CharStatus.unknown) {
            status = CharStatus.absent;
          }
        }
      }
    }
    
    return status;
  }
  
  void reset() {
    attempts = [];
    currentGuess = '';
    isWon = false;
    isLost = false;
    notifyListeners();
  }
}
