#!/bin/bash

# AAPT2 Build Error - Automated Fix Script
# This script cleans all caches and rebuilds the project

echo "=========================================="
echo "AAPT2 Daemon Failure - Automated Fix"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/renasa/Development/projects/performax"
cd "$PROJECT_ROOT"

echo "Step 1: Stopping Flutter processes..."
pkill -f flutter || true
echo "✅ Flutter processes stopped"
echo ""

echo "Step 2: Killing Gradle daemons..."
pkill -f gradle || true
pkill -f java || true
echo "✅ Gradle daemons killed"
echo ""

echo "Step 3: Cleaning Flutter cache..."
flutter clean
echo "✅ Flutter cache cleaned"
echo ""

echo "Step 4: Removing Android build directories..."
rm -rf android/.gradle
rm -rf android/app/build
rm -rf android/build
rm -rf .dart_tool
rm -rf build
echo "✅ Android build directories removed"
echo ""

echo "Step 5: Clearing Gradle user cache..."
rm -rf ~/.gradle/caches/
rm -rf ~/.gradle/daemon/
echo "✅ Gradle cache cleared"
echo ""

echo "Step 6: Getting Flutter packages..."
flutter pub get
echo "✅ Packages fetched"
echo ""

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Now run: flutter run"
echo ""
echo "If error persists, try:"
echo "1. Restart your computer"
echo "2. Reinstall Flutter SDK"
echo "3. Check Android SDK installation"
echo ""

