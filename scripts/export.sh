#!/bin/bash
set -e

echo "======================================"
echo "⚒ Forge — Export Unsigned IPA"
echo "======================================"

cd project

# --------------------------------------------------
# 1. Forge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Forge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# --------------------------------------------------
# 2. Archive
# --------------------------------------------------

ARCHIVE_PATH="build/Forge.xcarchive"
EXPORT_PATH="build/export"
STAGING_PATH="build/ipa-staging"
IPA_PATH="$EXPORT_PATH/Forge-unsigned.ipa"

echo ""
echo "======================================"
echo "📦 Archive"
echo "======================================"

echo "$ARCHIVE_PATH"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found:"
    echo "$ARCHIVE_PATH"
    exit 1
fi

# --------------------------------------------------
# 3. Find Application
# --------------------------------------------------

echo ""
echo "======================================"
echo "🔍 Finding Application"
echo "======================================"

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

echo "Application:"
echo "$APP_PATH"

# --------------------------------------------------
# 4. Prepare IPA Structure
# --------------------------------------------------

echo ""
echo "======================================"
echo "📁 Preparing IPA"
echo "======================================"

rm -rf "$STAGING_PATH"
mkdir -p "$STAGING_PATH/Payload"
mkdir -p "$EXPORT_PATH"

cp -R "$APP_PATH" "$STAGING_PATH/Payload/"

# --------------------------------------------------
# 5. Create Unsigned IPA
# --------------------------------------------------

echo ""
echo "======================================"
echo "📦 Creating Unsigned IPA"
echo "======================================"

cd "$STAGING_PATH"

zip -qry \
    "../export/Forge-unsigned.ipa" \
    Payload

cd ..

# --------------------------------------------------
# 6. Verify IPA
# --------------------------------------------------

echo ""
echo "======================================"
echo "🔎 Verifying IPA"
echo "======================================"

if [ ! -f "export/Forge-unsigned.ipa" ]; then
    echo "❌ IPA was not created."
    exit 1
fi

echo ""
echo "IPA:"
echo "build/export/Forge-unsigned.ipa"

echo ""
echo "Size:"
du -h "export/Forge-unsigned.ipa"

echo ""
echo "======================================"
echo "📂 Export Result"
echo "======================================"

find "export" -maxdepth 1 -type f -print

echo ""
echo "======================================"
echo "✅ Unsigned IPA Ready"
echo "======================================"
