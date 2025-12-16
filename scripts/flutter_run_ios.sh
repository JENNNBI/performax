#!/bin/bash
# Flutter iOS Run Script - Prevents concurrent builds automatically

set -e

echo "🚀 Flutter iOS Run Script"
echo "========================="
echo ""

# Function to kill all Xcode processes (AGGRESSIVE)
kill_xcode_processes() {
    echo "🔪 Aggressively killing ALL Xcode processes..."
    
    # Kill all Xcode-related processes multiple times
    for i in {1..3}; do
        pkill -9 -f Xcode 2>/dev/null || true
        pkill -9 -f xcodebuild 2>/dev/null || true
        pkill -9 -f com.apple.CoreSimulator 2>/dev/null || true
        pkill -9 -f Simulator 2>/dev/null || true
        pkill -9 -f "CoreSimulatorService" 2>/dev/null || true
        pkill -9 -f "com.apple.dt.SKAgent" 2>/dev/null || true
        pkill -9 -f "com.apple.dt.Xcode" 2>/dev/null || true
        sleep 1
    done
    
    # Kill processes locking DerivedData
    lsof +D ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | xargs kill -9 2>/dev/null || true
    
    # Wait and verify
    sleep 3
    REMAINING=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')
    if [ "$REMAINING" -gt 0 ]; then
        echo "⚠️  Warning: $REMAINING process(es) still running, killing again..."
        pkill -9 -f Xcode 2>/dev/null || true
        pkill -9 -f xcodebuild 2>/dev/null || true
        sleep 2
    fi
    
    echo "✅ Processes killed"
}

# Function to clean build artifacts (AGGRESSIVE)
clean_build_artifacts() {
    echo "🧹 Aggressively cleaning build artifacts..."
    
    # Clean ALL DerivedData (not just Runner-*)
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
    
    # Remove ALL lock files
    find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
    find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true
    
    # Clean Flutter build
    flutter clean > /dev/null 2>&1 || true
    
    # Clean iOS build artifacts
    cd ios
    rm -rf build Pods/.symlinks Pods/Target\ Support\ Files .symlinks 2>/dev/null || true
    cd ..
    rm -rf build/ios .dart_tool/build .flutter-plugins-dependencies 2>/dev/null || true
    
    # Wait a moment for file system to sync
    sleep 1
    
    echo "✅ Build artifacts cleaned"
}

# Check for running processes (AGGRESSIVE CHECK)
XCODE_PROCESSES=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')

if [ "$XCODE_PROCESSES" -gt 0 ]; then
    echo "⚠️  Warning: $XCODE_PROCESSES Xcode/xcodebuild process(es) detected!"
    echo "🔪 Aggressively killing ALL processes to prevent concurrent builds..."
    kill_xcode_processes
    
    # Double-check
    sleep 2
    XCODE_PROCESSES=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')
    if [ "$XCODE_PROCESSES" -gt 0 ]; then
        echo "⚠️  CRITICAL: $XCODE_PROCESSES process(es) still running!"
        echo "💡 Run './kill_all_builds.sh' manually, then try again"
        exit 1
    fi
fi

# Check for lock files
LOCK_FILES=$(find ~/Library/Developer/Xcode/DerivedData -name "*.lock" 2>/dev/null | wc -l | tr -d ' ')

if [ "$LOCK_FILES" -gt 0 ]; then
    echo "⚠️  Warning: $LOCK_FILES lock file(s) found"
    echo "🧹 Cleaning build artifacts..."
    clean_build_artifacts
fi

# Get device from argument or use default
DEVICE="${1:-iPhone 17 Pro}"

echo ""
echo "📱 Building for device: $DEVICE"
echo ""

# Ensure we're in the project directory
cd "$(dirname "$0")"

# Boot simulator if it's not running
echo "🔍 Checking simulator status..."
SIMULATOR_ID=$(xcrun simctl list devices | grep "$DEVICE" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -n "$SIMULATOR_ID" ]; then
    BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
    
    if [ -z "$BOOT_STATUS" ]; then
        echo "📱 Simulator is shut down. Booting..."
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
        open -a Simulator 2>/dev/null || true
        echo "⏳ Waiting for simulator to boot (this may take 10-15 seconds)..."
        
        # Wait longer and check multiple times
        for i in {1..6}; do
            sleep 3
            BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
            if [ -n "$BOOT_STATUS" ]; then
                echo "✅ Simulator booted successfully"
                break
            fi
            echo "   Still booting... ($i/6)"
        done
        
        # Final check
        BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
        if [ -z "$BOOT_STATUS" ]; then
            echo "⚠️  Simulator may still be booting. Will continue anyway..."
            echo "💡 If build fails, manually open Simulator app and try again"
        fi
    else
        echo "✅ Simulator is already booted"
    fi
else
    echo "⚠️  Could not find simulator ID for '$DEVICE'"
    echo "💡 Available simulators:"
    xcrun simctl list devices | grep "iPhone" | head -5
    exit 1
fi

# Ensure Simulator app is running
if ! pgrep -x "Simulator" > /dev/null; then
    echo "📱 Opening Simulator app..."
    open -a Simulator 2>/dev/null || true
    sleep 2
fi

echo ""

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1

# Install pods if needed
if [ ! -d "ios/Pods" ]; then
    echo "📦 Installing CocoaPods..."
    cd ios
    export LANG=en_US.UTF-8
    pod install > /dev/null 2>&1
    cd ..
fi

echo ""
echo "✅ Pre-build checks complete!"
echo "🚀 Starting Flutter app..."
echo ""

# Try to find device ID if device name is provided
if [[ "$DEVICE" =~ ^[A-F0-9-]{36}$ ]]; then
    # Device ID provided, use it directly
    DEVICE_ID="$DEVICE"
else
    # Device name provided, try to find ID
    DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE" | grep -oE '[A-F0-9-]{36}' | head -1)
    if [ -z "$DEVICE_ID" ]; then
        echo "⚠️  Could not find device ID for '$DEVICE', using name directly"
        DEVICE_ID="$DEVICE"
    else
        echo "📱 Found device ID: $DEVICE_ID"
    fi
fi

# Run Flutter
exec flutter run -d "$DEVICE_ID"

