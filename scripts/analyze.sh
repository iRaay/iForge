#!/bin/bash
set -e

echo "=============================="
echo "🔍 iOS Project Analyzer"
echo "=============================="

cd project

echo ""
echo "📁 Current Directory:"
pwd

echo ""
echo "📦 Xcode Projects:"
find . -name "*.xcodeproj"

PROJECT=$(find . -name "*.xcodeproj" | head -n 1)

if [ -z "$PROJECT" ]; then
  echo "❌ No Xcode project found."
  exit 1
fi

echo ""
echo "✅ Project:"
echo "$PROJECT"

echo ""
echo "=============================="
echo "📋 Project Information"
echo "=============================="

xcodebuild -list -project "$PROJECT"

echo ""
echo "=============================="
echo "📱 Available Schemes"
echo "=============================="

xcodebuild -list -project "$PROJECT" | sed -n '/Schemes:/,$p'

echo ""
echo "=============================="
echo "📦 Swift Packages"
echo "=============================="

xcodebuild \
-list \
-project "$PROJECT" \
-showBuildSettings > /dev/null

echo "Resolved successfully."

echo ""
echo "=============================="
echo "✅ Analysis Complete"
echo "=============================="
