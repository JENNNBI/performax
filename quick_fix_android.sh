#!/bin/bash

# Quick Fix for Android Launch Issue
# Tries the most common solutions automatically

echo "=========================================="
echo "Android Launch - Quick Fix Script"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/renasa/Development/projects/performax"
DEVICE="emulator-5554"

cd "$PROJECT_ROOT"

echo "🔍 Detecting issue..."
echo ""

# Check if emulator is running
if ! adb devices | grep -q "$DEVICE"; then
    echo "❌ Emulator not running!"
    echo "Please start Android emulator first:"
    echo "   flutter emulators --launch <emulator_name>"
    exit 1
fi

echo "✅ Emulator is running"
echo ""

echo "Step 1: Uninstalling existing app..."
adb -s "$DEVICE" uninstall com.example.performax 2>/dev/null
echo "✅ App uninstalled (if it existed)"
echo ""

echo "Step 2: Cleaning project..."
flutter clean > /dev/null 2>&1
echo "✅ Project cleaned"
echo ""

echo "Step 3: Getting packages..."
flutter pub get > /dev/null 2>&1
echo "✅ Packages fetched"
echo ""

echo "Step 4: Granting permissions preemptively..."
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.CAMERA 2>/dev/null
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.READ_SMS 2>/dev/null
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.RECEIVE_SMS 2>/dev/null
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.READ_PHONE_STATE 2>/dev/null
echo "✅ Permissions granted (will apply after install)"
echo ""

echo "Step 5: Building app..."
if flutter build apk --debug > /dev/null 2>&1; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    echo ""
    echo "Running build again with output:"
    flutter build apk --debug
    exit 1
fi
echo ""

echo "Step 6: Installing app..."
if adb -s "$DEVICE" install build/app/outputs/flutter-apk/app-debug.apk 2>&1 | grep -q "Success"; then
    echo "✅ App installed successfully!"
else
    echo "⚠️  Installation had warnings or failed"
    adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
fi
echo ""

echo "Step 7: Granting permissions after install..."
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.CAMERA
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.READ_SMS
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.RECEIVE_SMS
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.READ_PHONE_STATE
adb -s "$DEVICE" shell pm grant com.example.performax android.permission.READ_PHONE_NUMBERS
echo "✅ Permissions granted"
echo ""

echo "Step 8: Launching app..."
adb -s "$DEVICE" shell am start -n com.example.performax/.MainActivity
echo ""

echo "Step 9: Monitoring for crashes (10 seconds)..."
echo "If you see errors below, app crashed:"
echo "----------------------------------------"
adb -s "$DEVICE" logcat -c  # Clear log
sleep 2  # Wait for app to start

# Monitor for 8 seconds
(adb -s "$DEVICE" logcat & echo $! > /tmp/logcat.pid) | grep --line-buffered -E "AndroidRuntime|FATAL|performax|flutter" &
LOGCAT_PID=$!

sleep 8
kill $LOGCAT_PID 2>/dev/null
echo "----------------------------------------"
echo ""

echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Check your emulator. The app should be running."
echo ""
echo "If app crashed or didn't launch:"
echo "1. Check errors above"
echo "2. Run: adb -s $DEVICE logcat | grep flutter"
echo "3. See ANDROID_LAUNCH_FIX.md for more solutions"
echo ""

