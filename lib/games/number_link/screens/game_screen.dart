import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:all_in_one_games/games/number_link/models/game_state.dart';
import 'package:all_in_one_games/games/number_link/models/cell_style.dart';
import 'package:all_in_one_games/games/number_link/services/level_service.dart';
import 'package:all_in_one_games/core/services/token_service.dart';
import 'package:all_in_one_games/core/l10n/app_localizations.dart';
import 'package:all_in_one_games/games/number_link/services/storage_service.dart';
import 'package:all_in_one_games/games/number_link/widgets/game_board_unity_style.dart';
import 'package:all_in_one_games/games/number_link/services/animal_skin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Leaderboard Entry Model
class LeaderboardEntry {
  final String name;
  final int level;
  final Timestamp timestamp;

  LeaderboardEntry({
    required this.name,
    required this.level,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'timestamp': timestamp,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      name: map['name'] as String,
      level: map['level'] as int,
      timestamp: map['timestamp'] as Timestamp,
    );
  }
  
  static Map<String, dynamic> createNew(String name, int level) {
    return {
      'name': name,
      'level': level,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

// Leaderboard Service
class LeaderboardService {
  static const int MIN_LEVEL_FOR_LEADERBOARD = 50;
  static const int MAX_ENTRIES = 100;
  static const String CACHED_NAME_KEY = 'numberlink_leaderboard_player_name';
  
  // Lazy-initialize Firestore to avoid "No Firebase App" error
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  Future<String?> getCachedPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(CACHED_NAME_KEY);
  }
  
  Future<void> cachePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CACHED_NAME_KEY, name);
  }
  
  bool qualifiesForLeaderboard(int level) {
    return level > MIN_LEVEL_FOR_LEADERBOARD;
  }
  
  Future<bool> submitScore(String playerName, int level) async {
    try {
      final docRef = _firestore.collection('numberlink_leaderboard').doc('highest_level');
      
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        List<LeaderboardEntry> entries = [];
        
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['entries'] != null) {
            final entriesList = data['entries'] as List<dynamic>;
            entries = entriesList.map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>)).toList();
          }
        }
        
        final existingIndex = entries.indexWhere((entry) => entry.name == playerName);
        Timestamp? existingTimestamp;
        
        if (existingIndex != -1) {
          existingTimestamp = entries[existingIndex].timestamp;
          entries.removeAt(existingIndex);
        }
        
        final qualifies = entries.length < MAX_ENTRIES || 
                         (entries.isNotEmpty && level > entries.last.level);
        
        if (!qualifies) {
          return false;
        }
        
        final now = existingTimestamp ?? Timestamp.now();
        entries.add(LeaderboardEntry(
          name: playerName,
          level: level,
          timestamp: now,
        ));
        
        entries.sort((a, b) {
          final levelCompare = b.level.compareTo(a.level);
          if (levelCompare != 0) return levelCompare;
          return a.timestamp.compareTo(b.timestamp);
        });
        
        if (entries.length > MAX_ENTRIES) {
          entries = entries.sublist(0, MAX_ENTRIES);
        }
        
        transaction.set(docRef, {
          'entries': entries.map((e) => e.toMap()).toList(),
        });
        
        return true;
      });
      
      return result;
    } catch (e) {
      print('Error submitting score: $e');
      return false;
    }
  }
  
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final docRef = _firestore.collection('numberlink_leaderboard').doc('highest_level');
      final snapshot = await docRef.get();
      
      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }
      
      final data = snapshot.data()!;
      if (data['entries'] == null) {
        return [];
      }
      
      final entriesList = data['entries'] as List<dynamic>;
      return entriesList.map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }
}

class GameScreen extends StatefulWidget {
  final String difficulty;

  const GameScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LevelService _levelService;
  late final StorageService _storageService;
  late final LeaderboardService _leaderboardService;
  bool _servicesInitialized = false;
  bool _isDialogOpen = false;

  // Game-dependent item quantities (default 3 each)
  int _skinCount = 3;
  int _hintCount = 3;
  int _puzzleShuffleCount = 3;

  final GlobalKey _gameBoardKey = GlobalKey();
  Uint8List? _solvedPuzzleScreenshot;
  
  // Leaderboard cache
  List<LeaderboardEntry>? _cachedLeaderboard;
  String? _cachedPlayerName;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    print('🔵 Starting service initialization...');
    _levelService = LevelService();
    _storageService = StorageService();
    _leaderboardService = LeaderboardService();
    
    try {
      print('🔵 Calling levelService.initialize()...');
      await _levelService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Level service initialization timed out after 10 seconds');
          throw TimeoutException('Level service initialization timed out');
        },
      );
      print('🔵 Level service initialized successfully');
      
      // Load game state after services are initialized
      print('🔵 Loading game state...');
      await _loadGameState();
      print('🔵 Game state loaded successfully');
      
      if (mounted) {
        print('🔵 Setting _servicesInitialized = true');
        setState(() {
          _servicesInitialized = true;
        });
        print('✅ All services initialized, game should now be visible');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in _initializeServices: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _servicesInitialized = true; // Show error state
        });
        // Show error dialog
        Future.delayed(Duration.zero, () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF00D9FF), width: 2),
                ),
                title: Center(
                  child: Text(
                    'Initialization Error',
                    style: TextStyle(
                      color: const Color(0xFF00D9FF),
                      fontWeight: FontWeight.bold,
                      fontSize: _dialogTitleFontSize,
                    ),
                  ),
                ),
                content: Text(
                  'Failed to initialize game: $e',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: const Color(0xFF00D9FF),
                        fontWeight: FontWeight.bold,
                        fontSize: _dialogButtonFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _loadGameState() async {
    if (!mounted) return;
    
    final gameState = Provider.of<GameState>(context, listen: false);
    
    try {
      // Load progress (skins, etc.)
      await gameState.loadProgress(_storageService);
      // Game level always starts from level 1
      gameState.resetLevelNumber();
      
      // Set difficulty for level 1 and load first puzzle
      final difficulty = _levelService.getDifficultyForLevel(1);
      gameState.setDifficulty(difficulty);
      final level = _levelService.getRandomLevel(difficulty);
      
      if (level != null) {
        gameState.loadLevel(level);
        print('✅ Level loaded successfully: ${level.width}x${level.height}');
      } else {
        print('❌ ERROR: Could not load level for difficulty: $difficulty');
        // Try loading a fallback level
        final fallbackLevel = _levelService.getRandomLevel('very_easy');
        if (fallbackLevel != null) {
          gameState.loadLevel(fallbackLevel);
          print('✅ Loaded fallback very_easy level');
        }
      }
      
      // Load score and player name
      await _loadScore();
      await _loadCachedPlayerName();
    } catch (e) {
      print('❌ ERROR in _loadGameState: $e');
    }
  }
  
  Future<void> _loadCachedPlayerName() async {
    final cachedName = await _leaderboardService.getCachedPlayerName();
    if (mounted && cachedName != null && cachedName.isNotEmpty) {
      setState(() {
        _cachedPlayerName = cachedName;
      });
    }
  }

  Future<void> _loadScore() async {
    final score = await _storageService.getCumulativeScore();
    if (mounted) {
      context.read<GameState>().setCumulativeScore(score);
    }
  }

  void _loadInitialLevel() {
    final gameState = context.read<GameState>();
    // In endless mode, use algorithm to get difficulty
    final difficulty = _levelService.getDifficultyForLevel(gameState.currentLevelNumber);
    final level = _levelService.getRandomLevel(difficulty);
    if (level != null) {
      gameState.setDifficulty(difficulty);
      gameState.loadLevel(level);
    }
  }

  void _showShuffleConfirm(Color themeColor) {
    if (_puzzleShuffleCount <= 0) return;
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Puzzle Shuffle',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: const Text(
          'Load a new random puzzle of the same difficulty. Your current progress on this puzzle will be lost. Continue?',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onPuzzleShuffle();
            },
            child: Text('Yes', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _onPuzzleShuffle() {
    final gameState = context.read<GameState>();
    if (_puzzleShuffleCount <= 0) return;
    // Load a random puzzle from the same difficulty (very_easy, easy, normal, hard, very_hard)
    final difficulty = gameState.difficulty;
    final level = _levelService.getRandomLevel(difficulty);
    if (level != null) {
      setState(() => _puzzleShuffleCount--);
      gameState.loadLevel(level);
    }
  }

  void _loadNewLevel() {
    final gameState = context.read<GameState>();
    gameState.advanceToNextLevel();
    
    // Clear previous screenshot
    setState(() {
      _solvedPuzzleScreenshot = null;
    });
    
    // Save progress after advancing level
    gameState.saveProgress(_storageService);
    
    // Check if a new skin is unlocked
    final newlyUnlockedSkin = gameState.checkForNewlyUnlockedSkin();
    if (newlyUnlockedSkin != null) {
      _showSkinUnlockDialog(newlyUnlockedSkin);
    }
    
    // Use algorithm to determine difficulty based on new level number
    final difficulty = _levelService.getDifficultyForLevel(gameState.currentLevelNumber);
    final level = _levelService.getRandomLevel(difficulty);
    if (level != null) {
      gameState.setDifficulty(difficulty);
      gameState.loadLevel(level);
    }
  }
  
  /// Check if level qualifies for leaderboard and handle submission
  // TODO: Leaderboard methods temporarily disabled
  // Future<void> _checkAndSubmitLeaderboard(int completedLevel) async {
  //   // Only check if level qualifies
  //   if (!_leaderboardService.qualifiesForLeaderboard(completedLevel)) {
  //     return; // Level too low, skip
  //   }
  //   
  //   // Check if player name is cached
  //   final cachedName = await _leaderboardService.getCachedPlayerName();
  //   
  //   if (cachedName != null && cachedName.isNotEmpty) {
  //     // Auto-submit with cached name
  //     await _submitToLeaderboard(cachedName, completedLevel);
  //   } else {
  //     // Show name entry dialog
  //     _showNameEntryDialog(completedLevel);
  //   }
  // }
  // 
  // /// Submit score to leaderboard
  // Future<void> _submitToLeaderboard(String playerName, int level) async {
  //   final success = await _leaderboardService.submitScore(playerName, level);
  //   
  //   if (mounted) {
  //     if (success) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('🎉 Level $level added to leaderboard!'),
  //           backgroundColor: Colors.green,
  //           duration: const Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   }
  // }
  // 
  // /// Show name entry dialog for first-time leaderboard submission
  // void _showNameEntryDialog(int level) {
  //   final nameController = TextEditingController();
  //   
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       title: Row(
  //         children: const [
  //           Icon(Icons.leaderboard, color: Colors.amber, size: 28),
  //           SizedBox(width: 12),
  //           Text('Leaderboard Entry!'),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'You\'ve reached Level $level!',
  //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 8),
  //           const Text(
  //             'Enter your name for the leaderboard:',
  //             style: TextStyle(fontSize: 14),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 20),
  //           TextField(
  //             controller: nameController,
  //             decoration: const InputDecoration(
  //               labelText: 'Your Name',
  //               hintText: 'Enter 3-20 characters',
  //               border: OutlineInputBorder(),
  //               prefixIcon: Icon(Icons.person),
  //             ),
  //             maxLength: 20,
  //             autofocus: true,
  //             textCapitalization: TextCapitalization.words,
  //           ),
  //           const SizedBox(height: 8),
  //           const Text(
  //             'Your name will be saved for future submissions.',
  //             style: TextStyle(fontSize: 12, color: Colors.grey),
  //             textAlign: TextAlign.center,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Skip'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             final name = nameController.text.trim();
  //             if (name.length < 3) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Name must be at least 3 characters'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //               return;
  //             }
  //             
  //             // Cache the name for future use
  //             await _leaderboardService.cachePlayerName(name);
  //             
  //             // Submit to leaderboard
  //             Navigator.pop(context);
  //             await _submitToLeaderboard(name, level);
  //           },
  //           child: const Text('Submit'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  
  void _showSkinUnlockDialog(CellStyle unlockedSkin) {
    const Color _dialogTheme = Color(0xFF00D9FF);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _dialogTheme, width: 2),
        ),
        title: Center(
          child: Text(
            'New Skin Unlocked!',
            style: TextStyle(
              color: _dialogTheme,
              fontWeight: FontWeight.bold,
              fontSize: _dialogTitleFontSize,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve unlocked the ${unlockedSkin.displayName} skin!',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unlockedSkin == CellStyle.animal ? Colors.transparent : Colors.orange,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _dialogTheme.withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _buildStylePreview(unlockedSkin),
            ),
            const SizedBox(height: 16),
            Text(
              'You can now use this skin in the game!',
              style: TextStyle(
                fontSize: 14,
                color: _dialogTheme,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'AWESOME!',
              style: TextStyle(
                color: _dialogTheme,
                fontWeight: FontWeight.bold,
                fontSize: _dialogButtonFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isHintMode = false;

  void _toggleHintMode() {
    final gameState = context.read<GameState>();
    
    final themeColor = _topHintColor;
    // Only block when no hints left
    if (_hintCount <= 0) {
      setState(() => _isDialogOpen = true);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: themeColor, width: 2),
          ),
          title: Center(
            child: Text(
              'No Hints Left',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: _dialogTitleFontSize,
              ),
            ),
          ),
          content: const Text(
            'You have no hints left. Get more from the Shop.',
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: _dialogButtonFontSize,
                ),
              ),
            ),
          ],
        ),
      ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
      return;
    }
    
    // Show hint confirmation dialog (same style as other popups)
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: themeColor, width: 2),
        ),
        title: Center(
          child: Text(
            'Use Hint?',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: _dialogTitleFontSize,
            ),
          ),
        ),
        content: const Text(
          'Tap on any endpoint to reveal its complete path. Do you want to use one hint?',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: _dialogButtonFontSize,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) setState(() {
                _isHintMode = true;
                debugPrint('=== HINT MODE ENABLED ===');
              });
            },
            child: Text(
              'Yes',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: _dialogButtonFontSize,
              ),
            ),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _handleHintSelection(String color) {
    setState(() {
      _isHintMode = false;
      _hintCount--; // Decrement only when hint is actually used on the puzzle
    });
    context.read<GameState>().applyHint(color);
    _checkWin();
  }

  void _showStyleDialog(Color themeColor) {
    final gameState = context.read<GameState>();
    
    // Show all skins (same style as other popups: black bg, theme border, theme title)
    final allStyles = CellStyle.values.toList();

    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: themeColor, width: 2),
        ),
        title: Center(
          child: Text(
            'Choose Skin Style',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: _dialogTitleFontSize,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: allStyles.map((style) {
              final isUnlocked = gameState.isSkinUnlocked(style);
              final isSelected = gameState.cellStyle == style;
              
              // Get unlock condition text
              String unlockText = '';
              if (!isUnlocked) {
                switch (style) {
                  case CellStyle.strip:
                    unlockText = 'Unlock at level 11';
                    break;
                  case CellStyle.glow:
                    unlockText = 'Unlock at level 31';
                    break;
                  case CellStyle.animal:
                    unlockText = 'Unlock at level 51';
                    break;
                  case CellStyle.cat:
                    unlockText = 'Unlock at level 71';
                    break;
                  case CellStyle.dog:
                    unlockText = 'Unlock at level 91';
                    break;
                  case CellStyle.ghost:
                    unlockText = 'Unlock at level 111';
                    break;
                  case CellStyle.monster:
                    unlockText = 'Unlock at level 131';
                    break;
                  default:
                    unlockText = '';
                }
              }
              
              return Opacity(
                opacity: isUnlocked ? 1.0 : 0.5,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  title: Row(
                    children: [
                      // Preview Container with blur for locked
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: (style == CellStyle.animal || 
                                      style == CellStyle.cat || 
                                      style == CellStyle.dog || 
                                      style == CellStyle.ghost || 
                                      style == CellStyle.monster) 
                                  ? Colors.transparent 
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isUnlocked
                                ? _buildStylePreview(style)
                                : ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                    child: _buildStylePreview(style),
                                  ),
                          ),
                          if (!isUnlocked)
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey, width: 1),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.displayName,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.grey,
                                letterSpacing: 0.5,
                                fontWeight: isUnlocked ? FontWeight.normal : FontWeight.w300,
                              ),
                            ),
                            if (!isUnlocked)
                              Text(
                                unlockText,
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  leading: Radio<CellStyle>(
                    value: style,
                    groupValue: gameState.cellStyle,
                    activeColor: themeColor,
                    onChanged: isUnlocked
                        ? (CellStyle? value) {
                            if (value != null) {
                              gameState.setCellStyle(value);
                              gameState.saveProgress(_storageService);
                              Navigator.pop(context);
                            }
                          }
                        : null,
                  ),
                  selected: isSelected,
                  enabled: isUnlocked,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Don't change",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
            ),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  // Bottom 5 buttons: left to right = neon light blue, neon green, neon yellow, neon orange, neon magenta
  static const Color _bottomRestartColor = Color(0xFF00D9FF);    // neon light blue
  static const Color _bottomLeaderboardColor = Color(0xFF00FF41); // neon green
  static const Color _bottomShopColor = Color(0xFFCCFF00);      // neon yellow
  static const Color _bottomGameRuleColor = Color(0xFFFF6600);  // neon orange
  static const Color _bottomLeaveColor = Color(0xFFFF00FF);     // neon magenta

  // Top 3 buttons: from interface table — Ruby, Gold, Mint
  static const Color _topSkinColor = Color(0xFFFF5252);   // Ruby
  static const Color _topHintColor = Color(0xFFFFD700);    // Gold
  static const Color _topShuffleColor = Color(0xFF00FFCC); // Mint

  static const double _standardButtonHeight = 42; // 28 * 1.5
  static const double _standardButtonFontSize = 11;
  static const double _standardButtonIconSize = 12;
  static const double _standardButtonRadius = 12;
  static const double _buttonGlowBlur = 10;
  static const double _buttonGlowSpread = 1;
  /// All dialogs: title theme color + center + this size; button text this size; content white.
  static const double _dialogTitleFontSize = 16;
  static const double _dialogButtonFontSize = 14;

  /// Bottom panel button: black fill, theme color border/text/icon, rounded, outer glow. Small consistent font.
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

  /// Top panel button: same config as bottom (icon + label, black fill, theme border, outer glow). Dims when popup open (onPressed null).
  Widget _gameDependentPanelButton(BuildContext context, IconData icon, String label, VoidCallback? onPressed, {required Color themeColor}) {
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
    final gameState = context.read<GameState>();
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
        content: const Text('If you restart, all progress will be gone. Start from level 1?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            gameState.resetLevelNumber();
            await gameState.saveProgress(_storageService);
            _loadInitialLevel();
          }, child: Text('Yes', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize))),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showNumberLinkShopDialog(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final t = (String key) => AppLocalizations.tr(context, key);
          return AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
          title: Center(
            child: Text(
              t('shop'),
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
                                '${TokenService.getTokenCount()} ${TokenService.getTokenCount() == 1 ? "Token" : "Tokens"}',
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
                            _hintCount > 0 ? 'Hint x $_hintCount' : 'Hint',
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
                            _puzzleShuffleCount > 0 ? 'Shuffle x $_puzzleShuffleCount' : 'Shuffle',
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('hint_x1'), t('reveal_one_path'), 2, TokenService.canAfford(2), () async {
                    final ok = await TokenService.spendTokens(2);
                    if (ok && mounted) {
                      setState(() => _hintCount++);
                      setDialogState(() {});
                    }
                  }),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('hint_x5'), t('reveal_one_path_per_hint'), 6, TokenService.canAfford(6), () async {
                    final ok = await TokenService.spendTokens(6);
                    if (ok && mounted) {
                      setState(() => _hintCount += 5);
                      setDialogState(() {});
                    }
                  }),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('hint_x25'), t('reveal_one_path_per_hint'), 18, TokenService.canAfford(18), () async {
                    final ok = await TokenService.spendTokens(18);
                    if (ok && mounted) {
                      setState(() => _hintCount += 25);
                      setDialogState(() {});
                    }
                  }),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('shuffle_x1'), t('load_new_puzzle'), 1, TokenService.canAfford(1), () async {
                    final ok = await TokenService.spendTokens(1);
                    if (ok && mounted) {
                      setState(() => _puzzleShuffleCount++);
                      setDialogState(() {});
                    }
                  }),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('shuffle_x5'), t('load_new_puzzle_each'), 3, TokenService.canAfford(3), () async {
                    final ok = await TokenService.spendTokens(3);
                    if (ok && mounted) {
                      setState(() => _puzzleShuffleCount += 5);
                      setDialogState(() {});
                    }
                  }),
                  _shopRowNL(dialogContext, themeColor, setDialogState, t('shuffle_x25'), t('load_new_puzzle_each'), 9, TokenService.canAfford(9), () async {
                    final ok = await TokenService.spendTokens(9);
                    if (ok && mounted) {
                      setState(() => _puzzleShuffleCount += 25);
                      setDialogState(() {});
                    }
                  }),
                  ...TokenService.tokenPacks.map((pack) => _shopRowNLTokenPack(
                    dialogContext,
                    themeColor,
                    setDialogState,
                    pack,
                    () async {
                      await TokenService.addTokens(pack.tokens);
                      if (dialogContext.mounted) {
                        setDialogState(() {});
                      }
                    },
                  )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t('close'), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
            ),
          ],
        );
        },
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  Widget _shopRowNL(
    BuildContext context,
    Color themeColor,
    void Function(void Function()) setDialogState,
    String name,
    String desc,
    int price,
    bool enabled,
    VoidCallback onBuy,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? () => onBuy() : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on, color: themeColor, size: 18),
                const SizedBox(width: 4),
                Text('$price', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopRowNLTokenPack(
    BuildContext context,
    Color themeColor,
    void Function(void Function()) setDialogState,
    TokenPack pack,
    VoidCallback onBuy,
  ) {
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
                Text('x ${pack.tokens}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Text('\$${pack.usd.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => onBuy(),
            child: Text('Buy', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)),
          ),
        ],
      ),
    );
  }

  void _showGameRuleDialog(Color themeColor) {
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: themeColor, width: 2)),
        title: Center(
          child: Text(
            'Game Rule',
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogTitleFontSize),
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Connect all pairs of numbers with paths. Paths cannot cross each other or overlap. '
            'Draw from one number to the other of the same value. Fill every cell to complete the level.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize)))],
      ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }

  void _showLeaderboardDialog(Color themeColor, {bool forceRefresh = false}) async {
    // Use cached data if available and not forcing refresh
    List<LeaderboardEntry> entries;
    
    if (_cachedLeaderboard != null && !forceRefresh) {
      entries = _cachedLeaderboard!;
      _showLeaderboardDialogWithData(entries, themeColor);
    } else {
      // Show loading dialog while fetching
      setState(() => _isDialogOpen = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: themeColor, width: 2),
          ),
          content: SizedBox(
            width: 100,
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: themeColor,
              ),
            ),
          ),
        ),
      );
      
      try {
        entries = await _leaderboardService.getLeaderboard();
        _cachedLeaderboard = entries; // Cache the data
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog (keeps _isDialogOpen true until data dialog closes)
          _showLeaderboardDialogWithData(entries, themeColor);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          setState(() => _isDialogOpen = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading leaderboard: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _showLeaderboardDialogWithData(List<LeaderboardEntry> entries, Color themeColor) {
    String selectedPeriod = 'All Time';
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: themeColor, width: 2),
          ),
          title: Center(
            child: Text(
              'Leaderboard',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: _dialogTitleFontSize,
              ),
            ),
          ),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['All Time', 'Weekly', 'Daily'].map((p) {
                    final isSelected = selectedPeriod == p;
                    return TextButton(
                      onPressed: () => setDialogState(() => selectedPeriod = p),
                      child: Text(p, style: TextStyle(color: themeColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: _dialogButtonFontSize)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'No leaderboard entries yet',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Rank',
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Name',
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Level',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scrollable list
                    Expanded(
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final rank = index + 1;
                          final isSelf = _cachedPlayerName != null && entry.name == _cachedPlayerName;
                          
                          // Trophy icons for top 3
                          Widget rankWidget;
                          if (rank == 1) {
                            rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24); // Gold
                          } else if (rank == 2) {
                            rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 24); // Silver
                          } else if (rank == 3) {
                            rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 24); // Bronze
                          } else {
                            rankWidget = Text(
                              '#$rank',
                              style: TextStyle(
                                color: isSelf ? themeColor : Colors.white70,
                                fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            );
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelf 
                                  ? themeColor.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isSelf 
                                  ? Border.all(color: themeColor.withOpacity(0.5), width: 1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: rankWidget,
                                ),
                                Expanded(
                                  child: Text(
                                    entry.name,
                                    style: TextStyle(
                                      color: isSelf ? Colors.white : Colors.white70,
                                      fontWeight: isSelf ? FontWeight.w600 : FontWeight.normal,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Lv ${entry.level}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: isSelf ? themeColor : Colors.white70,
                                      fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: _dialogButtonFontSize,
              ),
            ),
          ),
        ],
      ),
        ),
    ).then((_) { if (mounted) setState(() => _isDialogOpen = false); });
  }
  
  Future<void> _checkAndSubmitLeaderboardBlocking(int completedLevel) async {
    // Only check if level > 50
    if (completedLevel <= LeaderboardService.MIN_LEVEL_FOR_LEADERBOARD) {
      return;
    }
    
    try {
      // Use cached leaderboard if available, otherwise read from Firestore
      List<LeaderboardEntry> leaderboard;
      if (_cachedLeaderboard != null && _cachedLeaderboard!.isNotEmpty) {
        leaderboard = _cachedLeaderboard!;
        // No read needed - using cache
      } else {
        // Need to read from Firestore
        leaderboard = await _leaderboardService.getLeaderboard();
        _cachedLeaderboard = leaderboard;
      }
      
      // Check if user level is higher than #100
      bool qualifies = false;
      if (leaderboard.length < LeaderboardService.MAX_ENTRIES) {
        qualifies = true; // Less than 100 entries, auto-qualify
      } else if (leaderboard.isNotEmpty) {
        final lowestLevel = leaderboard.last.level;
        qualifies = completedLevel > lowestLevel;
      }
      
      if (!qualifies) {
        return; // Level not high enough for leaderboard
      }
      
      // Check if player name is cached
      if (_cachedPlayerName != null && _cachedPlayerName!.isNotEmpty) {
        // Auto-submit with cached name
        await _submitToLeaderboardBlocking(_cachedPlayerName!, completedLevel);
      } else {
        // Show name entry dialog and WAIT for it to complete
        await _showNameEntryDialogBlocking(completedLevel);
      }
    } catch (e) {
      print('Error checking leaderboard: $e');
    }
  }
  
  Future<void> _submitToLeaderboardBlocking(String playerName, int level) async {
    final success = await _leaderboardService.submitScore(playerName, level);
    
    if (mounted) {
      if (success) {
        // Refresh leaderboard cache from Firestore
        final updatedLeaderboard = await _leaderboardService.getLeaderboard();
        _cachedLeaderboard = updatedLeaderboard;
        
        // Find player's rank
        final rank = updatedLeaderboard.indexWhere((entry) => entry.name == playerName) + 1;
        
        // Show rank notification and WAIT for it to close
        await _showRankNotificationBlocking(rank);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit to leaderboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showNameEntryDialogBlocking(int level) async {
    final nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00FF41), width: 2),
        ),
        title: Center(
          child: Text(
            'Leaderboard Entry!',
            style: TextStyle(
              color: const Color(0xFF00FF41),
              fontWeight: FontWeight.bold,
              fontSize: _dialogTitleFontSize,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You reached Level $level!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your name for the leaderboard:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Visitor',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00FF41)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00FF41)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00FF41), width: 2),
                ),
              ),
              onSubmitted: (value) {
                final trimmed = value.trim();
                Navigator.pop(context, trimmed.isEmpty ? 'Visitor' : trimmed);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Visitor');
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: const Color(0xFF00FF41), fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF41),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final nameText = nameController.text.trim();
              Navigator.pop(context, nameText.isEmpty ? 'Visitor' : nameText);
            },
            child: Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
            ),
          ),
        ],
      ),
    );
    
    // Name should always be set (either user input or "Visitor")
    if (name != null && name.isNotEmpty) {
      // Cache name and submit
      await _leaderboardService.cachePlayerName(name);
      setState(() {
        _cachedPlayerName = name;
      });
      await _submitToLeaderboardBlocking(name, level);
    }
  }
  
  Future<void> _showRankNotificationBlocking(int rank) async {
    String rankText;
    if (rank == 1) {
      rankText = '🏆 You are #1! 🏆';
    } else if (rank == 2) {
      rankText = '🥈 You are #2! 🥈';
    } else if (rank == 3) {
      rankText = '🥉 You are #3! 🥉';
    } else {
      rankText = 'You are ranked #$rank!';
    }
    
    if (mounted) setState(() => _isDialogOpen = true);
    const Color _rankTheme = Color(0xFF00FF41);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _rankTheme, width: 2),
        ),
        title: Center(
          child: Text(
            'Your Rank',
            style: TextStyle(
              color: _rankTheme,
              fontWeight: FontWeight.bold,
              fontSize: _dialogTitleFontSize,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rankText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Great job!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _rankTheme,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: _dialogButtonFontSize),
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isDialogOpen = false);
  }

  Widget _buildStylePreview(CellStyle style) {
     switch (style) {
      case CellStyle.numbered:
        return const Center(
          child: Text(
            '1',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24, // 40 * 0.6
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case CellStyle.square:
        return Center(
          child: Container(
            width: 12, // 40 * 0.3
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case CellStyle.strip:
        // 7x7 grid with 4 concentric square rims
        // Rim 1 (distance 0): Orange, Rim 2 (distance 1): White
        // Rim 3 (distance 2): Orange, Rim 4 (distance 3): White
        final double unit = 40.0 / 7.0;
        
        return SizedBox(
          width: 40,
          height: 40,
          child: Column(
            children: [
              // Row 0: Rim 1 - All orange
              Container(width: 40, height: unit, color: Colors.orange),
              // Row 1: Rim 1 edges, Rim 2 inner
              Row(children: [
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit * 5, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
              ]),
              // Row 2: Rim 1, Rim 2, Rim 3
              Row(children: [
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit * 3, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
              ]),
              // Row 3: Rim 1, Rim 2, Rim 3, Rim 4
              Row(children: [
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
              ]),
              // Row 4: Same as Row 2
              Row(children: [
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit * 3, height: unit, color: Colors.orange),
                Container(width: unit, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
              ]),
              // Row 5: Same as Row 1
              Row(children: [
                Container(width: unit, height: unit, color: Colors.orange),
                Container(width: unit * 5, height: unit, color: Colors.white),
                Container(width: unit, height: unit, color: Colors.orange),
              ]),
              // Row 6: Rim 1 - All orange
              Container(width: 40, height: unit, color: Colors.orange),
            ],
          ),
        );
      case CellStyle.animal:
        return Stack(
          children: [
            // Orange background cell
            Container(
              width: 40,
              height: 40,
              color: Colors.orange,
            ),
            // Blurred layer for glow (respects transparency)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset(
                  'assets/games/number link/images/animal skin/animal_image_01.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Original sharp image
            Image.asset(
              'assets/games/number link/images/animal skin/animal_image_01.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey,
                child: const Icon(Icons.pets, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      case CellStyle.cat:
        return Stack(
          children: [
            // Orange background cell
            Container(
              width: 40,
              height: 40,
              color: Colors.orange,
            ),
            // Blurred layer for glow (respects transparency)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset(
                  'assets/games/number link/images/cat skin/cat_image_01.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Original sharp image
            Image.asset(
              'assets/games/number link/images/cat skin/cat_image_01.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.pink.shade100,
                child: const Icon(Icons.pets, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      case CellStyle.dog:
        return Stack(
          children: [
            // Orange background cell
            Container(
              width: 40,
              height: 40,
              color: Colors.orange,
            ),
            // Blurred layer for glow (respects transparency)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset(
                  'assets/games/number link/images/dog skin/dog_image_01.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Original sharp image
            Image.asset(
              'assets/games/number link/images/dog skin/dog_image_01.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.brown.shade100,
                child: const Icon(Icons.pets, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      case CellStyle.ghost:
        return Stack(
          children: [
            // Orange background cell
            Container(
              width: 40,
              height: 40,
              color: Colors.orange,
            ),
            // Blurred layer for glow (respects transparency)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset(
                  'assets/games/number link/images/ghost skin/ghost_image_01.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Original sharp image
            Image.asset(
              'assets/games/number link/images/ghost skin/ghost_image_01.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.cloud, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      case CellStyle.monster:
        return Stack(
          children: [
            // Orange background cell
            Container(
              width: 40,
              height: 40,
              color: Colors.orange,
            ),
            // Blurred layer for glow (respects transparency)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: Image.asset(
                  'assets/games/number link/images/monster skin/monster_image_01.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Original sharp image
            Image.asset(
              'assets/games/number link/images/monster skin/monster_image_01.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.purple.shade100,
                child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      case CellStyle.glow:
        // Glow skin preview - show color_block01 with index01 on top
        return Stack(
          children: [
            Image.asset(
              'assets/games/number link/images/glow skin/color_block01.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey,
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
            ),
            Image.asset(
              'assets/games/number link/images/glow skin/index01.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Container(),
            ),
          ],
        );
    } 
  }

  Widget _triangle(Color color) {
    return Container(width: 8, height: 8, color: color); // Simplified square for preview or implement clipper
  }

  Widget _buildFinishedPuzzlePreview(GameState gameState, double maxWidth, double maxHeight) {
    if (gameState.currentLevel == null) {
      return const SizedBox();
    }

    final level = gameState.currentLevel!;
    final playerGrid = gameState.playerGrid;
    final colorMapping = gameState.colorMapping;
    
    // Calculate cell size and gaps that scale together
    // Gap between cells and edge padding are equal
    final cellGap = maxWidth * 0.012; // Gap between cells
    final edgePadding = cellGap; // Same as cell gap (per user requirement)
    
    final availableWidth = maxWidth - (edgePadding * 2);
    final availableHeight = maxHeight - (edgePadding * 2);
    
    // Account for gaps between cells
    final totalGapWidth = cellGap * (level.width - 1);
    final totalGapHeight = cellGap * (level.height - 1);
    
    final cellSize = min(
      (availableWidth - totalGapWidth) / level.width,
      (availableHeight - totalGapHeight) / level.height,
    );

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(edgePadding), // Equal to cell gap
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: List.generate(level.height, (row) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: row < level.height - 1 ? cellGap : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
                children: List.generate(level.width, (col) {
                  final cell = playerGrid[row][col];
                  final color = colorMapping[cell] ?? Colors.white;
                  
                  // Check if this is a terminal cell (question grid shows terminal cells)
                  final isTerminal = level.questionGrid[row][col] != '-';
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      right: col < level.width - 1 ? cellGap : 0,
                    ),
                    child: _buildPreviewCell(
                      cellSize, 
                      color, 
                      cell, 
                      isTerminal,
                      gameState.cellStyle,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPreviewCell(double size, Color color, String cellValue, bool isTerminal, CellStyle style) {
    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    // For non-terminal cells, just show colored square
    if (!isTerminal) {
      return container;
    }

    // For terminal cells, apply the selected skin style
    switch (style) {
      case CellStyle.numbered:
        // Show number (a=1, b=2, etc.)
        final index = cellValue.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
        return Stack(
          alignment: Alignment.center, // Ensure perfect centering
          children: [
            container,
            Text(
              '$index',
              style: TextStyle(
                color: Colors.black, // Changed to black
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case CellStyle.square:
        // Show white square in center
        return Stack(
          alignment: Alignment.center, // Ensure perfect centering
          children: [
            container,
            Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );

      case CellStyle.strip:
        // Show concentric white squares
        final rimSize = size * 0.14;
        return Stack(
          children: [
            container,
            // White rim 2 (second from outside)
            Center(
              child: Container(
                width: size - (rimSize * 2),
                height: size - (rimSize * 2),
                color: Colors.white,
                child: Center(
                  // Center 3x3 white
                  child: Container(
                    width: size - (rimSize * 4),
                    height: size - (rimSize * 4),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );

      case CellStyle.glow:
      case CellStyle.animal:
      case CellStyle.cat:
      case CellStyle.dog:
      case CellStyle.ghost:
      case CellStyle.monster:
        // For glow and image-based skins, just show colored square with small indicator
        return Stack(
          children: [
            container,
            Center(
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
    }
  }

  bool _isButtonsEnabled = true; // Track if buttons are clickable
  
  Future<void> _captureGameBoardScreenshot() async {
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary boundary = _gameBoardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      
      // Convert to bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData != null) {
        setState(() {
          _solvedPuzzleScreenshot = byteData.buffer.asUint8List();
        });
        print('Screenshot captured successfully');
      }
    } catch (e) {
      print('Error capturing screenshot: $e');
    }
  }
  
  void _checkWin() {
    final gameState = context.read<GameState>();
    if (gameState.checkWin()) {
      // Freeze the puzzle immediately to prevent further changes
      gameState.freezePuzzle();
      
      // Disable buttons immediately
      setState(() {
        _isButtonsEnabled = false;
      });
      
      // Wait for rendering to complete, then capture screenshot
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _captureGameBoardScreenshot();
        
        // Check and submit to leaderboard FIRST (blocking), then show congratulation
        final completedLevel = gameState.currentLevelNumber;
        await _checkAndSubmitLeaderboardBlocking(completedLevel);
        
        // Wait additional time before showing dialog
        Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() => _isDialogOpen = true);
        const Color _completeThemeColor = Color(0xFFFF00FF);
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final puzzleSize = (screenWidth * 0.7).clamp(200.0, 320.0);
            return AlertDialog(
              backgroundColor: const Color(0xFF000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _completeThemeColor, width: 2),
              ),
              title: Center(
                child: Text(
                  'Congratulations',
                  style: TextStyle(
                    color: _completeThemeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: _dialogTitleFontSize,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Level ${gameState.currentLevelNumber} Complete',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_solvedPuzzleScreenshot != null)
                        Container(
                          width: puzzleSize,
                          height: puzzleSize,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _completeThemeColor, width: 1),
                          ),
                          child: Image.memory(
                            _solvedPuzzleScreenshot!,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        Container(
                          width: puzzleSize,
                          height: puzzleSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _completeThemeColor, width: 1),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF00FF)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Share to Friends - placeholder; hook to share_plus or platform share later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share to Friends'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Text(
                    'Share to Friends',
                    style: TextStyle(
                      color: _completeThemeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: _dialogButtonFontSize,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Next Level',
                    style: TextStyle(
                      color: _completeThemeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: _dialogButtonFontSize,
                    ),
                  ),
                ),
              ],
            );
          },
        ).then((_) {
        // When dialog is dismissed (by tapping outside or Next Level button)
        if (mounted) setState(() {
          _isButtonsEnabled = true;
          _isDialogOpen = false;
        });
        _loadNewLevel();
      });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while services are initializing
    if (!_servicesInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF000000),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00D9FF)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'NUMBER LINK',
            style: TextStyle(
              color: Color(0xFF00D9FF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF00D9FF)),
              SizedBox(height: 20),
              Text(
                'LOADING NUMBER LINK...',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Loading puzzles and initializing game...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Consumer<GameState>(
            builder: (context, gameState, _) => Text(
              'Level ${gameState.currentLevelNumber}',
              style: const TextStyle(
                fontFamily: 'Arial',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, _) {
          if (gameState.currentLevel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Game-dependent buttons at top (orange) with quantity
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                color: const Color(0xFF000000),
                child: Row(
                  children: [
                    Expanded(child: _gameDependentPanelButton(context, Icons.palette, 'Skin', (_isButtonsEnabled && !_isDialogOpen) ? () => _showStyleDialog(_topSkinColor) : null, themeColor: _topSkinColor)),
                    const SizedBox(width: 6),
                    Expanded(child: _gameDependentPanelButton(context, Icons.lightbulb_outline, _hintCount > 0 ? 'Hint x $_hintCount' : 'Hint', (_isButtonsEnabled && !_isDialogOpen && _hintCount > 0) ? () => _toggleHintMode() : null, themeColor: _topHintColor)),
                    const SizedBox(width: 6),
                    Expanded(child: _gameDependentPanelButton(context, Icons.shuffle, _puzzleShuffleCount > 0 ? 'Shuffle x $_puzzleShuffleCount' : 'Shuffle', (_isButtonsEnabled && !_isDialogOpen && _puzzleShuffleCount > 0) ? () => _showShuffleConfirm(_topShuffleColor) : null, themeColor: _topShuffleColor)),
                  ],
                ),
              ),

              // Game board - fits screen without scrolling
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 0, bottom: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: RepaintBoundary(
                          key: _gameBoardKey,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                            ),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: GameBoardUnityStyle(
                                onCellChanged: () => _checkWin(),
                                isHintMode: _isHintMode,
                                onHintSelected: _handleHintSelection,
                                onHintCancelled: () => setState(() => _isHintMode = false),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Standard buttons at bottom: 5 same-size buttons with icons. SafeArea + margin for device gesture area.
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                  color: const Color(0xFF000000),
                  child: Row(
                  children: [
                    Expanded(child: _standardPanelButton(context, Icons.replay, 'Restart', (_isButtonsEnabled && !_isDialogOpen) ? () => _showRestartConfirm(_bottomRestartColor) : null, themeColor: _bottomRestartColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _standardPanelButton(context, Icons.leaderboard, 'Rank', (_isButtonsEnabled && !_isDialogOpen) ? () => _showLeaderboardDialog(_bottomLeaderboardColor) : null, themeColor: _bottomLeaderboardColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _standardPanelButton(context, Icons.shopping_cart, 'Shop', (_isButtonsEnabled && !_isDialogOpen) ? () => _showNumberLinkShopDialog(_bottomShopColor) : null, themeColor: _bottomShopColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _standardPanelButton(context, Icons.menu_book, 'Rules', !_isDialogOpen ? () => _showGameRuleDialog(_bottomGameRuleColor) : null, themeColor: _bottomGameRuleColor)),
                    const SizedBox(width: 4),
                    Expanded(child: _standardPanelButton(context, Icons.logout, 'Leave', !_isDialogOpen ? () => _showLeaveConfirm(_bottomLeaveColor) : null, themeColor: _bottomLeaveColor)),
                  ],
                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String assetPath;
  final double size;
  final bool enabled;

  const _ImageButton({
    required this.onPressed,
    required this.assetPath,
    this.size = 150, // 2.5x larger
    this.enabled = true,
  });

  @override
  State<_ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<_ImageButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1, // Scale down by 10%
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? _onTapDown : null,
      onTapUp: widget.enabled ? _onTapUp : null,
      onTapCancel: widget.enabled ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _controller.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Stack(
                  children: [
                    Image.asset(
                      widget.assetPath,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                    ),
                    if (!widget.enabled)
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

