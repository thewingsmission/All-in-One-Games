import 'storage_service.dart';

/// Token pack: tokens amount and price in USD
class TokenPack {
  final int tokens;
  final double usd;
  const TokenPack(this.tokens, this.usd);
}

/// Global token pack offerings (menu shop and in-game shop)
class TokenService {
  static final List<TokenPack> tokenPacks = const [
    TokenPack(10, 1),
    TokenPack(25, 2),
    TokenPack(75, 5),
    TokenPack(200, 10),
    TokenPack(1500, 500),
    TokenPack(4000, 1000),
  ];

  static int getTokenCount() => StorageService.tokenCountSync;

  static Future<bool> setTokenCount(int value) async {
    final svc = await StorageService.getInstance();
    return svc.saveInt(StorageService.tokenKey, value);
  }

  static Future<bool> addTokens(int delta) async {
    return setTokenCount(StorageService.tokenCountSync + delta);
  }

  static Future<bool> spendTokens(int amount) async {
    if (StorageService.tokenCountSync < amount) return false;
    return setTokenCount(StorageService.tokenCountSync - amount);
  }

  static bool canAfford(int amount) => getTokenCount() >= amount;
}
