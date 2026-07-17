#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-1.0.0}"
BUILD="${2:-1}"

echo "=== PetFriendly Watch App Build v${VERSION} (build ${BUILD}) ==="
echo ""

# 编译真机版本（for device）
xcodebuild -project PetFriendlyWatch.xcodeproj \
  -scheme PetFriendlyWatch \
  -configuration Release \
  -destination 'generic/platform=watchOS' \
  -derivedDataPath /tmp/PFWDerivedData \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD}" \
  archive \
  -archivePath /tmp/PetFriendlyWatch.xcarchive 2>&1 | tail -5

echo ""
echo "✅ 编译完成"
echo "   归档: /tmp/PetFriendlyWatch.xcarchive"
echo "   App:  /tmp/PFWDerivedData/Build/Products/Release-watchos/PetFriendlyWatch.app"
echo ""
echo "===== 安装到 Apple Watch S4 ====="
echo "方法1: Xcode -> Window -> Devices & Simulators (⌘⇧2)"
echo "        连接 iPhone -> 在 Installed Apps 点 + -> 选择上面的 .app"
echo ""
echo "方法2: Xcode 直接 Run"
echo "        选择 PetFriendlyWatch scheme -> 目标选 Apple Watch -> ⌘R"
echo ""
echo "方法3: 通过主 App 嵌入（推荐生产环境用）"
echo "        把这个 Watch target 加到 PetFriendly 主项目的 Embed Watch Content 阶段"
