#!/bin/bash
# Check and prevent concurrent builds - AUTOMATIC MODE

echo "🔍 Checking for concurrent build issues..."
echo ""

# Check if any Xcode processes are running
XCODE_PROCESSES=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')

if [ "$XCODE_PROCESSES" -gt 0 ]; then
    echo "⚠️  Warning: $XCODE_PROCESSES Xcode/xcodebuild process(es) detected!"
    echo "🔪 Automatically killing processes to prevent concurrent builds..."
    
    pkill -9 -f Xcode 2>/dev/null || true
    pkill -9 -f xcodebuild 2>/dev/null || true
    pkill -9 -f com.apple.CoreSimulator 2>/dev/null || true
    pkill -9 -f Simulator 2>/dev/null || true
    
    # Kill processes locking DerivedData
    lsof +D ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | xargs kill -9 2>/dev/null || true
    
    sleep 2
    
    # Verify they're killed
    REMAINING=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')
    if [ "$REMAINING" -eq 0 ]; then
        echo "✅ All processes killed successfully"
    else
        echo "⚠️  Warning: $REMAINING process(es) still running"
    fi
else
    echo "✅ No Xcode processes running"
fi

# Check for lock files
LOCK_FILES=$(find ~/Library/Developer/Xcode/DerivedData -name "*.lock" 2>/dev/null | wc -l | tr -d ' ')

if [ "$LOCK_FILES" -gt 0 ]; then
    echo "⚠️  Warning: $LOCK_FILES lock file(s) found in DerivedData"
    echo "🧹 Removing lock files..."
    find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
    find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true
    echo "✅ Lock files removed"
fi

# Check for build databases
DB_FILES=$(find ~/Library/Developer/Xcode/DerivedData -name "build.db*" 2>/dev/null | wc -l | tr -d ' ')

if [ "$DB_FILES" -gt 0 ]; then
    echo "⚠️  Warning: $DB_FILES build database file(s) found"
    echo "🧹 Removing build databases..."
    find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true
    echo "✅ Build databases removed"
fi

echo ""
echo "✅ Pre-build check complete - safe to build!"
echo ""
echo "💡 Tip: Use './flutter_run_ios.sh' for automatic cleanup and build"

