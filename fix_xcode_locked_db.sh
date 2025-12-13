#!/bin/bash
# Fix Xcode Build Database Lock Error

set -e

echo "🔧 Fixing Xcode Build Database Lock Error"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Step 1: Kill all Xcode and build processes
echo "1. Stopping all build processes..."
echo "   Killing xcodebuild processes..."
pkill -9 -f xcodebuild 2>/dev/null || echo "   ✓ No xcodebuild processes found"

echo "   Killing Xcode processes..."
pkill -9 -f "Xcode.app" 2>/dev/null || echo "   ✓ No Xcode processes found"

echo "   Killing Flutter build processes..."
pkill -9 -f "flutter.*build" 2>/dev/null || echo "   ✓ No Flutter build processes found"

sleep 2
echo "   ✅ All build processes stopped"
echo ""

# Step 2: Clean Xcode DerivedData
echo "2. Cleaning Xcode DerivedData..."
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA_PATH" ]; then
    # Clean Runner-specific DerivedData
    rm -rf "$DERIVED_DATA_PATH"/Runner-* 2>/dev/null || true
    echo "   ✅ Runner DerivedData cleaned"
    
    # Also try to unlock any locked databases
    find "$DERIVED_DATA_PATH" -name "build.db*" -type f -exec rm -f {} \; 2>/dev/null || true
    echo "   ✅ Locked databases removed"
else
    echo "   ℹ️  DerivedData folder not found"
fi
echo ""

# Step 3: Clean Flutter build
echo "3. Cleaning Flutter build..."
flutter clean
echo "   ✅ Flutter build cleaned"
echo ""

# Step 4: Clean iOS build artifacts
echo "4. Cleaning iOS build artifacts..."
cd ios
rm -rf build Pods/Pods.xcodeproj/xcuserdata 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
cd ..
echo "   ✅ iOS build artifacts cleaned"
echo ""

# Step 5: Verify Xcode is not running
echo "5. Checking Xcode status..."
if pgrep -x "Xcode" > /dev/null; then
    echo "   ⚠️  Xcode is still running"
    echo "   💡 Please quit Xcode completely (Cmd+Q) before building"
    echo ""
    read -p "   Press Enter after quitting Xcode, or Ctrl+C to cancel..."
else
    echo "   ✅ Xcode is not running"
fi
echo ""

# Step 6: Reinstall pods
echo "6. Reinstalling CocoaPods dependencies..."
cd ios
pod deintegrate 2>/dev/null || true
pod install
cd ..
echo "   ✅ Pods reinstalled"
echo ""

# Step 7: Regenerate Flutter files
echo "7. Regenerating Flutter configuration..."
flutter pub get
echo "   ✅ Flutter configuration regenerated"
echo ""

echo "✅ Fix Complete!"
echo ""
echo "Now you can:"
echo "  1. Open Xcode: open ios/Runner.xcworkspace"
echo "  2. Or build from command line: flutter run -d 'iPhone 17 Pro'"
echo ""
echo "💡 Tip: Make sure Xcode is completely closed before building!"

