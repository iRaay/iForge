#!/bin/bash
set -e

echo "==============================="
echo "📦 Export Results"
echo "==============================="

cd project

echo ""
echo "Searching for archives..."

find build -name "*.xcarchive"

echo ""
echo "Searching for ipa..."

find build -name "*.ipa"

echo ""
echo "Searching for app..."

find build -name "*.app"

echo ""
echo "✅ Export Complete"
