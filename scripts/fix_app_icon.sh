#!/bin/bash
# Fix AppIcon issue by copying the app icon to AppIcon.appiconset

echo "🎨 Fixing AppIcon for iOS..."
echo ""

cd "$(dirname "$0")"

ICON_SOURCE="assets/images/app_icon.png"
ICON_DEST="ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

if [ ! -f "$ICON_SOURCE" ]; then
    echo "❌ Error: $ICON_SOURCE not found!"
    exit 1
fi

# Copy the icon
if cp "$ICON_SOURCE" "$ICON_DEST"; then
    echo "✅ Successfully copied app icon to $ICON_DEST"
    echo ""
    echo "📦 The AppIcon.appiconset structure is now complete."
    echo ""
    echo "💡 For best results with all icon sizes, run:"
    echo "   flutter pub run flutter_launcher_icons"
else
    echo "❌ Failed to copy icon file"
    exit 1
fi

