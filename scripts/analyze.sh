#!/bin/bash
set -e

echo "======================================"
echo "⚒ Forge — iOS Project Analyzer"
echo "======================================"

cd project

echo ""
echo "📁 Project Directory:"
pwd

mkdir -p build

# --------------------------------------------------
# 1. Detect Real Workspace
# --------------------------------------------------

WORKSPACE=$(find . \
  -type d \
  -name "*.xcodeproj" -prune -o \
  -type d -name "*.xcworkspace" -print \
  | head -n 1)

# --------------------------------------------------
# 2. Detect Xcode Project
# --------------------------------------------------

PROJECT=$(find . \
  -type d \
  -name "*.xcodeproj" -print \
  | head -n 1)

echo ""
echo "======================================"
echo "🔍 Project Detection"
echo "======================================"

if [ -n "$WORKSPACE" ]; then

    BUILD_TYPE="workspace"
    BUILD_FILE="$WORKSPACE"

    echo "✅ Workspace detected:"
    echo "$WORKSPACE"

elif [ -n "$PROJECT" ]; then

    BUILD_TYPE="project"
    BUILD_FILE="$PROJECT"

    echo "✅ Xcode Project detected:"
    echo "$PROJECT"

else

    echo "❌ No .xcworkspace or .xcodeproj found."
    exit 1

fi

# --------------------------------------------------
# 3. Detect Schemes
# --------------------------------------------------

echo ""
echo "======================================"
echo "🎯 Scheme Detection"
echo "======================================"

if [ "$BUILD_TYPE" = "workspace" ]; then

    LIST_OUTPUT=$(xcodebuild -list -workspace "$BUILD_FILE")

else

    LIST_OUTPUT=$(xcodebuild -list -project "$BUILD_FILE")

fi

echo "$LIST_OUTPUT"

echo ""
echo "--------------------------------------"
echo "📱 Available Schemes"
echo "--------------------------------------"

SCHEMES=$(echo "$LIST_OUTPUT" |
    sed -n '/Schemes:/,$p' |
    tail -n +2 |
    sed '/^[[:space:]]*$/d' |
    sed 's/^[[:space:]]*//')

if [ -z "$SCHEMES" ]; then
    echo "❌ No schemes found."
    exit 1
fi

echo "$SCHEMES"

# --------------------------------------------------
# 4. Select First Scheme
# --------------------------------------------------

SCHEME=$(echo "$SCHEMES" | head -n 1)

echo ""
echo "======================================"
echo "🎯 Selected Scheme"
echo "======================================"

echo "$SCHEME"

# --------------------------------------------------
# 5. Detect Build Requirements
# --------------------------------------------------

echo ""
echo "======================================"
echo "🧠 Requirements Detection"
echo "======================================"

# Defaults
FORGE_USE_SPM="false"
FORGE_USE_COCOAPODS="false"
FORGE_USE_CARTHAGE="false"
FORGE_USE_MISE="false"

# --------------------------------------------------
# Swift Package Manager
# --------------------------------------------------

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

# --------------------------------------------------
# CocoaPods
# --------------------------------------------------

if find . \
    -type f \
    -name "Podfile" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_COCOAPODS="true"

fi

# --------------------------------------------------
# Carthage
# --------------------------------------------------

if find . \
    -type f \
    -name "Cartfile" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    | grep -q .; then

    FORGE_USE_CARTHAGE="true"

fi

# --------------------------------------------------
# mise
# --------------------------------------------------

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
# Requirements Report
# --------------------------------------------------

echo ""
echo "--------------------------------------"
echo "📋 Detected Requirements"
echo "--------------------------------------"

echo "Swift Package Manager:"
if [ "$FORGE_USE_SPM" = "true" ]; then
    echo "✅ Required"
else
    echo "❌ Not detected"
fi

echo ""
echo "CocoaPods:"
if [ "$FORGE_USE_COCOAPODS" = "true" ]; then
    echo "✅ Required"
else
    echo "❌ Not detected"
fi

echo ""
echo "Carthage:"
if [ "$FORGE_USE_CARTHAGE" = "true" ]; then
    echo "✅ Required"
else
    echo "❌ Not detected"
fi

echo ""
echo "mise:"
if [ "$FORGE_USE_MISE" = "true" ]; then
    echo "✅ Required"
else
    echo "❌ Not detected"
fi

# --------------------------------------------------
# 6. Save Forge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$BUILD_TYPE"
FORGE_BUILD_FILE="$BUILD_FILE"
FORGE_SCHEME="$SCHEME"

FORGE_USE_SPM="$FORGE_USE_SPM"
FORGE_USE_COCOAPODS="$FORGE_USE_COCOAPODS"
FORGE_USE_CARTHAGE="$FORGE_USE_CARTHAGE"
FORGE_USE_MISE="$FORGE_USE_MISE"
EOF

echo ""
echo "======================================"
echo "⚙️ Forge Configuration"
echo "======================================"

cat "$CONFIG_FILE"

echo ""
echo "======================================"
echo "✅ Analysis Complete"
echo "======================================"
