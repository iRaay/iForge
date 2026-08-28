#!/bin/bash
set -euo pipefail

echo "======================================"
echo "⚒ iForge — iOS Project Analyzer"
echo "======================================"
echo ""

cd project
mkdir -p build/logs

CONFIGURATION="${CONFIGURATION:-Release}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"
FORGE_ALLOW_PACKAGE_PLUGINS="${FORGE_ALLOW_PACKAGE_PLUGINS:-false}"

case "$FORGE_ALLOW_PACKAGE_PLUGINS" in
    true|false) ;;
    *)
        echo "❌ FORGE_ALLOW_PACKAGE_PLUGINS must be true or false."
        exit 1
        ;;
esac

WORKSPACE=$(find . -type d -name "*.xcworkspace" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    -not -path "*.xcodeproj/*" \
    -print | sort | head -n 1)
PROJECT=$(find . -type d -name "*.xcodeproj" -not -path "./.git/*" -not -path "./build/*" -print | sort | head -n 1)

if [ -n "$WORKSPACE" ]; then
    BUILD_TYPE="workspace"
    BUILD_FILE="$WORKSPACE"
elif [ -n "$PROJECT" ]; then
    BUILD_TYPE="project"
    BUILD_FILE="$PROJECT"
else
    echo "❌ No .xcworkspace or .xcodeproj found."
    exit 1
fi

echo ""
echo "======================================"
echo "🔍 Project Detection"
echo "======================================"
echo "Build Type: $BUILD_TYPE"
echo "Build File: $BUILD_FILE"

echo ""
echo "======================================"
echo "🔐 Swift Package Plugin Policy"
echo "======================================"
if [ "$FORGE_ALLOW_PACKAGE_PLUGINS" = "true" ]; then
    echo "⚠️ Package plugin validation bypass is explicitly ENABLED for this build."
else
    echo "🔒 Package plugin validation bypass is DISABLED (secure default)."
fi

if [ "$BUILD_TYPE" = "workspace" ]; then
    LIST_OUTPUT=$(xcodebuild -list -workspace "$BUILD_FILE" 2>&1)
else
    LIST_OUTPUT=$(xcodebuild -list -project "$BUILD_FILE" 2>&1)
fi

echo ""
echo "======================================"
echo "📋 Xcode Project Information"
echo "======================================"
echo "$LIST_OUTPUT"

TARGETS=$(echo "$LIST_OUTPUT" | awk '
    /^[[:space:]]*Targets:[[:space:]]*$/ {inside=1; next}
    /^[[:space:]]*Build Configurations:[[:space:]]*$/ {inside=0}
    /^[[:space:]]*Schemes:[[:space:]]*$/ {inside=0}
    inside && /^[[:space:]]+[^[:space:]]/ {gsub(/^[[:space:]]+/, ""); print}
')

SCHEMES=$(echo "$LIST_OUTPUT" | awk '
    /^[[:space:]]*Schemes:[[:space:]]*$/ {inside=1; next}
    inside && /^[[:space:]]+[^[:space:]]/ {gsub(/^[[:space:]]+/, ""); print}
')

if [ -z "$SCHEMES" ]; then
    echo ""
    echo "❌ No schemes found."
    echo "$LIST_OUTPUT"
    exit 1
fi

echo ""
echo "======================================"
echo "🎯 Targets"
echo "======================================"
echo "${TARGETS:-No targets detected.}"
echo ""
echo "======================================"
echo "🎯 Available Schemes"
echo "======================================"
echo "$SCHEMES"

xcode_settings() {
    local scheme="$1"
    if [ "$BUILD_TYPE" = "workspace" ]; then
        xcodebuild -workspace "$BUILD_FILE" -scheme "$scheme" -configuration "$CONFIGURATION" -sdk iphoneos -destination "generic/platform=iOS" -showBuildSettings 2>&1
    else
        xcodebuild -project "$BUILD_FILE" -scheme "$scheme" -configuration "$CONFIGURATION" -sdk iphoneos -destination "generic/platform=iOS" -showBuildSettings 2>&1
    fi
}

setting_value() {
    local key="$1"
    awk -F'= ' -v key="$key" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" {print $2; exit}'
}

BEST_SCHEME=""
BEST_SCORE=-999999
BEST_REASON=""

while IFS= read -r SCHEME; do
    [ -z "$SCHEME" ] && continue
    echo ""
    echo "--------------------------------------"
    echo "🔎 Evaluating Scheme: $SCHEME"
    echo "--------------------------------------"

    LOWER=$(echo "$SCHEME" | tr '[:upper:]' '[:lower:]')

    if ! SETTINGS_OUTPUT=$(xcode_settings "$SCHEME"); then
        echo "❌ Rejected: scheme cannot resolve a generic iOS destination."
        echo "$SETTINGS_OUTPUT" | tail -n 30
        continue
    fi

    SDKROOT=$(echo "$SETTINGS_OUTPUT" | setting_value "SDKROOT")
    PLATFORM_NAME=$(echo "$SETTINGS_OUTPUT" | setting_value "PLATFORM_NAME")
    SUPPORTED_PLATFORMS=$(echo "$SETTINGS_OUTPUT" | setting_value "SUPPORTED_PLATFORMS")
    PRODUCT_TYPE=$(echo "$SETTINGS_OUTPUT" | setting_value "PRODUCT_TYPE")
    TARGET_NAME=$(echo "$SETTINGS_OUTPUT" | setting_value "TARGET_NAME")
    PRODUCT_NAME=$(echo "$SETTINGS_OUTPUT" | setting_value "PRODUCT_NAME")
    SUPPORTS_MACCATALYST=$(echo "$SETTINGS_OUTPUT" | setting_value "SUPPORTS_MACCATALYST")

    echo "SDKROOT: ${SDKROOT:-<unset>}"
    echo "PLATFORM_NAME: ${PLATFORM_NAME:-<unset>}"
    echo "SUPPORTED_PLATFORMS: ${SUPPORTED_PLATFORMS:-<unset>}"
    echo "PRODUCT_TYPE: ${PRODUCT_TYPE:-<unset>}"
    echo "TARGET_NAME: ${TARGET_NAME:-<unset>}"

    if ! echo "$SUPPORTED_PLATFORMS" | grep -Eq '(^|[[:space:]])iphoneos([[:space:]]|$)'; then
        echo "❌ Rejected: scheme does not support iphoneos."
        continue
    fi

    if [ "$PLATFORM_NAME" != "iphoneos" ]; then
        echo "❌ Rejected: PLATFORM_NAME is not iphoneos: ${PLATFORM_NAME:-<unset>}"
        continue
    fi

    # Xcode may expose SDKROOT as either a logical value such as iphoneos26.5
    # or a full iPhoneOS SDK path. Do not require one representation.
    # PLATFORM_NAME + SUPPORTED_PLATFORMS are the authoritative destination checks.
    if [ -z "$SDKROOT" ]; then
        echo "⚠️ SDKROOT is unavailable; continuing because the iOS destination resolved successfully."
    elif ! echo "$SDKROOT" | grep -Eiq '(^|/)iphoneos[0-9.]*$|/iPhoneOS[0-9.]*\.sdk$'; then
        echo "⚠️ SDKROOT has an unrecognized representation: $SDKROOT"
        echo "   Continuing because PLATFORM_NAME=iphoneos and iphoneos is supported."
    fi

    if [ "$PRODUCT_TYPE" != "com.apple.product-type.application" ]; then
        echo "❌ Rejected: product is not an iOS application."
        continue
    fi

    if echo "$LOWER" | grep -Eq '(^|[-_ .])(test|tests|uitest|ui-test|ui_tests)([-_ .]|$)'; then
        echo "❌ Rejected: test/UI-test scheme."
        continue
    fi

    if echo "$LOWER" | grep -Eq '(watch|widget|extension|intent)'; then
        echo "❌ Rejected: Watch/Widget/Extension/Intent scheme."
        continue
    fi

    SCORE=100
    REASONS="ios-compatible;application;"

    if [ -n "$TARGET_NAME" ] && [ "$SCHEME" = "$TARGET_NAME" ]; then
        SCORE=$((SCORE + 100))
        REASONS="$REASONS exact-target-match;"
    elif echo "$TARGETS" | grep -Fxq "$SCHEME"; then
        SCORE=$((SCORE + 100))
        REASONS="$REASONS exact-target-match;"
    fi

    if [ -n "$PRODUCT_NAME" ] && [ "$SCHEME" = "$PRODUCT_NAME" ]; then
        SCORE=$((SCORE + 30))
        REASONS="$REASONS product-name-match;"
    fi

    if echo "$LOWER" | grep -Eq '(^|[-_ .])app($|[-_ .])|app$'; then
        SCORE=$((SCORE + 25))
        REASONS="$REASONS app-name;"
    fi

    if [ "$SUPPORTS_MACCATALYST" = "NO" ]; then
        SCORE=$((SCORE + 10))
        REASONS="$REASONS not-mac-catalyst;"
    fi

    echo "✅ Eligible iOS application"
    echo "Score: $SCORE"
    echo "Reason: $REASONS"

    if [ "$SCORE" -gt "$BEST_SCORE" ]; then
        BEST_SCORE="$SCORE"
        BEST_SCHEME="$SCHEME"
        BEST_REASON="$REASONS"
    fi
done <<< "$SCHEMES"

if [ -z "$BEST_SCHEME" ]; then
    echo ""
    echo "======================================"
    echo "❌ No iOS application Scheme found"
    echo "======================================"
    echo "Every discovered Scheme was rejected by the iOS eligibility checks."
    exit 1
fi

echo ""
echo "======================================"
echo "🏆 Selected Scheme"
echo "======================================"
echo "Scheme: $BEST_SCHEME"
echo "Score: $BEST_SCORE"
echo "Reason: $BEST_REASON"

FORGE_USE_SPM="false"
FORGE_USE_COCOAPODS="false"
FORGE_USE_CARTHAGE="false"
FORGE_USE_MISE="false"

if find . -type f \( -name "Package.swift" -o -name "Package.resolved" \) -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_SPM="true"
elif find . -type f -name "project.pbxproj" -not -path "./.git/*" -not -path "./build/*" -exec grep -l -e "XCRemoteSwiftPackageReference" -e "XCLocalSwiftPackageReference" {} + | grep -q .; then
    FORGE_USE_SPM="true"
fi

if find . -type f -name "Podfile" -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_COCOAPODS="true"
fi

if find . -type f -name "Cartfile" -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_CARTHAGE="true"
fi

if find . -type f \( -name ".mise.toml" -o -name "mise.toml" -o -name ".mise.local.toml" -o -name "mise.local.toml" \) -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_MISE="true"
fi

CONFIG_FILE="build/forge.env"
cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$BUILD_TYPE"
FORGE_BUILD_FILE="$BUILD_FILE"
FORGE_SCHEME="$BEST_SCHEME"
FORGE_CONFIGURATION="$CONFIGURATION"
FORGE_CLEAN_BUILD="$CLEAN_BUILD"
FORGE_USE_SPM="$FORGE_USE_SPM"
FORGE_USE_COCOAPODS="$FORGE_USE_COCOAPODS"
FORGE_USE_CARTHAGE="$FORGE_USE_CARTHAGE"
FORGE_USE_MISE="$FORGE_USE_MISE"
FORGE_ALLOW_PACKAGE_PLUGINS="$FORGE_ALLOW_PACKAGE_PLUGINS"
FORGE_ENABLE_PREVIEWS="false"
FORGE_CODE_SIGNING_ALLOWED="NO"
FORGE_CODE_SIGNING_REQUIRED="NO"
EOF

echo ""
echo "======================================"
echo "⚙️ iForge Analysis Result"
echo "======================================"
cat "$CONFIG_FILE"
echo ""
echo "======================================"
echo "✅ Analysis Complete"