import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/game_menu/game_menu_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../games/number_link/screens/game_screen.dart' as number_link;
import '../../games/downstairs/game_screen.dart';
import '../../games/wordle/screens/game_screen.dart';
import '../../games/nerdle/screens/game_screen.dart';
import '../../games/jenga/screens/game_screen.dart' as jenga_game;
import '../../games/pong/screens/game_screen.dart' as pong_game;
import '../../games/pokerdle/screens/game_screen.dart' as pokerdle_game;
import '../../games/pokerdle/models/card.dart' as pokerdle_models;
import '../../games/sudoku/screens/game_screen.dart' as sudoku_game;
import '../../games/sudoku/models/sudoku_puzzle.dart';

/// Custom page route that disables iOS swipe-back gesture
class NoSwipePageRoute<T> extends MaterialPageRoute<T> {
  NoSwipePageRoute({
    required super.builder,
    super.settings,
  });

  @override
  bool get popGestureEnabled => false; // Disable swipe-back gesture
}

/// Navigation router for the app
class AppRouter {
  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String gameMenu = '/game-menu';
  static const String settings = '/settings';
  
  // Game routes
  static const String numberLink = '/number-link';
  static const String wordle = '/wordle';
  static const String nerdle = '/nerdle';
  static const String pokerdle = '/pokerdle';
  static const String sudoku = '/sudoku';
  static const String downstairs = '/downstairs';
  static const String jenga = '/jenga';
  static const String pong = '/pong';
  
  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    
    if (routeName == splash) {
      return NoSwipePageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );
    } else if (routeName == home) {
      return NoSwipePageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );
    } else if (routeName == gameMenu) {
      final gameId = settings.arguments as String;
      return NoSwipePageRoute(
        builder: (_) => GameMenuScreen(gameId: gameId),
        settings: settings,
      );
    } else if (routeName == settings) {
      return NoSwipePageRoute(
        builder: (_) => const SettingsScreen(),
        settings: settings,
      );
    } else if (routeName == numberLink) {
      final difficulty = settings.arguments as String?;
      return NoSwipePageRoute(
        builder: (_) => number_link.GameScreen(difficulty: difficulty ?? 'normal'),
        settings: settings,
      );
    } else if (routeName == downstairs) {
      return NoSwipePageRoute(
        builder: (_) => const DownstairsGameScreen(),
        settings: settings,
      );
    } else if (routeName == wordle) {
      // Wordle can have different word lengths, default to 5
      final wordLength = (settings.arguments as int?) ?? 5;
      return NoSwipePageRoute(
        builder: (_) => WordleGameScreen(wordLength: wordLength),
        settings: settings,
      );
    } else if (routeName == nerdle) {
      // Nerdle uses formula progression (Formula 1, 2, ...); no pre-game
      return NoSwipePageRoute(
        builder: (_) => const NerdleGameScreen(),
        settings: settings,
      );
    } else if (routeName == jenga) {
      return NoSwipePageRoute(
        builder: (_) => const jenga_game.GameScreen(),
        settings: settings,
      );
    } else if (routeName == pong) {
      return NoSwipePageRoute(
        builder: (_) => const pong_game.GameScreen(),
        settings: settings,
      );
    } else if (routeName == pokerdle) {
      // Pokerdle requires a hand type, default to Flush
      final handType = (settings.arguments as pokerdle_models.HandType?) ?? pokerdle_models.HandType.flush;
      return NoSwipePageRoute(
        builder: (_) => pokerdle_game.GameScreen(handType: handType),
        settings: settings,
      );
    } else if (routeName == sudoku) {
      // Sudoku requires a puzzle
      final puzzle = settings.arguments as SudokuPuzzle?;
      if (puzzle == null) {
        // Return error screen if no puzzle provided
        return NoSwipePageRoute(
          builder: (_) => const ErrorScreen(),
          settings: settings,
        );
      }
      return NoSwipePageRoute(
        builder: (_) => sudoku_game.GameScreen(puzzle: puzzle),
        settings: settings,
      );
    } else if (routeName == pokerdle || routeName == sudoku) {
      // Placeholder for other games
      return NoSwipePageRoute(
        builder: (_) => PlaceholderGameScreen(gameName: routeName!.substring(1)),
        settings: settings,
      );
    } else {
      // Default error screen
      return NoSwipePageRoute(
        builder: (_) => const ErrorScreen(),
        settings: settings,
      );
    }
  }
  
  /// Navigate to game menu
  static void toGameMenu(BuildContext context, String gameId) {
    Navigator.pushNamed(context, gameMenu, arguments: gameId);
  }
  
  /// Navigate to game
  static void toGame(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
  
  /// Go back
  static void back(BuildContext context) {
    Navigator.pop(context);
  }
}

// Placeholder for actual game screens
class PlaceholderGameScreen extends StatelessWidget {
  final String gameName;
  
  const PlaceholderGameScreen({Key? key, required this.gameName}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(gameName)),
      body: Center(child: Text('$gameName Game - Coming Soon')),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text('Page not found')),
    );
  }
}
