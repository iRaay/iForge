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

# --------------------------------------------------
# 1. Load Forge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "❌ Forge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

echo ""
echo "======================================"
echo "⚙️ Forge Configuration"
echo "======================================"

echo "Build Type:"
echo "$FORGE_BUILD_TYPE"

echo "Build File:"
echo "$FORGE_BUILD_FILE"

echo "Scheme:"
echo "$FORGE_SCHEME"

# --------------------------------------------------
# 2. Resolve Swift Package Dependencies
# --------------------------------------------------

echo ""
echo "📦 Resolving Swift Packages..."

if [ "$FORGE_BUILD_TYPE" = "workspace" ]; then

    xcodebuild \
        -resolvePackageDependencies \
        -workspace "$FORGE_BUILD_FILE"

elif [ "$FORGE_BUILD_TYPE" = "project" ]; then

    xcodebuild \
        -resolvePackageDependencies \
        -project "$FORGE_BUILD_FILE"

else

    echo ""
    echo "❌ Unknown Forge build type:"
    echo "$FORGE_BUILD_TYPE"
    exit 1

fi

echo ""
echo "======================================"
echo "✅ Environment Ready"
echo "======================================"
