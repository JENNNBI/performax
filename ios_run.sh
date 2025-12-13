#!/bin/bash

# ABSOLUTE ANTI-CONCURRENT BUILD SCRIPT
# This script GUARANTEES only one build at a time

set -e

PROJECT_DIR="/Users/renasa/Development/projects/performax"
DEVICE="iPhone 17 Pro"
LOCK_FILE="/tmp/performax_build_absolute.lock"
MAX_WAIT=300  # 5 minutes max wait for existing builds

echo "🔒 Performax Absolute Single Build System"
echo "=========================================="

# Function to cleanup
cleanup() {
    rm -f "$LOCK_FILE"
    echo "🧹 Cleanup complete"
}

trap cleanup EXIT INT TERM

# Kill ANY existing builds immediately
echo "🔫 Killing all existing build processes..."
killall -9 xcodebuild 2>/dev/null || true
killall -9 dart 2>/dev/null || true
pkill -9 -f "flutter run" 2>/dev/null || true
pkill -9 -f "flutter build" 2>/dev/null || true
sleep 5

# Wait for any lingering processes
echo "⏳ Waiting for processes to fully terminate..."
WAIT_TIME=0
while [ $(ps aux | grep -E "xcodebuild.*Runner" | grep -v grep | wc -l) -gt 0 ] && [ $WAIT_TIME -lt 30 ]; do
    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
done

# Check if lock file exists and is stale
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && ! ps -p $LOCK_PID > /dev/null 2>&1; then
        echo "🗑️  Removing stale lock file (PID $LOCK_PID no longer running)"
        rm -f "$LOCK_FILE"
    elif [ -n "$LOCK_PID" ]; then
        echo "❌ ERROR: Another build is running (PID: $LOCK_PID)"
        echo "   Kill it with: kill -9 $LOCK_PID"
        echo "   Or wait for it to complete"
        exit 1
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"
echo "🔐 Lock acquired (PID: $$)"

# Verify no builds are running
if [ $(ps aux | grep -E "xcodebuild" | grep -v grep | wc -l) -gt 0 ]; then
    echo "❌ ERROR: xcodebuild processes still running!"
    ps aux | grep xcodebuild | grep -v grep
    exit 1
fi

# Navigate to project
cd "$PROJECT_DIR"

# Set environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Clean derived data and local Xcode build db
echo "🧹 Cleaning DerivedData and local Xcode build DB..."
# Kill any leftover indexers silently
pkill -9 -f "Xcode\\sindexing" 2>/dev/null || true
# Remove project-local Xcode build database
rm -rf ios/build/XCBuildData 2>/dev/null || true
# Aggressive DerivedData cleanup (move then delete if stubborn)
DDIR=~/Library/Developer/Xcode/DerivedData
if [ -d "$DDIR" ]; then
  # Prefer moving problematic Runner entries out, then delete
  for dir in "$DDIR"/Runner-*; do
    [ -e "$dir" ] || continue
    mv "$dir" "/tmp/$(basename "$dir")-OLD" 2>/dev/null || true
  done
  /usr/bin/find "$DDIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
fi
# Also remove any temp-moved copies
/usr/bin/find /tmp -maxdepth 1 -type d -name 'Runner-* -OLD' -exec rm -rf {} + 2>/dev/null || true

# Ensure pods are installed
if [ ! -d "ios/Pods" ]; then
    echo "📦 Installing pods..."
    cd ios
    pod install
    cd ..
fi

echo ""
echo "🚀 Starting SINGLE-THREADED Flutter build..."
echo "   Device: $DEVICE"
echo "   Lock: $LOCK_FILE"
echo ""

# Run with forced single job
cd "$PROJECT_DIR"
flutter run -d "$DEVICE" \
    --dart-define=FLUTTER_BUILD_MODE=debug \
    --verbose 2>&1 | while IFS= read -r line; do
        echo "$line"
        # Check for concurrent build error
        if echo "$line" | grep -q "concurrent builds"; then
            echo ""
            echo "❌❌❌ CONCURRENT BUILD ERROR DETECTED!"
            echo "This should be impossible with current settings!"
            echo ""
            exit 1
        fi
    done

echo ""
echo "✅ Build completed successfully!"

