import 'storage_service.dart';

/// Single achievement definition and state
class Achievement {
  final String id;
  final String name;
  final String description;
  final String reward; // Exact reward text shown on claim button (e.g. "Freeze x 1")
  final double progress; // 0.0 .. 1.0
  final bool canClaim; // progress >= 1.0
  final bool claimed;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.reward,
    required this.progress,
    required this.canClaim,
    required this.claimed,
  });
}

/// Keys for achievement claimed state (persisted)
const String _prefixClaimed = 'achievement_claimed_';

/// Achievement IDs (must match keys used when marking progress)
const String achFirstGame = 'first_game';
const String achPlayFiveGames = 'play_five_games';
const String achTokenCollector = 'token_collector';
const String achJengaBlocks = 'jenga_blocks';
const String achNumberLinkLevels = 'number_link_levels';
const String achShopBuy = 'shop_buy';
const String achHighScore = 'high_score';

/// Service that provides achievement list and claim. Progress is read from app state / storage.
class AchievementService {
  static String _claimedKey(String id) => '$_prefixClaimed$id';

  static Future<bool> isClaimed(String id) async {
    final s = await StorageService.getInstance();
    return s.getBool(_claimedKey(id)) ?? false;
  }

  static Future<void> setClaimed(String id) async {
    final s = await StorageService.getInstance();
    await s.saveBool(_claimedKey(id), true);
  }

  static const String keyTotalGamesPlayed = 'total_games_played';
  static const String keyJengaBestBlocks = 'jenga_best_blocks';
  static const String keyNumberLinkMaxLevel = 'number_link_max_level';
  static const String keyShopPurchasesCount = 'shop_purchases_count';
  static const String keyHighScore = 'achievement_high_score';

  /// Build list of achievements. Progress read from StorageService and token count.
  static Future<List<Achievement>> getAchievements() async {
    final s = await StorageService.getInstance();
    final games = s.getInt(keyTotalGamesPlayed) ?? 0;
    final tokens = StorageService.tokenCountSync;
    final jenga = s.getInt(keyJengaBestBlocks) ?? s.getInt('jenga_bestScore') ?? 0;
    final nl = s.getInt(keyNumberLinkMaxLevel) ?? s.getInt('numberlink_level') ?? 1;
    final shopCount = s.getInt(keyShopPurchasesCount) ?? 0;
    final score = s.getInt(keyHighScore) ?? jenga;
    final list = <Achievement>[];

    final firstClaimed = await isClaimed(achFirstGame);
    list.add(Achievement(
      id: achFirstGame,
      name: 'First Game',
      description: 'Play your first game',
      reward: '5 Tokens',
      progress: games >= 1 ? 1.0 : games / 1.0,
      canClaim: games >= 1 && !firstClaimed,
      claimed: firstClaimed,
    ));

    final fiveClaimed = await isClaimed(achPlayFiveGames);
    list.add(Achievement(
      id: achPlayFiveGames,
      name: 'Getting Started',
      description: 'Play 5 games',
      reward: 'Reborn x 1',
      progress: (games / 5.0).clamp(0.0, 1.0),
      canClaim: games >= 5 && !fiveClaimed,
      claimed: fiveClaimed,
    ));

    final tokenClaimed = await isClaimed(achTokenCollector);
    list.add(Achievement(
      id: achTokenCollector,
      name: 'Token Collector',
      description: 'Hold 100 Tokens',
      reward: '25 Tokens',
      progress: (tokens / 100.0).clamp(0.0, 1.0),
      canClaim: tokens >= 100 && !tokenClaimed,
      claimed: tokenClaimed,
    ));

    final jengaClaimed = await isClaimed(achJengaBlocks);
    list.add(Achievement(
      id: achJengaBlocks,
      name: 'Jenga Builder',
      description: 'Place 10 blocks in Jenga',
      reward: 'Freeze x 1',
      progress: (jenga / 10.0).clamp(0.0, 1.0),
      canClaim: jenga >= 10 && !jengaClaimed,
      claimed: jengaClaimed,
    ));

    final nlClaimed = await isClaimed(achNumberLinkLevels);
    list.add(Achievement(
      id: achNumberLinkLevels,
      name: 'Number Link Fan',
      description: 'Complete level 5 in Number Link',
      reward: 'Hint x 1',
      progress: (nl / 5.0).clamp(0.0, 1.0),
      canClaim: nl >= 5 && !nlClaimed,
      claimed: nlClaimed,
    ));

    final shopClaimed = await isClaimed(achShopBuy);
    list.add(Achievement(
      id: achShopBuy,
      name: 'Shopper',
      description: 'Make 1 purchase in Shop',
      reward: '10 Tokens',
      progress: shopCount >= 1 ? 1.0 : 0.0,
      canClaim: shopCount >= 1 && !shopClaimed,
      claimed: shopClaimed,
    ));

    final highClaimed = await isClaimed(achHighScore);
    list.add(Achievement(
      id: achHighScore,
      name: 'High Scorer',
      description: 'Reach 500 points in any game',
      reward: 'Reborn x 1',
      progress: (score / 500.0).clamp(0.0, 1.0),
      canClaim: score >= 500 && !highClaimed,
      claimed: highClaimed,
    ));

    return list;
  }
}
