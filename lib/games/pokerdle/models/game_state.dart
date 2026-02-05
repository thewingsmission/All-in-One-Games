import 'card.dart';

enum CardState {
  empty,    // Not yet selected
  editing,  // Currently being edited
  wrong,    // Card not in answer (grey)
  wrongPosition, // Card in answer but wrong position (yellow)
  correct,  // Card in correct position (green)
}

class GuessCard {
  final PlayingCard? card;
  final CardState state;

  GuessCard({
    this.card,
    required this.state,
  });

  GuessCard copyWith({
    PlayingCard? card,
    CardState? state,
  }) {
    return GuessCard(
      card: card ?? this.card,
      state: state ?? this.state,
    );
  }
}

class GameState {
  final PokerHand targetHand;
  final List<List<GuessCard>> guesses;
  final int currentRow;
  final int currentCol;
  final int maxAttempts;
  final bool isComplete;
  final bool isWon;
  final int secondsElapsed;
  final int hintsUsed;

  GameState({
    required this.targetHand,
    required this.guesses,
    this.currentRow = 0,
    this.currentCol = 0,
    required this.maxAttempts,
    this.isComplete = false,
    this.isWon = false,
    this.secondsElapsed = 0,
    this.hintsUsed = 0,
  });

  // Create initial game state
  factory GameState.initial({
    required PokerHand hand,
    int maxAttempts = 5,
  }) {
    final guesses = List.generate(
      maxAttempts,
      (row) => List.generate(
        5,
        (col) => GuessCard(card: null, state: CardState.empty),
      ),
    );

    return GameState(
      targetHand: hand,
      guesses: guesses,
      maxAttempts: maxAttempts,
    );
  }

  GameState copyWith({
    PokerHand? targetHand,
    List<List<GuessCard>>? guesses,
    int? currentRow,
    int? currentCol,
    int? maxAttempts,
    bool? isComplete,
    bool? isWon,
    int? secondsElapsed,
    int? hintsUsed,
  }) {
    return GameState(
      targetHand: targetHand ?? this.targetHand,
      guesses: guesses ?? this.guesses,
      currentRow: currentRow ?? this.currentRow,
      currentCol: currentCol ?? this.currentCol,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      isComplete: isComplete ?? this.isComplete,
      isWon: isWon ?? this.isWon,
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      hintsUsed: hintsUsed ?? this.hintsUsed,
    );
  }

  // Check if current row is filled
  bool isCurrentRowFilled() {
    return currentCol == 5;
  }

  // Evaluate the current guess and return new state
  GameState evaluateGuess() {
    if (!isCurrentRowFilled()) return this;

    final guessCards = guesses[currentRow].map((g) => g.card!).toList();
    final targetCards = targetHand.cards;
    
    // Create a copy of the current row
    final newRow = List<GuessCard>.from(guesses[currentRow]);
    
    // Track which target cards have been matched
    final targetMatched = List<bool>.filled(5, false);
    final guessMatched = List<bool>.filled(5, false);
    
    // First pass: mark correct positions
    for (int i = 0; i < 5; i++) {
      if (guessCards[i] == targetCards[i]) {
        newRow[i] = GuessCard(
          card: guessCards[i],
          state: CardState.correct,
        );
        targetMatched[i] = true;
        guessMatched[i] = true;
      }
    }
    
    // Second pass: mark wrong positions
    for (int i = 0; i < 5; i++) {
      if (guessMatched[i]) continue;
      
      bool foundMatch = false;
      for (int j = 0; j < 5; j++) {
        if (!targetMatched[j] && guessCards[i] == targetCards[j]) {
          newRow[i] = GuessCard(
            card: guessCards[i],
            state: CardState.wrongPosition,
          );
          targetMatched[j] = true;
          foundMatch = true;
          break;
        }
      }
      
      if (!foundMatch) {
        newRow[i] = GuessCard(
          card: guessCards[i],
          state: CardState.wrong,
        );
      }
    }
    
    // Update guesses
    final newGuesses = List<List<GuessCard>>.from(guesses);
    newGuesses[currentRow] = newRow;
    
    // Check if won
    bool won = true;
    for (int i = 0; i < 5; i++) {
      if (guessCards[i] != targetCards[i]) {
        won = false;
        break;
      }
    }
    
    final nextRow = currentRow + 1;
    final complete = won || nextRow >= maxAttempts;
    
    return copyWith(
      guesses: newGuesses,
      currentRow: nextRow,
      currentCol: 0,
      isComplete: complete,
      isWon: won,
    );
  }

  // Add card at specific position
  GameState addCardAt(PlayingCard card, int row, int col) {
    if (isComplete || row != currentRow) return this;
    if (col >= 5) return this;

    final newGuesses = List<List<GuessCard>>.from(
      guesses.map((row) => List<GuessCard>.from(row)),
    );
    
    newGuesses[row][col] = GuessCard(
      card: card,
      state: CardState.editing,
    );

    // Update currentCol to be after the last filled cell
    int newCol = 0;
    for (int i = 0; i < 5; i++) {
      if (newGuesses[row][i].card != null) {
        newCol = i + 1;
      }
    }

    return copyWith(
      guesses: newGuesses,
      currentCol: newCol,
    );
  }

  // Remove card at specific position
  GameState removeCardAt(int row, int col) {
    if (isComplete || row != currentRow) return this;
    if (col >= 5) return this;

    final newGuesses = List<List<GuessCard>>.from(
      guesses.map((row) => List<GuessCard>.from(row)),
    );
    
    newGuesses[row][col] = GuessCard(
      card: null,
      state: CardState.empty,
    );

    // Update currentCol to be after the last filled cell
    int newCol = 0;
    for (int i = 0; i < 5; i++) {
      if (newGuesses[row][i].card != null) {
        newCol = i + 1;
      }
    }

    return copyWith(
      guesses: newGuesses,
      currentCol: newCol,
    );
  }

  // Get cards that have been used
  Map<PlayingCard, CardState> getUsedCards() {
    final usedCards = <PlayingCard, CardState>{};
    
    // Iterate through all evaluated guesses (completed rows)
    for (int row = 0; row < currentRow; row++) {
      for (var guessCard in guesses[row]) {
        if (guessCard.card == null) continue;
        
        final card = guessCard.card!;
        final currentState = usedCards[card];
        
        // Priority: correct > wrongPosition > wrong
        if (currentState == CardState.correct) {
          continue;
        } else if (guessCard.state == CardState.correct) {
          usedCards[card] = CardState.correct;
        } else if (guessCard.state == CardState.wrongPosition && currentState != CardState.correct) {
          usedCards[card] = CardState.wrongPosition;
        } else if (guessCard.state == CardState.wrong && currentState == null) {
          usedCards[card] = CardState.wrong;
        }
      }
    }
    
    return usedCards;
  }

  // Update elapsed time
  GameState updateTime(int seconds) {
    return copyWith(secondsElapsed: seconds);
  }
}
