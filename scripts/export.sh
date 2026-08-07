#!/bin/bash
set -e

echo "=============================="
echo "📦 Export Results"
echo "=============================="

cd project

echo ""
echo "Searching for build products..."

find . \
-name "*.app" \
-o -name "*.ipa" \
-o -name "*.xcarchive"

echo ""
echo "✅ Export Complete"
