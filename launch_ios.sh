#!/bin/bash
# Script to launch Performax app on iOS simulator

# Set UTF-8 encoding for CocoaPods
export LANG=en_US.UTF-8

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Launching Performax on iOS Simulator...${NC}"

# Navigate to project directory
cd "$(dirname "$0")"

# Get the iOS simulator device ID
DEVICE_ID=$(flutter devices | grep "iPhone.*simulator" | awk '{print $4}' | sed 's/(//;s/)//')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}No iOS simulator found. Opening one...${NC}"
    open -a Simulator
    sleep 5
    DEVICE_ID=$(flutter devices | grep "iPhone.*simulator" | awk '{print $4}' | sed 's/(//;s/)//')
fi

echo -e "${GREEN}Using device: $DEVICE_ID${NC}"

# Run the app
flutter run -d "$DEVICE_ID"

