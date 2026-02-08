import 'package:flutter/material.dart';
import '../../core/constants/game_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/token_service.dart';
import '../../core/services/achievement_service.dart';
import '../../shared/themes/app_theme.dart';
import '../design_guide/design_guide_screen.dart';
import '../settings/settings_popup.dart';

/// Home screen - Main menu with games in 2 columns
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Left column: Pong, Jenga, Number Link, Downstairs
    final leftColumnGames = [
      AppConstants.gamePong,
      AppConstants.gameJenga,
      AppConstants.gameNumberLink,
      AppConstants.gameDownstairs,
    ];
    
    // Right column: Sudoku, Wordle, Nerdle, Pokerdle
    final rightColumnGames = [
      AppConstants.gameSudoku,
      AppConstants.gameWordle,
      AppConstants.gameNerdle,
      AppConstants.gamePokerdle,
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryCyan, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.primaryCyan, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${TokenService.getTokenCount()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () => _showSettingsPopup(context),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, size: 28),
            tooltip: 'Achievements',
            onPressed: () => _showAchievementPopup(context),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, size: 28),
            onPressed: () => _showShopDialog(context),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.palette, size: 28, color: Colors.amber),
            tooltip: 'Design Guide',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DesignGuideScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _TwoColumnGameGrid(
            leftColumnGames: leftColumnGames,
            rightColumnGames: rightColumnGames,
          ),
        ),
      ),
    );
  }

  void _showShopDialog(BuildContext context) {
    final themeColor = AppTheme.primaryCyan;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: themeColor, width: 2),
        ),
        title: Center(
          child: Text(
            'Shop',
            style: TextStyle(
              color: themeColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, color: themeColor, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${TokenService.getTokenCount()}',
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on, color: themeColor, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tokens can be used to purchase game items in each game\'s shop',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                ...TokenService.tokenPacks.map((pack) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on, color: themeColor, size: 20),
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
                        ),
                        TextButton(
                          onPressed: () async {
                            await TokenService.addTokens(pack.tokens);
                            if (ctx.mounted) {
                              setState(() {});
                            }
                          },
                          child: Text(
                            '\$${pack.usd.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => setState(() {}));
  }

  void _showAchievementPopup(BuildContext context) {
    final themeColor = AppTheme.primaryCyan;
    showDialog<void>(
      context: context,
      builder: (ctx) => _AchievementDialog(themeColor: themeColor),
    );
  }

  void _showSettingsPopup(BuildContext context) {
    showSettingsPopup(context);
  }
}

class _AchievementDialog extends StatefulWidget {
  final Color themeColor;

  const _AchievementDialog({required this.themeColor});

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog> {
  List<Achievement> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AchievementService.getAchievements();
    if (mounted) setState(() { _list = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.themeColor;
    if (_loading) {
      return AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        content: const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
      );
    }
    return AlertDialog(
      backgroundColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
      title: Center(
        child: Text(
          'Achievements',
          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      content: SizedBox(
        width: 360,
        height: 400,
        child: ListView.builder(
          itemCount: _list.length,
          itemBuilder: (context, i) {
            final a = _list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColor.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(a.description, style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: a.progress.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: a.claimed ? null : (a.canClaim
                          ? () async {
                              await AchievementService.setClaimed(a.id);
                              if (mounted) await _load();
                            }
                          : null),
                      child: Text(
                        a.claimed ? 'Claimed' : (a.canClaim ? a.reward : a.reward),
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _TwoColumnGameGrid extends StatelessWidget {
  final List<String> leftColumnGames;
  final List<String> rightColumnGames;

  const _TwoColumnGameGrid({
    required this.leftColumnGames,
    required this.rightColumnGames,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max length to ensure both columns scroll together
    final maxLength = leftColumnGames.length > rightColumnGames.length
        ? leftColumnGames.length
        : rightColumnGames.length;

    return ListView.builder(
      itemCount: maxLength,
      itemBuilder: (context, index) {
        final leftGame = index < leftColumnGames.length
            ? GameRepository.getGameById(leftColumnGames[index])
            : null;
        final rightGame = index < rightColumnGames.length
            ? GameRepository.getGameById(rightColumnGames[index])
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Left button
              Expanded(
                child: leftGame != null
                    ? _GameIconButton(
                        game: leftGame,
                        onTap: () {
                          if (leftGame.id == AppConstants.gameNumberLink) {
                            Navigator.pushNamed(context, AppRouter.numberLink, arguments: 'normal');
                          } else if (leftGame.id == AppConstants.gameJenga) {
                            Navigator.pushNamed(context, AppRouter.jenga);
                          } else if (leftGame.id == AppConstants.gameWordle) {
                            Navigator.pushNamed(context, AppRouter.wordle, arguments: 5);
                          } else if (leftGame.id == AppConstants.gameNerdle) {
                            Navigator.pushNamed(context, AppRouter.nerdle);
                          } else {
                            AppRouter.toGameMenu(context, leftGame.id);
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 16),
              // Right button
              Expanded(
                child: rightGame != null
                    ? _GameIconButton(
                        game: rightGame,
                        onTap: () {
                          if (rightGame.id == AppConstants.gameNumberLink) {
                            Navigator.pushNamed(context, AppRouter.numberLink, arguments: 'normal');
                          } else if (rightGame.id == AppConstants.gameJenga) {
                            Navigator.pushNamed(context, AppRouter.jenga);
                          } else if (rightGame.id == AppConstants.gameWordle) {
                            Navigator.pushNamed(context, AppRouter.wordle, arguments: 5);
                          } else if (rightGame.id == AppConstants.gameNerdle) {
                            Navigator.pushNamed(context, AppRouter.nerdle);
                          } else {
                            AppRouter.toGameMenu(context, rightGame.id);
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameIconButton extends StatefulWidget {
  final dynamic game;
  final VoidCallback onTap;

  const _GameIconButton({
    required this.game,
    required this.onTap,
  });

  @override
  State<_GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<_GameIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Transform.scale(
          scale: 0.95,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final radius = size * 0.05; // 5% of button size
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: widget.game.themeColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.game.themeColor.withOpacity(0.45),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: widget.game.themeColor.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Image.asset(
                      widget.game.iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryOrange,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.games, size: 40, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  widget.game.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
