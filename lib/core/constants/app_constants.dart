/// App-wide constants
class AppConstants {
  // App info
  static const String appName = 'All-in-One Games';
  static const String appSubtitle = 'Play & Win';
  
  // Game IDs
  static const String gameNumberLink = 'number_link';
  static const String gameWordle = 'wordle';
  static const String gameNerdle = 'nerdle';
  static const String gamePokerdle = 'pokerdle';
  static const String gameSudoku = 'sudoku';
  static const String gameDownstairs = 'downstairs';
  static const String gameJenga = 'jenga';
  static const String gamePong = 'pong';
  
  // Asset paths - Common
  static const String iconPath = 'assets/common/icons/';

  /// Game icon paths: assets/games/<folder>/images/<Game Name> Icon.png
  static const String numberLinkIcon = 'assets/games/number link/images/Number Link Icon.png';
  static const String wordleIcon = 'assets/games/wordle/images/Wordle Icon.png';
  static const String nerdleIcon = 'assets/games/nerdle/images/Nerdle Icon.png';
  static const String pokerdleIcon = 'assets/games/pokerdle/images/Pokerdle Icon.png';
  static const String sudokuIcon = 'assets/games/sudoku/images/Sudoku Icon.png';
  static const String downstairsIcon = 'assets/games/downstairs/images/Downstairs Icon.png';
  static const String jengaIcon = 'assets/games/jenga/images/Jenga Icon.png';
  static const String pongIcon = 'assets/games/pong/images/Pong Icon.png';
  
  // Leaderboard
  static const int leaderboardTopCount = 3;
  
  // Storage keys
  static const String keyLastPlayedGame = 'last_played_game';
  static const String keyTotalGamesPlayed = 'total_games_played';
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Screen padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
}
