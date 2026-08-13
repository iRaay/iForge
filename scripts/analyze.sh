#!/bin/bash
set -euo pipefail

echo "======================================"
echo "⚒ iForge — iOS Project Analyzer"
echo "======================================"

cd project

mkdir -p build/logs

CONFIGURATION="${CONFIGURATION:-Release}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"

echo ""
echo "======================================"
echo "📁 Project"
echo "======================================"
pwd

# --------------------------------------------------
# 1. Detect Workspace / Project
# --------------------------------------------------

WORKSPACE=$(find . \
  -type d \
  -name "*.xcworkspace" \
  -not -path "./.git/*" \
  -not -path "./build/*" \
  -print \
  | sort \
  | head -n 1)

PROJECT=$(find . \
  -type d \
  -name "*.xcodeproj" \
  -not -path "./.git/*" \
  -not -path "./build/*" \
  -print \
  | sort \
  | head -n 1)

echo ""
echo "======================================"
echo "🔍 Project Detection"
echo "======================================"

if [ -n "$WORKSPACE" ]; then
    BUILD_TYPE="workspace"
    BUILD_FILE="$WORKSPACE"
    echo "✅ Workspace:"
    echo "$WORKSPACE"
elif [ -n "$PROJECT" ]; then
    BUILD_TYPE="project"
    BUILD_FILE="$PROJECT"
    echo "✅ Project:"
    echo "$PROJECT"
else
    echo "❌ No .xcworkspace or .xcodeproj found."
    exit 1
fi

# --------------------------------------------------
# 2. xcodebuild -list
# --------------------------------------------------

echo ""
echo "======================================"
echo "📋 Xcode Project Information"
echo "======================================"

if [ "$BUILD_TYPE" = "workspace" ]; then
    LIST_OUTPUT=$(xcodebuild -list -workspace "$BUILD_FILE" 2>&1)
else
    LIST_OUTPUT=$(xcodebuild -list -project "$BUILD_FILE" 2>&1)
fi

echo "$LIST_OUTPUT"

# --------------------------------------------------
# 3. Extract Targets
# --------------------------------------------------
# xcodebuild -list indents section headers (for example "    Targets:").
# Match optional leading/trailing whitespace so parsing is independent
# of Xcode's formatting/indentation.

TARGETS=$(echo "$LIST_OUTPUT" |
    awk '
        /^[[:space:]]*Targets:[[:space:]]*$/ {inside=1; next}
        /^[[:space:]]*Build Configurations:[[:space:]]*$/ {inside=0}
        /^[[:space:]]*Schemes:[[:space:]]*$/ {inside=0}
        inside && /^[[:space:]]+[^[:space:]]/ {
            gsub(/^[[:space:]]+/, "")
            print
        }
    ')

# --------------------------------------------------
# 4. Extract Schemes
# --------------------------------------------------

SCHEMES=$(echo "$LIST_OUTPUT" |
    awk '
        /^[[:space:]]*Schemes:[[:space:]]*$/ {inside=1; next}
        inside && /^[[:space:]]+[^[:space:]]/ {
            gsub(/^[[:space:]]+/, "")
            print
        }
    ')

if [ -z "$SCHEMES" ]; then
    echo ""
    echo "❌ No schemes found."
    echo ""
    echo "Debug: xcodebuild reported the following list:"
    echo "$LIST_OUTPUT"
    exit 1
fi

echo ""
echo "======================================"
echo "🎯 Targets"
echo "======================================"

if [ -n "$TARGETS" ]; then
    echo "$TARGETS"
else
    echo "⚠️ No targets detected."
fi

echo ""
echo "======================================"
echo "🎯 Available Schemes"
echo "======================================"

echo "$SCHEMES"

# --------------------------------------------------
# 5. Smart Scheme Scoring
# --------------------------------------------------

echo ""
echo "======================================"
echo "🧠 Smart Scheme Selection"
echo "======================================"

BEST_SCHEME=""
BEST_SCORE=-999999
BEST_REASON=""

while IFS= read -r SCHEME; do

    [ -z "$SCHEME" ] && continue

    SCORE=0
    REASONS=""

    LOWER=$(echo "$SCHEME" | tr '[:upper:]' '[:lower:]')

    # ----------------------------------------------
    # Exact Target Match
    # ----------------------------------------------

    if echo "$TARGETS" | grep -Fxq "$SCHEME"; then
        SCORE=$((SCORE + 100))
        REASONS="$REASONS exact-target-match;"
    fi

    # ----------------------------------------------
    # App naming
    # ----------------------------------------------

    if echo "$LOWER" | grep -Eq 'app$|app[-_ ]'; then
        SCORE=$((SCORE + 25))
        REASONS="$REASONS app-name;"
    fi

    # ----------------------------------------------
    # Test / UI Test
    # ----------------------------------------------

    if echo "$LOWER" | grep -Eq 'test|tests|uitest|ui-test|ui_test'; then
        SCORE=$((SCORE - 100))
        REASONS="$REASONS test-target;"
    fi

    # ----------------------------------------------
    # Watch / Widget / Extension
    # ----------------------------------------------

    if echo "$LOWER" | grep -Eq 'watch|widget|extension|intent'; then
        SCORE=$((SCORE - 60))
        REASONS="$REASONS extension-target;"
    fi

    # ----------------------------------------------
    # Framework / Package
    # ----------------------------------------------

    if echo "$LOWER" | grep -Eq 'framework|package'; then
        SCORE=$((SCORE - 50))
        REASONS="$REASONS framework-package;"
    fi

    # ----------------------------------------------
    # Verify build settings
    # ----------------------------------------------

    SETTINGS_OUTPUT=""

    if [ "$BUILD_TYPE" = "workspace" ]; then
        SETTINGS_OUTPUT=$(xcodebuild \
            -workspace "$BUILD_FILE" \
            -scheme "$SCHEME" \
            -showBuildSettings \
            2>/dev/null || true)
    else
        SETTINGS_OUTPUT=$(xcodebuild \
            -project "$BUILD_FILE" \
            -scheme "$SCHEME" \
            -showBuildSettings \
            2>/dev/null || true)
    fi

    SDKROOT=$(echo "$SETTINGS_OUTPUT" |
        awk -F'= ' '/SDKROOT =/ {print $2; exit}')

    PLATFORM_NAME=$(echo "$SETTINGS_OUTPUT" |
        awk -F'= ' '/PLATFORM_NAME =/ {print $2; exit}')

    PRODUCT_TYPE=$(echo "$SETTINGS_OUTPUT" |
        awk -F'= ' '/PRODUCT_TYPE =/ {print $2; exit}')

    # ----------------------------------------------
    # iOS preference
    # ----------------------------------------------

    if echo "$SDKROOT" | grep -qi 'iphoneos'; then
        SCORE=$((SCORE + 80))
        REASONS="$REASONS ios-sdk;"
    elif echo "$PLATFORM_NAME" | grep -qi 'iphoneos'; then
        SCORE=$((SCORE + 80))
        REASONS="$REASONS ios-platform;"
    elif echo "$SDKROOT" | grep -qi 'macos'; then
        SCORE=$((SCORE - 100))
        REASONS="$REASONS macos-sdk;"
    fi

    # ----------------------------------------------
    # Application product type
    # ----------------------------------------------

    if echo "$PRODUCT_TYPE" | grep -qi 'com.apple.product-type.application'; then
        SCORE=$((SCORE + 80))
        REASONS="$REASONS application-product;"
    fi

    echo ""
    echo "Scheme: $SCHEME"
    echo "Score:  $SCORE"

    if [ -n "$REASONS" ]; then
        echo "Reason: $REASONS"
    fi

    if [ "$SCORE" -gt "$BEST_SCORE" ]; then
        BEST_SCORE="$SCORE"
        BEST_SCHEME="$SCHEME"
        BEST_REASON="$REASONS"
    fi

done <<< "$SCHEMES"

if [ -z "$BEST_SCHEME" ]; then
    echo ""
    echo "❌ Unable to select a suitable iOS scheme."
    exit 1
fi

# --------------------------------------------------
# 6. Final Scheme
# --------------------------------------------------

echo ""
echo "======================================"
echo "🏆 Selected Scheme"
echo "======================================"

echo "Scheme: $BEST_SCHEME"
echo "Score:  $BEST_SCORE"
echo "Reason: $BEST_REASON"

# --------------------------------------------------
# 7. Requirements Detection
# --------------------------------------------------

FORGE_USE_SPM="false"
FORGE_USE_COCOAPODS="false"
FORGE_USE_CARTHAGE="false"
FORGE_USE_MISE="false"

if find . \
    -type f \
    \( -name "Package.swift" -o -name "Package.resolved" \) \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_SPM="true"

elif find . \
    -type f \
    -name "project.pbxproj" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    -exec grep -l \
    -e "XCRemoteSwiftPackageReference" \
    -e "XCLocalSwiftPackageReference" \
    {} + \
    | grep -q .; then

    FORGE_USE_SPM="true"
fi

if find . \
    -type f \
    -name "Podfile" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_COCOAPODS="true"
fi

if find . \
    -type f \
    -name "Cartfile" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_CARTHAGE="true"
fi

if find . \
    -type f \
    \( \
        -name ".mise.toml" \
        -o -name "mise.toml" \
        -o -name ".mise.local.toml" \
        -o -name "mise.local.toml" \
    \) \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_MISE="true"
fi

# --------------------------------------------------
# 8. Save Build Configuration
# --------------------------------------------------

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
echo "⚙️ iForge Configuration"
echo "======================================"

cat "$CONFIG_FILE"

echo ""
echo "======================================"
echo "✅ Analysis Complete"
echo "======================================"
