#!/bin/bash
set -e

echo "======================================"
echo "⚒ iForge — Export IPA"
echo "======================================"

cd project

CONFIG_FILE="build/forge.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ iForge configuration not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

ARCHIVE_PATH="build/Forge.xcarchive"
EXPORT_PATH="build/export"
STAGING_PATH="build/ipa-staging"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found: $ARCHIVE_PATH"
    exit 1
fi

echo ""
echo "🔍 Finding Application"
APP_PATH=$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -type d -name "*.app" -print -quit)
if [ -z "$APP_PATH" ]; then
    echo "❌ No .app found inside archive."
    exit 1
fi

APP_NAME=$(basename "$APP_PATH" .app)
if [ "$APP_NAME" = "iForge" ]; then
    IPA_NAME="iForge-Build.ipa"
else
    IPA_NAME="${APP_NAME}.ipa"
fi
IPA_PATH="$EXPORT_PATH/$IPA_NAME"

echo "Application: $APP_NAME.app"
echo "IPA: $IPA_NAME"

rm -rf "$STAGING_PATH"
mkdir -p "$STAGING_PATH/Payload" "$EXPORT_PATH"
cp -R "$APP_PATH" "$STAGING_PATH/Payload/"

cd "$STAGING_PATH"
zip -qry "../export/$IPA_NAME" Payload
cd ..

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA was not created: $IPA_PATH"
    exit 1
fi

echo ""
echo "Size:"
du -h "$IPA_PATH"
echo ""
echo "✅ IPA Ready: $IPA_PATH"
