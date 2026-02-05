import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/themes/app_theme.dart';
import '../../../core/services/token_service.dart';
import '../../../core/constants/game_repository.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class Block {
  double x;
  double y;
  String imagePath;
  bool isPlaced;
  double width;
  double height;
  double rotation;
  Color color;

  Block({
    required this.x,
    required this.y,
    required this.imagePath,
    this.isPlaced = false,
    this.width = 100,
    this.height = 50,
    this.rotation = 0,
    this.color = Colors.red,
  });
}

class FallingPaw {
  double x;
  double y;
  double speed;
  double size;
  String imagePath;
  
  FallingPaw({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.imagePath,
  });
}

/// Block skin styles for Jenga (8 total; neon and galaxy have animation)
enum JengaBlockSkin {
  classic,
  wood,
  neon,
  marble,
  candy,
  fire,
  ice,
  galaxy,
}

// Pong menu color for Jenga game over (same as Pong theme)
const Color _jengaGameOverColor = Color(0xFF00B0FF);

// Storage keys for Jenga consumables and skin
const String _jengaAlignKey = 'jenga_align_count';
const String _jengaFreezeKey = 'jenga_freeze_count';
const String _jengaSkinKey = 'jenga_skin_index';

const int _maxBlocksInMemory = 15;

// Game over: lift phase shows top N blocks + falling block, then capture gameplay screen
const int _gameOverVisibleBlocks = 14;
const int _gameOverLiftMs = 400;
const int _gameOverHoldMs = 500;
const double _gameOverScreenshotWidth = 200;
const double _gameOverScreenshotHeight = 320;

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Neon laser colors: first 10 for feedback font, indices 10..19 for overflow glow
  final List<Color> laserColors = [
    AppColors.primary,       // 0 Neon Cyan
    AppColors.accent,        // 1 Neon Magenta
    AppTheme.primaryOrange,  // 2 Neon Orange
    AppTheme.neonGreen,      // 3 Neon Green
    const Color(0xFFFFFF00), // 4 Yellow
    const Color(0xFF9900FF), // 5 Purple
    const Color(0xFF00FFAA), // 6 Turquoise
    const Color(0xFFFF0080), // 7 Hot Pink
    const Color(0xFF00FFFF), // 8 Cyan
    const Color(0xFFFF6600), // 9 Orange
    const Color(0xFF00FF00), // 10 glow
    const Color(0xFF0080FF), // 11
    const Color(0xFFFF00FF), // 12
    const Color(0xFF80FF00), // 13
    const Color(0xFFFF8000), // 14
    const Color(0xFF8000FF), // 15
    const Color(0xFF00FF80), // 16
    const Color(0xFFFF0080), // 17
    const Color(0xFF80FFFF), // 18
    const Color(0xFFFFFF80), // 19
  ];

  List<Block> placedBlocks = [];
  int _totalBlocksPlaced = 0; // for display "Block X"; only top 15 blocks kept in placedBlocks
  Block? currentBlock;
  Uint8List? _towerScreenshot;
  final GlobalKey _gameAreaCaptureKey = GlobalKey();
  bool _isGameOverLiftPhase = false;
  double _liftStartDrawOffsetY = 0;
  double _liftTargetDrawOffsetY = 0;
  double _liftAnimationValue = 0;
  AnimationController? _liftAnimationController;
  Timer? _liftBlockRotationTimer;
  double screenWidth = 0;
  double screenHeight = 0;
  double _reservedTopHeight = 106; // Title row + button row
  double _reservedBottomHeight = 88; // Bottom panel + SafeArea (increased so blocks don't sink into panel)
  double _gameAreaHeight = 0; // Set from LayoutBuilder; 0 = use fallback
  double _gameAreaWidth = 0; // Set from LayoutBuilder; used for block trajectory
  double get gameplayHeight => _gameAreaHeight > 0 ? _gameAreaHeight : (screenHeight - _reservedTopHeight - _reservedBottomHeight).clamp(100.0, double.infinity);
  double get _trajectoryWidth => _gameAreaWidth > 0 ? _gameAreaWidth : screenWidth;
  // 15 * block height = gameplay screen height; width = 2 * height (scales with device)
  double get _blockHeight => gameplayHeight / 15;
  double get _blockWidth => _blockHeight * 2;
  bool isGameOver = false;
  bool hasGameStarted = false;
  String? feedbackText;
  int _feedbackColorIndex = 0; // 0..9 for font; glow = laserColors[10 + index]
  Color? _feedbackFontColor; // palette color for text (set when showing feedback)
  Color? _feedbackGlowColor; // palette color for outer glow (set when showing feedback)
  AnimationController? feedbackController;
  String playerName = 'Player';
  double cameraOffsetY = 0;
  double targetCameraOffsetY = 0;
  
  double stackShakeOffset = 0;
  double stackInstability = 0;
  AnimationController? shakeController;
  int acceptableBlockCount = 0;
  /// Vertical shake on touch: entire tower (and new block) move up and down quickly (not earthquake).
  double stackBounceOffsetY = 0;
  AnimationController? bounceController;
  Timer? continuousWaveTimer;
  double wavePhase = 0;

  final Random random = Random();
  final FocusNode _focusNode = FocusNode();
  
  Timer? _autoMoveTimer;
  double _moveDirection = 1;
  static const double _moveSpeedMin = 3;
  static const double _moveSpeedMax = 6;
  double _moveSpeed = _moveSpeedMin; // ramps with block count up to _moveSpeedMax
  
  Timer? _cameraTimer;

  // At touch: freeze shake at touch value (no teleport); during vibration keep that value; resume wave when finished
  bool _zeroShakeDuringVibration = false;
  double _shakeFrozenAtTouch = 0; // tower drawn position = block.x + this (no snap to block.x)

  /// Temporary stop on touch: no x-motion for tower or new block for this many ms (avoids slip).
  static const int _touchFreezeMs = 500;
  /// Approx frames at 60fps: _touchFreezeMs/16.67 ≈ 30 frames

  /// True from touch until 500ms callback (merge).
  bool _isInTouchFreeze = false;
  /// During touch freeze, multiplier for drawing current block with tower shake (same as top block).
  double _touchFreezeNewBlockShakeMult = 0;
  /// True when horizontal shake ran during the 500ms freeze (bad placement); skip x-correction at merge.
  bool _didTouchShake = false;
  AnimationController? _touchShakeController;

  // Jenga consumables and UI
  int _alignCount = 3; // consumable align items
  int _alignUseCount = 0; // times align used this game (cost = 2^_alignUseCount)
  int _freezeCount = 3;
  int _freezeUseCount = 0; // times freeze used this game (cost = 2^_freezeUseCount)
  int _rebornTimesUsedThisGame = 0; // 0 = first lose (8 tokens or ad), 1 = 16 tokens, 2 = 32, ...
  int _skinIndex = 0; // JengaBlockSkin index
  bool _isDialogOpen = false;
  DateTime? _freezeUntil; // When freeze ends; when set, no shake/movement
  bool get _isFrozen => _freezeUntil != null && DateTime.now().isBefore(_freezeUntil!);
  double _freezeRemainingSec = 0; // For countdown display in Freeze button (e.g. 2.34)
  Timer? _freezeCountdownTimer;
  // Skin animation (two skins: neon pulse, galaxy shift)
  AnimationController? _neonPulseController;
  AnimationController? _galaxyShiftController;
  double _neonPulseValue = 0;
  double _galaxyShiftValue = 0;
  static const double _standardButtonHeight = 42;
  static const double _standardButtonFontSize = 11;
  static const double _standardButtonIconSize = 12;
  static const double _standardButtonRadius = 12;
  static const double _buttonGlowBlur = 10;
  static const double _buttonGlowSpread = 1;
  static const double _dialogTitleFontSize = 16;
  static const double _dialogButtonFontSize = 14;
  // Bottom 5 buttons (same as Number Link)
  static const Color _bottomRestartColor = Color(0xFF00D9FF);
  static const Color _bottomLeaderboardColor = Color(0xFF00FF41);
  static const Color _bottomShopColor = Color(0xFFCCFF00);
  static const Color _bottomGameRuleColor = Color(0xFFFF6600);
  static const Color _bottomLeaveColor = Color(0xFFFF00FF);
  // Top 3: Skin, Align, Freeze
  static const Color _topSkinColor = Color(0xFFFF5252);
  static const Color _topAlignColor = Color(0xFFFFD700); // gold
  static const Color _topFreezeColor = Color(0xFF00FFCC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Start game immediately without showing start screen
      _startGame();
    });
    
    _cameraTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if ((cameraOffsetY - targetCameraOffsetY).abs() > 0.5) {
        setState(() {
          cameraOffsetY += (targetCameraOffsetY - cameraOffsetY) * 0.1;
        });
      }
    });
    
    _initSkinAnimations();
    _loadSavedData();
  }

  void _initSkinAnimations() {
    _neonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        if (mounted) setState(() => _neonPulseValue = _neonPulseController!.value);
      });
    _galaxyShiftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        if (mounted) setState(() => _galaxyShiftValue = _galaxyShiftController!.value);
      });
  }

  void _startSkinAnimationsIfNeeded() {
    _neonPulseController?.stop();
    _galaxyShiftController?.stop();
    final skin = JengaBlockSkin.values[_skinIndex.clamp(0, JengaBlockSkin.values.length - 1)];
    if (skin == JengaBlockSkin.neon) {
      _neonPulseController?.repeat();
    } else if (skin == JengaBlockSkin.galaxy) {
      _galaxyShiftController?.repeat();
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('jenga_playerName') ?? 'Player';
      _alignCount = prefs.getInt(_jengaAlignKey) ?? 3;
      _freezeCount = prefs.getInt(_jengaFreezeKey) ?? 3;
      _skinIndex = (prefs.getInt(_jengaSkinKey) ?? 0).clamp(0, JengaBlockSkin.values.length - 1);
    });
    _startSkinAnimationsIfNeeded();
  }

  Future<void> _saveJengaConsumables() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_jengaAlignKey, _alignCount);
    await prefs.setInt(_jengaFreezeKey, _freezeCount);
    await prefs.setInt(_jengaSkinKey, _skinIndex);
  }

  // ignore: unused_element - kept for future leaderboard/rank
  Future<void> _savePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jenga_playerName', name);
  }

  @override
  void dispose() {
    _neonPulseController?.dispose();
    _galaxyShiftController?.dispose();
    feedbackController?.dispose();
    shakeController?.dispose();
    bounceController?.dispose();
    _touchShakeController?.dispose();
    _liftAnimationController?.dispose();
    _liftBlockRotationTimer?.cancel();
    _focusNode.dispose();
    _autoMoveTimer?.cancel();
    _cameraTimer?.cancel();
    continuousWaveTimer?.cancel();
    _freezeCountdownTimer?.cancel();
    super.dispose();
  }

  /// Play vertical shake on touch: entire tower moves up then down quickly (not horizontal earthquake).
  void _playTouchBounce() {
    if (_isFrozen) return;
    bounceController?.dispose();
    bounceController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    final bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: bounceController!, curve: Curves.easeOut));
    bounceAnimation.addListener(() {
      if (mounted) setState(() => stackBounceOffsetY = bounceAnimation.value);
    });
    bounceController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        bounceController?.dispose();
        bounceController = null;
        if (mounted) setState(() => stackBounceOffsetY = 0);
      }
    });
    bounceController!.forward();
  }

  void _spawnNewBlock() {
    if (isGameOver) return;

    setState(() {
      final lastColor = placedBlocks.isNotEmpty ? placedBlocks.last.color : null;
      Color randomColor = laserColors[random.nextInt(laserColors.length)];
      if (lastColor != null && laserColors.length > 1) {
        while (randomColor == lastColor) {
          randomColor = laserColors[random.nextInt(laserColors.length)];
        }
      }
      final bh = _blockHeight;
      final bw = _blockWidth;
      final maxX = (_trajectoryWidth - bw).clamp(0.0, double.infinity);
      final startX = maxX > 0 ? random.nextDouble() * maxX : 0.0;
      // Spawn at top of gameplay area: use the EXACT same formula as the renderer's drawOffsetY.
      // Renderer: drawOffsetY = (lowest.y + lowest.height) - h; block screen Y = block.y - drawOffsetY.
      // So for block at top (screen Y = 0): spawnY = drawOffsetY = (lowest.y + lowest.height) - h.
      // We must use the same h the LayoutBuilder uses; _gameAreaHeight is that value (set from constraints.maxHeight).
      final spawnY = placedBlocks.isEmpty
          ? cameraOffsetY
          : (() {
              final h = _gameAreaHeight > 0 ? _gameAreaHeight : gameplayHeight;
              final topEntries = placedBlocks.toList()..sort((a, b) => a.y.compareTo(b.y));
              final top5 = topEntries.take(5).toList();
              if (top5.isEmpty) return cameraOffsetY;
              final lowest = top5.reduce((a, b) => a.y > b.y ? a : b);
              return (lowest.y + lowest.height) - h;
            }());
      currentBlock = Block(
        x: startX,
        y: spawnY,
        imagePath: '',
        color: randomColor,
        width: bw,
        height: bh,
      );
      _moveDirection = 1;
      // Ramp horizontal speed: 3 at 0 blocks → 6 at 100 blocks (linear), then cap at 6
      final n = placedBlocks.length;
      _moveSpeed = (_moveSpeedMin + n * 0.03).clamp(_moveSpeedMin, _moveSpeedMax);
    });
    
    _startAutoMovement();
  }

  void _startAutoMovement() {
    _autoMoveTimer?.cancel();
    
    _autoMoveTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (currentBlock == null || currentBlock!.isPlaced || isGameOver) {
        timer.cancel();
        return;
      }
      
      setState(() {
        currentBlock!.x += _moveSpeed * _moveDirection;
        // Clamp to game area: left edge 0, right edge = trajectoryWidth - block width
        final minX = 0.0;
        final maxX = (_trajectoryWidth - currentBlock!.width).clamp(0.0, double.infinity);
        if (currentBlock!.x <= minX) {
          currentBlock!.x = minX;
          _moveDirection = 1;
        } else if (currentBlock!.x >= maxX) {
          currentBlock!.x = maxX;
          _moveDirection = -1;
        }
      });
    });
  }

  void _releaseBlock() {
    if (currentBlock == null || currentBlock!.isPlaced) return;

    _autoMoveTimer?.cancel();

    setState(() {
      currentBlock!.isPlaced = true;
    });

    _animateBlockFall();
  }

  void _animateBlockFall() {
    if (currentBlock == null) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final targetY = _calculateLandingPosition();
    final startY = currentBlock!.y;

    final animation = Tween<double>(begin: startY, end: targetY).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    animation.addListener(() {
      if (currentBlock != null) {
        setState(() {
          currentBlock!.y = animation.value;
        });
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkPlacement();
        controller.dispose();
      }
    });

    controller.forward();
  }

  /// Landing Y in game-area coordinates. Floor = gameplayHeight - block height;
  /// on tower = top block Y minus block height. X is never changed on land (no snap).
  double _calculateLandingPosition() {
    if (placedBlocks.isEmpty) {
      return gameplayHeight - currentBlock!.height;
    }

    double highestBlockY = gameplayHeight;
    for (var block in placedBlocks) {
      if (block.y < highestBlockY) {
        highestBlockY = block.y;
      }
    }

    return highestBlockY - currentBlock!.height;
  }

  /// On touch: add block to tower at current x,y. No horizontal alignment; colors preserved.
  void _checkPlacement() {
    if (currentBlock == null) return;

    bool isTouching = false;
    double alignmentScore = 0;
    Block? blockBelow;

    if (placedBlocks.isEmpty) {
      isTouching = true;
      alignmentScore = 1.0;
      currentBlock!.y = gameplayHeight - currentBlock!.height;
    } else {
      Block? topmostTouching;
      for (var block in placedBlocks) {
        if (_blocksAreTouching(currentBlock!, block)) {
          isTouching = true;
          if (blockBelow == null || block.y < blockBelow!.y) {
            blockBelow = block;
            topmostTouching = block;
          }
        }
      }
      if (topmostTouching != null) {
        alignmentScore = _calculateAlignment(currentBlock!, topmostTouching);
      }
      if (isTouching && blockBelow != null) {
        currentBlock!.y = blockBelow.y - currentBlock!.height;
      }
    }

    if (isTouching) {
      _shakeFrozenAtTouch = stackShakeOffset;
      _isInTouchFreeze = true;
      _touchFreezeNewBlockShakeMult = (placedBlocks.length / 10.0).clamp(0.0, 1.0);
      continuousWaveTimer?.cancel();
      if (shakeController != null && shakeController!.isAnimating) {
        shakeController!.stop();
      }
      final badPlacement = alignmentScore < 1.0;
      if (badPlacement) {
        _didTouchShake = true;
        _zeroShakeDuringVibration = true;
        _playTouchShake(); // horizontal shake during 500ms; tower and current block move together
      } else {
        _didTouchShake = false;
        stackShakeOffset = _shakeFrozenAtTouch; // freeze tower x
      }
      setState(() {});
      Future.delayed(const Duration(milliseconds: _touchFreezeMs), () {
        if (!mounted || currentBlock == null) return;
        _touchShakeController?.dispose();
        _touchShakeController = null;
        setState(() {
          final newBlockMult = (placedBlocks.length / 10.0).clamp(0.0, 1.0);
          // Align stored x so drawn position matches (good: frozen at _shakeFrozenAtTouch; bad: was drawn with relative offset)
          currentBlock!.x -= _shakeFrozenAtTouch * newBlockMult;
          placedBlocks.add(currentBlock!);
          _totalBlocksPlaced++;
          // Keep only top 15 blocks in memory (smallest y = top); order as bottom-first for _alignBlocksToCenter
          if (placedBlocks.length > _maxBlocksInMemory) {
            placedBlocks.sort((a, b) => a.y.compareTo(b.y)); // ascending: top first
            placedBlocks = placedBlocks.sublist(0, _maxBlocksInMemory); // keep top 15 (first 15 after sort)
            placedBlocks = placedBlocks.reversed.toList(); // now index 0 = bottom of our 15, last = top
          }
          currentBlock = null;
          _isInTouchFreeze = false;
          _didTouchShake = false;
        });
        _updateCamera();
        if (placedBlocks.length > 1) {
          _showFeedback(alignmentScore);
          _addInstability(alignmentScore, didTouchShake: badPlacement);
          _playTouchBounce(); // vertical shake: entire tower move up and down quickly on touch
          if (placedBlocks.length >= 2) _startContinuousWave();
        }
        Future.delayed(Duration(milliseconds: placedBlocks.length == 1 ? 200 : 400), () {
          _spawnNewBlock();
        });
      });
    } else {
      _animateBlockToFloor();
    }
  }

  void _updateCamera() {
    if (placedBlocks.isEmpty) return;
    
    double highestY = placedBlocks.map((b) => b.y).reduce((a, b) => a < b ? a : b);
    double gameplayMiddle = gameplayHeight / 2;
    final visibleHeight = _gameAreaHeight > 0 ? _gameAreaHeight : gameplayHeight;
    final floorAtBottom = gameplayHeight - visibleHeight;
    // First block: pin floor to bottom. 2+ blocks: center tower for space above, but never show below floor (no float).
    if (placedBlocks.length == 1) {
      targetCameraOffsetY = floorAtBottom;
    } else {
      targetCameraOffsetY = highestY - gameplayMiddle;
      if (targetCameraOffsetY > highestY) targetCameraOffsetY = highestY;
      // Never show below floor: cap at floorAtBottom so tower never floats (visible bottom = cameraOffsetY + visibleHeight <= gameplayHeight)
      if (targetCameraOffsetY > floorAtBottom) targetCameraOffsetY = floorAtBottom;
    }
    cameraOffsetY = targetCameraOffsetY;
  }

  void _animateBlockToFloor() {
    if (currentBlock == null) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final startY = currentBlock!.y;
    final targetY = gameplayHeight - currentBlock!.height;

    final animation = Tween<double>(begin: startY, end: targetY).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    final blockCenterX = currentBlock!.x + currentBlock!.width / 2;
    final screenCenterX = screenWidth / 2;
    final isOnLeftSide = blockCenterX < screenCenterX;
    final rotationDirection = isOnLeftSide ? 1.0 : -1.0;

    final rotationAnimation = Tween<double>(
      begin: 0, 
      end: 3.14159 * 2 * rotationDirection,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    animation.addListener(() {
      if (currentBlock != null) {
        setState(() {
          currentBlock!.y = animation.value;
          currentBlock!.rotation = rotationAnimation.value;
        });
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _startGameOverLiftPhase();
      }
    });

    controller.forward();
  }

  bool _blocksAreTouching(Block block1, Block block2) {
    final block1Center = block1.x + block1.width / 2;
    final block2Center = block2.x + block2.width / 2;
    final centerDifference = (block1Center - block2Center).abs();
    // Use percentage of block width so behavior scales across device resolutions
    final maxCenterDistance = block1.width * 0.6; // 60% of block width
    if (centerDifference > maxCenterDistance) {
      return false;
    }
    
    final overlapLeft = max(block1.x, block2.x);
    final overlapRight = min(block1.x + block1.width, block2.x + block2.width);
    final overlapWidth = max(0.0, overlapRight - overlapLeft);
    
    final minRequiredOverlap = block1.width * 0.1;
    final hasSignificantOverlap = overlapWidth >= minRequiredOverlap;
    
    final verticalDistance = (block1.y + block1.height - block2.y).abs();
    
    return hasSignificantOverlap && verticalDistance <= 5;
  }

  /// Alignment score 0..1: horizontal center offset vs block width.
  /// Score = 1 - (centerDifference / width); 1.0 = perfectly centered, 0 = fully off.
  /// We score against the topmost touching block only (smallest y) so PERFECT/GOOD match the block you see under the new one.
  double _calculateAlignment(Block current, Block placed) {
    final currentCenter = current.x + current.width / 2;
    final placedCenter = placed.x + placed.width / 2;
    final difference = (currentCenter - placedCenter).abs();
    return max(0, 1 - (difference / current.width));
  }

  /// Feedback text from alignment score (vs topmost touching block):
  /// PERFECT >= 1.0, GREAT > 0.90, GOOD > 0.80, NORMAL > 0.60, BAD <= 0.60.
  void _showFeedback(double alignmentScore) {
    String feedback = '';
    if (alignmentScore >= 1.0) {
      feedback = 'PERFECT!';
    } else if (alignmentScore > 0.90) {
      feedback = 'GREAT!';
    } else if (alignmentScore > 0.80) {
      feedback = 'GOOD';
    } else if (alignmentScore > 0.60) {
      feedback = 'NORMAL';
    } else {
      feedback = 'BAD';
    }
    setState(() {
      feedbackText = feedback;
      final x = random.nextInt(10); // 0..9: font = laserColors[x], glow = laserColors[x+10] (strict pair)
      _feedbackColorIndex = x;
      _feedbackFontColor = laserColors[x];
      _feedbackGlowColor = laserColors[10 + x];
    });

    feedbackController?.dispose();
    feedbackController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    feedbackController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          feedbackText = null;
          _feedbackFontColor = null;
          _feedbackGlowColor = null;
        });
      }
    });

    feedbackController!.forward();
  }

  void _addInstability(double alignmentScore, {bool didTouchShake = false}) {
    double instabilityIncrease = 0;
    
    if (alignmentScore >= 1.0) {
      instabilityIncrease = 0;
      acceptableBlockCount = max(0, acceptableBlockCount - 1);
    } else if (alignmentScore > 0.90) {
      instabilityIncrease = 0.05;
      acceptableBlockCount = max(0, acceptableBlockCount - 1);
    } else if (alignmentScore > 0.80) {
      instabilityIncrease = 0.1;
      acceptableBlockCount = max(0, acceptableBlockCount - 1);
    } else if (alignmentScore > 0.60) {
      instabilityIncrease = 0.15;
      acceptableBlockCount = max(0, acceptableBlockCount - 1);
    } else {
      instabilityIncrease = 0.2;
      acceptableBlockCount++;
    }
    
    stackInstability = (stackInstability + instabilityIncrease).clamp(0, 1.0);
    
    if (instabilityIncrease > 0) {
      if (didTouchShake) {
        // Shake already ran during 500ms freeze; go straight to continuous wave
        _zeroShakeDuringVibration = false;
        if (placedBlocks.length >= 2) _syncWavePhaseToShake();
      } else {
        _shakeStack(onComplete: () {
          setState(() => _zeroShakeDuringVibration = false);
          if (acceptableBlockCount >= 2) _syncWavePhaseToShake();
        });
      }
    } else {
      _zeroShakeDuringVibration = false;
    }
    
    if (acceptableBlockCount >= 2 && instabilityIncrease == 0) {
      _startContinuousWave();
    }
    // Do not cancel wave when acceptableBlockCount < 2 — keep wobble visible (amplitude uses min below)
    
    if (acceptableBlockCount >= 8) {
      _triggerBigWaveGameOver();
    }
  }

  /// Center all placed blocks and restore tower stack (Y positions) so reborn shows tower correctly.
  void _alignBlocksToCenter() {
    if (placedBlocks.isEmpty) return;
    final centerX = _trajectoryWidth / 2;
    // Restore Y so tower stacks from floor: index 0 = bottom, last = top
    double baseY = gameplayHeight;
    for (var block in placedBlocks) {
      baseY -= block.height;
      block.y = baseY;
    }
    for (var block in placedBlocks) {
      block.x = centerX - block.width / 2;
      block.rotation = 0;
    }
    stackShakeOffset = 0;
    stackInstability = 0;
    acceptableBlockCount = 0;
    continuousWaveTimer?.cancel();
    wavePhase = 0;
    // Reborn camera: when tower has > 6 blocks, always sink so tower doesn't protrude at top; else floor at bottom when fits
    final highestY = placedBlocks.map((b) => b.y).reduce((a, b) => a < b ? a : b);
    final visibleHeight = _gameAreaHeight > 0 ? _gameAreaHeight : gameplayHeight;
    final floorAtBottomOffset = gameplayHeight - visibleHeight;
    final visibleCenter = visibleHeight / 2; // center of visible viewport so top block sits above it
    final bool towerTall = placedBlocks.length > 6 || highestY < floorAtBottomOffset;
    if (!towerTall) {
      // Tower fits in view: pin floor to bottom of screen so tower does not float
      targetCameraOffsetY = floorAtBottomOffset;
    } else {
      // Tower > 6 blocks or taller than view: sink so top of tower is at visible center (no protrusion at device top)
      targetCameraOffsetY = highestY - visibleCenter;
      if (targetCameraOffsetY > highestY) targetCameraOffsetY = highestY;
    }
    cameraOffsetY = targetCameraOffsetY;
    // Re-apply camera for 3 frames when tower is tall so reborn tower sinks and timer/layout don't overwrite
    if (towerTall) {
      void reapplyRebornCamera() {
        if (!mounted || isGameOver || placedBlocks.isEmpty) return;
        final topY = placedBlocks.map((b) => b.y).reduce((a, b) => a < b ? a : b);
        final visH = _gameAreaHeight > 0 ? _gameAreaHeight : gameplayHeight;
        final mid = visH / 2;
        final target = topY - mid;
        setState(() {
          targetCameraOffsetY = target;
          cameraOffsetY = target;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reapplyRebornCamera();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          reapplyRebornCamera();
          WidgetsBinding.instance.addPostFrameCallback((_) => reapplyRebornCamera());
        });
      });
    }
  }

  int get _alignCost => (1 << _alignUseCount).clamp(1, 1 << 20);
  int get _freezeCost => (1 << _freezeUseCount).clamp(1, 1 << 20);

  void _showAlignConfirmDialog() {
    final themeColor = _topAlignColor;
    final cost = _alignCost;
    final canAfford = _alignCount >= cost;
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(child: Text('Align x $_alignCount', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items Owned: $_alignCount', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Items Required: $cost', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Effect: Tower aligns at center.', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(
            onPressed: canAfford
                ? () {
                    Navigator.pop(ctx);
                    setState(() {
                      _alignCount -= cost;
                      _alignUseCount++;
                      _isDialogOpen = false;
                    });
                    _saveJengaConsumables();
                    _alignBlocksToCenter();
                  }
                : null,
            child: Text('Use', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showFreezeConfirmDialog() {
    final themeColor = _topFreezeColor;
    final cost = _freezeCost;
    final canAfford = _freezeCount >= cost;
    setState(() => _isDialogOpen = true);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(child: Text('Freeze x $_freezeCount', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items Owned: $_freezeCount', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Items Required: $cost', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Effect: Tower freezes for 5 seconds (no movement/shake).', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(
            onPressed: canAfford
                ? () {
                    Navigator.pop(ctx);
                    setState(() {
                      _freezeCount -= cost;
                      _freezeUseCount++;
                      _isDialogOpen = false;
                    });
                    _saveJengaConsumables();
                    _useFreeze(cost);
                  }
                : null,
            child: Text('Use', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  /// Activate freeze for 5 seconds: no movement/shake. Caller must have already decremented _freezeCount.
  void _useFreeze([int itemsConsumed = 1]) {
    _freezeCountdownTimer?.cancel();
    final end = DateTime.now().add(const Duration(seconds: 5));
    setState(() {
      _freezeUntil = end;
      _freezeRemainingSec = 5.0;
    });
    _saveJengaConsumables();
    _freezeCountdownTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) { t.cancel(); return; }
      final rem = end.difference(DateTime.now()).inMilliseconds / 1000.0;
      if (rem <= 0) {
        t.cancel();
        _freezeCountdownTimer = null;
        setState(() { _freezeUntil = null; _freezeRemainingSec = 0; });
        return;
      }
      setState(() => _freezeRemainingSec = rem);
    });
  }

  void _shakeStack({VoidCallback? onComplete}) {
    if (_isFrozen) return;
    shakeController?.dispose();
    shakeController = AnimationController(
      duration: Duration(milliseconds: 300 + (stackInstability * 200).toInt()),
      vsync: this,
    );

    final shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 5 * stackInstability),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5 * stackInstability, end: -5 * stackInstability),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5 * stackInstability, end: 3 * stackInstability),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 3 * stackInstability, end: -3 * stackInstability),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -3 * stackInstability, end: 0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: shakeController!,
      curve: Curves.easeInOut,
    ));

    shakeAnimation.addListener(() {
      setState(() {
        stackShakeOffset = _zeroShakeDuringVibration ? _shakeFrozenAtTouch : shakeAnimation.value;
      });
    });

    if (onComplete != null) {
      shakeController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          onComplete();
        }
      });
    }
    shakeController!.forward();
  }

  /// Horizontal shake only during the 500ms touch freeze (bad placement). Drives stackShakeOffset from _shakeFrozenAtTouch.
  void _playTouchShake() {
    _touchShakeController?.dispose();
    _touchShakeController = AnimationController(
      duration: const Duration(milliseconds: _touchFreezeMs),
      vsync: this,
    );
    final base = _shakeFrozenAtTouch;
    final wobble = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 6, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _touchShakeController!,
      curve: Curves.easeInOut,
    ));
    wobble.addListener(() {
      if (mounted) setState(() => stackShakeOffset = base + wobble.value);
    });
    // Dispose only in the 500ms callback and in widget dispose — never in completed listener, to avoid stop() after dispose()
    _touchShakeController!.forward();
  }

  static const double _waveAmplitudeBase = 7.5 * 2.5; // 250% of original for visible swing

  /// Set wavePhase so sin(wavePhase)*amplitude equals current stackShakeOffset, then start wave.
  void _syncWavePhaseToShake() {
    final amplitude = max(acceptableBlockCount, 1) * _waveAmplitudeBase;
    if (amplitude <= 0) {
      wavePhase = 0;
    } else {
      final s = (stackShakeOffset / amplitude).clamp(-1.0, 1.0);
      wavePhase = asin(s);
    }
    _startContinuousWave();
  }

  void _startContinuousWave() {
    if (continuousWaveTimer != null && continuousWaveTimer!.isActive) return;
    continuousWaveTimer?.cancel();
    continuousWaveTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      if (_isFrozen) return;
      setState(() {
        // Amplitude 250% of original so tower swing is clearly visible
        double amplitude = max(acceptableBlockCount, 1) * _waveAmplitudeBase;
        double frequency = 0.02 + (max(acceptableBlockCount, 1) * 0.005);
        wavePhase += frequency;
        stackShakeOffset = sin(wavePhase) * amplitude;
      });
    });
  }

  void _triggerBigWaveGameOver() {
    continuousWaveTimer?.cancel();
    
    final bigWaveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    final bigWaveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 60), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 60, end: -60), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -60, end: 50), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 50, end: -50), weight: 1),
    ]).animate(CurvedAnimation(
      parent: bigWaveController,
      curve: Curves.easeInOut,
    ));
    
    bigWaveAnimation.addListener(() {
      setState(() {
        stackShakeOffset = bigWaveAnimation.value;
      });
    });
    
    bigWaveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _makeAllBlocksFall();
      }
    });
    
    bigWaveController.forward();
  }

  void _makeAllBlocksFall() {
    if (placedBlocks.isEmpty) {
      _gameOver();
      return;
    }
    
    final fallController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    final List<double> initialYPositions = placedBlocks.map((b) => b.y).toList();
    final targetY = gameplayHeight + 100;
    
    final fallAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: fallController, curve: Curves.easeIn),
    );
    
    fallAnimation.addListener(() {
      setState(() {
        for (int i = 0; i < placedBlocks.length; i++) {
          placedBlocks[i].y = initialYPositions[i] + 
              (targetY - initialYPositions[i]) * fallAnimation.value;
          
          placedBlocks[i].rotation = fallAnimation.value * 3.14159 * (i % 2 == 0 ? 1 : -1);
        }
      });
    });
    
    fallController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        fallController.dispose();
        _startGameOverLiftPhase();
      }
    });

    fallController.forward();
  }

  void _startGameOverLiftPhase() {
    if (placedBlocks.isEmpty && currentBlock == null) {
      setState(() => isGameOver = true);
      return;
    }
    continuousWaveTimer?.cancel();
    setState(() {
      stackShakeOffset = 0;
      feedbackText = null;
    });
    final h = _gameAreaHeight > 0 ? _gameAreaHeight : gameplayHeight;
    final topEntries = placedBlocks.asMap().entries.toList()
      ..sort((a, b) => a.value.y.compareTo(b.value.y));
    final top5 = topEntries.take(5).toList();
    final top18 = topEntries.take(_gameOverVisibleBlocks).toList();
    final startLowest = top5.isEmpty ? null : top5.map((e) => e.value).reduce((a, b) => a.y > b.y ? a : b);
    final targetLowest = top18.isEmpty ? null : top18.map((e) => e.value).reduce((a, b) => a.y > b.y ? a : b);
    final startDrawOffsetY = startLowest != null ? (startLowest.y + startLowest.height) - h : 0.0;
    final targetDrawOffsetY = targetLowest != null ? (targetLowest.y + targetLowest.height) - h : 0.0;

    setState(() {
      _isGameOverLiftPhase = true;
      _liftStartDrawOffsetY = startDrawOffsetY;
      _liftTargetDrawOffsetY = targetDrawOffsetY;
      _liftAnimationValue = 0;
    });

    _liftAnimationController?.dispose();
    _liftAnimationController = AnimationController(
      duration: const Duration(milliseconds: _gameOverLiftMs),
      vsync: this,
    );
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _liftAnimationController!, curve: Curves.easeOut),
    );
    anim.addListener(() {
      if (mounted) setState(() => _liftAnimationValue = anim.value);
    });
    _liftAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _liftAnimationController?.dispose();
        _liftAnimationController = null;
        _liftBlockRotationTimer?.cancel();
        Future.delayed(const Duration(milliseconds: _gameOverHoldMs), () async {
          if (!mounted) return;
          await _captureGameAreaScreenshot();
          if (!mounted) return;
          setState(() {
            isGameOver = true;
            _isGameOverLiftPhase = false;
            _liftBlockRotationTimer?.cancel();
            currentBlock = null;
          });
        });
      }
    });
    _liftAnimationController!.forward();

    if (currentBlock != null) {
      _liftBlockRotationTimer?.cancel();
      _liftBlockRotationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (mounted && _isGameOverLiftPhase && currentBlock != null) {
          setState(() => currentBlock!.rotation += 0.15);
        }
      });
    }
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
      _towerScreenshot = null;
    });
  }

  Widget _standardPanelButton(BuildContext context, IconData icon, String label, VoidCallback? onPressed, {required Color themeColor}) {
    return SizedBox(
      height: _standardButtonHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_standardButtonRadius),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.5),
              blurRadius: _buttonGlowBlur,
              spreadRadius: _buttonGlowSpread,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: themeColor,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_standardButtonRadius),
              side: BorderSide(color: themeColor, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _standardButtonIconSize, color: themeColor),
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: _standardButtonFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: themeColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameDependentPanelButton(BuildContext context, IconData icon, String label, VoidCallback? onPressed, {required Color themeColor}) {
    final enabled = onPressed != null;
    final button = SizedBox(
      height: _standardButtonHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_standardButtonRadius),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.5),
              blurRadius: _buttonGlowBlur,
              spreadRadius: _buttonGlowSpread,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: themeColor,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_standardButtonRadius),
              side: BorderSide(color: themeColor, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _standardButtonIconSize, color: themeColor),
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: _standardButtonFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: themeColor),
              ),
            ],
          ),
        ),
      ),
    );
    if (!enabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: button,
      );
    }
    return button;
  }

  void _showLeaveConfirm(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Leave game?',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: const Text('If you leave, all progress will be gone.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Yes', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showRestartConfirm(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Restart?',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: const Text('If you restart, all progress will be gone.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(onPressed: () {
            Navigator.pop(context);
            _resetGame();
            _startGame();
          }, child: Text('Yes', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showRulesDialog(Color themeColor) {
    final gameInfo = GameRepository.getGameById('jenga');
    final rules = gameInfo?.rules ?? 'Stack blocks as high as you can. Tap or press Space to drop.';
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Rules',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(rules, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showRankDialog(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Rank',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: const Text('Leaderboard for Jenga is not available yet.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  /// Preview block for skin (mimic Number Link style preview)
  Widget _buildSkinPreview(JengaBlockSkin skin) {
    const previewColor = Color(0xFFFF9800);
    return Container(
      width: 48,
      height: 24,
      margin: const EdgeInsets.only(right: 12),
      decoration: _blockDecorationForSkin(skin, previewColor),
    );
  }

  void _showSkinDialog(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Block Skin',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: JengaBlockSkin.values.asMap().entries.map((e) {
              final i = e.key;
              final skin = e.value;
              final name = switch (skin) {
                JengaBlockSkin.classic => 'Classic',
                JengaBlockSkin.wood => 'Wood',
                JengaBlockSkin.neon => 'Neon',
                JengaBlockSkin.marble => 'Marble',
                JengaBlockSkin.candy => 'Candy',
                JengaBlockSkin.fire => 'Fire',
                JengaBlockSkin.ice => 'Ice',
                JengaBlockSkin.galaxy => 'Galaxy',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: _skinIndex == i ? themeColor.withOpacity(0.2) : null,
                  leading: _buildSkinPreview(skin),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _skinIndex = i;
                      _saveJengaConsumables();
                      _startSkinAnimationsIfNeeded();
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showTokenOnlyShopOverGameOver() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _jengaGameOverColor, width: 2)),
        title: Center(child: Text('Shop', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize))),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: TokenService.tokenPacks.map((pack) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, color: _jengaGameOverColor, size: 24),
                            const SizedBox(width: 8),
                            Text('x ${pack.tokens}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('\$${pack.usd.toStringAsFixed(0)}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TokenService.addTokens(pack.tokens);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            setState(() {});
                          }
                        },
                        child: Text('Buy', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    );
  }

  void _showJengaShopDialog(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF000000),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
            title: Center(
              child: Text(
                'Shop',
                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
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
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: themeColor, width: 1),
                            ),
                            child: Text(
                              'Align x $_alignCount',
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: themeColor, width: 1),
                            ),
                            child: Text(
                              'Freeze x $_freezeCount',
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Align x 1 (1), x 2 (2), x 4 (4), x 8 (8)
                    _shopRowWithIcon('Align x 1', 1, () async {
                      if (!TokenService.canAfford(1)) return;
                      await TokenService.spendTokens(1);
                      setState(() { _alignCount++; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Align x 2', 2, () async {
                      if (!TokenService.canAfford(2)) return;
                      await TokenService.spendTokens(2);
                      setState(() { _alignCount += 2; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Align x 4', 4, () async {
                      if (!TokenService.canAfford(4)) return;
                      await TokenService.spendTokens(4);
                      setState(() { _alignCount += 4; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Align x 8', 8, () async {
                      if (!TokenService.canAfford(8)) return;
                      await TokenService.spendTokens(8);
                      setState(() { _alignCount += 8; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    const Divider(color: Colors.white24),
                    // Freeze x 1 (1), x 2 (2), x 4 (4), x 8 (8)
                    _shopRowWithIcon('Freeze x 1', 1, () async {
                      if (!TokenService.canAfford(1)) return;
                      await TokenService.spendTokens(1);
                      setState(() { _freezeCount++; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Freeze x 2', 2, () async {
                      if (!TokenService.canAfford(2)) return;
                      await TokenService.spendTokens(2);
                      setState(() { _freezeCount += 2; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Freeze x 4', 4, () async {
                      if (!TokenService.canAfford(4)) return;
                      await TokenService.spendTokens(4);
                      setState(() { _freezeCount += 4; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                    _shopRowWithIcon('Freeze x 8', 8, () async {
                      if (!TokenService.canAfford(8)) return;
                      await TokenService.spendTokens(8);
                      setState(() { _freezeCount += 8; _saveJengaConsumables(); });
                      setDialogState(() {});
                    }, themeColor),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
            ],
          );
        },
      ),
    ).then((_) async {
      if (mounted) await _loadSavedData();
      if (mounted) setState(() => _isDialogOpen = false);
    });
  }

  BoxDecoration _blockDecorationForSkin(JengaBlockSkin skin, Color c) {
    switch (skin) {
      case JengaBlockSkin.classic:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [c, c.withOpacity(0.6), c],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: c.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)],
          border: Border.all(color: c.withOpacity(0.8), width: 2),
        );
      case JengaBlockSkin.wood:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B4513), Color(0xFFA0522D), Color(0xFF654321)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF5D3A1A), width: 2),
        );
      case JengaBlockSkin.neon:
        final pulse = 0.6 + 0.4 * sin(pi * _neonPulseValue);
        return BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c, width: 3),
          boxShadow: [
            BoxShadow(color: c.withOpacity(0.9), blurRadius: 12 * pulse, spreadRadius: 1 * pulse),
            BoxShadow(color: c.withOpacity(0.5), blurRadius: 24 * pulse, spreadRadius: 2 * pulse),
          ],
        );
      case JengaBlockSkin.marble:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.95), Colors.white70, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
        );
      case JengaBlockSkin.candy:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [c, c.withOpacity(0.7), c.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: c.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)],
        );
      case JengaBlockSkin.fire:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFF5722), Color(0xFFFF9800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCC80), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFE65100).withOpacity(0.7), blurRadius: 12, spreadRadius: 2)],
        );
      case JengaBlockSkin.ice:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              const Color(0xFFB3E5FC),
              const Color(0xFF81D4FA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1F5FE), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF81D4FA).withOpacity(0.5), blurRadius: 10, spreadRadius: 1)],
        );
      case JengaBlockSkin.galaxy:
        final t = _galaxyShiftValue;
        final c1 = Color.lerp(const Color(0xFF5E35B1), const Color(0xFF7E57C2), t)!;
        final c2 = Color.lerp(const Color(0xFF3949AB), const Color(0xFF5C6BC0), 1 - t)!;
        final c3 = Color.lerp(const Color(0xFF1A237E), const Color(0xFF3F51B5), t)!;
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2, c3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB39DDB), width: 2),
          boxShadow: [
            BoxShadow(color: c1.withOpacity(0.6), blurRadius: 12 + 6 * t, spreadRadius: 2),
          ],
        );
    }
  }

  BoxDecoration _blockDecoration(Block block) {
    final skin = JengaBlockSkin.values[_skinIndex.clamp(0, JengaBlockSkin.values.length - 1)];
    final c = block.color;
    return _blockDecorationForSkin(skin, c);
  }

  Future<void> _captureGameAreaScreenshot() async {
    try {
      final context = _gameAreaCaptureKey.currentContext;
      if (context == null) return;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null && mounted) {
        setState(() => _towerScreenshot = byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Jenga game area screenshot error: $e');
    }
  }

  Widget _shopRow(String title, String priceLabel, int cost, VoidCallback onPurchase) {
    final themeColor = _bottomShopColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: TokenService.canAfford(cost) ? onPurchase : null,
            child: Text(
              priceLabel,
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopRowWithIcon(String title, int cost, VoidCallback onPurchase, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, color: themeColor, size: 18),
              const SizedBox(width: 4),
              Text('$cost', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: TokenService.canAfford(cost) ? onPurchase : null,
            child: Text(
              'Buy',
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
            ),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    continuousWaveTimer?.cancel();
    _liftAnimationController?.dispose();
    _liftAnimationController = null;
    _liftBlockRotationTimer?.cancel();
    _liftBlockRotationTimer = null;
    setState(() {
      placedBlocks.clear();
      currentBlock = null;
      isGameOver = false;
      hasGameStarted = false;
      feedbackText = null;
      cameraOffsetY = 0;
      targetCameraOffsetY = 0;
      stackInstability = 0;
      stackShakeOffset = 0;
      acceptableBlockCount = 0;
      wavePhase = 0;
      _towerScreenshot = null;
      _isGameOverLiftPhase = false;
      _totalBlocksPlaced = 0;
      _alignUseCount = 0;
      _freezeUseCount = 0;
      _rebornTimesUsedThisGame = 0;
    });
    // Reload align/freeze counts from storage so Align/Freeze work after Play again
    _loadSavedData();
  }

  void _startGame() {
    setState(() {
      hasGameStarted = true;
    });
    _spawnNewBlock();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    _reservedTopHeight = 56 + 50 + padding.top;
    _reservedBottomHeight = 84 + padding.bottom; // extra pixels so lowest block not too close to panel

    final blockCount = _totalBlocksPlaced; // Total placed (only top 15 kept in memory)

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (!isGameOver && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _releaseBlock();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          if (!isGameOver && hasGameStarted) {
            _releaseBlock();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SafeArea(
                top: true,
                child: Column(
                  children: [
                    // Top title: Block X
                    Container(
                  height: 56,
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: Text(
                    'Block $blockCount',
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Top panel: Skin, Reborn x N (display only), Freeze x N
                Container(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                  color: AppColors.background,
                  child: Row(
                    children: [
                      Expanded(child: _gameDependentPanelButton(context, Icons.palette, 'Skin', (!_isDialogOpen) ? () => _showSkinDialog(_topSkinColor) : null, themeColor: _topSkinColor)),
                      const SizedBox(width: 6),
                      Expanded(child: _gameDependentPanelButton(context, Icons.center_focus_strong, _alignCount > 0 ? 'Align x $_alignCount' : 'Align', (!_isDialogOpen && placedBlocks.length >= 2) ? () => _showAlignConfirmDialog() : null, themeColor: _topAlignColor)),
                      const SizedBox(width: 6),
                      Expanded(child: _gameDependentPanelButton(context, Icons.ac_unit, _isFrozen ? '${_freezeRemainingSec.toStringAsFixed(2)}' : (_freezeCount > 0 ? 'Freeze x $_freezeCount' : 'Freeze'), (!_isDialogOpen && !_isFrozen) ? () => _showFreezeConfirmDialog() : null, themeColor: _topFreezeColor)),
                    ],
                  ),
                ),
                // Game area — use LayoutBuilder so floor and width match visible area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final h = constraints.maxHeight;
                      final w = constraints.maxWidth;
                      final prevH = _gameAreaHeight;
                      if (h > 0) {
                        _gameAreaHeight = h;
                      }
                      if (h > 0 && (prevH - h).abs() > 0.5) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {
                            _gameAreaHeight = h;
                            final bh = _blockHeight;
                            final bw = _blockWidth;
                            for (var b in placedBlocks) {
                              b.width = bw;
                              b.height = bh;
                            }
                            if (currentBlock != null) {
                              currentBlock!.width = bw;
                              currentBlock!.height = bh;
                            }
                          });
                        });
                      }
                      if (w > 0 && (_gameAreaWidth - w).abs() > 0.5) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _gameAreaWidth = w);
                        });
                      }
                      // Normal play: top 5 blocks; lift phase (game over): top 18 blocks for screenshot
                      final topEntries = placedBlocks.asMap().entries.toList()
                        ..sort((a, b) => a.value.y.compareTo(b.value.y));
                      final visibleCount = _isGameOverLiftPhase ? _gameOverVisibleBlocks : 5;
                      final visiblePlacedBlocks = topEntries.take(visibleCount).toList();
                      final drawOffsetY = _isGameOverLiftPhase
                          ? (_liftStartDrawOffsetY + (_liftTargetDrawOffsetY - _liftStartDrawOffsetY) * _liftAnimationValue)
                          : (placedBlocks.isEmpty
                              ? cameraOffsetY
                              : (visiblePlacedBlocks.isEmpty
                                  ? cameraOffsetY
                                  : () {
                                      final lowest = visiblePlacedBlocks.map((e) => e.value).reduce((a, b) => a.y > b.y ? a : b);
                                      return (lowest.y + lowest.height) - h;
                                    }()));
                      return RepaintBoundary(
                        key: _gameAreaCaptureKey,
                        child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
              // Placed blocks — show only top 5; physics: world position (block.x, block.y). Shake: left = block.x + stackShakeOffset * multiplier.
              ...visiblePlacedBlocks.map((entry) {
                final index = entry.key;
                final block = entry.value;
                const int _shakeScale = 10; // so multiplier = index/10, capped at 1
                final shakeMultiplier = placedBlocks.length > 1
                    ? (index / _shakeScale).clamp(0.0, 1.0)
                    : 0.0;
                return Positioned(
                  left: block.x + (stackShakeOffset * shakeMultiplier),
                  top: block.y - drawOffsetY + stackBounceOffsetY,
                  child: Transform.rotate(
                    angle: block.rotation,
                    child: Container(
                      width: block.width,
                      height: block.height,
                      decoration: _blockDecoration(block),
                    ),
                  ),
                );
              }),

              // Current block — during 500ms touch shake move with tower (relative to touch position so no jump)
              if (currentBlock != null)
                Positioned(
                  left: _isInTouchFreeze && _didTouchShake
                      ? currentBlock!.x + (stackShakeOffset - _shakeFrozenAtTouch) * _touchFreezeNewBlockShakeMult
                      : currentBlock!.x,
                  top: currentBlock!.y - drawOffsetY + stackBounceOffsetY,
                  child: Transform.rotate(
                    angle: currentBlock!.rotation,
                    child: Container(
                      width: currentBlock!.width,
                      height: currentBlock!.height,
                      decoration: _blockDecoration(currentBlock!),
                    ),
                  ),
                ),

              // Feedback text — always use palette: random from first 10 for font, index+10 for outer glow
              if (feedbackText != null && _feedbackFontColor != null && _feedbackGlowColor != null)
                Center(
                  child: AnimatedOpacity(
                    opacity: feedbackController?.value != null 
                        ? 1 - feedbackController!.value 
                        : 1,
                    duration: const Duration(milliseconds: 100),
                    child: Text(
                      feedbackText!,
                      style: TextStyle(
                        color: _feedbackFontColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: _feedbackGlowColor!.withOpacity(0.9),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                    ],  // End of Stack children
                        ),  // End of Stack
                      );  // End of RepaintBoundary
                    },
                  ),  // End of LayoutBuilder
                ),  // End of Expanded
                // Bottom panel: Restart, Rank, Shop, Rules, Leave
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                    color: AppColors.background,
                    child: Row(
                      children: [
                        Expanded(child: _standardPanelButton(context, Icons.replay, 'Restart', (!_isDialogOpen) ? () => _showRestartConfirm(_bottomRestartColor) : null, themeColor: _bottomRestartColor)),
                        const SizedBox(width: 4),
                        Expanded(child: _standardPanelButton(context, Icons.leaderboard, 'Rank', (!_isDialogOpen) ? () => _showRankDialog(_bottomLeaderboardColor) : null, themeColor: _bottomLeaderboardColor)),
                        const SizedBox(width: 4),
                        Expanded(child: _standardPanelButton(context, Icons.shopping_cart, 'Shop', (!_isDialogOpen) ? () => _showJengaShopDialog(_bottomShopColor) : null, themeColor: _bottomShopColor)),
                        const SizedBox(width: 4),
                        Expanded(child: _standardPanelButton(context, Icons.menu_book, 'Rules', !_isDialogOpen ? () => _showRulesDialog(_bottomGameRuleColor) : null, themeColor: _bottomGameRuleColor)),
                        const SizedBox(width: 4),
                        Expanded(child: _standardPanelButton(context, Icons.logout, 'Leave', !_isDialogOpen ? () => _showLeaveConfirm(_bottomLeaveColor) : null, themeColor: _bottomLeaveColor)),
                      ],
                    ),
                  ),
                ),
                  ],  // End of Column children
                ),
              ),  // End of SafeArea
              // Game over — full-screen overlay (covers title, panels, game area) so Freeze etc. cannot be pressed
              if (isGameOver)
                Positioned.fill(
                  child: ModalBarrier(
                    color: Colors.black.withOpacity(0.75),
                    dismissible: false,
                  ),
                ),
              if (isGameOver)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320, maxHeight: double.infinity),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _jengaGameOverColor, width: 2),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.monetization_on, color: _jengaGameOverColor, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${TokenService.getTokenCount()}',
                                    style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Game over',
                                  style: TextStyle(
                                    color: _jengaGameOverColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You placed $_totalBlocksPlaced blocks.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            if (_towerScreenshot != null)
                              Container(
                                width: _gameOverScreenshotWidth,
                                height: _gameOverScreenshotHeight,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _jengaGameOverColor, width: 1),
                                ),
                                child: Image.memory(
                                  _towerScreenshot!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            else
                              Container(
                                width: _gameOverScreenshotWidth,
                                height: _gameOverScreenshotHeight,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _jengaGameOverColor, width: 1),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(color: _jengaGameOverColor),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Invisible 2x3 grid: Row 1 = Share|Shop, Row 2 = Token Revive (merged when not first)|Free Revive, Row 3 = Play again|Leave
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Row 1: Share to Friends | Shop
                                Row(
                                  children: [
                                    Expanded(child: Center(child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Share to Friends'), duration: Duration(seconds: 2)),
                                        );
                                      },
                                      child: Text('Share to Friends', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                                    ))),
                                    Expanded(child: Center(child: TextButton(
                                      onPressed: _showTokenOnlyShopOverGameOver,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shopping_cart, color: _jengaGameOverColor, size: 16),
                                          const SizedBox(width: 4),
                                          Text('Shop', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ))),
                                  ],
                                ),
                                // Row 2: Token Revive (full-width centered when not first) | Token Revive + Free Revive (first time)
                                if (_rebornTimesUsedThisGame == 0)
                                  Row(
                                    children: [
                                      Expanded(child: Center(child: TextButton(
                                        onPressed: TokenService.canAfford(8 * (1 << _rebornTimesUsedThisGame))
                                            ? () {
                                                final cost = 8 * (1 << _rebornTimesUsedThisGame);
                                                TokenService.spendTokens(cost).then((_) {
                                                  if (!mounted) return;
                                                  setState(() {
                                                    _rebornTimesUsedThisGame++;
                                                    isGameOver = false;
                                                    _alignBlocksToCenter();
                                                  });
                                                  _spawnNewBlock();
                                                });
                                              }
                                            : null,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Token Revive ', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                            Icon(Icons.monetization_on, color: _jengaGameOverColor, size: 16),
                                            Text(' x ${8 * (1 << _rebornTimesUsedThisGame)}', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ))),
                                      Expanded(child: Center(child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _rebornTimesUsedThisGame++;
                                            isGameOver = false;
                                            _alignBlocksToCenter();
                                          });
                                          _spawnNewBlock();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.campaign, color: _jengaGameOverColor, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Free Revive', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ))),
                                    ],
                                  )
                                else
                                  Center(
                                    child: TextButton(
                                      onPressed: TokenService.canAfford(8 * (1 << _rebornTimesUsedThisGame))
                                          ? () {
                                              final cost = 8 * (1 << _rebornTimesUsedThisGame);
                                              TokenService.spendTokens(cost).then((_) {
                                                if (!mounted) return;
                                                setState(() {
                                                  _rebornTimesUsedThisGame++;
                                                  isGameOver = false;
                                                  _alignBlocksToCenter();
                                                });
                                                _spawnNewBlock();
                                              });
                                            }
                                          : null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Token Revive ', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                          Icon(Icons.monetization_on, color: _jengaGameOverColor, size: 16),
                                          Text(' x ${8 * (1 << _rebornTimesUsedThisGame)}', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Row 3: Play again | Leave
                                Row(
                                  children: [
                                    Expanded(child: Center(child: TextButton(
                                      onPressed: () {
                                        _resetGame();
                                        _startGame();
                                      },
                                      child: Text('Play again', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
                                    ))),
                                    Expanded(child: Center(child: TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Leave', style: TextStyle(color: _jengaGameOverColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],  // End of Stack children
          ),  // End of body
        ),  // End of Scaffold
      ),  // End of GestureDetector child
    );  // End of KeyboardListener
  }
}
