#!/bin/bash

# Android Launch Issue - Diagnostic & Fix Script
# This script diagnoses why the app won't launch on Android

echo "=========================================="
echo "Android Launch Issue - Diagnostic Tool"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/renasa/Development/projects/performax"
cd "$PROJECT_ROOT"

echo "Step 1: Checking Flutter doctor..."
flutter doctor -v | grep -A 5 "Android"
echo ""

echo "Step 2: Listing available devices..."
flutter devices
echo ""

echo "Step 3: Checking Android emulators..."
emulator -list-avds
echo ""

echo "Step 4: Checking if app is already installed..."
adb -s emulator-5554 shell pm list packages | grep performax
echo ""

echo "Step 5: Checking logcat for errors..."
echo "If app crashes, errors will appear below:"
adb -s emulator-5554 logcat -c  # Clear logcat
echo "Logcat cleared, ready for fresh logs"
echo ""

echo "Step 6: Attempting to build APK..."
flutter build apk --debug
BUILD_STATUS=$?
echo ""

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "Step 7: Installing APK manually..."
    adb -s emulator-5554 install build/app/outputs/flutter-apk/app-debug.apk
    echo ""
    
    echo "Step 8: Launching app..."
    adb -s emulator-5554 shell am start -n com.example.performax/.MainActivity
    echo ""
    
    echo "Step 9: Monitoring logcat for crashes..."
    echo "Press Ctrl+C to stop monitoring"
    adb -s emulator-5554 logcat | grep -E "AndroidRuntime|flutter|performax|FATAL"
else
    echo "❌ Build failed!"
    echo "Check the errors above"
fi

echo ""
echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="

