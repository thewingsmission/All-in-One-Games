import 'package:flutter/material.dart';

import '../../shared/themes/app_theme.dart';
import '../models/game_info.dart';
import 'app_constants.dart';

/// Repository of all available games. Each game has a distinct menu color.
class GameRepository {
  static const Color _yellow = Color(0xFFCCFF00);
  static const Color _blue = Color(0xFF00B0FF);
  static const Color _red = Color(0xFFFF5252);
  static const Color _jengaPink = Color(0xFFFF4081);
  static const Color _downstairsCyan = Color(0xFF00D9FF);
  static const Color _wordleAmber = Color(0xFFFFCC80);
  static const Color _nerdleMagenta = Color(0xFFFF59FF);
  static const Color _pokerdleOrange = Color(0xFFFF9452);
  static const Color _pongLavender = Color(0xFFE7C1E9);

  static const List<GameInfo> allGames = [
    GameInfo(
      id: AppConstants.gameNumberLink,
      name: 'Number Link',
      description: 'Connect matching numbers without crossing paths',
      iconPath: AppConstants.numberLinkIcon,
      themeColor: AppTheme.primaryMagenta,
      hasDifficulty: true,
      difficulties: ['Very Easy', 'Easy', 'Normal', 'Hard', 'Very Hard'],
      rules: '''Connect all pairs of matching numbers with paths that don't cross.
      
• Each number must be connected to its pair
• Paths cannot cross each other
• Fill the entire grid to win
• Use hints if you get stuck''',
    ),
    GameInfo(
      id: AppConstants.gameWordle,
      name: 'Wordle',
      description: 'Guess the word in 6 tries',
      iconPath: AppConstants.wordleIcon,
      themeColor: _wordleAmber,
      hasDifficulty: true,
      difficulties: ['3 Letters', '4 Letters', '5 Letters', '6 Letters', '7 Letters', '8 Letters'],
      rules: '''Guess the hidden word in 6 attempts.
      
• Green: Letter is correct and in right position
• Yellow: Letter is in the word but wrong position
• Gray: Letter is not in the word
• Each guess must be a valid word''',
    ),
    GameInfo(
      id: AppConstants.gameNerdle,
      name: 'Nerdle',
      description: 'Mathematical equation puzzle',
      iconPath: AppConstants.nerdleIcon,
      themeColor: _nerdleMagenta,
      hasDifficulty: true,
      difficulties: ['5 Chars', '6 Chars', '7 Chars', '8 Chars', '9 Chars', '10 Chars'],
      rules: '''Guess the mathematical equation.
      
• Green: Number/symbol correct and in right place
• Yellow: Number/symbol in equation but wrong place
• Gray: Not in the equation
• Must be a valid equation with = sign
• Order of operations matters (x and ÷ before + and -)''',
    ),
    GameInfo(
      id: AppConstants.gamePokerdle,
      name: 'Pokerdle',
      description: 'Poker hand guessing game',
      iconPath: AppConstants.pokerdleIcon,
      themeColor: _pokerdleOrange,
      hasDifficulty: false,
      rules: '''Guess the poker hand.
      
• Identify the correct 5-card poker hand
• Use poker hand rankings as clues
• Limited attempts to find the right combination''',
    ),
    GameInfo(
      id: AppConstants.gameSudoku,
      name: 'Sudoku',
      description: 'Classic number puzzle',
      iconPath: AppConstants.sudokuIcon,
      themeColor: _yellow,
      hasDifficulty: true,
      difficulties: ['Easy', 'Medium', 'Hard', 'Expert'],
      rules: '''Fill the 9×9 grid with numbers 1-9.
      
• Each row must contain 1-9 without repetition
• Each column must contain 1-9 without repetition
• Each 3×3 box must contain 1-9 without repetition
• Use logic to deduce the correct numbers''',
    ),
    GameInfo(
      id: AppConstants.gameDownstairs,
      name: 'Downstairs',
      description: 'Endless runner game',
      iconPath: AppConstants.downstairsIcon,
      themeColor: AppTheme.primaryCyan,
      hasDifficulty: false,
      rules: '''Navigate your character down the endless stairs.
      
• Move left and right to avoid obstacles
• Don't fall off the edges
• Survive as long as possible
• Beat your high score''',
    ),
    GameInfo(
      id: AppConstants.gameJenga,
      name: 'Jenga',
      description: 'Stack blocks as high as you can',
      iconPath: AppConstants.jengaIcon,
      themeColor: _jengaPink,
      hasDifficulty: false,
      rules: '''Stack colorful blocks to build the highest tower.
      
• Tap or press Space to drop the block
• Align blocks perfectly for bonus points
• Poor alignment causes instability
• Stack collapses after too many bad blocks''',
    ),
    GameInfo(
      id: AppConstants.gamePong,
      name: 'Pong',
      description: 'Classic arcade game',
      iconPath: AppConstants.pongIcon,
      themeColor: _pongLavender,
      hasDifficulty: false,
      rules: '''Keep the ball in play with your paddle.
      
• Move paddle with arrow keys or drag
• Ball speeds up every 3 bounces
• Hit edges for sharper angles
• Don't let the ball fall!''',
    ),
  ];
  
  /// Get game by ID
  static GameInfo? getGameById(String id) {
    try {
      return allGames.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }
}
