#!/bin/bash
set -e

echo "============================"
echo "📦 Export IPA"
echo "============================"

ARCHIVE_PATH="build/Navi.xcarchive"
EXPORT_PATH="build/export"

echo ""
echo "Archive:"
echo "$ARCHIVE_PATH"

echo ""
echo "Export Path:"
echo "$EXPORT_PATH"

mkdir -p "$EXPORT_PATH"

xcodebuild \
-exportArchive \
-archivePath "$ARCHIVE_PATH" \
-exportOptionsPlist scripts/ExportOptions.plist \
-exportPath "$EXPORT_PATH"

echo ""
echo "============================"
echo "📂 Export Result"
echo "============================"

find "$EXPORT_PATH" -type f

echo ""
echo "✅ Finished"
