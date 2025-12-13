#!/bin/bash
# Fix PhaseScriptExecution Errors - Comprehensive Fix

set -e

echo "🔧 Fixing PhaseScriptExecution Errors"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# Step 1: Verify Flutter installation
echo "1. Verifying Flutter installation..."
FLUTTER_ROOT=$(flutter --version 2>/dev/null | grep -i "flutter" | head -1 || echo "")
if [ -z "$FLUTTER_ROOT" ]; then
    FLUTTER_PATH=$(which flutter)
    if [ -n "$FLUTTER_PATH" ]; then
        FLUTTER_ROOT=$(dirname $(dirname "$FLUTTER_PATH"))
    fi
fi

if [ -z "$FLUTTER_ROOT" ]; then
    echo "   ❌ Flutter not found in PATH"
    echo "   Please ensure Flutter is installed and in your PATH"
    exit 1
fi

echo "   ✅ Flutter found: $FLUTTER_ROOT"
echo ""

# Step 2: Verify Generated.xcconfig exists and has correct FLUTTER_ROOT
echo "2. Verifying Generated.xcconfig..."
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "   📦 Generating Generated.xcconfig..."
    flutter pub get
fi

# Update FLUTTER_ROOT in Generated.xcconfig if needed
CURRENT_ROOT=$(grep "^FLUTTER_ROOT=" ios/Flutter/Generated.xcconfig 2>/dev/null | cut -d'=' -f2 || echo "")
if [ -z "$CURRENT_ROOT" ] || [ "$CURRENT_ROOT" != "$FLUTTER_ROOT" ]; then
    echo "   🔄 Updating FLUTTER_ROOT in Generated.xcconfig..."
    flutter pub get
fi

echo "   ✅ Generated.xcconfig verified"
echo ""

# Step 3: Verify xcode_backend.sh exists
echo "3. Verifying Flutter build scripts..."
XCODE_BACKEND="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ ! -f "$XCODE_BACKEND" ]; then
    echo "   ❌ xcode_backend.sh not found at: $XCODE_BACKEND"
    echo "   📦 Running flutter precache --ios..."
    flutter precache --ios
else
    echo "   ✅ xcode_backend.sh found"
    # Make sure it's executable
    chmod +x "$XCODE_BACKEND" 2>/dev/null || true
fi
echo ""

# Step 4: Kill all build processes
echo "4. Stopping all build processes..."
pkill -9 -f xcodebuild 2>/dev/null || echo "   ✓ No xcodebuild processes"
pkill -9 -f "Xcode.app" 2>/dev/null || echo "   ✓ No Xcode processes"
sleep 2
echo "   ✅ Build processes stopped"
echo ""

# Step 5: Clean DerivedData
echo "5. Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/*/Build/Intermediates.noindex/XCBuildData/build.db* 2>/dev/null || true
echo "   ✅ DerivedData cleaned"
echo ""

# Step 6: Clean Flutter build
echo "6. Cleaning Flutter build..."
flutter clean
echo "   ✅ Flutter build cleaned"
echo ""

# Step 7: Clean and reinstall pods
echo "7. Reinstalling CocoaPods dependencies..."
cd ios
rm -rf Pods Podfile.lock
pod deintegrate 2>/dev/null || true
pod install --repo-update
cd ..
echo "   ✅ Pods reinstalled"
echo ""

# Step 8: Regenerate Flutter files
echo "8. Regenerating Flutter configuration..."
flutter pub get
flutter precache --ios --force
echo "   ✅ Flutter configuration regenerated"
echo ""

# Step 9: Verify script permissions
echo "9. Verifying script permissions..."
find "$FLUTTER_ROOT/packages/flutter_tools/bin" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "   ✅ Script permissions verified"
echo ""

# Step 10: Test build script
echo "10. Testing xcode_backend.sh script..."
if [ -f "$XCODE_BACKEND" ]; then
    bash -n "$XCODE_BACKEND" && echo "   ✅ Script syntax is valid" || echo "   ⚠️  Script has syntax errors"
else
    echo "   ❌ Script not found"
fi
echo ""

echo "✅ Fix Complete!"
echo ""
echo "Next steps:"
echo "  1. Make sure Xcode is completely closed (Cmd+Q)"
echo "  2. Wait 5 seconds"
echo "  3. Try building again:"
echo "     - From Xcode: open ios/Runner.xcworkspace"
echo "     - Or from terminal: flutter run -d 'iPhone 17 Pro'"
echo ""
echo "💡 If errors persist, check Xcode build log for the specific script phase that's failing"

