#!/bin/bash
set -e

echo "======================================"
echo "⚒ iForge — Export IPA"
echo "======================================"

cd project
PROJECT_ROOT="$(pwd)"

CONFIG_FILE="$PROJECT_ROOT/build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ iForge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

ARCHIVE_PATH="$PROJECT_ROOT/build/Forge.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/build/export"
STAGING_PATH="$PROJECT_ROOT/build/ipa-staging"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found:"
    echo "$ARCHIVE_PATH"
    exit 1
fi

echo ""
echo "🔍 Finding Application"

APP_PATH=$(find \
    "$ARCHIVE_PATH/Products/Applications" \
    -maxdepth 1 \
    -type d \
    -name "*.app" \
    -print \
    -quit)

if [ -z "$APP_PATH" ]; then
    echo "❌ No .app found inside archive."
    exit 1
fi

APP_NAME="$(basename "$APP_PATH" .app)"

if [ "$APP_NAME" = "iForge" ]; then
    IPA_NAME="iForge-Build.ipa"
else
    IPA_NAME="${APP_NAME}.ipa"
fi

IPA_PATH="$EXPORT_PATH/$IPA_NAME"

echo "Application: $APP_NAME.app"
echo "IPA: $IPA_NAME"

# --------------------------------------------------
# Safari / App Extensions
# --------------------------------------------------

echo ""
echo "🔌 Checking embedded extensions"

EXTENSION_COUNT=0

if [ -d "$APP_PATH/PlugIns" ]; then

    while IFS= read -r EXTENSION; do
        if [ -n "$EXTENSION" ]; then
            EXTENSION_COUNT=$((EXTENSION_COUNT + 1))
            echo "✅ Extension found:"
            echo "   $(basename "$EXTENSION")"
        fi
    done < <(
        find "$APP_PATH/PlugIns" \
            -maxdepth 1 \
            -type d \
            -name "*.appex" \
            -print
    )

else

    echo "ℹ️ No PlugIns directory found."

fi

echo "Extension count: $EXTENSION_COUNT"

# --------------------------------------------------
# Prepare IPA
# --------------------------------------------------

echo ""
echo "📦 Preparing IPA"

rm -rf "$STAGING_PATH"
rm -f "$IPA_PATH"

mkdir -p \
    "$STAGING_PATH/Payload" \
    "$EXPORT_PATH"

cp -R "$APP_PATH" "$STAGING_PATH/Payload/"

echo ""
echo "📁 IPA contents before compression:"

find "$STAGING_PATH/Payload" \
    -maxdepth 3 \
    -type d \
    -name "*.appex" \
    -print || true

# --------------------------------------------------
# Create IPA
# --------------------------------------------------

echo ""
echo "🗜 Creating IPA"

(
    cd "$STAGING_PATH"
    zip -qry "$IPA_PATH" Payload
)

# --------------------------------------------------
# Validate IPA
# --------------------------------------------------

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA was not created:"
    echo "$IPA_PATH"
    exit 1
fi

echo ""
echo "🔎 Validating IPA"

if ! unzip -tq "$IPA_PATH" >/dev/null; then
    echo "❌ IPA archive validation failed."
    exit 1
fi

echo "✅ IPA archive is valid."

if [ "$EXTENSION_COUNT" -gt 0 ]; then

    echo ""
    echo "🔌 Validating embedded extensions"

    if unzip -l "$IPA_PATH" | grep -q "PlugIns/.*\.appex/"; then
        echo "✅ Embedded extension preserved inside IPA."
    else
        echo "❌ Extension was present before compression but is missing from IPA."
        exit 1
    fi

fi

echo ""
echo "Size:"
du -h "$IPA_PATH"

echo ""
echo "======================================"
echo "✅ IPA Ready"
echo "======================================"
echo "$IPA_PATH"
