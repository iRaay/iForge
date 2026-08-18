#!/bin/bash
set -euo pipefail

echo "======================================"
echo "📦 iForge — Source Preparation"
echo "======================================"
echo ""

PROJECT_DIR="project"
cd "$PROJECT_DIR"
mkdir -p build/logs

LOG_FILE="build/logs/source-preparation.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔎 Checking Git submodules..."

if [ ! -f .gitmodules ]; then
    echo "ℹ️ No .gitmodules file found."
    echo "✅ Source preparation complete."
    exit 0
fi

echo ""
echo "📋 Submodules declared by source repository:"
git config -f .gitmodules --get-regexp '^submodule\..*\.url$' || true

echo ""
echo "🔐 Validating submodule URLs..."

INVALID=0
while IFS= read -r LINE; do
    [ -z "$LINE" ] && continue

    URL="${LINE#* }"

    # iForge intentionally permits HTTPS submodule sources only.
    # This prevents file://, local paths, SSH/scp syntax, and other transports
    # from being used to reach the runner or an unexpected network endpoint.
    if [[ "$URL" != https://* ]]; then
        echo "❌ Rejected submodule URL (HTTPS required): $URL"
        INVALID=1
        continue
    fi

    # Never accept embedded credentials in a source URL.
    if [[ "$URL" =~ ^https://[^/]*@ ]]; then
        echo "❌ Rejected submodule URL containing embedded credentials."
        INVALID=1
        continue
    fi

done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.url$' || true)

if [ "$INVALID" -ne 0 ]; then
    echo ""
    echo "❌ Source preparation stopped for security reasons."
    echo "   Only credential-free HTTPS submodule URLs are supported."
    echo "   Private submodules must be made accessible through a future iForge-managed credential flow."
    exit 1
fi

echo "✅ Submodule URL validation passed."
echo ""
echo "🔄 Initializing submodules recursively..."

export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/usr/bin/false

# Explicitly disable local-file transport and interactive credential prompts.
git -c protocol.file.allow=never -c credential.helper= submodule sync --recursive
git -c protocol.file.allow=never -c credential.helper= submodule update --init --recursive --depth 1

echo ""
echo "🔎 Verifying submodule state..."
git submodule status --recursive

echo ""
echo "======================================"
echo "✅ Source Preparation Complete"
echo "======================================"
