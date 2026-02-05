#!/bin/bash
# Run this script to fix CocoaPods and launch app

echo "🔧 Fixing Ruby gems..."
sudo gem pristine ffi --version 1.15.5
sudo gem pristine json --version 1.8.6

echo "✅ Gems fixed! Now running app..."

cd "/Users/leekaiyan/Desktop/Flutter Projects/All‑in‑One Games - Play & Win"

# Clean and rebuild
flutter clean
flutter pub get

# Open simulator
open -a Simulator

echo "⏳ Waiting for simulator to boot..."
sleep 15

# Run app
flutter run
