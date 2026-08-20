#!/bin/bash
set -Eeuo pipefail

echo "======================================"
echo "⚒ iForge — Build"
echo "======================================"

cd project

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ iForge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

LOG_DIR="build/logs"
LOG_FILE="$LOG_DIR/xcodebuild.log"

mkdir -p "$LOG_DIR"

# --------------------------------------------------
# Error Diagnostics
# --------------------------------------------------

print_build_error() {
    EXIT_CODE=$?

    echo ""
    echo "======================================"
    echo "❌ Xcode Build Failed"
    echo "======================================"

    echo ""
    echo "Configuration:"
    echo "Scheme: $FORGE_SCHEME"
    echo "Configuration: ${FORGE_CONFIGURATION:-Release}"
    echo "Clean Build: ${FORGE_CLEAN_BUILD:-false}"
    echo "Package Plugin Validation Bypass: ${FORGE_ALLOW_PACKAGE_PLUGINS:-false}"

    if [ -f "$LOG_FILE" ]; then

        echo ""
        echo "--------------------------------------"
        echo "📋 Last 100 Log Lines"
        echo "--------------------------------------"

        tail -n 100 "$LOG_FILE"

        echo ""
        echo "--------------------------------------"
        echo "🚨 Detected Xcode Errors"
        echo "--------------------------------------"

        grep -E \
            "error:|fatal error:|BUILD FAILED|ARCHIVE FAILED|Unable to find a destination" \
            "$LOG_FILE" \
            | tail -n 50 \
            || true

        echo ""
        echo "Full build log:"
        echo "$LOG_FILE"
    fi

    exit "$EXIT_CODE"
}

trap print_build_error ERR

# --------------------------------------------------
# Configuration
# --------------------------------------------------

FORGE_CONFIGURATION="${FORGE_CONFIGURATION:-Release}"
FORGE_CLEAN_BUILD="${FORGE_CLEAN_BUILD:-false}"
FORGE_ALLOW_PACKAGE_PLUGINS="${FORGE_ALLOW_PACKAGE_PLUGINS:-false}"

case "$FORGE_ALLOW_PACKAGE_PLUGINS" in
    true|false) ;;
    *)
        echo "❌ FORGE_ALLOW_PACKAGE_PLUGINS must be true or false."
        exit 1
        ;;
esac

if [ -z "${FORGE_BUILD_TYPE:-}" ]; then
    echo "❌ FORGE_BUILD_TYPE is missing."
    exit 1
fi

if [ -z "${FORGE_BUILD_FILE:-}" ]; then
    echo "❌ FORGE_BUILD_FILE is missing."
    exit 1
fi

if [ -z "${FORGE_SCHEME:-}" ]; then
    echo "❌ FORGE_SCHEME is missing."
    exit 1
fi

ARCHIVE_PATH="build/Forge.xcarchive"
DERIVED_DATA_PATH="build/DerivedData"

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
echo ""
echo "Configuration:"
echo "$FORGE_CONFIGURATION"
echo ""
echo "Clean Build:"
echo "$FORGE_CLEAN_BUILD"
echo ""
echo "Package Plugin Validation Bypass:"
echo "$FORGE_ALLOW_PACKAGE_PLUGINS"

# --------------------------------------------------
# Clean Build
# --------------------------------------------------

if [ "$FORGE_CLEAN_BUILD" = "true" ]; then

    echo ""
    echo "======================================"
    echo "🧹 Clean Build"
    echo "======================================"

    rm -rf "$DERIVED_DATA_PATH"
    rm -rf "$ARCHIVE_PATH"
    rm -rf "build/export"
    rm -rf "build/ipa-staging"
    rm -f "$LOG_FILE"

    mkdir -p "$LOG_DIR"

    echo "✅ Build directories cleaned."

else

    echo ""
    echo "ℹ️ Clean Build disabled."

fi

# --------------------------------------------------
# Build Argument
# --------------------------------------------------

if [ "$FORGE_BUILD_TYPE" = "workspace" ]; then

    BUILD_ARGUMENT=(-workspace "$FORGE_BUILD_FILE")

elif [ "$FORGE_BUILD_TYPE" = "project" ]; then

    BUILD_ARGUMENT=(-project "$FORGE_BUILD_FILE")

else

    echo "❌ Unknown build type:"
    echo "$FORGE_BUILD_TYPE"
    exit 1

fi

# --------------------------------------------------
# Package Plugin Policy
# --------------------------------------------------

XCODE_PACKAGE_PLUGIN_ARGUMENTS=()

if [ "$FORGE_ALLOW_PACKAGE_PLUGINS" = "true" ]; then
    echo ""
    echo "======================================"
    echo "⚠️ Swift Package Plugin Policy"
    echo "======================================"
    echo "Explicit opt-in detected."
    echo "Using: -skipPackagePluginValidation"
    XCODE_PACKAGE_PLUGIN_ARGUMENTS=(-skipPackagePluginValidation)
else
    echo ""
    echo "======================================"
    echo "🔒 Swift Package Plugin Policy"
    echo "======================================"
    echo "Secure default: package plugin validation remains enabled."
fi

# --------------------------------------------------
# Build
# --------------------------------------------------

echo ""
echo "======================================"
echo "📦 Xcode Archive"
echo "======================================"

echo ""
echo "🎯 iOS destination:"
echo "generic/platform=iOS"

set +e

xcodebuild \
    "${BUILD_ARGUMENT[@]}" \
    -scheme "$FORGE_SCHEME" \
    -configuration "$FORGE_CONFIGURATION" \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -archivePath "$ARCHIVE_PATH" \
    "${XCODE_PACKAGE_PLUGIN_ARGUMENTS[@]}" \
    ENABLE_PREVIEWS=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    archive \
    2>&1 | tee "$LOG_FILE"

XCODE_EXIT=${PIPESTATUS[0]}

set -e

if [ "$XCODE_EXIT" -ne 0 ]; then
    echo ""
    echo "❌ xcodebuild exited with code $XCODE_EXIT"
    exit "$XCODE_EXIT"
fi

echo ""
echo "======================================"
echo "✅ iForge Archive Finished"
echo "======================================"
echo ""
echo "Archive:"
echo "$ARCHIVE_PATH"
echo ""
echo "Build Log:"
echo "$LOG_FILE"
