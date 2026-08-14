#!/bin/bash
set -euo pipefail

# iForge — iOS Project Analyzer
# A: Smart Scheme Selection
# F: Analysis produces the build configuration consumed by build.sh

echo "======================================"
echo "⚒ iForge — iOS Project Analyzer"
echo "======================================"
echo ""

cd project
mkdir -p build/logs

CONFIGURATION="${CONFIGURATION:-Release}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"

# --------------------------------------------------
# 1. Detect Workspace / Project
# --------------------------------------------------

WORKSPACE=$(find . -type d -name "*.xcworkspace" \
  -not -path "./.git/*" -not -path "./build/*" -print | sort | head -n 1)

PROJECT=$(find . -type d -name "*.xcodeproj" \
  -not -path "./.git/*" -not -path "./build/*" -print | sort | head -n 1)

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

# --------------------------------------------------
# 2. xcodebuild -list
# --------------------------------------------------

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

# --------------------------------------------------
# 3. Extract Targets and Schemes
# --------------------------------------------------

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
    echo ""
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

# --------------------------------------------------
# 4. Helpers
# --------------------------------------------------

# IMPORTANT:
# Do NOT pass -sdk iphoneos here.
# A/5 must inspect the project's native configuration rather than
# forcing an iOS SDK and then incorrectly concluding that the scheme
# supports iOS.
xcode_settings() {
    local scheme="$1"

    if [ "$BUILD_TYPE" = "workspace" ]; then
        xcodebuild -workspace "$BUILD_FILE" \
            -scheme "$scheme" \
            -configuration "$CONFIGURATION" \
            -showBuildSettings 2>&1
    else
        xcodebuild -project "$BUILD_FILE" \
            -scheme "$scheme" \
            -configuration "$CONFIGURATION" \
            -showBuildSettings 2>&1
    fi
}

setting_value() {
    local key="$1"
    awk -F'= ' -v key="$key" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" {print $2; exit}'
}

# --------------------------------------------------
# 5. Smart Scheme Selection
# --------------------------------------------------
# A/5 is a hard eligibility gate, not a score penalty.
# The scheme must naturally describe an iOS application before it
# can receive any Smart Scheme score.

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

    SETTINGS_OUTPUT=""
    SETTINGS_STATUS=0

    if SETTINGS_OUTPUT=$(xcode_settings "$SCHEME"); then
        SETTINGS_STATUS=0
    else
        SETTINGS_STATUS=$?
    fi

    if [ "$SETTINGS_STATUS" -ne 0 ]; then
        echo "❌ Rejected: xcodebuild -showBuildSettings failed."
        echo "$SETTINGS_OUTPUT" | tail -n 20
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

    # --------------------------------------------------
    # A/5 — iOS eligibility gate
    # --------------------------------------------------
    # These checks inspect the project's native settings. We do not
    # override SDKROOT during analysis because doing so can make a
    # macOS target look like an iOS target.

    if ! echo "$SUPPORTED_PLATFORMS" | grep -Eq '(^|[[:space:]])iphoneos([[:space:]]|$)'; then
        echo "❌ Rejected: scheme does not natively support iphoneos."
        continue
    fi

    # Xcode may report SDKROOT as a full path, e.g.:
    # /Applications/Xcode_26.6.app/.../iPhoneOS26.5.sdk
    # Validate the actual SDK path/name rather than expecting only
    # the logical value "iphoneos".
    SDKROOT_BASENAME=$(basename "$SDKROOT")
    if ! echo "$SDKROOT" | grep -Eq '/iPhoneOS\.platform/'; then
        echo "❌ Rejected: SDKROOT is not an iPhoneOS platform path: ${SDKROOT:-<unset>}"
        continue
    fi
    if ! echo "$SDKROOT_BASENAME" | grep -Eq '^iPhoneOS[0-9]+([.][0-9]+)*\.sdk$'; then
        echo "❌ Rejected: SDKROOT does not name a versioned iOS SDK: ${SDKROOT:-<unset>}"
        continue
    fi

    if [ "$PLATFORM_NAME" != "iphoneos" ]; then
        echo "❌ Rejected: PLATFORM_NAME is not iphoneos: ${PLATFORM_NAME:-<unset>}"
        continue
    fi

    if [ "$PRODUCT_TYPE" != "com.apple.product-type.application" ]; then
        echo "❌ Rejected: product is not an iOS application."
        continue
    fi

    # --------------------------------------------------
    # Name-based safety filters
    # --------------------------------------------------

    if echo "$LOWER" | grep -Eq '(^|[-_ .])(test|tests|uitest|ui-test|ui_tests)([-_ .]|$)'; then
        echo "❌ Rejected: test/UI-test scheme."
        continue
    fi

    if echo "$LOWER" | grep -Eq '(watch|widget|extension|intent)'; then
        echo "❌ Rejected: Watch/Widget/Extension/Intent scheme."
        continue
    fi

    # --------------------------------------------------
    # Score eligible iOS application schemes
    # --------------------------------------------------

    SCORE=100
    REASONS="ios-compatible;application;"

    if [ "$SCHEME" = "$TARGET_NAME" ] || echo "$TARGETS" | grep -Fxq "$SCHEME"; then
        SCORE=$((SCORE + 100))
        REASONS="$REASONS exact-target-match;"
    fi

    if [ -n "$TARGET_NAME" ] && [ "$SCHEME" = "$PRODUCT_NAME" ]; then
        SCORE=$((SCORE + 30))
        REASONS="$REASONS product-name-match;"
    fi

    if echo "$LOWER" | grep -Eq 'app$|app[-_ ]'; then
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

# --------------------------------------------------
# 6. Final Selection
# --------------------------------------------------

echo ""
echo "======================================"
echo "🏆 Selected Scheme"
echo "======================================"
echo "Scheme: $BEST_SCHEME"
echo "Score: $BEST_SCORE"
echo "Reason: $BEST_REASON"

# --------------------------------------------------
# 7. Dependency Detection
# --------------------------------------------------

FORGE_USE_SPM="false"
FORGE_USE_COCOAPODS="false"
FORGE_USE_CARTHAGE="false"
FORGE_USE_MISE="false"

if find . -type f \( -name "Package.swift" -o -name "Package.resolved" \) \
    -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_SPM="true"
elif find . -type f -name "project.pbxproj" \
    -not -path "./.git/*" -not -path "./build/*" \
    -exec grep -l -e "XCRemoteSwiftPackageReference" -e "XCLocalSwiftPackageReference" {} + \
    | grep -q .; then
    FORGE_USE_SPM="true"
fi

if find . -type f -name "Podfile" -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_COCOAPODS="true"
fi

if find . -type f -name "Cartfile" -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_CARTHAGE="true"
fi

if find . -type f \( -name ".mise.toml" -o -name "mise.toml" -o -name ".mise.local.toml" -o -name "mise.local.toml" \) \
    -not -path "./.git/*" -not -path "./build/*" | grep -q .; then
    FORGE_USE_MISE="true"
fi

# --------------------------------------------------
# 8. Persist Analysis Result
# --------------------------------------------------
# This is the boundary between Analysis (F) and Build.

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
echo "======================================"
