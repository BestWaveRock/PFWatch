#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-1.0.0}"
BUILD="${2:-1}"

echo "=== PetFriendly Watch App Build v${VERSION} (build ${BUILD}) ==="
echo ""

# 1. Clean and build
xcodebuild -project PetFriendlyWatch.xcodeproj \
  -scheme PetFriendlyWatch \
  -configuration Release \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath /tmp/PFWDerivedData \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD}" \
  build 2>&1 | tail -5

echo ""
echo "✅ Build complete!"
echo "   App: /tmp/PFWDerivedData/Build/Products/Release-watchsimulator/PetFriendlyWatch.app"
