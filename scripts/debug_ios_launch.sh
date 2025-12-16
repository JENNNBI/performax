#!/bin/bash
# Debug iOS Launch Issues

echo "🔍 Debugging iOS Launch Issues"
echo "==============================="
echo ""

cd "$(dirname "$0")"

# 1. Check simulator status
echo "1. Checking iPhone 17 Pro simulator status..."
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "   ❌ iPhone 17 Pro simulator not found in available devices"
    echo "   Available simulators:"
    xcrun simctl list devices available | grep "iPhone" | head -5
    exit 1
fi

echo "   ✅ Found simulator: $SIMULATOR_ID"

# Check if booted
BOOTED=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -i "booted")
if [ -z "$BOOTED" ]; then
    echo "   ⚠️  Simulator is not booted"
    echo "   📱 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null
    open -a Simulator
    sleep 3
else
    echo "   ✅ Simulator is booted"
fi

echo ""

# 2. Check if app is installed
echo "2. Checking if app is installed..."
APP_INSTALLED=$(xcrun simctl listapps "$SIMULATOR_ID" | grep "com.performax.performax")
if [ -n "$APP_INSTALLED" ]; then
    echo "   ✅ App is installed"
else
    echo "   ⚠️  App is not installed"
fi

echo ""

# 3. Check Generated.xcconfig
echo "3. Checking Generated.xcconfig..."
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "   ✅ Generated.xcconfig exists"
else
    echo "   ❌ Generated.xcconfig missing - regenerating..."
    flutter pub get
fi

echo ""

# 4. Try to launch app
echo "4. Attempting to launch app..."
flutter run -d "$SIMULATOR_ID" --verbose 2>&1 | tee /tmp/flutter_launch.log

echo ""
echo "✅ Debug complete. Check /tmp/flutter_launch.log for details"

