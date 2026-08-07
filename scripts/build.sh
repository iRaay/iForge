#!/bin/bash
set -e

echo "=============================="
echo "🚀 Build Project"
echo "=============================="

cd project

echo ""
echo "Building..."

xcodebuild \
-project Navi.xcodeproj \
-scheme "Navi iOS" \
-configuration Debug \
-destination "generic/platform=iOS" \
-derivedDataPath build \
CODE_SIGNING_ALLOWED=NO \
build

echo ""
echo "✅ Build Finished"
