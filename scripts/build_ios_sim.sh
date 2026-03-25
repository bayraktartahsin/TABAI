#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/ios/TAIApp/TAIApp.xcodeproj"

if [ ! -d "${PROJECT_PATH}" ]; then
  echo "Missing project at ${PROJECT_PATH}. Run ./scripts/generate_ios_project.sh first."
  exit 1
fi

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme TAIApp \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath /tmp/taiapp-derived \
  build
