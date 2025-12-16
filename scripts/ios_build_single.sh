#!/bin/bash

# Single Process iOS Build Script for Flutter
# This prevents concurrent build errors by ensuring only one build runs at a time

set -e

LOCK_FILE="/tmp/performax_ios_build.lock"
PROJECT_DIR="/Users/renasa/Development/projects/performax"

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up lock file..."
    rm -f "$LOCK_FILE"
}

trap cleanup EXIT

# Check for existing builds
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        echo "❌ Error: Another build is already running (PID: $PID)"
        echo "Please wait for it to complete or kill it with: kill $PID"
        exit 1
    else
        echo "Removing stale lock file..."
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"
echo "🔒 Build lock acquired (PID: $$)"

# Kill any stray xcodebuild processes
echo "Checking for stray processes..."
killall -9 xcodebuild 2>/dev/null || true
sleep 2

# Navigate to project directory
cd "$PROJECT_DIR"

# Set proper encoding for CocoaPods
export LANG=en_US.UTF-8

# Run Flutter pub get if needed
if [ ! -d ".dart_tool" ]; then
    echo "📦 Running flutter pub get..."
    flutter pub get
fi

# Run pod install if needed
if [ ! -d "ios/Pods" ]; then
    echo "📦 Running pod install..."
    cd ios
    pod install
    cd ..
fi

# Build and run
echo "🚀 Starting Flutter build..."
flutter run -d "iPhone 17 Pro" --disable-service-auth-codes

# Cleanup is handled by trap

