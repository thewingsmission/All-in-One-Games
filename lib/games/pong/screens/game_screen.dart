import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import '../../../shared/themes/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Timer _gameTimer;
  final FocusNode _focusNode = FocusNode();
  
  // Game state
  bool isGameOver = false;
  bool hasGameStarted = false;
  int score = 0;
  double ballSpeed = 500.0;
  
  // Ball
  Offset ballPosition = const Offset(0, 0);
  Offset ballVelocity = const Offset(0, 0);
  final double ballRadius = 20;
  
  // Paddle
  double paddleX = 0;
  double targetPaddleX = 0;
  final double paddleWidth = 120;
  final double paddleHeight = 15;
  final double paddleSpeed = 800;
  
  // Paddle colors (cycling)
  final List<Color> paddleColors = [
    AppTheme.neonGreen,
    AppColors.accent,
    const Color(0xFFFFFF00), // Yellow
    AppColors.primary,
    AppTheme.primaryOrange,
    const Color(0xFF6600FF), // Purple
    const Color(0xFF00FF99), // Mint
    const Color(0xFFFF0066), // Pink
  ];
  int currentColorIndex = 0;
  
  // Screen dimensions
  double screenWidth = 0;
  double screenHeight = 0;
  final double wallThickness = 10;
  
  // Keyboard
  final Set<LogicalKeyboardKey> pressedKeys = {};
  
  // Stars background
  List<Star> stars = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _initializeGame();
      // Start game immediately
      _startGame();
    });
  }

  void _initializeGame() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    
    // Initialize stars
    stars.clear();
    for (int i = 0; i < 80; i++) {
      stars.add(Star(
        position: Offset(
          random.nextDouble() * screenWidth,
          random.nextDouble() * screenHeight,
        ),
        size: random.nextDouble() * 2 + 0.5,
        speed: random.nextDouble() * 30 + 10,
        brightness: random.nextDouble() * 0.5 + 0.5,
      ));
    }
    
    // Initialize paddle position
    paddleX = screenWidth / 2;
    targetPaddleX = paddleX;
  }

  void _startGame() {
    setState(() {
      hasGameStarted = true;
      isGameOver = false;
      score = 0;
      ballSpeed = 500.0;
      currentColorIndex = 0;
      
      // Reset ball
      ballPosition = Offset(screenWidth / 2, 100);
      ballVelocity = Offset(0, ballSpeed);
      
      // Reset paddle
      paddleX = screenWidth / 2;
      targetPaddleX = paddleX;
    });
    
    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!hasGameStarted || isGameOver) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _updateGame(0.016);
      });
    });
  }

  void _updateGame(double dt) {
    // Update stars
    for (var star in stars) {
      star.update(dt, screenWidth, screenHeight);
    }
    
    // Update paddle
    _updatePaddle(dt);
    
    // Update ball
    _updateBall(dt);
  }

  void _updatePaddle(double dt) {
    // Handle keyboard input
    if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      targetPaddleX = paddleX - paddleSpeed * dt;
    }
    if (pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      targetPaddleX = paddleX + paddleSpeed * dt;
    }
    
    // Smooth movement
    final diff = targetPaddleX - paddleX;
    if (diff.abs() > 2) {
      paddleX += diff.sign * min(paddleSpeed * dt, diff.abs());
    }
    
    // Keep within bounds
    final halfWidth = paddleWidth / 2;
    if (paddleX < wallThickness + halfWidth) {
      paddleX = wallThickness + halfWidth;
      targetPaddleX = paddleX;
    }
    if (paddleX > screenWidth - wallThickness - halfWidth) {
      paddleX = screenWidth - wallThickness - halfWidth;
      targetPaddleX = paddleX;
    }
  }

  void _updateBall(double dt) {
    // Move ball
    ballPosition = Offset(
      ballPosition.dx + ballVelocity.dx * dt,
      ballPosition.dy + ballVelocity.dy * dt,
    );
    
    // Check collision with top wall
    if (ballPosition.dy - ballRadius <= wallThickness) {
      ballPosition = Offset(ballPosition.dx, wallThickness + ballRadius);
      ballVelocity = Offset(ballVelocity.dx, ballVelocity.dy.abs());
      _addRandomHorizontal();
    }
    
    // Check collision with left wall
    if (ballPosition.dx - ballRadius <= wallThickness) {
      ballPosition = Offset(wallThickness + ballRadius, ballPosition.dy);
      ballVelocity = Offset(ballVelocity.dx.abs(), ballVelocity.dy);
    }
    
    // Check collision with right wall
    if (ballPosition.dx + ballRadius >= screenWidth - wallThickness) {
      ballPosition = Offset(screenWidth - wallThickness - ballRadius, ballPosition.dy);
      ballVelocity = Offset(-ballVelocity.dx.abs(), ballVelocity.dy);
    }
    
    // Check if ball fell off bottom
    if (ballPosition.dy > screenHeight + 50) {
      _gameOver();
      return;
    }
    
    // Check collision with paddle
    if (_checkPaddleCollision()) {
      ballVelocity = Offset(ballVelocity.dx, -ballSpeed);
      _incrementScore();
      _addRandomHorizontal();
    }
  }

  bool _checkPaddleCollision() {
    final paddleY = screenHeight - 150;
    
    if (ballVelocity.dy > 0 && // Ball moving down
        ballPosition.dy + ballRadius >= paddleY - paddleHeight / 2 &&
        ballPosition.dy - ballRadius <= paddleY + paddleHeight / 2 &&
        ballPosition.dx >= paddleX - paddleWidth / 2 &&
        ballPosition.dx <= paddleX + paddleWidth / 2) {
      
      // Calculate hit position on paddle (-1 to 1)
      final hitPos = (ballPosition.dx - paddleX) / (paddleWidth / 2);
      
      // Apply angle based on hit position
      final angleFactor = hitPos * hitPos.abs();
      ballVelocity = Offset(angleFactor * 400, ballVelocity.dy);
      
      return true;
    }
    return false;
  }

  void _addRandomHorizontal() {
    if (ballVelocity.dx.abs() < 50) {
      ballVelocity = Offset(
        ballVelocity.dx + (random.nextDouble() - 0.5) * 100,
        ballVelocity.dy,
      );
    }
  }

  void _incrementScore() {
    score++;
    
    // Change paddle color
    currentColorIndex = (currentColorIndex + 1) % paddleColors.length;
    
    // Increase speed every 3 bounces
    if (score % 3 == 0) {
      ballSpeed += 75;
    }
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
    });
  }

  void _handlePointerMove(Offset position) {
    if (!isGameOver && hasGameStarted) {
      setState(() {
        targetPaddleX = position.dx;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          pressedKeys.add(event.logicalKey);
          if (isGameOver && event.logicalKey == LogicalKeyboardKey.space) {
            _startGame();
          }
        } else if (event is KeyUpEvent) {
          pressedKeys.remove(event.logicalKey);
        }
      },
      child: GestureDetector(
        onTapDown: (details) {
          _focusNode.requestFocus();
          if (isGameOver) {
            // Don't restart on tap; user must use PLAY AGAIN or Menu
            return;
          } else if (hasGameStarted) {
            _handlePointerMove(details.localPosition);
          }
        },
        onPanUpdate: (details) {
          _handlePointerMove(details.localPosition);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Game canvas
              CustomPaint(
                painter: PongPainter(
                  stars: stars,
                  ballPosition: ballPosition,
                  ballRadius: ballRadius,
                  paddleX: paddleX,
                  paddleWidth: paddleWidth,
                  paddleHeight: paddleHeight,
                  paddleColor: paddleColors[currentColorIndex],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  wallThickness: wallThickness,
                ),
                child: Container(),
              ),
              
              // Score
              if (hasGameStarted && !isGameOver)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Score: $score',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Game over screen
              if (isGameOver)
                Container(
                  color: AppColors.background.withOpacity(0.95),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Final Score: $score',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 25,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'PLAY AGAIN',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 22,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Back button (top-right, offset down to avoid status bar and improve tap target)
              if (hasGameStarted && !isGameOver)
                Positioned(
                  top: 56,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.primary, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(12),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PongPainter extends CustomPainter {
  final List<Star> stars;
  final Offset ballPosition;
  final double ballRadius;
  final double paddleX;
  final double paddleWidth;
  final double paddleHeight;
  final Color paddleColor;
  final double screenWidth;
  final double screenHeight;
  final double wallThickness;

  PongPainter({
    required this.stars,
    required this.ballPosition,
    required this.ballRadius,
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.paddleColor,
    required this.screenWidth,
    required this.screenHeight,
    required this.wallThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var star in stars) {
      star.render(canvas, starPaint);
    }
    
    // Draw walls
    final wallPaint = Paint()
      ..color = const Color(0xFF0066FF).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Top wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, wallThickness),
      wallPaint,
    );
    // Left wall
    canvas.drawRect(
      Rect.fromLTWH(0, 0, wallThickness, screenHeight),
      wallPaint,
    );
    // Right wall
    canvas.drawRect(
      Rect.fromLTWH(screenWidth - wallThickness, 0, wallThickness, screenHeight),
      wallPaint,
    );
    
    // Draw ball
    final ballPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    final ballGlowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(ballPosition, ballRadius + 6, ballGlowPaint);
    canvas.drawCircle(ballPosition, ballRadius, ballPaint);
    
    // Draw paddle
    final paddleY = screenHeight - 150;
    final paddleRect = Rect.fromCenter(
      center: Offset(paddleX, paddleY),
      width: paddleWidth,
      height: paddleHeight,
    );
    
    final paddlePaint = Paint()
      ..color = paddleColor
      ..style = PaintingStyle.fill;
    
    final paddleGlowPaint = Paint()
      ..color = paddleColor.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final paddleGlowRect = Rect.fromCenter(
      center: Offset(paddleX, paddleY),
      width: paddleWidth + 10,
      height: paddleHeight + 10,
    );
    
    canvas.drawRect(paddleGlowRect, paddleGlowPaint);
    canvas.drawRect(paddleRect, paddlePaint);
  }

  @override
  bool shouldRepaint(PongPainter oldDelegate) => true;
}

class Star {
  Offset position;
  double size;
  double speed;
  double brightness;
  double twinklePhase;
  
  Star({
    required this.position,
    required this.size,
    required this.speed,
    required this.brightness,
  }) : twinklePhase = Random().nextDouble() * 2 * pi;
  
  void update(double dt, double screenWidth, double screenHeight) {
    // Move star downward
    position = Offset(position.dx, position.dy + speed * dt);
    
    // Update twinkle
    twinklePhase += dt;
    
    // Wrap around
    if (position.dy > screenHeight) {
      position = Offset(Random().nextDouble() * screenWidth, 0);
    }
  }
  
  void render(Canvas canvas, Paint sharedPaint) {
    final twinkle = (sin(twinklePhase) + 1) / 2;
    final opacity = brightness * (0.5 + twinkle * 0.5);
    
    sharedPaint.color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(position, size, sharedPaint);
  }
}
