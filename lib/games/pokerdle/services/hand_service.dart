import 'dart:math';
import '../models/card.dart';

class HandService {
  static final _random = Random();

  // Generate a random poker hand of a specific type
  static PokerHand generateHand(HandType type) {
    switch (type) {
      case HandType.royalFlush:
        return _generateRoyalFlush();
      case HandType.straightFlush:
        return _generateStraightFlush();
      case HandType.fourOfAKind:
        return _generateFourOfAKind();
      case HandType.fullHouse:
        return _generateFullHouse();
      case HandType.flush:
        return _generateFlush();
      case HandType.straight:
        return _generateStraight();
    }
  }

  static PokerHand _generateRoyalFlush() {
    final suit = Suit.values[_random.nextInt(4)];
    final cards = [
      PlayingCard(rank: Rank.ten, suit: suit),
      PlayingCard(rank: Rank.jack, suit: suit),
      PlayingCard(rank: Rank.queen, suit: suit),
      PlayingCard(rank: Rank.king, suit: suit),
      PlayingCard(rank: Rank.ace, suit: suit),
    ];
    // Keep cards in ascending order - don't shuffle
    return PokerHand(cards: cards, type: HandType.royalFlush);
  }

  static PokerHand _generateStraightFlush() {
    final suit = Suit.values[_random.nextInt(4)];
    
    // Possible starting ranks for straight flush (not royal)
    // Can start from 2 to 9 (not 10 because that would be royal)
    final possibleStarts = [
      Rank.two,
      Rank.three,
      Rank.four,
      Rank.five,
      Rank.six,
      Rank.seven,
      Rank.eight,
      Rank.nine,
    ];
    
    final startRank = possibleStarts[_random.nextInt(possibleStarts.length)];
    final startIndex = startRank.index;
    
    final cards = List.generate(5, (i) {
      return PlayingCard(
        rank: Rank.values[startIndex + i],
        suit: suit,
      );
    });
    
    // Keep cards in ascending order - don't shuffle
    return PokerHand(cards: cards, type: HandType.straightFlush);
  }

  static PokerHand _generateFourOfAKind() {
    // Pick a rank for the four cards
    final fourRank = Rank.values[_random.nextInt(Rank.values.length)];
    
    // Pick a different rank for the fifth card
    Rank fifthRank;
    do {
      fifthRank = Rank.values[_random.nextInt(Rank.values.length)];
    } while (fifthRank == fourRank);
    
    final cards = [
      PlayingCard(rank: fourRank, suit: Suit.clubs),
      PlayingCard(rank: fourRank, suit: Suit.diamonds),
      PlayingCard(rank: fourRank, suit: Suit.hearts),
      PlayingCard(rank: fourRank, suit: Suit.spades),
      PlayingCard(rank: fifthRank, suit: Suit.clubs),
    ];
    
    // Sort by rank, then by suit
    cards.sort((a, b) {
      final rankCompare = a.rank.value.compareTo(b.rank.value);
      if (rankCompare != 0) return rankCompare;
      return a.suit.index.compareTo(b.suit.index);
    });
    
    return PokerHand(cards: cards, type: HandType.fourOfAKind);
  }

  static PokerHand _generateFullHouse() {
    // Pick ranks for three and two
    final threeRank = Rank.values[_random.nextInt(Rank.values.length)];
    Rank twoRank;
    do {
      twoRank = Rank.values[_random.nextInt(Rank.values.length)];
    } while (twoRank == threeRank);
    
    final cards = [
      PlayingCard(rank: threeRank, suit: Suit.clubs),
      PlayingCard(rank: threeRank, suit: Suit.diamonds),
      PlayingCard(rank: threeRank, suit: Suit.hearts),
      PlayingCard(rank: twoRank, suit: Suit.clubs),
      PlayingCard(rank: twoRank, suit: Suit.diamonds),
    ];
    
    // Sort by rank, then by suit
    cards.sort((a, b) {
      final rankCompare = a.rank.value.compareTo(b.rank.value);
      if (rankCompare != 0) return rankCompare;
      return a.suit.index.compareTo(b.suit.index);
    });
    
    return PokerHand(cards: cards, type: HandType.fullHouse);
  }

  static PokerHand _generateFlush() {
    final suit = Suit.values[_random.nextInt(4)];
    
    // Pick 5 different ranks that don't form a straight or royal flush
    final allRanks = Rank.values.toList()..shuffle(_random);
    List<Rank> selectedRanks;
    
    // Keep trying until we get ranks that don't form a straight
    do {
      allRanks.shuffle(_random);
      selectedRanks = allRanks.take(5).toList()..sort((a, b) => a.value.compareTo(b.value));
    } while (_formsStraight(selectedRanks) || _isRoyalRanks(selectedRanks));
    
    final cards = selectedRanks.map((rank) => PlayingCard(rank: rank, suit: suit)).toList();
    // Keep cards sorted in ascending order
    return PokerHand(cards: cards, type: HandType.flush);
  }

  static PokerHand _generateStraight() {
    // Pick a starting rank for the straight
    final possibleStarts = [
      Rank.two,
      Rank.three,
      Rank.four,
      Rank.five,
      Rank.six,
      Rank.seven,
      Rank.eight,
      Rank.nine,
      Rank.ten,
    ];
    
    final startRank = possibleStarts[_random.nextInt(possibleStarts.length)];
    final startIndex = startRank.index;
    
    final ranks = List.generate(5, (i) => Rank.values[startIndex + i]);
    
    // Pick random suits, ensuring they're not all the same (which would be a straight flush)
    final suits = <Suit>[];
    for (int i = 0; i < 5; i++) {
      suits.add(Suit.values[_random.nextInt(4)]);
    }
    
    // Ensure not all suits are the same
    while (suits.toSet().length == 1) {
      suits[_random.nextInt(5)] = Suit.values[_random.nextInt(4)];
    }
    
    final cards = List.generate(5, (i) {
      return PlayingCard(rank: ranks[i], suit: suits[i]);
    });
    
    // Keep cards in ascending order by rank
    return PokerHand(cards: cards, type: HandType.straight);
  }

  static bool _formsStraight(List<Rank> ranks) {
    if (ranks.length != 5) return false;
    
    final sorted = ranks.toList()..sort((a, b) => a.value.compareTo(b.value));
    
    // Check regular straight
    bool isRegular = true;
    for (int i = 0; i < 4; i++) {
      if (sorted[i + 1].value - sorted[i].value != 1) {
        isRegular = false;
        break;
      }
    }
    
    if (isRegular) return true;
    
    // Check for A-2-3-4-5 (wheel)
    if (sorted[0] == Rank.two &&
        sorted[1] == Rank.three &&
        sorted[2] == Rank.four &&
        sorted[3] == Rank.five &&
        sorted[4] == Rank.ace) {
      return true;
    }
    
    return false;
  }

  static bool _isRoyalRanks(List<Rank> ranks) {
    final rankSet = ranks.toSet();
    return rankSet.containsAll([
      Rank.ten,
      Rank.jack,
      Rank.queen,
      Rank.king,
      Rank.ace,
    ]);
  }

  // Get all 52 cards
  static List<PlayingCard> getAllCards() {
    final cards = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(PlayingCard(rank: rank, suit: suit));
      }
    }
    return cards;
  }
}
