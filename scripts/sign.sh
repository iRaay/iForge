#!/bin/bash
set -e

echo "==============================="
echo "🔐 Signing Environment"
echo "==============================="

echo ""
echo "Current directory:"
pwd

echo ""
echo "Searching certificates..."

find certificates -type f || true

echo ""
echo "Available Keychains:"

security list-keychains || true

echo ""
echo "Installed identities:"

security find-identity -v -p codesigning || true

echo ""
echo "✅ Signing check complete"
