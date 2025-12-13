#!/bin/bash
# Safe Flutter iOS Run Script with Build Lock

set -e

LOCK_FILE="/tmp/flutter_ios_build.lock"
MAX_WAIT=60  # Maximum seconds to wait for lock

# Function to acquire lock
acquire_lock() {
    local wait_time=0
    while [ -f "$LOCK_FILE" ]; do
        if [ $wait_time -ge $MAX_WAIT ]; then
            echo "❌ ERROR: Build lock held for more than $MAX_WAIT seconds"
            echo "💡 Another build may be running. If not, delete: $LOCK_FILE"
            exit 1
        fi
        echo "⏳ Waiting for build lock to be released ($wait_time/$MAX_WAIT seconds)..."
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    # Create lock file with PID
    echo $$ > "$LOCK_FILE"
    trap "rm -f $LOCK_FILE" EXIT INT TERM
    echo "✅ Build lock acquired"
}

# Function to wait for existing builds to finish
wait_for_builds() {
    local max_wait=30
    local waited=0
    
    echo "🔍 Checking for existing builds..."
    while [ $waited -lt $max_wait ]; do
        BUILD_PROCESSES=$(ps aux | grep -E "[x]codebuild.*Runner" | grep -v grep | wc -l | tr -d ' ')
        if [ "$BUILD_PROCESSES" -eq 0 ]; then
            echo "✅ No builds running"
            return 0
        fi
        echo "⏳ Waiting for existing build to finish ($waited/$max_wait seconds)..."
        sleep 3
        waited=$((waited + 3))
    done
    
    echo "⚠️  Build still running after $max_wait seconds"
    return 1
}

# Function to kill ALL processes aggressively (but NOT Flutter's xcodebuild)
kill_all_builds() {
    echo "🔪 Checking for build processes..."
    
    # First, wait for any legitimate builds to finish
    if ! wait_for_builds; then
        echo "⚠️  Existing build detected. Killing it..."
        # Only kill xcodebuild processes NOT related to our current build
        pkill -9 -f "xcodebuild.*Runner" 2>/dev/null || true
        sleep 3
    fi
    
    # Kill Xcode app (but not xcodebuild that Flutter will start)
    pkill -9 -f "Xcode.app" 2>/dev/null || true
    pkill -9 -f com.apple.CoreSimulator 2>/dev/null || true
    pkill -9 -f Simulator 2>/dev/null || true
    pkill -9 -f "CoreSimulatorService" 2>/dev/null || true
    
    sleep 2
    
    # Kill processes locking DerivedData (but be careful)
    lsof +D ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | while read pid; do
        # Don't kill Flutter or our own process
        if [ "$pid" != "$$" ] && ! ps -p "$pid" -o comm= | grep -q "flutter\|dart"; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
    
    echo "✅ Processes cleaned"
    return 0
}

# Function to clean DerivedData
clean_derived_data() {
    echo "🧹 Cleaning DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
    find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
    find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true
    sleep 1
    echo "✅ DerivedData cleaned"
}

echo "🚀 Flutter iOS Run Script (Safe Mode)"
echo "======================================"
echo ""

# Acquire build lock
acquire_lock

# Kill all processes first
if ! kill_all_builds; then
    echo "❌ Failed to kill all processes. Exiting."
    exit 1
fi

# Clean DerivedData
clean_derived_data

# Get device from argument or use default
DEVICE="${1:-iPhone 17 Pro}"

echo ""
echo "📱 Building for device: $DEVICE"
echo ""

# Ensure we're in the project directory
cd "$(dirname "$0")"

# Boot simulator if needed
echo "🔍 Checking simulator status..."
SIMULATOR_ID=$(xcrun simctl list devices | grep "$DEVICE" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -n "$SIMULATOR_ID" ]; then
    BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
    
    if [ -z "$BOOT_STATUS" ]; then
        echo "📱 Booting simulator..."
        xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
        open -a Simulator 2>/dev/null || true
        
        for i in {1..6}; do
            sleep 3
            BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE" | grep -i "booted")
            if [ -n "$BOOT_STATUS" ]; then
                echo "✅ Simulator booted"
                break
            fi
        done
    else
        echo "✅ Simulator is booted"
    fi
    
    # Ensure Simulator app is running
    if ! pgrep -x "Simulator" > /dev/null; then
        open -a Simulator 2>/dev/null || true
        sleep 2
    fi
else
    echo "❌ Could not find simulator for '$DEVICE'"
    exit 1
fi

# Get dependencies
echo ""
echo "📦 Getting dependencies..."
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

# Use device ID for more reliable targeting
DEVICE_ID="$SIMULATOR_ID"

# Run Flutter (this will release the lock on exit due to trap)
exec flutter run -d "$DEVICE_ID"

