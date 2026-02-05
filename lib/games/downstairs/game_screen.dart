import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/gameplay_palette.dart';
import '../../shared/themes/app_theme.dart';

/// Downstairs - Endless runner game where cat runs down the stairs
class DownstairsGameScreen extends StatefulWidget {
  const DownstairsGameScreen({Key? key}) : super(key: key);

  @override
  State<DownstairsGameScreen> createState() => _DownstairsGameScreenState();
}

class _DownstairsGameScreenState extends State<DownstairsGameScreen> with TickerProviderStateMixin {
  // Game state
  GameState _gameState = GameState.start;
  int _score = 0;
  int _bestScore = 0;
  int _difficulty = 1;
  
  // Cat properties
  double _catX = 0;
  double _catY = 0;
  double _catVelocityX = 2.0;
  double _catVelocityY = 0;
  String _catDirection = 'right';
  bool _catOnGround = false;
  
  // Game parameters (moving block a bit smaller; sits with lower edge on bar upper edge)
  static const double catWidth = 52;
  static const double catHeight = 52;
  static const double gravity = 0.5;
  static const double jumpStrength = -12;
  static const double stairVerticalSpacing = 70;
  static const double stairWidth = 150;
  static const double stairHeight = 15;
  
  // Game objects
  List<Stair> _stairs = [];
  List<Obstacle> _obstacles = [];
  double _scrollOffset = 0;
  double _currentScrollSpeed = 0.4;
  double _currentCatSpeed = 1.8;
  int _stairIdCounter = 0;
  Set<int> _passedStairIds = {};
  
  // Touch tracking
  double? _currentTouchX; // Track current touch position
  
  // Animation
  Timer? _gameTimer;
  int _animationFrame = 0;

  // Moving block color from 20 palette, set at game start
  Color _catColor = GameplayPalette.colors.first;
  
  @override
  void initState() {
    super.initState();
    _loadBestScore();
    // Auto-start game when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('downstairs_best_score') ?? 0;
    });
  }
  
  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('downstairs_best_score', _score);
      setState(() {
        _bestScore = _score;
      });
    }
  }
  
  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _difficulty = 1;
      _scrollOffset = 0;
      _currentScrollSpeed = 0.4;
      _currentCatSpeed = 1.8;
      _passedStairIds.clear();
      _obstacles.clear();
      _catColor = GameplayPalette.colors[Random().nextInt(GameplayPalette.colors.length)];

      // Generate stairs
      _generateInitialStairs();
      
      // Place cat on first stair
      _catX = _stairs[0].x + _stairs[0].width / 2 - catWidth / 2;
      _catY = _stairs[0].y - catHeight;
      _catVelocityX = _currentCatSpeed;
      _catVelocityY = 0;
      _catDirection = 'right';
      _catOnGround = true;
      _animationFrame = 0;
      
      // Start game loop
      _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _gameLoop());
    });
  }
  
  void _generateInitialStairs() {
    _stairs.clear();
    _stairIdCounter = 0;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double y = screenHeight / 2;
    
    for (int i = 0; i < 30; i++) {
      double x;
      if (i == 0) {
        x = screenWidth / 2 - stairWidth / 2;
      } else {
        final prevStair = _stairs[i - 1];
        final minX = max(0.0, prevStair.x - prevStair.width + 50);
        final maxX = min(screenWidth - stairWidth, prevStair.x + prevStair.width - 50);
        x = minX + Random().nextDouble() * (maxX - minX);
      }
      
      _addStair(x, y, i == 0);
      
      y += stairVerticalSpacing + Random().nextDouble() * 30;
    }
    
    _passedStairIds.add(_stairs[0].id);
  }

  void _addStair(double x, double y, bool isInitial) {
    final idx = Random().nextInt(GameplayPalette.mainColors.length);
    final width = stairWidth + (Random().nextDouble() < 0.3 ? 50 : 0);
    _stairs.add(Stair(
      id: _stairIdCounter++,
      x: x,
      y: y,
      width: width,
      height: stairHeight,
      color: GameplayPalette.mainColors[idx],
      borderColor: GameplayPalette.paleColors[idx],
      isTransparent: !isInitial && Random().nextDouble() < 0.12,
      isBounce: !isInitial && Random().nextDouble() < 0.1,
    ));
  }

  void _gameLoop() {
    if (_gameState != GameState.playing) return;
    
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Update cat direction based on current touch position (if touching)
      if (_currentTouchX != null) {
        final catCenterX = _catX + catWidth / 2;
        if (_currentTouchX! < catCenterX) {
          _catDirection = 'left';
          _catVelocityX = -_currentCatSpeed;
        } else {
          _catDirection = 'right';
          _catVelocityX = _currentCatSpeed;
        }
      }
      
      // Scroll screen
      _scrollOffset += _currentScrollSpeed;
      
      // Count passed stairs
      for (final stair in _stairs) {
        final stairScreenY = stair.y - _scrollOffset;
        if (_catY > stairScreenY + stair.height && !_passedStairIds.contains(stair.id)) {
          _passedStairIds.add(stair.id);
          final stairsPassed = _passedStairIds.length - 1;
          _score = stairsPassed ~/ 10;
          
          // Increase difficulty
          final newDifficulty = (stairsPassed ~/ 50) + 1;
          if (newDifficulty > _difficulty) {
            _difficulty = newDifficulty;
            _currentScrollSpeed = 0.4 + (_difficulty - 1) * 0.25;
            _currentCatSpeed = 1.8 + (_difficulty - 1) * 0.35;
            if (_catDirection == 'right') {
              _catVelocityX = _currentCatSpeed;
            } else {
              _catVelocityX = -_currentCatSpeed;
            }
          }
        }
      }
      
      // Generate new stairs at bottom
      while (_stairs.isNotEmpty) {
        final bottomStair = _stairs.last;
        final bottomStairScreenY = bottomStair.y - _scrollOffset;
        if (bottomStairScreenY <= screenHeight + 300) {
          final prevStair = _stairs.last;
          final minX = max(0.0, prevStair.x - prevStair.width + 50);
          final maxX = min(screenWidth - stairWidth, prevStair.x + prevStair.width - 50);
          final x = minX + Random().nextDouble() * (maxX - minX);
          final y = prevStair.y + stairVerticalSpacing + Random().nextDouble() * 30;
          _addStair(x, y, false);
        } else {
          break;
        }
      }
      
      // Remove off-screen stairs
      _stairs.removeWhere((stair) => stair.y - _scrollOffset <= -100);
      
      // Apply gravity
      _catVelocityY += gravity;
      
      // Update cat position
      _catX += _catVelocityX;
      _catY += _catVelocityY;
      
      // Check stair collision
      _catOnGround = false;
      for (final stair in _stairs) {
        if (stair.isTransparent) continue;
        
        final stairScreenY = stair.y - _scrollOffset;
        if (_catVelocityY >= 0 &&
            _catY + catHeight >= stairScreenY &&
            _catY + catHeight <= stairScreenY + stair.height + 10 &&
            _catX + catWidth > stair.x &&
            _catX < stair.x + stair.width) {
          _catY = stairScreenY - catHeight;
          _catVelocityY = 0;
          _catOnGround = true;
          
          if (stair.isBounce) {
            _catVelocityY = jumpStrength;
            _catOnGround = false;
          }
          break;
        }
      }
      
      // Wall collision
      if (_catX <= 0) {
        _catX = 0;
        _catVelocityX = _currentCatSpeed;
        _catDirection = 'right';
      } else if (_catX + catWidth >= screenWidth) {
        _catX = screenWidth - catWidth;
        _catVelocityX = -_currentCatSpeed;
        _catDirection = 'left';
      }
      
      // Animation frame
      _animationFrame++;
      
      // Game over conditions
      if (_catY <= 0 || _catY > screenHeight) {
        _gameOver();
      }
    });
  }
  
  void _gameOver() {
    _gameTimer?.cancel();
    _saveBestScore();
    setState(() {
      _gameState = GameState.gameOver;
      _currentTouchX = null; // Clear touch when game ends
    });
  }
  
  void _handleTouchStart(TapDownDetails details) {
    if (_gameState != GameState.playing) return;
    _currentTouchX = details.localPosition.dx;
  }
  
  void _handleTouchUpdate(DragUpdateDetails details) {
    if (_gameState != GameState.playing) return;
    _currentTouchX = details.localPosition.dx;
  }
  
  void _handleTouchEnd(DragEndDetails details) {
    if (_gameState != GameState.playing) return;
    _currentTouchX = null;
  }
  
  void _handleTouchCancel() {
    if (_gameState != GameState.playing) return;
    _currentTouchX = null;
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return WillPopScope(
      onWillPop: () async {
        // Allow back button, but this prevents the gesture from interfering
        if (_gameState == GameState.playing) {
          _gameTimer?.cancel();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: _handleTouchStart,
          onPanStart: (details) => _handleTouchStart(TapDownDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
          )),
          onPanUpdate: _handleTouchUpdate,
          onPanEnd: _handleTouchEnd,
          onPanCancel: _handleTouchCancel,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Game canvas
              if (_gameState == GameState.playing)
                CustomPaint(
                  size: Size(screenWidth, screenHeight),
                  painter: GamePainter(
                    stairs: _stairs,
                    catX: _catX,
                    catY: _catY,
                    catColor: _catColor,
                    catDirection: _catDirection,
                    animationFrame: _animationFrame,
                    scrollOffset: _scrollOffset,
                  ),
                ),
              
              // Game over screen
              if (_gameState == GameState.gameOver)
                _buildGameOverScreen(),
              
              // HUD at top (Floor + game-dependent row)
              if (_gameState == GameState.playing)
                _buildHUD(),
              // Standard 5 buttons at bottom panel
              if (_gameState == GameState.playing)
                _buildBottomStandardPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStandardPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 10),
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(child: _standardPanelButton(Icons.replay, 'Play Again', _onPlayAgainTapped)),
              const SizedBox(width: 6),
              Expanded(child: _standardPanelButton(Icons.leaderboard, 'Leaderboard', _showLeaderboardDialog)),
              const SizedBox(width: 6),
              Expanded(child: _standardPanelButton(Icons.shop, 'Shop', _showShopDialog)),
              const SizedBox(width: 6),
              Expanded(child: _standardPanelButton(Icons.menu_book, 'Game Rule', _showGameRuleDialog)),
              const SizedBox(width: 6),
              Expanded(child: _standardPanelButton(Icons.logout, 'Leave', () { _gameTimer?.cancel(); Navigator.pop(context); })),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGameOverScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryMagenta, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryMagenta.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied, color: AppTheme.primaryMagenta, size: 56),
            const SizedBox(height: 12),
            Text(
              'GAME OVER',
              style: TextStyle(
                color: AppTheme.primaryMagenta,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: $_score',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_bestScore > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Best: $_bestScore',
                  style: const TextStyle(color: Colors.yellow, fontSize: 14),
                ),
              ),
            const SizedBox(height: 24),
            if (_rebornCount >= 1) ...[
              _buildGameOverButton('Reborn', () { setState(() => _rebornCount--); _startGame(); }),
              const SizedBox(height: 10),
            ],
            _buildGameOverButton('Play Again', _startGame),
            const SizedBox(height: 10),
            _buildGameOverButton('Back to All Games', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMagenta,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
  
  Widget _buildHUD() {
    // Progress at top + game-dependent row only; standard buttons are in bottom panel
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Floor $_score',
              style: const TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _buildGameDependentButtonsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDependentButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _gameDependentPanelButton('Slow Down', _onSlowDownTapped)),
        ],
      ),
    );
  }

  static const double _standardButtonHeight = 52;
  static const double _standardButtonFontSize = 12;
  static const double _standardButtonIconSize = 20;

  Widget _standardPanelButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      height: _standardButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: _standardButtonIconSize),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _standardButtonFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameDependentPanelButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
      ),
    );
  }

  void _onPlayAgainTapped() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.primaryMagenta, width: 2)),
        title: const Text('Restart?', style: TextStyle(color: Colors.white)),
        content: const Text('Your previous progress will be gone. Do you want to restart?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () { Navigator.pop(context); _startGame(); }, child: const Text('Yes', style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showLeaderboardDialog() {
    String selectedPeriod = 'All Time';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.neonGreen, width: 2)),
          title: const Center(child: Text('Leaderboard', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 20))),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['All Time', 'Weekly', 'Daily'].map((p) {
                    final isSelected = selectedPeriod == p;
                    return TextButton(
                      onPressed: () => setDialogState(() => selectedPeriod = p),
                      child: Text(p, style: TextStyle(color: isSelected ? AppTheme.neonGreen : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: ListView(
                    children: [
                      _leaderboardRow(1, 'Player1', 42),
                      _leaderboardRow(2, 'Player2', 38),
                      _leaderboardRow(3, 'Player3', 35),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: AppTheme.neonGreen)))],
        ),
      ),
    );
  }

  Widget _leaderboardRow(int rank, String name, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('$rank', style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold))),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
          Text('$score', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  int _rebornCount = 0;
  int _slowDownCount = 0;

  void _showShopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.primaryMagenta, width: 2)),
        title: const Center(child: Text('Shop', style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold))),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shopRow('Reborn', 'Revive once when game over', 50, () => setState(() => _rebornCount++)),
              _shopRow('Slow Down', 'Reduce scroll speed for 10s', 30, () => setState(() => _slowDownCount++)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: AppTheme.primaryMagenta)))],
      ),
    );
  }

  void _showGameRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.primaryCyan, width: 2)),
        title: const Center(child: Text('Game Rule', style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold))),
        content: const SingleChildScrollView(
          child: Text(
            'Guide the cat down the stairs. Tap and hold left or right to move. Avoid falling off the edges. '
            'Each floor you pass increases your score. Use Reborn from the shop to revive once when you game over.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppTheme.primaryCyan)))],
      ),
    );
  }

  Widget _shopRow(String name, String desc, int price, VoidCallback onBuy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
          Text('$price', style: const TextStyle(color: AppTheme.primaryOrange)),
          const SizedBox(width: 8),
          TextButton(onPressed: onBuy, child: const Text('Buy')),
        ],
      ),
    );
  }

  void _onSlowDownTapped() {
    if (_slowDownCount > 0) {
      setState(() => _slowDownCount--);
      // TODO: apply slow-down effect (reduce _currentScrollSpeed temporarily)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slow Down activated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Slow Down items. Buy in Shop.')));
    }
  }
}

// Stair data class (rack: inner from first 10 palette, border = 10+x = pale)
class Stair {
  final int id;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;       // inner: mainColors[idx]
  final Color borderColor;  // border: paleColors[idx] = palette 10+x
  final bool isTransparent;
  final bool isBounce;

  Stair({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.borderColor,
    this.isTransparent = false,
    this.isBounce = false,
  });
}

// Obstacle data class
class Obstacle {
  final int stairId;
  final double x;
  final double y;
  final double width;
  final double height;
  final String type;
  
  Obstacle({
    required this.stairId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
  });
}

// Game state enum
enum GameState { start, playing, gameOver }

// Custom painter for game
class GamePainter extends CustomPainter {
  final List<Stair> stairs;
  final double catX;
  final double catY;
  final Color catColor;
  final String catDirection;
  final int animationFrame;
  final double scrollOffset;

  GamePainter({
    required this.stairs,
    required this.catX,
    required this.catY,
    required this.catColor,
    required this.catDirection,
    required this.animationFrame,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal bars (stairs): rectangular, solid color
    for (final stair in stairs) {
      final screenY = stair.y - scrollOffset;

      if (screenY > -stair.height - 50 && screenY < size.height + 50) {
        final rect = Rect.fromLTWH(stair.x, screenY, stair.width, stair.height);
        final fillPaint = Paint()
          ..color = stair.isTransparent ? stair.color.withOpacity(0.3) : stair.color
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fillPaint);

        final borderPaint = Paint()
          ..color = stair.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(rect, borderPaint);

        if (stair.isBounce) {
          final textPainter = TextPainter(
            text: const TextSpan(text: '↑', style: TextStyle(fontSize: 20, color: Colors.white)),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(stair.x + stair.width / 2 - 10, screenY - 5));
        }
      }
    }

    // Draw moving block: lower edge touches bar upper edge (catY = bar top - block height)
    const catSize = 52.0;
    final catRect = Rect.fromLTWH(catX, catY, catSize, catSize);
    final catRRect = RRect.fromRectAndRadius(catRect, const Radius.circular(8));

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        catColor,
        Color.lerp(catColor, Colors.black, 0.2)!,
        catColor,
      ],
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(catRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(catRRect, gradientPaint);

    final catBorderPaint = Paint()
      ..color = catColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(catRRect, catBorderPaint);

    final dangerPaint = Paint()
      ..color = const Color(0xFFC896FF).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 50), dangerPaint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
