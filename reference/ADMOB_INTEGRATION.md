# AdMob integration for All-in-One Games

To use Google AdMob in this Flutter app, do the following.

## 1. Add the dependency

In **`pubspec.yaml`** under `dependencies:` add:

```yaml
google_mobile_ads: ^5.2.0   # or latest compatible version
```

Then run:

```bash
flutter pub get
```

## 2. Get AdMob IDs

1. Sign in at [AdMob](https://admob.google.com/).
2. Create an app (or use an existing one) and get:
   - **App ID** (one per platform: Android and iOS).
   - **Ad unit IDs** for the ad types you want (e.g. Banner, Interstitial, Rewarded).

Use **test IDs** during development so you don’t risk policy issues:

- Android banner: `ca-app-pub-3940256099942544/6300978111`
- iOS banner: `ca-app-pub-3940256099942544/2934735716`
- Android app ID (test): `ca-app-pub-3940256099942544~3347511713`
- iOS app ID (test): `ca-app-pub-3940256099942544~1458002511`

Replace with your real App ID and ad unit IDs before release.

## 3. Android setup

1. **`android/app/src/main/AndroidManifest.xml`**  
   Inside `<application>`, add your Android App ID:

   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
   ```

   Use the test value above for development.

2. **`android/app/build.gradle.kts`**  
   Ensure `minSdkVersion` is at least **21** (required by the plugin).  
   The plugin will add the necessary dependencies; no extra Gradle config is usually needed.

## 4. iOS setup

1. **`ios/Runner/Info.plist`**  
   Add your iOS App ID (use the test value for development):

   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-3940256099942544~1458002511</string>
   ```

2. **App Tracking Transparency (optional but recommended)**  
   If you use personalized ads or track users, add the usage description:

   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>This identifier will be used to deliver personalized ads to you.</string>
   ```

3. Run **`pod install`** in the `ios/` directory after adding the dependency.

## 5. Initialize in the app

In **`lib/main.dart`** (or your app’s entry point), initialize the Mobile Ads SDK **before** `runApp`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}
```

If you already have other async initialization (e.g. Firebase), call `MobileAds.instance.initialize()` in that same `main()` after `ensureInitialized()`.

## 6. Show ads

### Banner

- Create a `BannerAd` with your ad unit ID, load it, then put an `AdWidget(ad: myBannerAd)` in your layout (e.g. at bottom of the screen).
- Load in `initState` (or when the screen appears) and dispose in `dispose`.

### Interstitial

- Create an `InterstitialAd.load(...)` with your interstitial ad unit ID.
- When the ad is loaded, call `interstitialAd.show()` at the right time (e.g. after a game ends or when leaving a screen).
- Dispose after showing.

### Rewarded

- Use `RewardedAd.load(...)` and show when the user chooses to watch an ad for a reward (e.g. extra hints or tokens).
- Implement `FullScreenContentCallback` to grant the reward and dispose the ad.

## 7. Checklist

- [ ] Add `google_mobile_ads` in `pubspec.yaml` and run `flutter pub get`.
- [ ] Add Android App ID in `AndroidManifest.xml`.
- [ ] Add iOS App ID (and optional tracking description) in `Info.plist`.
- [ ] Call `MobileAds.instance.initialize()` in `main()` before `runApp`.
- [ ] Use test App IDs and test ad unit IDs during development.
- [ ] Replace with real App ID and ad unit IDs for release.
- [ ] Follow [AdMob policy](https://support.google.com/admob/answer/6128543) and [Flutter plugin docs](https://pub.dev/packages/google_mobile_ads).
