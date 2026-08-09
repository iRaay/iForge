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

    PROJECT_NAME="$(basename "$FORGE_BUILD_FILE" .xcodeproj)"
    GENERATED_WORKSPACE="./${PROJECT_NAME}.xcworkspace"

    if [ -d "$GENERATED_WORKSPACE" ]; then
        FORGE_BUILD_TYPE="workspace"
        FORGE_BUILD_FILE="$GENERATED_WORKSPACE"

        echo ""
        echo "✅ CocoaPods workspace detected:"
        echo "$FORGE_BUILD_FILE"
    else
        echo "❌ pod install completed, but no .xcworkspace was found."
        exit 1
    fi

    cat > "$CONFIG_FILE" <<EOF
FORGE_BUILD_TYPE="$FORGE_BUILD_TYPE"
FORGE_BUILD_FILE="$FORGE_BUILD_FILE"
FORGE_SCHEME="$FORGE_SCHEME"

FORGE_USE_SPM="$FORGE_USE_SPM"
FORGE_USE_COCOAPODS="$FORGE_USE_COCOAPODS"
FORGE_USE_CARTHAGE="$FORGE_USE_CARTHAGE"
FORGE_USE_MISE="$FORGE_USE_MISE"
EOF

else

    echo ""
    echo "🍫 CocoaPods"
    echo "⏭️ Not required — skipping"

fi
