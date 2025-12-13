#!/bin/bash
# Aggressive build process killer - Use this before building

echo "🔪 Aggressively killing ALL build processes..."
echo ""

# Kill all Xcode-related processes
echo "1. Killing Xcode processes..."
pkill -9 -f Xcode 2>/dev/null || true
pkill -9 -f xcodebuild 2>/dev/null || true
pkill -9 -f com.apple.CoreSimulator 2>/dev/null || true
pkill -9 -f Simulator 2>/dev/null || true
pkill -9 -f "CoreSimulatorService" 2>/dev/null || true
pkill -9 -f "com.apple.dt.SKAgent" 2>/dev/null || true
pkill -9 -f "com.apple.dt.Xcode" 2>/dev/null || true

# Kill processes locking DerivedData
echo "2. Killing processes locking DerivedData..."
lsof +D ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | xargs kill -9 2>/dev/null || true

# Wait for processes to die
echo "3. Waiting for processes to terminate..."
for i in {1..5}; do
    sleep 2
    REMAINING=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')
    if [ "$REMAINING" -eq 0 ]; then
        echo "   ✅ All processes terminated"
        break
    else
        echo "   ⏳ $REMAINING process(es) still running, waiting..."
        pkill -9 -f Xcode 2>/dev/null || true
        pkill -9 -f xcodebuild 2>/dev/null || true
    fi
done

# Clean DerivedData
echo "4. Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "*.lock" -delete 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "build.db*" -delete 2>/dev/null || true

# Verify
REMAINING=$(ps aux | grep -E "(Xcode|xcodebuild)" | grep -v grep | wc -l | tr -d ' ')
if [ "$REMAINING" -eq 0 ]; then
    echo ""
    echo "✅ All build processes killed successfully!"
    echo "✅ DerivedData cleaned"
    echo ""
    echo "Safe to build now!"
else
    echo ""
    echo "⚠️  Warning: $REMAINING process(es) still running"
    echo "You may need to manually kill them or restart your Mac"
fi

