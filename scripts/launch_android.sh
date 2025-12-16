#!/bin/bash
# Script to launch Performax app on Android emulator/device

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Launching Performax on Android...${NC}"

# Navigate to project directory
cd "$(dirname "$0")"

# Check for connected Android devices
DEVICE_ID=$(flutter devices | grep "android" | head -1 | awk '{print $4}' | sed 's/(//;s/)//')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}No Android device/emulator found. Starting emulator...${NC}"
    # Get first available emulator
    EMULATOR=$(flutter emulators | grep "^[^•]" | head -1 | awk '{print $1}')
    if [ -n "$EMULATOR" ]; then
        flutter emulators --launch "$EMULATOR"
        sleep 10
        DEVICE_ID=$(flutter devices | grep "android" | head -1 | awk '{print $4}' | sed 's/(//;s/)//')
    else
        echo -e "${YELLOW}No emulators configured. Please create one in Android Studio.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Using device: $DEVICE_ID${NC}"

# Run the app
flutter run -d "$DEVICE_ID"

