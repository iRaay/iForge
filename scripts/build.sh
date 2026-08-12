#!/bin/bash
set -e

echo "======================================"
echo "⚒ iForge — Build"
echo "======================================"

cd project

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ iForge configuration not found."
    exit 1
fi

source "$CONFIG_FILE"

if [ -z "$FORGE_BUILD_TYPE" ]; then
    echo "❌ FORGE_BUILD_TYPE is missing."
    exit 1
fi

if [ -z "$FORGE_BUILD_FILE" ]; then
    echo "❌ FORGE_BUILD_FILE is missing."
    exit 1
fi

if [ -z "$FORGE_SCHEME" ]; then
    echo "❌ FORGE_SCHEME is missing."
    exit 1
fi

echo ""
echo "======================================"
echo "📋 iForge Configuration"
echo "======================================"
echo "Build Type:"
echo "$FORGE_BUILD_TYPE"
echo ""
echo "Build File:"
echo "$FORGE_BUILD_FILE"
echo ""
echo "Scheme:"
echo "$FORGE_SCHEME"

mkdir -p build
ARCHIVE_PATH="build/Forge.xcarchive"

echo ""
echo "======================================"
echo "📦 Archive"
echo "======================================"
echo "Archive Path:"
echo "$ARCHIVE_PATH"

if [ "$FORGE_BUILD_TYPE" = "workspace" ]; then
    BUILD_ARGUMENT=(-workspace "$FORGE_BUILD_FILE")
elif [ "$FORGE_BUILD_TYPE" = "project" ]; then
    BUILD_ARGUMENT=(-project "$FORGE_BUILD_FILE")
else
    echo "❌ Unknown build type: $FORGE_BUILD_TYPE"
    exit 1
fi

xcodebuild \
"${BUILD_ARGUMENT[@]}" \
-scheme "$FORGE_SCHEME" \
-configuration Release \
-destination "generic/platform=iOS" \
-derivedDataPath build \
-archivePath "$ARCHIVE_PATH" \
CODE_SIGNING_ALLOWED=NO \
archive

echo ""
echo "======================================"
echo "✅ iForge Archive Finished"
echo "======================================"
echo ""
echo "Archive:"
echo "$ARCHIVE_PATH"
