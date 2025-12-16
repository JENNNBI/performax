#!/bin/bash

# BULLETPROOF iOS Launch Script
# This script ensures ZERO concurrent builds

set -e

PROJECT_DIR="/Users/renasa/Development/projects/performax"
DEVICE_ID="33955A47-72A1-49A8-9B0E-C71093CD4D58"
APP_BUNDLE_ID="com.example.performax"

echo "🚀 Performax iOS Launch Script"
echo "================================"

# Step 1: Kill EVERYTHING
echo "🔫 Killing all build processes..."
killall -9 xcodebuild 2>/dev/null || true
killall -9 dart 2>/dev/null || true
killall -9 flutter 2>/dev/null || true
killall -9 Xcode 2>/dev/null || true
sleep 5

# Step 2: Verify nothing is running
RUNNING=$(ps aux | grep -E "xcodebuild|flutter run" | grep -v grep | wc -l)
if [ "$RUNNING" -gt 0 ]; then
    echo "❌ ERROR: Processes still running!"
    ps aux | grep -E "xcodebuild|flutter" | grep -v grep
    exit 1
fi
echo "✅ All processes terminated"

# Step 3: Clean everything
echo "🧹 Deep cleaning..."
cd "$PROJECT_DIR"
rm -rf build ios/build ~/Library/Developer/Xcode/DerivedData/Runner-*
flutter clean > /dev/null 2>&1
echo "✅ Clean complete"

# Step 4: Boot simulator if needed
echo "📱 Checking simulator..."
SIM_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted\|Shutdown")
if [ "$SIM_STATE" != "Booted" ]; then
    echo "   Booting iPhone 17 Pro..."
    xcrun simctl boot "$DEVICE_ID"
    sleep 5
fi
open -a Simulator
echo "✅ Simulator ready"

# Step 5: Build using Xcode DIRECTLY (not Flutter)
echo "🔨 Building with Xcode (single-threaded)..."
cd "$PROJECT_DIR/ios"

# Set environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ensure pods are installed
if [ ! -d "Pods" ]; then
    echo "   Installing CocoaPods..."
    pod install
fi

# Build with Xcode CLI - SINGLE JOB ONLY
xcodebuild clean build \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "id=$DEVICE_ID" \
    -jobs 1 \
    BUILD_DIR="$PROJECT_DIR/build/ios" \
    SYMROOT="$PROJECT_DIR/build/ios" \
    OBJROOT="$PROJECT_DIR/build/ios/Intermediates" \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    | grep -E "Build succeeded|error:|warning:|failed"

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build succeeded!"

# Step 6: Install app to simulator
echo "📲 Installing app..."
APP_PATH=$(find "$PROJECT_DIR/build/ios" -name "Runner.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ ERROR: Runner.app not found!"
    exit 1
fi

xcrun simctl install "$DEVICE_ID" "$APP_PATH"
echo "✅ App installed"

# Step 7: Launch app
echo "🚀 Launching app..."
xcrun simctl launch --console "$DEVICE_ID" "$APP_BUNDLE_ID"

echo ""
echo "✅✅✅ SUCCESS! App is running on iPhone 17 Pro"
echo ""
echo "To rebuild, run: ./launch_app.sh"

