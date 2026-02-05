import 'package:flutter/foundation.dart';

enum LetterStatus { correct, present, absent, unknown }

class WordleGame extends ChangeNotifier {
  final int wordLength;
  final int maxAttempts = 6;

  /// Extra attempts from shop (Trial)
  int extraAttempts = 0;
  
  String targetWord = '';
  List<String> attempts = [];
  String currentGuess = '';
  bool isWon = false;
  bool isLost = false;
  
  WordleGame({required this.wordLength});
  
  void startNewGame(String word) {
    targetWord = word.toUpperCase();
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
  
  void addLetter(String letter) {
    if (currentGuess.length < wordLength && !isWon && !isLost) {
      currentGuess += letter.toUpperCase();
      notifyListeners();
    }
  }
  
  void removeLetter() {
    if (currentGuess.isNotEmpty && !isWon && !isLost) {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      notifyListeners();
    }
  }
  
  bool submitGuess() {
    if (currentGuess.length != wordLength || isWon || isLost) return false;
    
    attempts.add(currentGuess);
    
    if (currentGuess == targetWord) {
      isWon = true;
    } else if (attempts.length >= maxAttempts + extraAttempts) {
      isLost = true;
    }
    
    currentGuess = '';
    notifyListeners();
    return true;
  }
  
  LetterStatus getLetterStatus(int attemptIndex, int letterIndex) {
    if (attemptIndex >= attempts.length) return LetterStatus.unknown;
    
    final attempt = attempts[attemptIndex];
    if (letterIndex >= attempt.length) return LetterStatus.unknown;
    
    final letter = attempt[letterIndex];
    final targetLetter = targetWord[letterIndex];
    
    if (letter == targetLetter) {
      return LetterStatus.correct;
    } else if (targetWord.contains(letter)) {
      return LetterStatus.present;
    } else {
      return LetterStatus.absent;
    }
  }
  
  LetterStatus getKeyboardLetterStatus(String letter) {
    LetterStatus status = LetterStatus.unknown;
    
    for (var attempt in attempts) {
      for (int i = 0; i < attempt.length; i++) {
        if (attempt[i] == letter) {
          if (targetWord[i] == letter) {
            return LetterStatus.correct; // Best status - return immediately
          } else if (targetWord.contains(letter)) {
            status = LetterStatus.present; // Keep checking for better status
          } else if (status == LetterStatus.unknown) {
            status = LetterStatus.absent;
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
