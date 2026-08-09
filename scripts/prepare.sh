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

echo ""
echo "Swift Package Manager:"
echo "$FORGE_USE_SPM"

echo "CocoaPods:"
echo "$FORGE_USE_COCOAPODS"

echo "Carthage:"
echo "$FORGE_USE_CARTHAGE"

echo "mise:"
echo "$FORGE_USE_MISE"

# --------------------------------------------------
# 2. Prepare mise
# --------------------------------------------------

if [ "$FORGE_USE_MISE" = "true" ]; then

    echo ""
    echo "======================================"
    echo "🧰 mise Required"
    echo "======================================"

    if command -v mise >/dev/null 2>&1; then

        echo "✅ mise already installed"
        mise --version

    else

        echo "📦 Installing mise..."

        brew install mise

        echo ""
        echo "✅ mise installed"
        mise --version

    fi

else

    echo ""
    echo "======================================"
    echo "🧰 mise"
    echo "======================================"

    echo "⏭️ mise not required — skipping"

fi

# --------------------------------------------------
# 3. Resolve Swift Package Dependencies
# --------------------------------------------------

if [ "$FORGE_USE_SPM" = "true" ]; then

    echo ""
    echo "======================================"
    echo "📦 Swift Package Manager"
    echo "======================================"

    echo "🔄 Resolving Swift Packages..."

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

else

    echo ""
    echo "📦 Swift Package Manager"
    echo "⏭️ Not required — skipping"

fi

# --------------------------------------------------
# 4. CocoaPods
# --------------------------------------------------

if [ "$FORGE_USE_COCOAPODS" = "true" ]; then

    echo ""
    echo "======================================"
    echo "🍫 CocoaPods"
    echo "======================================"

    echo "⚠️ CocoaPods detected."
    echo "Automatic installation will be handled by Forge."

else

    echo ""
    echo "🍫 CocoaPods"
    echo "⏭️ Not required — skipping"

fi

# --------------------------------------------------
# 5. Carthage
# --------------------------------------------------

if [ "$FORGE_USE_CARTHAGE" = "true" ]; then

    echo ""
    echo "======================================"
    echo "🛒 Carthage"
    echo "======================================"

    echo "⚠️ Carthage detected."
    echo "Automatic installation will be handled by Forge."

else

    echo ""
    echo "🛒 Carthage"
    echo "⏭️ Not required — skipping"

fi

# --------------------------------------------------
# 6. Finish
# --------------------------------------------------

echo ""
echo "======================================"
echo "✅ Environment Ready"
echo "======================================"
