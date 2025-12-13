#!/bin/bash
# Final iOS Run Script - Prevents ALL concurrent build issues

set -e

LOCK_FILE="/tmp/flutter_ios_build.lock"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
    # Don't kill processes here - let Flutter handle its own cleanup
}

trap cleanup EXIT INT TERM

echo "🚀 Flutter iOS Run Script"
echo "========================="
echo ""

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && ps -p "$LOCK_PID" > /dev/null 2>&1; then
        echo "❌ ERROR: Another build is already running (PID: $LOCK_PID)"
        echo "💡 Wait for it to finish or kill it: kill $LOCK_PID"
        exit 1
    else
        echo "🧹 Removing stale lock file..."
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Step 1: Kill ALL Flutter and Xcode processes
echo "1️⃣  Stopping all Flutter and Xcode processes..."
pkill -9 -f "flutter run" 2>/dev/null || true
pkill -9 -f "flutter.*ios" 2>/dev/null || true
pkill -9 -f "xcodebuild.*Runner" 2>/dev/null || true
pkill -9 -f Xcode.app 2>/dev/null || true

# Wait for processes to die
sleep 5

# Step 2: Clean DerivedData
echo "2️⃣  Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true
sleep 2

# Step 3: Clean Flutter build
echo "3️⃣  Cleaning Flutter build..."
cd "$SCRIPT_DIR"
flutter clean > /dev/null 2>&1 || true
rm -rf build/ios .dart_tool/build 2>/dev/null || true

# Step 4: Boot simulator
echo "4️⃣  Booting simulator..."
DEVICE="${1:-iPhone 17 Pro}"
SIMULATOR_ID=$(xcrun simctl list devices | grep "$DEVICE" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ Could not find simulator: $DEVICE"
    exit 1
fi

BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
if [ -z "$BOOT_STATUS" ]; then
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    open -a Simulator 2>/dev/null || true
    sleep 8
fi

# Step 5: Get dependencies
echo "5️⃣  Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Step 6: Install pods
echo "6️⃣  Installing CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod install > /dev/null 2>&1 || true
cd ..

echo ""
echo "✅ Pre-build complete!"
echo "🚀 Starting Flutter app..."
echo ""

# Step 7: Run Flutter (this will start xcodebuild, which is expected)
exec flutter run -d "$SIMULATOR_ID"

