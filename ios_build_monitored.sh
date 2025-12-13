#!/bin/bash

# iOS Build Monitor Script
# Monitors build process and switches to alternative troubleshooting if Build status not achieved within 20 seconds

set -e

PROJECT_DIR="/Users/renasa/Development/projects/performax"
DEVICE="iPhone 17 Pro"
BUILD_TIMEOUT=20  # seconds after CocoaPods load
COCOAPODS_LOADED=false
BUILD_STATUS_ACHIEVED=false

echo "🚀 iOS Build Monitor - iPhone 17 Pro"
echo "====================================="
echo ""

# Navigate to project
cd "$PROJECT_DIR"

# Kill any existing builds
echo "🧹 Cleaning up existing processes..."
killall -9 xcodebuild 2>/dev/null || true
killall -9 dart 2>/dev/null || true
pkill -9 -f "flutter run" 2>/dev/null || true
pkill -9 -f "flutter build" 2>/dev/null || true
sleep 2

# Ensure CocoaPods dependencies are loaded
echo "📦 Checking CocoaPods dependencies..."
if [ ! -d "ios/Pods" ] || [ ! -f "ios/Podfile.lock" ]; then
    echo "   Installing CocoaPods dependencies..."
    cd ios
    pod install
    cd ..
    COCOAPODS_LOADED=true
    echo "   ✅ CocoaPods dependencies loaded"
else
    echo "   ✅ CocoaPods dependencies already present"
    COCOAPODS_LOADED=true
fi

# Start build process in background and monitor output
echo ""
echo "🔨 Initiating build process..."
echo "   Monitoring for Build status (timeout: ${BUILD_TIMEOUT}s after CocoaPods load)"
echo ""

# Create a temporary log file
LOG_FILE="/tmp/performax_build_monitor.log"
rm -f "$LOG_FILE"

# Start Flutter build with verbose output
(
    cd "$PROJECT_DIR"
    flutter run -d "$DEVICE" --verbose 2>&1 | tee "$LOG_FILE"
) &
BUILD_PID=$!

# Monitor for Build status
START_TIME=$(date +%s)
COCOAPODS_TIME=$START_TIME
TIMEOUT_REACHED=false

echo "   Build PID: $BUILD_PID"
echo "   Monitoring started at $(date)"
echo ""

# Monitor log file for key indicators
while kill -0 $BUILD_PID 2>/dev/null; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    # Check if CocoaPods have finished loading
    if [ "$COCOAPODS_LOADED" = true ] && [ -z "$COCOAPODS_FINISHED_TIME" ]; then
        if grep -q "Running pod install\|CocoaPods dependencies installed\|Pod installation complete" "$LOG_FILE" 2>/dev/null; then
            COCOAPODS_FINISHED_TIME=$(date +%s)
            echo "   ✅ CocoaPods dependencies loaded at $(date)"
            echo "   ⏱️  Starting ${BUILD_TIMEOUT}s timer for Build status..."
        fi
    fi
    
    # Check for Build status
    if grep -q "Building\|Build succeeded\|BUILD SUCCEEDED\|Compiling\|Building iOS app" "$LOG_FILE" 2>/dev/null; then
        BUILD_STATUS_ACHIEVED=true
        echo "   ✅ Build status achieved!"
        break
    fi
    
    # Check timeout after CocoaPods load
    if [ -n "$COCOAPODS_FINISHED_TIME" ]; then
        TIME_SINCE_COCOAPODS=$((CURRENT_TIME - COCOAPODS_FINISHED_TIME))
        if [ $TIME_SINCE_COCOAPODS -ge $BUILD_TIMEOUT ]; then
            TIMEOUT_REACHED=true
            echo ""
            echo "   ⚠️  TIMEOUT: Build status not achieved within ${BUILD_TIMEOUT}s"
            echo "   🛑 Halting current process..."
            kill -9 $BUILD_PID 2>/dev/null || true
            break
        fi
    fi
    
    sleep 1
done

# Wait for process to fully terminate
wait $BUILD_PID 2>/dev/null || true

# Decision point: Switch to alternative troubleshooting if timeout reached
if [ "$TIMEOUT_REACHED" = true ]; then
    echo ""
    echo "🔄 Switching to alternative troubleshooting methodology..."
    echo ""
    
    # Alternative troubleshooting approach
    echo "📋 Alternative Troubleshooting Steps:"
    echo "   1. Checking Xcode project configuration..."
    echo "   2. Verifying simulator compatibility..."
    echo "   3. Checking for build configuration issues..."
    echo ""
    
    # Check Xcode project settings
    echo "🔍 Step 1: Xcode Project Configuration"
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        echo "   ✅ Xcode project found"
        # Check for common issues
        if grep -q "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj; then
            DEPLOYMENT_TARGET=$(grep -A 1 "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | head -1 | grep -oE "[0-9]+\.[0-9]+" | head -1)
            echo "   📱 Deployment Target: iOS $DEPLOYMENT_TARGET"
        fi
    fi
    
    # Check simulator status
    echo ""
    echo "🔍 Step 2: Simulator Status"
    SIMULATOR_STATUS=$(xcrun simctl list devices | grep "iPhone 17 Pro" | head -1)
    if echo "$SIMULATOR_STATUS" | grep -q "Booted"; then
        echo "   ✅ Simulator is booted"
    else
        echo "   ⚠️  Simulator may not be booted"
        echo "   🔄 Attempting to boot simulator..."
        xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
        sleep 3
    fi
    
    # Check for common build issues
    echo ""
    echo "🔍 Step 3: Build Configuration Check"
    
    # Check Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        echo "   ✅ Info.plist found"
        if grep -q "MinimumOSVersion" ios/Runner/Info.plist; then
            MIN_VERSION=$(grep -A 1 "MinimumOSVersion" ios/Runner/Info.plist | tail -1 | grep -oE "[0-9]+\.[0-9]+" | head -1)
            echo "   📱 Minimum OS Version: iOS $MIN_VERSION"
        fi
    fi
    
    # Check Podfile
    if [ -f "ios/Podfile" ]; then
        PODFILE_PLATFORM=$(grep "platform :ios" ios/Podfile | grep -oE "[0-9]+\.[0-9]+" | head -1)
        echo "   📦 Podfile platform: iOS $PODFILE_PLATFORM"
    fi
    
    # Try alternative build approach
    echo ""
    echo "🔧 Step 4: Attempting Alternative Build Method"
    echo "   Using flutter build ios --simulator --debug..."
    
    cd "$PROJECT_DIR"
    flutter build ios --simulator --debug --verbose 2>&1 | head -50
    
    echo ""
    echo "📊 Build log saved to: $LOG_FILE"
    echo "   Review the log for specific error messages"
    
else
    if [ "$BUILD_STATUS_ACHIEVED" = true ]; then
        echo ""
        echo "✅ Build process initiated successfully!"
        echo "   Build status achieved within timeout period"
    else
        echo ""
        echo "⚠️  Build process completed but status unclear"
        echo "   Review log: $LOG_FILE"
    fi
fi

echo ""
echo "🏁 Troubleshooting session complete"

