#!/bin/bash
# iOS Launch Diagnostic Script

echo "🔍 iOS Launch Diagnostics"
echo "=========================="
echo ""

# Check simulator status
echo "1. Checking simulator status..."
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 17 Pro" | grep -oE '[A-F0-9-]{36}' | head -1)
if [ -n "$SIMULATOR_ID" ]; then
    BOOT_STATUS=$(xcrun simctl list devices | grep "iPhone 17 Pro" | grep -i "booted")
    if [ -n "$BOOT_STATUS" ]; then
        echo "   ✅ Simulator is booted: $SIMULATOR_ID"
    else
        echo "   ⚠️  Simulator is shut down"
        echo "   📱 Booting simulator..."
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
        open -a Simulator 2>/dev/null || true
        sleep 5
    fi
else
    echo "   ❌ Could not find iPhone 17 Pro simulator"
fi

echo ""

# Check if app is installed
echo "2. Checking if app is installed..."
APP_INSTALLED=$(xcrun simctl listapps booted | grep "com.performax.performax")
if [ -n "$APP_INSTALLED" ]; then
    echo "   ✅ App is installed"
else
    echo "   ⚠️  App is not installed"
fi

echo ""

# Check for running processes
echo "3. Checking for build processes..."
XCODE_PROCESSES=$(ps aux | grep -E "(xcodebuild|Xcode)" | grep -v grep | wc -l | tr -d ' ')
if [ "$XCODE_PROCESSES" -gt 0 ]; then
    echo "   ⚠️  $XCODE_PROCESSES build process(es) running"
    echo "   💡 A build may be in progress. Wait for it to complete."
else
    echo "   ✅ No build processes running"
fi

echo ""

# Check Flutter devices
echo "4. Checking Flutter devices..."
flutter devices 2>&1 | grep -i "iPhone 17 Pro" && echo "   ✅ Flutter can see the device" || echo "   ⚠️  Flutter cannot see the device"

echo ""

# Check for crash logs
echo "5. Checking for recent crash logs..."
CRASHES=$(xcrun simctl spawn booted log show --predicate 'processImagePath contains "Runner" AND eventType == "logEvent" AND messageType == "Error"' --last 1m 2>/dev/null | wc -l | tr -d ' ')
if [ "$CRASHES" -gt 0 ]; then
    echo "   ⚠️  Found crash logs. Recent errors:"
    xcrun simctl spawn booted log show --predicate 'processImagePath contains "Runner" AND eventType == "logEvent" AND messageType == "Error"' --last 1m 2>/dev/null | tail -5
else
    echo "   ✅ No recent crash logs found"
fi

echo ""

# Try to launch app manually
echo "6. Attempting to launch app..."
xcrun simctl launch booted com.performax.performax 2>&1 | head -3

echo ""
echo "✅ Diagnostics complete!"
echo ""
echo "💡 To build and run:"
echo "   ./flutter_run_ios.sh \"iPhone 17 Pro\""
echo ""
echo "💡 To see detailed logs:"
echo "   flutter run -d \"iPhone 17 Pro\" --verbose"

