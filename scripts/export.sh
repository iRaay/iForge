#!/bin/bash
set -e

echo "======================================"
echo "⚒ Forge — Export"
echo "======================================"

cd project

# --------------------------------------------------
# 1. Load Forge Configuration
# --------------------------------------------------

CONFIG_FILE="build/forge.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Forge configuration not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# --------------------------------------------------
# 2. Validate Configuration
# --------------------------------------------------

if [ -z "$FORGE_SCHEME" ]; then
    echo "❌ FORGE_SCHEME is missing."
    exit 1
fi

# --------------------------------------------------
# 3. Archive Path
# --------------------------------------------------

ARCHIVE_PATH="build/Forge.xcarchive"
EXPORT_PATH="build/export"

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
# 4. Export Path
# --------------------------------------------------

mkdir -p "$EXPORT_PATH"

echo ""
echo "======================================"
echo "📤 Export"
echo "======================================"

echo "Export Path:"
echo "$EXPORT_PATH"

# --------------------------------------------------
# 5. Export IPA
# --------------------------------------------------

xcodebuild \
-exportArchive \
-archivePath "$ARCHIVE_PATH" \
-exportOptionsPlist scripts/ExportOptions.plist \
-exportPath "$EXPORT_PATH"

# --------------------------------------------------
# 6. Show Result
# --------------------------------------------------

echo ""
echo "======================================"
echo "📂 Export Result"
echo "======================================"

find "$EXPORT_PATH" -type f -maxdepth 2 -print

echo ""
echo "======================================"
echo "✅ Export Finished"
echo "======================================"
