#!/bin/bash

# Android SHA Certificate Generator
# This script generates SHA-1 and SHA-256 fingerprints needed for Firebase Phone Auth
# Run this script from the project root directory

echo "=========================================="
echo "Android SHA Certificate Generator"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/renasa/Development/projects/performax"
cd "$PROJECT_ROOT/android"

echo "📱 Generating SHA Certificates for Firebase..."
echo ""

echo "----------------------------------------"
echo "DEBUG BUILD SHA CERTIFICATES"
echo "----------------------------------------"
echo ""

# Check if debug keystore exists
if [ -f "./debug.keystore" ]; then
    echo "✅ Debug keystore found"
    echo ""
    echo "Extracting SHA-1 and SHA-256..."
    echo ""
    keytool -list -v -keystore ./debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
    echo ""
else
    echo "⚠️  Debug keystore not found at ./debug.keystore"
    echo "Trying default Android debug keystore location..."
    echo ""
    if [ -f "$HOME/.android/debug.keystore" ]; then
        keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
        echo ""
    else
        echo "❌ Debug keystore not found"
    fi
fi

echo "----------------------------------------"
echo "ALTERNATIVE: Using Gradle signingReport"
echo "----------------------------------------"
echo ""
echo "Running: ./gradlew signingReport"
echo ""

if [ -f "./gradlew" ]; then
    ./gradlew signingReport | grep -A 10 "SHA1:" | head -20
    echo ""
else
    echo "❌ gradlew not found"
fi

echo ""
echo "=========================================="
echo "INSTRUCTIONS:"
echo "=========================================="
echo ""
echo "1. Copy the SHA-1 and SHA-256 values from above"
echo ""
echo "2. Go to Firebase Console:"
echo "   https://console.firebase.google.com/project/performax-e4b1c/settings/general"
echo ""
echo "3. Scroll to 'Your apps' section"
echo ""
echo "4. Find Android app: com.example.performax"
echo ""
echo "5. Click 'Add fingerprint'"
echo ""
echo "6. Paste SHA-1 fingerprint"
echo ""
echo "7. Click 'Add fingerprint' again"
echo ""
echo "8. Paste SHA-256 fingerprint"
echo ""
echo "9. Click 'Save'"
echo ""
echo "10. Download updated google-services.json"
echo ""
echo "11. Replace android/app/google-services.json"
echo ""
echo "12. Run: flutter clean && flutter pub get"
echo ""
echo "13. Rebuild and test the app"
echo ""
echo "=========================================="
echo ""

echo "✅ SHA certificate extraction complete!"
echo ""
echo "NOTE: After adding certificates to Firebase, you MUST:"
echo "  - Download updated google-services.json"
echo "  - Replace it in android/app/"
echo "  - Run flutter clean"
echo "  - Rebuild the app"
echo ""

