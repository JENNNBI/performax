#!/bin/bash

# Reset Swift build services and XCBuild databases to avoid Xcode's
# "database is locked" failures when running on iOS simulators.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IOS_DIR="${PROJECT_ROOT}/ios"

log() {
  echo "🔄 [Performax] $*"
}

kill_service() {
  local name="$1"
  if pgrep -x "$name" >/dev/null 2>&1; then
    log "Stopping $name"
    pkill -9 -x "$name" || true
  fi
}

cleanup_dir() {
  local dir="$1"
  if [ -e "$dir" ]; then
    log "Removing $dir"
    rm -rf "$dir"
  fi
}

log "Resetting Swift build state"

kill_service "SWBBuildService"

BUILD_ARTIFACTS=(
  "${IOS_DIR}/build/XCBuildData"
  "${IOS_DIR}/build/ExplicitPrecompiledModules"
  "${PROJECT_ROOT}/build/ios/XCBuildData"
  "${PROJECT_ROOT}/build/ios/ExplicitPrecompiledModules"
)

for path in "${BUILD_ARTIFACTS[@]}"; do
  cleanup_dir "$path"
done

find "${IOS_DIR}/build" -name "build.db*" -delete 2>/dev/null || true
find "${PROJECT_ROOT}/build/ios" -name "build.db*" -delete 2>/dev/null || true

log "Swift build reset complete"

