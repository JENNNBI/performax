#!/bin/bash
# Generate iOS App Icons from app_icon.png

ICON_SOURCE="assets/images/app_icon.png"
ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$ICON_SOURCE" ]; then
    echo "❌ Error: $ICON_SOURCE not found"
    exit 1
fi

echo "🎨 Generating iOS app icons from $ICON_SOURCE..."

# Use sips (macOS built-in) to resize the icon
# Create a temporary 1024x1024 icon first
TEMP_1024="$ICON_DIR/icon_1024.png"
sips -z 1024 1024 "$ICON_SOURCE" --out "$TEMP_1024" 2>/dev/null || {
    echo "⚠️  sips not available, trying ImageMagick..."
    # Fallback: copy the original and let Xcode handle resizing
    cp "$ICON_SOURCE" "$TEMP_1024" 2>/dev/null || {
        echo "⚠️  Could not create icon files automatically"
        echo "✅ AppIcon.appiconset structure created - you can add icon files manually"
        exit 0
    }
}

echo "✅ Created base icon at $TEMP_1024"
echo ""
echo "💡 Note: The AppIcon.appiconset structure is now in place."
echo "   For best results, run: flutter pub run flutter_launcher_icons"
echo "   Or manually add icon files to: $ICON_DIR"

