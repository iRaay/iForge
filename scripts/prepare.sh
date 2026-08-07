#!/bin/bash
set -e

echo "=============================="
echo "🛠 Preparing Environment"
echo "=============================="

cd project

echo ""
echo "📂 Working directory:"
pwd

echo ""
echo "📦 Xcode version:"
xcodebuild -version

echo ""
echo "🍎 Swift version:"
swift --version

echo ""
echo "📦 Resolving Swift Packages..."

xcodebuild \
-resolvePackageDependencies \
-project Navi.xcodeproj

echo ""
echo "✅ Environment Ready"
