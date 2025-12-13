#!/bin/bash
# iOS Clean Build Script - Prevents concurrent build errors

set -e

echo "🧹 Cleaning iOS build environment..."

# Kill any running Xcode processes (more aggressive)
echo "Killing Xcode processes..."
pkill -9 -f Xcode 2>/dev/null || true
pkill -9 -f xcodebuild 2>/dev/null || true
pkill -9 -f com.apple.CoreSimulator 2>/dev/null || true
pkill -9 -f Simulator 2>/dev/null || true
pkill -9 -f "CoreSimulatorService" 2>/dev/null || true

# Wait for processes to terminate
echo "Waiting for processes to terminate..."
sleep 3

# Kill any processes locking DerivedData
echo "Killing processes locking DerivedData..."
lsof +D ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | xargs kill -9 2>/dev/null || true

# Clean DerivedData
echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

# Remove lock files
echo "Removing lock files..."
find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true

# Clean Flutter build
echo "Cleaning Flutter build..."
cd "$(dirname "$0")/.."
flutter clean

# Clean iOS specific build artifacts
echo "Cleaning iOS build artifacts..."
cd ios
rm -rf build Pods/.symlinks Pods/Target\ Support\ Files .symlinks 2>/dev/null || true
rm -rf Podfile.lock 2>/dev/null || true

# Clean Flutter iOS build directory
cd ..
rm -rf build/ios .dart_tool/build .flutter-plugins-dependencies 2>/dev/null || true

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Install pods
echo "Installing CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod install

echo ""
echo "✅ Clean build environment ready!"
echo "✅ No processes running: $(ps aux | grep -E '(Xcode|xcodebuild|simulator)' | grep -v grep | wc -l | tr -d ' ') processes found"
echo ""
echo "You can now run: flutter run -d 'iPhone 17 Pro'"
