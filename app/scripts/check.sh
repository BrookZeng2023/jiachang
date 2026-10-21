#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:$PATH"

command -v xcodegen >/dev/null || {
  echo "xcodegen is required: brew install xcodegen" >&2
  exit 1
}

IOS_DESTINATION="${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
xcodegen generate >/dev/null
args=(
  -project jiachang.xcodeproj
  -scheme jiachang
  -destination "$IOS_DESTINATION"
  test
)

if command -v xcbeautify >/dev/null; then
  xcodebuild "${args[@]}" | xcbeautify
else
  xcodebuild "${args[@]}"
fi
