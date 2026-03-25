#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="${ROOT_DIR}/ios/TAIApp"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required but not installed."
  echo "Install with: brew install xcodegen"
  exit 1
fi

cd "${IOS_DIR}"
xcodegen generate

echo "Generated: ${IOS_DIR}/TAIApp.xcodeproj"
echo "Open with: open \"${IOS_DIR}/TAIApp.xcodeproj\""
