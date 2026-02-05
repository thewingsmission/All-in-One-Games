# Testing Guide - All-in-One Games Mobile App

## 📱 Available Testing Options

### ✅ Option 1: Physical iPhone (RECOMMENDED - Currently Running)
**Your iPhone: "Kai Yan's iPhone" (iOS 26.2)**
- Device ID: `00008120-000431202E88C01E`
- **Status: App is deploying now!**
- **Best option** - Real device experience, fastest testing

**Command:**
```bash
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
flutter run -d 00008120-000431202E88C01E
```

### ✅ Option 2: iOS Simulator
**Launch simulator then run app:**
```bash
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
open -a Simulator
# Wait for simulator to fully boot (look for iPhone home screen)
flutter run
```

**Or launch specific simulator:**
```bash
flutter emulators --launch apple_ios_simulator
flutter run
```

### ✅ Option 3: Chrome Web Browser (FASTEST for quick tests)
```bash
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
flutter run -d chrome
```

### ✅ Option 4: Android Emulator
```bash
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
flutter emulators --launch Pixel_3a_API_34_extension_level_7_arm64-v8a
flutter run
```

### ✅ Option 5: macOS Desktop App
```bash
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
flutter run -d macos
```

---

## 🎮 What to Test

### 1. App Launch
- ✅ Splash screen animation (3 seconds)
- ✅ Smooth transition to main menu

### 2. Main Menu (Home Screen)
- ✅ 6 game icon buttons visible
- ✅ Icons load correctly (check Downstairs icon especially)
- ✅ Light blue header section
- ✅ Tap each game button
- ✅ Settings button in app bar works

### 3. Game Menu Screens (for each game)
- ✅ Game icon and description display
- ✅ Leaderboard section shows
- ✅ Toggle between "All-Time" and "Weekly"
- ✅ Top 3 placeholder entries visible with medals
- ✅ Game rules text readable
- ✅ Difficulty selection (for games with levels)
- ✅ Start Game button prominent
- ✅ Back navigation works

### 4. Visual Style (Number Link Inspired)
- ✅ Clean white background
- ✅ Blue color scheme
- ✅ Card-based layouts with elevation
- ✅ Light blue accent sections
- ✅ Smooth rounded corners
- ✅ Professional typography

### 5. Portrait Orientation
- ✅ App locked to portrait only
- ✅ Rotating device doesn't change orientation

---

## 🔥 Hot Reload Commands

While app is running, you can use these keyboard shortcuts:

- `r` - Hot reload (instant updates for UI changes)
- `R` - Hot restart (full app restart)
- `h` - Show all commands
- `q` - Quit app
- `c` - Clear console

---

## 🐛 Troubleshooting

### iOS Simulator won't boot
```bash
# Force quit and restart
pkill -9 Simulator
open -a Simulator
```

### App won't install on physical iPhone
Check if Developer Mode is enabled:
- Settings > Privacy & Security > Developer Mode > ON
- Device may need to restart after enabling

### "Untrusted Developer" message
- Settings > General > VPN & Device Management
- Trust your developer certificate

### Build fails
```bash
# Clean and rebuild
cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"
flutter clean
flutter pub get
flutter run
```

---

## 📊 Current Status

### ✅ Completed
- App infrastructure
- Navigation system
- All 6 game menu screens
- Leaderboard UI
- Settings screen
- Asset migration
- Downstairs icon fixed
- Number Link style applied

### ⏳ Pending
- Actual game implementations (6 games)
- Real leaderboard data
- Sound effects
- Game-specific features

---

## 🎯 Next Testing Phase

Once you confirm the current app looks good:
1. I'll migrate the actual game code (starting with simpler games)
2. Wire up "Start Game" buttons to real games
3. Test gameplay on device
4. Polish and optimize

---

**Your app is deploying to your iPhone now! Check your phone in about 1-2 minutes.** 📱✨
