enum Suit {
  hearts,
  diamonds,
  clubs,
  spades;

  String get symbol {
    switch (this) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  String get name {
    switch (this) {
      case Suit.hearts:
        return 'Hearts';
      case Suit.diamonds:
        return 'Diamonds';
      case Suit.clubs:
        return 'Clubs';
      case Suit.spades:
        return 'Spades';
    }
  }

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
  bool get isBlack => this == Suit.clubs || this == Suit.spades;
}

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace;

  String get symbol {
    switch (this) {
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  int get value => index + 2;
}

class PlayingCard {
  final Rank rank;
  final Suit suit;

  const PlayingCard({
    required this.rank,
    required this.suit,
  });

  String get displayName => '${rank.symbol}${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;

  @override
  String toString() => displayName;
}

enum HandType {
  royalFlush,
  straightFlush,
  fourOfAKind,
  fullHouse,
  flush,
  straight;

  String get name {
    switch (this) {
      case HandType.royalFlush:
        return 'Royal Flush';
      case HandType.straightFlush:
        return 'Straight Flush';
      case HandType.fourOfAKind:
        return 'Four of a Kind';
      case HandType.fullHouse:
        return 'Full House';
      case HandType.flush:
        return 'Flush';
      case HandType.straight:
        return 'Straight';
    }
  }

  String get description {
    switch (this) {
      case HandType.royalFlush:
        return 'A, K, Q, J, 10 of same suit';
      case HandType.straightFlush:
        return '5 cards in sequence, same suit';
      case HandType.fourOfAKind:
        return '4 cards of same rank';
      case HandType.fullHouse:
        return '3 of a kind + pair';
      case HandType.flush:
        return '5 cards of same suit';
      case HandType.straight:
        return '5 cards in sequence';
    }
  }
}

class PokerHand {
  final List<PlayingCard> cards;
  final HandType type;

  const PokerHand({
    required this.cards,
    required this.type,
  });

  // Check if a hand is valid
  static bool isValid(List<PlayingCard> cards) {
    if (cards.length != 5) return false;
    
    // Check for duplicates
    final uniqueCards = cards.toSet();
    if (uniqueCards.length != 5) return false;
    
    return true;
  }

  // Determine the hand type
  static HandType? getHandType(List<PlayingCard> cards) {
    if (!isValid(cards)) return null;

    final sortedCards = List<PlayingCard>.from(cards)
      ..sort((a, b) => a.rank.value.compareTo(b.rank.value));

    final isFlush = _isFlush(sortedCards);
    final isStraight = _isStraight(sortedCards);
    final isRoyal = _isRoyal(sortedCards);

    if (isFlush && isStraight && isRoyal) {
      return HandType.royalFlush;
    }
    if (isFlush && isStraight) {
      return HandType.straightFlush;
    }
    if (_isFourOfAKind(sortedCards)) {
      return HandType.fourOfAKind;
    }
    if (_isFullHouse(sortedCards)) {
      return HandType.fullHouse;
    }
    if (isFlush) {
      return HandType.flush;
    }
    if (isStraight) {
      return HandType.straight;
    }

    return null;
  }

  static bool _isFlush(List<PlayingCard> cards) {
    final suit = cards.first.suit;
    return cards.every((card) => card.suit == suit);
  }

  static bool _isStraight(List<PlayingCard> cards) {
    final values = cards.map((card) => card.rank.value).toList()..sort();
    
    // Check regular straight
    bool isRegularStraight = true;
    for (int i = 0; i < values.length - 1; i++) {
      if (values[i + 1] - values[i] != 1) {
        isRegularStraight = false;
        break;
      }
    }
    
    if (isRegularStraight) return true;
    
    // Check for A-2-3-4-5 (wheel)
    if (values[0] == 2 && values[1] == 3 && values[2] == 4 && values[3] == 5 && values[4] == 14) {
      return true;
    }
    
    return false;
  }

  static bool _isRoyal(List<PlayingCard> cards) {
    final ranks = cards.map((card) => card.rank).toSet();
    return ranks.containsAll([
      Rank.ten,
      Rank.jack,
      Rank.queen,
      Rank.king,
      Rank.ace,
    ]);
  }

  static bool _isFourOfAKind(List<PlayingCard> cards) {
    final rankCounts = <Rank, int>{};
    for (var card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    return rankCounts.values.contains(4);
  }

  static bool _isFullHouse(List<PlayingCard> cards) {
    final rankCounts = <Rank, int>{};
    for (var card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    final counts = rankCounts.values.toList()..sort();
    return counts.length == 2 && counts[0] == 2 && counts[1] == 3;
  }
}
