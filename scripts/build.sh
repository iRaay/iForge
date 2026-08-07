#!/bin/bash
set -e

echo "==============================="
echo "🚀 Archive Project"
echo "==============================="

cd project

mkdir -p build

xcodebuild \
-project Navi.xcodeproj \
-scheme "Navi iOS" \
-configuration Release \
-destination "generic/platform=iOS" \
-derivedDataPath build \
-archivePath build/Navi.xcarchive \
CODE_SIGNING_ALLOWED=NO \
archive

echo ""
echo "✅ Archive Finished"
