#!/bin/bash
set -euo pipefail

echo "======================================"
echo "🛠 Preparing Environment"
echo "======================================"

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
# 1. Load iForge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "❌ iForge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

FORGE_CONFIGURATION="${FORGE_CONFIGURATION:-Release}"
FORGE_CLEAN_BUILD="${FORGE_CLEAN_BUILD:-false}"
FORGE_HAS_PACKAGE_PLUGINS="${FORGE_HAS_PACKAGE_PLUGINS:-false}"

if [ -z "${FORGE_SCHEME:-}" ]; then
    echo ""
    echo "❌ iForge Scheme is missing from forge.env."
    exit 1
fi

echo ""
echo "======================================"
echo "⚙️ iForge Configuration"
echo "======================================"
echo "Build Type:"
echo "$FORGE_BUILD_TYPE"
echo "Build File:"
echo "$FORGE_BUILD_FILE"
echo "Scheme:"
echo "$FORGE_SCHEME"
echo "Configuration:"
echo "$FORGE_CONFIGURATION"
echo "Clean Build:"
echo "$FORGE_CLEAN_BUILD"
echo ""
echo "Swift Package Manager:"
echo "$FORGE_USE_SPM"
echo "CocoaPods:"
echo "$FORGE_USE_COCOAPODS"
echo "Carthage:"
echo "$FORGE_USE_CARTHAGE"
echo "mise:"
echo "$FORGE_USE_MISE"
echo "Has Package Plugins:"
echo "$FORGE_HAS_PACKAGE_PLUGINS"

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

    if [ "$FORGE_HAS_PACKAGE_PLUGINS" = "true" ]; then
        echo ""
        echo "⚠️ Project uses Swift Package build-tool plugins"
        echo "Dependencies may require plugin compilation..."
    fi

    if [ "$FORGE_BUILD_TYPE" = "workspace" ]; then
        xcodebuild \
            -resolvePackageDependencies \
            -workspace "$FORGE_BUILD_FILE" \
            -scheme "$FORGE_SCHEME" \
            -configuration "$FORGE_CONFIGURATION"

    elif [ "$FORGE_BUILD_TYPE" = "project" ]; then
        xcodebuild \
            -resolvePackageDependencies \
            -project "$FORGE_BUILD_FILE" \
            -scheme "$FORGE_SCHEME" \
            -configuration "$FORGE_CONFIGURATION"

    else
        echo ""
        echo "❌ Unknown iForge build type:"
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
    echo "🍫 CocoaPods Required"
    echo "======================================"

    if ! command -v pod >/dev/null 2>&1; then
        echo "📦 Installing CocoaPods..."
        brew install cocoapods
    else
        echo "✅ CocoaPods already installed"
    fi

    echo ""
    echo "🔧 CocoaPods version:"
    pod --version

    if [ ! -f "Podfile" ]; then
        echo "❌ CocoaPods was detected, but Podfile is missing."
        exit 1
    fi

    echo ""
    echo "🔄 Installing CocoaPods dependencies..."
    pod install

    PROJECT_NAME=""

    if [ -n "${FORGE_BUILD_FILE:-}" ]; then
        case "$FORGE_BUILD_FILE" in
            *.xcodeproj)
                PROJECT_NAME="$(basename "$FORGE_BUILD_FILE" .xcodeproj)"
                ;;
            *.xcworkspace)
                PROJECT_NAME="$(basename "$FORGE_BUILD_FILE" .xcworkspace)"
                ;;
        esac
    fi

    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$(find . \
            -maxdepth 1 \
            -type d \
            -name "*.xcodeproj" \
            -print \
            | head -n 1 \
            | xargs -I{} basename "{}" .xcodeproj)"
    fi

    GENERATED_WORKSPACE="./${PROJECT_NAME}.xcworkspace"

    if [ -d "$GENERATED_WORKSPACE" ]; then
        FORGE_BUILD_TYPE="workspace"
        FORGE_BUILD_FILE="$GENERATED_WORKSPACE"

        echo ""
        echo "✅ CocoaPods workspace detected:"
        echo "$FORGE_BUILD_FILE"
    else
        echo ""
        echo "❌ pod install completed, but no .xcworkspace was found."
        exit 1
    fi
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
    echo "🛒 Carthage Required"
    echo "======================================"

    if command -v carthage >/dev/null 2>&1; then
        echo "✅ Carthage already installed"
        carthage version
    else
        echo "📦 Installing Carthage..."
        brew install carthage
        echo ""
        echo "✅ Carthage installed"
        carthage version
    fi

    if [ ! -f "Cartfile" ]; then
        echo ""
        echo "❌ Carthage was detected, but Cartfile is missing."
        exit 1
    fi

    echo ""
    echo "📄 Cartfile detected:"
    cat Cartfile

    echo ""
    echo "🔄 Resolving Carthage dependencies..."
    carthage update \
        --platform iOS \
        --use-xcframeworks

    if [ ! -d "Carthage/Build" ]; then
        echo ""
        echo "❌ Carthage completed, but Carthage/Build was not created."
        exit 1
    fi

    echo ""
    echo "✅ Carthage dependencies ready"
    echo ""
    echo "📦 Carthage build output:"
    find Carthage/Build \
        -maxdepth 2 \
        -type d \
        -name "*.xcframework" \
        -print
else
    echo ""
    echo "🛒 Carthage"
    echo "⏭️ Not required — skipping"
fi

# --------------------------------------------------
# 6. Preserve / Update forge.env
# --------------------------------------------------

echo ""
echo "======================================"
echo "💾 Updating iForge Configuration"
echo "======================================"

cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$FORGE_BUILD_TYPE"
FORGE_BUILD_FILE="$FORGE_BUILD_FILE"
FORGE_SCHEME="$FORGE_SCHEME"
FORGE_CONFIGURATION="$FORGE_CONFIGURATION"
FORGE_CLEAN_BUILD="$FORGE_CLEAN_BUILD"

FORGE_USE_SPM="$FORGE_USE_SPM"
FORGE_USE_COCOAPODS="$FORGE_USE_COCOAPODS"
FORGE_USE_CARTHAGE="$FORGE_USE_CARTHAGE"
FORGE_USE_MISE="$FORGE_USE_MISE"
FORGE_HAS_PACKAGE_PLUGINS="${FORGE_HAS_PACKAGE_PLUGINS:-false}"
FORGE_ALLOW_PACKAGE_PLUGINS="${FORGE_ALLOW_PACKAGE_PLUGINS:-false}"

FORGE_ENABLE_PREVIEWS="${FORGE_ENABLE_PREVIEWS:-false}"
FORGE_CODE_SIGNING_ALLOWED="${FORGE_CODE_SIGNING_ALLOWED:-NO}"
FORGE_CODE_SIGNING_REQUIRED="${FORGE_CODE_SIGNING_REQUIRED:-NO}"
EOF

echo ""
echo "Updated configuration:"
cat "$CONFIG_FILE"

# --------------------------------------------------
# 7. Finish
# --------------------------------------------------

echo ""
echo "======================================"
echo "✅ Environment Ready"
echo "======================================"
