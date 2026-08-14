#!/bin/bash
set -Eeuo pipefail

trap 'echo "❌ Export failed at line $LINENO: $BASH_COMMAND"' ERR

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

# Keep paths anchored to the project root so changing directories later
# cannot invalidate the IPA existence check.
PROJECT_ROOT="$(pwd)"
ARCHIVE_PATH="$PROJECT_ROOT/build/Forge.xcarchive"
EXPORT_PATH="$PROJECT_ROOT/build/export"
STAGING_PATH="$PROJECT_ROOT/build/ipa-staging"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found: $ARCHIVE_PATH"
    exit 1
fi

echo ""
echo "🔍 Finding Application"

# iForge supports arbitrary iOS projects. Never hard-code target app names.
# The first .app found in the archive determines the IPA filename.
APP_PATH=$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -type d -name "*.app" -print -quit)
if [ -z "$APP_PATH" ]; then
    echo "❌ No .app found inside archive."
    exit 1
fi

APP_NAME="$(basename "$APP_PATH" .app)"

# iForge itself keeps its branded distribution filename.
# All other apps use their detected .app bundle name automatically.
if [ "$APP_NAME" = "iForge" ]; then
    IPA_NAME="iForge-Build.ipa"
else
    IPA_NAME="${APP_NAME}.ipa"
fi

IPA_PATH="$EXPORT_PATH/$IPA_NAME"

echo "Application: $APP_NAME.app"
echo "IPA: $IPA_NAME"
echo "IPA path: $IPA_PATH"

echo ""
echo "📦 Preparing IPA"
rm -rf "$STAGING_PATH"
mkdir -p "$STAGING_PATH/Payload" "$EXPORT_PATH"
cp -R "$APP_PATH" "$STAGING_PATH/Payload/"

# Create the IPA from the staging directory using the absolute output path.
# This prevents relative-path bugs during validation.
rm -f "$IPA_PATH"
cd "$STAGING_PATH"
/usr/bin/zip -qry "$IPA_PATH" Payload
cd "$PROJECT_ROOT"

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA was not created: $IPA_PATH"
    echo ""
    echo "Export directory contents:"
    find "$EXPORT_PATH" -maxdepth 2 -print 2>/dev/null || true
    exit 1
fi

if [ ! -s "$IPA_PATH" ]; then
    echo "❌ IPA was created but is empty: $IPA_PATH"
    exit 1
fi

if ! /usr/bin/unzip -tq "$IPA_PATH" >/dev/null; then
    echo "❌ IPA archive validation failed: $IPA_PATH"
    exit 1
fi

if ! /usr/bin/unzip -l "$IPA_PATH" | grep -q 'Payload/[^/]\+\.app/'; then
    echo "❌ IPA does not contain an application bundle under Payload/."
    exit 1
fi

echo ""
echo "Size:"
du -h "$IPA_PATH"
echo ""
echo "======================================"
echo "✅ IPA Ready"
echo "======================================"
echo "$IPA_PATH"
