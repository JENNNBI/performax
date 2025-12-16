#!/bin/bash
# Comprehensive iOS Launch Fix

set -e

echo "🔧 Fixing iOS Launch Issues"
echo "============================"
echo ""

cd "$(dirname "$0")"

# Step 1: Ensure Generated.xcconfig exists
echo "1. Ensuring Generated.xcconfig exists..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "   📦 Running flutter pub get..."
    flutter pub get
fi
echo "   ✅ Generated.xcconfig ready"

# Step 2: Clean and reinstall pods
echo ""
echo "2. Reinstalling CocoaPods dependencies..."
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
echo "   ✅ Pods reinstalled"

# Step 3: Clean Flutter build
echo ""
echo "3. Cleaning Flutter build..."
flutter clean
flutter pub get
echo "   ✅ Build cleaned"

# Step 4: Boot simulator if not running
echo ""
echo "4. Checking iPhone 17 Pro simulator..."
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | head -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "   ❌ iPhone 17 Pro simulator not found"
    echo "   Available simulators:"
    xcrun simctl list devices available | grep "iPhone"
    exit 1
fi

echo "   ✅ Found simulator: $SIMULATOR_ID"

# Check boot status
BOOT_STATUS=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -i "booted")
if [ -z "$BOOT_STATUS" ]; then
    echo "   📱 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    sleep 2
    open -a Simulator || true
    sleep 3
fi
echo "   ✅ Simulator ready"

# Step 5: Uninstall old app if exists
echo ""
echo "5. Cleaning up old app installation..."
xcrun simctl uninstall "$SIMULATOR_ID" com.performax.performax 2>/dev/null || echo "   ℹ️  No existing app to uninstall"
echo "   ✅ Cleanup complete"

# Step 6: Build and run
echo ""
echo "6. Building and launching app..."
echo "   This may take a few minutes..."
echo ""

flutter run -d "$SIMULATOR_ID" --verbose

echo ""
echo "✅ Launch sequence complete!"

