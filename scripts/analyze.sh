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
  -name "*.xcworkspace" \
  -not -path "*/Pods/*" \
  -not -path "*/.xcodeproj/*" \
  | head -n 1)

# --------------------------------------------------
# 2. Detect Xcode Project
# --------------------------------------------------

PROJECT=$(find . \
  -name "*.xcodeproj" \
  -not -path "*/Pods/*" \
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
# 5. Save Forge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$BUILD_TYPE"
FORGE_BUILD_FILE="$BUILD_FILE"
FORGE_SCHEME="$SCHEME"
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
