import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../services/hand_service.dart';
import '../../../shared/themes/app_theme.dart';

class GameScreen extends StatefulWidget {
  final HandType handType;

  const GameScreen({
    super.key,
    required this.handType,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  Timer? _timer;
  int? _selectedRow;
  int? _selectedCol;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    final hand = HandService.generateHand(widget.handType);
    _gameState = GameState.initial(
      hand: hand,
      maxAttempts: 7,
    );
    _selectedRow = 0;
    _selectedCol = 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameState.isComplete) {
        setState(() {
          _gameState = _gameState.updateTime(_gameState.secondsElapsed + 1);
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onCellTap(int row, int col) {
    if (row == _gameState.currentRow && !_gameState.isComplete) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _onCardSelected(PlayingCard card) {
    if (_selectedRow == null || _selectedCol == null) return;
    
    setState(() {
      _gameState = _gameState.addCardAt(card, _selectedRow!, _selectedCol!);
      
      if (_selectedCol! < 4) {
        _selectedCol = _selectedCol! + 1;
      }
    });
  }

  void _removeCard() {
    if (_gameState.isComplete) return;
    
    int lastCol = -1;
    for (int i = 4; i >= 0; i--) {
      if (_gameState.guesses[_gameState.currentRow][i].card != null) {
        lastCol = i;
        break;
      }
    }
    
    if (lastCol >= 0) {
      setState(() {
        _gameState = _gameState.removeCardAt(_gameState.currentRow, lastCol);
        _selectedCol = lastCol;
      });
    }
  }

  void _submitGuess() {
    if (!_gameState.isCurrentRowFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select all 5 cards first!'),
          backgroundColor: AppTheme.primaryOrange,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _gameState = _gameState.evaluateGuess();
      
      if (!_gameState.isComplete) {
        _selectedRow = _gameState.currentRow;
        _selectedCol = 0;
      }
    });

    if (_gameState.isComplete) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showCompletionDialog();
      });
    }
  }

  void _showCompletionDialog() {
    final won = _gameState.isWon;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: won ? AppTheme.neonGreen : AppTheme.primaryOrange,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              won ? Icons.celebration : Icons.close,
              color: won ? AppTheme.neonGreen : AppTheme.primaryOrange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              won ? 'SOLVED!' : 'GAME OVER',
              style: TextStyle(
                color: won ? AppTheme.neonGreen : AppTheme.primaryOrange,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              won ? 'You guessed the poker hand!' : 'Better luck next time!',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Hand Type: ${_gameState.targetHand.type.name}',
              style: TextStyle(fontSize: 14, color: AppTheme.primaryCyan),
            ),
            Text(
              'Time: ${_formatTime(_gameState.secondsElapsed)}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('EXIT'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _initializeGame();
                _startTimer();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
            ),
            child: const Text('PLAY AGAIN', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usedCards = _gameState.getUsedCards();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button, time, and hint
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.primaryCyan),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.handType.name.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTime(_gameState.secondsElapsed),
                        style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Guess Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(_gameState.maxAttempts, (row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (col) {
                          final guessCard = _gameState.guesses[row][col];
                          final isSelected = row == _selectedRow && col == _selectedCol;
                          final isCurrentRow = row == _gameState.currentRow;
                          
                          return GestureDetector(
                            onTap: () => _onCellTap(row, col),
                            child: Container(
                              width: 60,
                              height: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: _getCardColor(guessCard.state),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryCyan : Colors.white24,
                                  width: isSelected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: guessCard.card != null
                                    ? Text(
                                        guessCard.card!.displayName,
                                        style: TextStyle(
                                          color: _getCardTextColor(guessCard.card!, guessCard.state),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : (isCurrentRow && isSelected)
                                        ? Icon(Icons.edit, color: AppTheme.primaryCyan, size: 20)
                                        : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Submit and Delete buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _gameState.isComplete ? null : _removeCard,
                        icon: const Icon(Icons.backspace),
                        label: const Text('DELETE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _gameState.isComplete ? null : _submitGuess,
                        icon: const Icon(Icons.check),
                        label: const Text('SUBMIT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Card Picker - Compact Grid
                  Text(
                    'SELECT CARD',
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryCyan),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 13,
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 52,
                      itemBuilder: (context, index) {
                        final allCards = HandService.getAllCards();
                        final card = allCards[index];
                        final cardState = usedCards[card];
                        
                        return GestureDetector(
                          onTap: _gameState.isComplete ? null : () => _onCardSelected(card),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardState != null ? _getCardColor(cardState) : Colors.grey[900],
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                card.displayName,
                                style: TextStyle(
                                  color: cardState != null 
                                      ? _getCardTextColor(card, cardState) 
                                      : (card.suit.isRed ? Colors.red : Colors.white),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
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
    );
  }

  Color _getCardColor(CardState state) {
    switch (state) {
      case CardState.correct:
        return AppColors.correctGreen; // Green - correct position
      case CardState.wrongPosition:
        return AppColors.presentYellow; // Yellow - wrong position
      case CardState.wrong:
        return AppColors.absentGray; // Grey - not in hand
      default:
        return AppTheme.backgroundColor;
    }
  }

  Color _getCardTextColor(PlayingCard card, CardState state) {
    // On colored backgrounds (green/yellow/grey), use white/black for contrast
    if (state == CardState.correct || state == CardState.wrongPosition) {
      return Colors.white; // White text on green/yellow background
    } else if (state == CardState.wrong) {
      return Colors.white70; // Slightly dimmed white on grey
    }
    
    // For empty/editing state, use suit-based coloring
    return card.suit.isRed ? Colors.red : Colors.white;
  }
}
