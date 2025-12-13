#!/bin/bash
# iOS Build Fix Script

echo "🔧 Fixing iOS Build Configuration..."
echo ""

# Navigate to project root
cd "$(dirname "$0")"

# Clean Flutter build
echo "1. Cleaning Flutter build..."
flutter clean

# Get Flutter dependencies
echo "2. Getting Flutter dependencies..."
flutter pub get

# Clean iOS pods
echo "3. Cleaning iOS pods..."
cd ios
rm -rf Pods Podfile.lock

# Reinstall pods
echo "4. Reinstalling CocoaPods dependencies..."
pod install --repo-update

cd ..

echo ""
echo "✅ iOS build configuration fixed!"
echo ""
echo "You can now try running:"
echo "  flutter run -d 'iPhone 17 Pro'"
echo ""

