# Xcode Build Database Lock Error - Fix Guide

## Critical Error Fixed ✅
The locked build database error should be resolved by running `fix_xcode_locked_db.sh`.

## To Fix the Warnings (Optional but Recommended)

The warnings about "Run script build phase 'Create Symlinks to Header Folders'" can be fixed by:

### Option 1: Ignore (Recommended for now)
These warnings won't prevent the app from building or running. They just indicate that some build phases run on every build, which is fine.

### Option 2: Fix in Xcode (If you want to eliminate warnings)
1. Open `ios/Pods/Pods.xcodeproj` in Xcode
2. For each target showing the warning (abseil, BoringSSL-GRPC, gRPC-C++, gRPC-Core):
   - Select the target
   - Go to "Build Phases" tab
   - Find "Create Symlinks to Header Folders" script phase
   - Uncheck "Based on dependency analysis" OR add output files to the script phase

## Manual Steps If Script Doesn't Work

### 1. Quit Xcode Completely
```bash
# Kill Xcode
killall Xcode

# Kill build processes
pkill -9 xcodebuild
```

### 2. Clean DerivedData
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

### 3. Clean Flutter Build
```bash
cd /Users/renasa/Development/projects/performax
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### 4. Rebuild
```bash
flutter run -d "iPhone 17 Pro"
```

## Important Notes

- **Always quit Xcode completely** (Cmd+Q) before running builds from terminal
- The build database lock happens when multiple builds try to access the same database
- After cleaning DerivedData, the first build will take longer (normal)

