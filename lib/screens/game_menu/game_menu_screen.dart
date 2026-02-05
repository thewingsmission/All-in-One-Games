import 'package:flutter/material.dart';
import '../../core/constants/game_repository.dart';
import '../../core/models/game_info.dart';
import '../../core/models/leaderboard_entry.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/token_service.dart';
import '../../shared/themes/app_theme.dart';
import '../../screens/settings/settings_popup.dart';
import '../../games/pokerdle/models/card.dart' as pokerdle_models;
import '../../games/sudoku/services/puzzle_service.dart';

/// Game menu screen - Number Link style with neon accents
class GameMenuScreen extends StatefulWidget {
  final String gameId;

  const GameMenuScreen({Key? key, required this.gameId}) : super(key: key);

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  String _selectedLeaderboardTab = 'all_time';
  String? _selectedDifficulty;
  
  late GameInfo? game;

  @override
  void initState() {
    super.initState();
    game = GameRepository.getGameById(widget.gameId);
    if (game != null && game!.hasDifficulty && game!.difficulties.isNotEmpty) {
      _selectedDifficulty = game!.difficulties.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (game == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('ERROR')),
        body: const Center(
          child: Text(
            'GAME NOT FOUND',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettingsPopup(context),
          color: Colors.white,
        ),
        title: const SizedBox.shrink(),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Token count
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryCyan, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.primaryCyan, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${TokenService.getTokenCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shop
          IconButton(
            icon: const Icon(Icons.shopping_cart, size: 28),
            onPressed: () => _showShopDialog(context),
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game header with icon
              _buildGameHeader(),
              
              const SizedBox(height: 20),
              
              // Leaderboard section
              _buildLeaderboardSection(),
              
              const SizedBox(height: 20),
              
              // Game rules section
              _buildRulesSection(),
              
              const SizedBox(height: 20),
              
              // Difficulty selection or start button
              if (game!.hasDifficulty)
                _buildDifficultySection()
              else
                _buildStartButton(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryCyan, width: 2),
      ),
      child: Row(
        children: [
          // Game icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                game!.iconPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryOrange,
                    child: const Icon(Icons.games, size: 35, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game!.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  game!.description,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.3,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEADERBOARD',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.neonGreen,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Toggle between All-Time and Weekly
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'ALL-TIME',
                  isSelected: _selectedLeaderboardTab == 'all_time',
                  onTap: () => setState(() => _selectedLeaderboardTab = 'all_time'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: 'WEEKLY',
                  isSelected: _selectedLeaderboardTab == 'weekly',
                  onTap: () => setState(() => _selectedLeaderboardTab = 'weekly'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Top 3 leaderboard entries
          ..._getPlaceholderLeaderboard().map((entry) => _buildLeaderboardEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    Color rankColor;
    IconData rankIcon;
    
    switch (entry.rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.white;
        rankIcon = Icons.person;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(rankIcon, color: rankColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.playerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            '${entry.score}',
            style: TextStyle(
              color: AppTheme.neonGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryOrange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO PLAY',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            game!.rules,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT DIFFICULTY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.primaryMagenta,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: game!.difficulties.map((difficulty) {
            final isSelected = _selectedDifficulty == difficulty;
            return GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = difficulty),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryMagenta : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryMagenta,
                    width: 2,
                  ),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isSelected ? Colors.black : AppTheme.primaryMagenta,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to actual game based on gameId
          if (widget.gameId == 'number_link') {
            // Convert display difficulty to internal format (e.g., "Very Easy" -> "very_easy")
            final internalDifficulty = (_selectedDifficulty ?? 'Normal')
                .toLowerCase()
                .replaceAll(' ', '_');
            
            Navigator.pushNamed(
              context,
              AppRouter.numberLink,
              arguments: internalDifficulty,
            );
          } else if (widget.gameId == 'downstairs') {
            Navigator.pushNamed(
              context,
              AppRouter.downstairs,
            );
          } else if (widget.gameId == 'wordle') {
            // Wordle uses word length (default 5)
            Navigator.pushNamed(
              context,
              AppRouter.wordle,
              arguments: 5, // Can be changed based on difficulty later
            );
          } else if (widget.gameId == 'nerdle') {
            // Nerdle uses formula progression (Formula 1, 2, ...); no pre-game selection
            Navigator.pushNamed(context, AppRouter.nerdle);
          } else if (widget.gameId == 'jenga') {
            Navigator.pushNamed(
              context,
              AppRouter.jenga,
            );
          } else if (widget.gameId == 'pong') {
            Navigator.pushNamed(
              context,
              AppRouter.pong,
            );
          } else if (widget.gameId == 'pokerdle') {
            // Generate a random hand type for Pokerdle (no selection)
            final randomHandType = pokerdle_models.HandType.values[
              DateTime.now().millisecondsSinceEpoch % pokerdle_models.HandType.values.length
            ];
            Navigator.pushNamed(
              context,
              AppRouter.pokerdle,
              arguments: randomHandType,
            );
          } else if (widget.gameId == 'sudoku') {
            _startSudoku();
          } else {
            // Show coming soon for other games
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'STARTING ${game!.name.toUpperCase()}${_selectedDifficulty != null ? ' - ${_selectedDifficulty!.toUpperCase()}' : ''}...',
                  style: const TextStyle(letterSpacing: 1.0),
                ),
                backgroundColor: AppTheme.primaryCyan,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryCyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_arrow, size: 32),
            SizedBox(width: 12),
            Text(
              'START GAME',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShopDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.primaryCyan, width: 2),
        ),
        title: Center(
          child: Text(
            'Shop',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on, color: AppTheme.primaryCyan, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${TokenService.getTokenCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ...TokenService.tokenPacks.map((pack) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.monetization_on, color: AppTheme.primaryCyan, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${pack.tokens}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${pack.usd.toStringAsFixed(0)} USD',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await TokenService.addTokens(pack.tokens);
                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                              setState(() {});
                            }
                          },
                          child: Text(
                            'Buy',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => setState(() {}));
  }

  void _showSettingsPopup(BuildContext context) {
    showSettingsPopup(context);
  }

  // Placeholder leaderboard data
  List<LeaderboardEntry> _getPlaceholderLeaderboard() {
    return [
      LeaderboardEntry(
        playerName: 'Player 1',
        score: 1000,
        timestamp: DateTime.now(),
        rank: 1,
      ),
      LeaderboardEntry(
        playerName: 'Player 2',
        score: 850,
        timestamp: DateTime.now(),
        rank: 2,
      ),
      LeaderboardEntry(
        playerName: 'Player 3',
        score: 720,
        timestamp: DateTime.now(),
        rank: 3,
      ),
    ];
  }

  // Start Sudoku with difficulty-based puzzle loading
  void _startSudoku() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryCyan),
        ),
      );

      // Load puzzle based on selected difficulty
      final puzzle = await PuzzleService.getRandomPuzzle(
        difficultyLevel: _selectedDifficulty,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to game
      Navigator.pushNamed(
        context,
        AppRouter.sudoku,
        arguments: puzzle,
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading puzzle: $e'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonGreen : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.neonGreen,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isSelected ? Colors.black : AppTheme.neonGreen,
          ),
        ),
      ),
    );
  }
}
