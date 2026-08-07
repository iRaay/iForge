#!/bin/bash

set -e

echo "🔍 Analyzing project..."

find . -name "*.xcodeproj"
find . -name "*.xcworkspace"
find . -name "Package.swift"
find . -name "Podfile"
find . -name "mise.toml"
find . -name "Tuist.swift"
