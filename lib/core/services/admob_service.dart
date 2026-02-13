import 'dart:io';

class AdMobService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Replace with your real Android Banner Ad Unit ID for production
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your real iOS Banner Ad Unit ID for production
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Replace with your real Android Interstitial Ad Unit ID
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your real iOS Interstitial Ad Unit ID
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // TODO: Replace with your real Android Rewarded Ad Unit ID
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      // TODO: Replace with your real iOS Rewarded Ad Unit ID
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }
}
